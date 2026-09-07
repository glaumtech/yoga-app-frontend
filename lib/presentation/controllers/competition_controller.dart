import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/championship_style.dart';
import '../../core/utils/storage_service.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/services/first_competition_gate_service.dart';
import '../../routes/app_router.dart';
import '../../core/utils/photo_upload_processor.dart';
import '../../data/repositories/competition_repository.dart';
import '../../data/models/competition_model.dart';
import '../../data/models/category_config_model.dart';
import '../../data/models/competition_grade_model.dart';
import '../../data/models/user_management_model.dart';
import '../models/competition_grade_entry.dart';
import '../../data/models/competition_option_model.dart';
import '../../core/utils/subscription_catalog_filter.dart';
import '../../data/models/subscription_mode_model.dart';
import '../../data/models/subscription_package_model.dart';
import '../../data/repositories/payment_repository.dart';
import '../../services/razorpay_checkout_service.dart';
import '../widgets/pinned_scroll_views.dart';

enum BrochureFileKind { image, pdf, unknown }

class CompetitionController extends GetxController {
  static const int brochureMaxPdfBytes = 25 * 1024 * 1024;
  static const String brochureUploadNotes =
      'Accepted: JPG, PNG, or PDF\n'
      '• Images over 2 MB are compressed to 2 MB\n'
      '• PDF: max 25 MB';

  final CompetitionRepository _repository = CompetitionRepository();
  final PaymentRepository _paymentRepository = PaymentRepository();
  final RazorpayCheckoutService _razorpayCheckout = RazorpayCheckoutService();

  // Form controllers — keys are replaced when the form subtree is (re)shown so one
  // GlobalKey is never attached to two widgets during list/form transitions.
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> get formKey => _formKey;

  final RxInt formKeyRevision = 0.obs;

  /// Bumped when any competition date changes so date [FormField]s rebuild.
  final RxInt competitionDatesRevision = 0.obs;

  static const String dateFieldStart = 'start';
  static const String dateFieldEnd = 'end';
  static const String dateFieldStartTime = 'startTime';
  static const String dateFieldEndTime = 'endTime';
  static const String dateFieldDisplayAd = 'displayAd';
  static const String dateFieldResultsPublishTime = 'resultsPublishTime';

  final RxSet<String> touchedCompetitionDateFields = <String>{}.obs;

  static const int descriptionMinLength = 10;
  static const String descriptionMinLengthMessage =
      'Description is required and must be at least 10 characters';

  static const int addressMinLength = 10;
  static const String addressMinLengthMessage =
      'Address is required and must be at least 10 characters';

  final RxBool descriptionTouched = false.obs;
  final RxString descriptionText = ''.obs;
  final RxBool addressTouched = false.obs;
  final RxString addressText = ''.obs;

  void markDescriptionTouched() {
    descriptionTouched.value = true;
  }

  void markAddressTouched() {
    addressTouched.value = true;
  }

  void _refreshFormKeys() {
    _formKey = GlobalKey<FormState>();
    formKeyRevision.value++;
  }

  void notifyCompetitionDatesChanged() {
    competitionDatesRevision.value++;
  }

  void markCompetitionDateFieldTouched(String fieldKey) {
    touchedCompetitionDateFields.add(fieldKey);
  }

  bool shouldShowCompetitionDateError(String fieldKey) {
    return hasAttemptedSubmit.value ||
        touchedCompetitionDateFields.contains(fieldKey);
  }

  void clearCompetitionDateFieldTouches() {
    touchedCompetitionDateFields.clear();
  }

  void _notifyError(String message) {
    errorMessage.value = message;
    SnackbarHelper.showErrorMessage(message);
  }

  void _notifySuccess(String message) {
    SnackbarHelper.showSuccessMessage(message);
  }

  /// Section keys used to scroll when non-FormField checks fail on submit.
  final GlobalKey competitionNameFieldKey = GlobalKey();
  final GlobalKey descriptionFieldKey = GlobalKey();
  final GlobalKey addressFieldKey = GlobalKey();
  final GlobalKey eventStartDateFieldKey = GlobalKey();
  final GlobalKey eventEndDateFieldKey = GlobalKey();
  final GlobalKey displayAdFromFieldKey = GlobalKey();
  final GlobalKey eventEndTimeFieldKey = GlobalKey();
  final GlobalKey resultsPublishTimeFieldKey = GlobalKey();
  final GlobalKey participantsPerStageFieldKey = GlobalKey();
  final GlobalKey prizesSectionKey = GlobalKey();
  final GlobalKey categoriesSectionKey = GlobalKey();
  final GlobalKey stagesSectionKey = GlobalKey();
  final GlobalKey gradesSectionKey = GlobalKey();
  final GlobalKey brochureSectionKey = GlobalKey();

  final FocusNode competitionNameFocusNode = FocusNode();
  final FocusNode descriptionFocusNode = FocusNode();
  final FocusNode addressFocusNode = FocusNode();

  bool _validateFormState() {
    final state = formKey.currentState;
    if (state == null) {
      _notifyError('Form is not ready. Please try again.');
      return false;
    }
    final isValid = state.validate();
    if (!isValid) {
      // Prefer stable section keys: FormField elements can remount after Obx
      // rebuilds triggered by hasAttemptedSubmit.
      final scrolled = scrollToFirstMissingMandatorySection(
        includeBrochure: !isEditMode.value,
      );
      if (!scrolled) {
        scrollToFirstInvalidFormField();
      }
      SnackbarHelper.showErrorMessage('Please fill all mandatory fields');
    }
    return isValid;
  }

  /// Scrolls to the first [FormField] with a validation error and focuses it
  /// when it is a text input.
  void scrollToFirstInvalidFormField() {
    final formContext = formKey.currentContext;
    if (formContext == null) return;

    BuildContext? firstInvalid;
    void visit(Element element) {
      if (firstInvalid != null) return;
      if (element is StatefulElement) {
        final fieldState = element.state;
        if (fieldState is FormFieldState &&
            fieldState.mounted &&
            fieldState.hasError) {
          firstInvalid = element;
          return;
        }
      }
      element.visitChildren(visit);
    }

    formContext.visitChildElements(visit);
    final target = firstInvalid;
    if (target == null) return;
    _scrollToAndFocus(target);
  }

  void scrollToSection(GlobalKey key, {FocusNode? focusNode}) {
    final context = key.currentContext;
    if (context == null) return;
    _scrollToAndFocus(context, focusNode: focusNode);
  }

  void _scrollToAndFocus(BuildContext context, {FocusNode? focusNode}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
      if (focusNode != null) {
        focusNode.requestFocus();
        return;
      }
      _requestTextFocusIn(context);
    });
  }

  void _requestTextFocusIn(BuildContext context) {
    var focused = false;
    void visit(Element element) {
      if (focused) return;
      final widget = element.widget;
      if (widget is EditableText) {
        widget.focusNode.requestFocus();
        focused = true;
        return;
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
  }

  /// Scrolls to the first missing mandatory value after form-level checks.
  /// Returns true when a target section was found.
  bool scrollToFirstMissingMandatorySection({
    required bool includeBrochure,
  }) {
    if (competitionNameController.text.trim().isEmpty) {
      scrollToSection(
        competitionNameFieldKey,
        focusNode: competitionNameFocusNode,
      );
      return true;
    }
    if (descriptionController.text.trim().length < descriptionMinLength) {
      scrollToSection(descriptionFieldKey, focusNode: descriptionFocusNode);
      return true;
    }
    if (addressController.text.trim().length < addressMinLength) {
      scrollToSection(addressFieldKey, focusNode: addressFocusNode);
      return true;
    }
    if (eventStartDate.value == null) {
      scrollToSection(eventStartDateFieldKey);
      return true;
    }
    if (eventEndDate.value == null) {
      scrollToSection(eventEndDateFieldKey);
      return true;
    }
    if (displayAdFrom.value == null) {
      scrollToSection(displayAdFromFieldKey);
      return true;
    }
    if (eventEndTime.value == null) {
      scrollToSection(eventEndTimeFieldKey);
      return true;
    }
    if (!publishResultNow.value && resultsPublishTime.value == null) {
      scrollToSection(resultsPublishTimeFieldKey);
      return true;
    }
    if (categoryConfigDrafts.isNotEmpty) {
      if (categoryConfigDrafts.any(
        (c) => c.isAsanas && !c.configured,
      )) {
        scrollToSection(categoriesSectionKey);
        return true;
      }
    } else {
      if (participantsPerStage.value <= 0) {
        scrollToSection(participantsPerStageFieldKey);
        return true;
      }
      if (selectedPrizeIds.isEmpty) {
        scrollToSection(prizesSectionKey);
        return true;
      }
      if (selectedCategoryIds.isEmpty) {
        scrollToSection(categoriesSectionKey);
        return true;
      }
      if (selectedStageIds.isEmpty) {
        scrollToSection(stagesSectionKey);
        return true;
      }
    }
    if (validateGradeEntries() != null) {
      scrollToSection(gradesSectionKey);
      return true;
    }
    final hasBrochure =
        brochureFile.value != null ||
        brochureFileLocal.value != null ||
        brochureBytes.value != null;
    if (includeBrochure && !hasBrochure) {
      scrollToSection(brochureSectionKey);
      return true;
    }
    return false;
  }

  final competitionNameController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();

  // Observable state
  final RxBool isLoading = false.obs;
  /// Loading flag for Add More prize/category/stage/group dialogs only.
  /// Kept separate from [isLoading] so the create form does not rebuild under an open dialog.
  final RxBool isAddingOption = false.obs;
  /// Guards concurrent prize/category/stage/group option list fetches.
  final RxBool isLoadingOptions = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<CompetitionModel> competitions = <CompetitionModel>[].obs;

  /// Public list for home screen (from GET /competition/public)
  final RxList<HomeCompetitionModel> homeCompetitions =
      <HomeCompetitionModel>[].obs;
  final RxBool isLoadingHomeCompetitions = false.obs;

  /// Tracks which login/branch scope [homeCompetitions] was loaded for.
  String? _homeCompetitionsScope;

  /// Tracks which scope [competitions] dropdown choices were synced for.
  String? _competitionChoicesScope;
  final RxString searchQuery = ''.obs;
  final RxString selectedFilter = ''.obs;
  final RxBool isListView = false.obs; // Toggle between create and list view
  final RxBool hasAttemptedSubmit =
      false.obs; // Track if form has been submitted
  final RxBool isEditMode = false.obs; // Track if in edit/view mode
  final RxBool isViewMode = false.obs; // Track if in view-only mode
  final Rx<CompetitionModel?> competitionToEdit = Rx<CompetitionModel?>(
    null,
  ); // Competition being edited

  /// Set after successful create; used to show registration QR dialog.
  final Rx<CompetitionModel?> lastSavedCompetitionForQr = Rx<CompetitionModel?>(
    null,
  );

  final RxBool showSubscriptionTopUp = false.obs;
  final RxBool isLoadingSubscriptionModes = false.obs;
  final RxBool isLoadingSubscriptionPackages = false.obs;
  final RxBool isProcessingSubscriptionPayment = false.obs;
  final RxString subscriptionModesError = ''.obs;
  final RxString subscriptionPackagesError = ''.obs;
  final RxList<SubscriptionModeModel> subscriptionModes =
      <SubscriptionModeModel>[].obs;
  final RxList<SubscriptionPackageModel> subscriptionPackages =
      <SubscriptionPackageModel>[].obs;
  final RxList<SubscriptionPackageModel> _allSubscriptionPackages =
      <SubscriptionPackageModel>[].obs;
  int _subscriptionPackageLoadSeq = 0;
  final RxnInt selectedSubscriptionModeId = RxnInt();
  final RxnInt selectedSubscriptionPackageId = RxnInt();
  final RxBool showSubscriptionAddonOptions = false.obs;

  final RxBool isOnDemandOrg = true.obs;
  final RxBool isLoadingOnDemandContext = false.obs;
  final RxInt onDemandMaintenanceFeePaise = 0.obs;
  final RxInt onDemandAsanasFeePaise = 500000.obs;
  final RxInt onDemandChallengeFeePaise = 100000.obs;
  final RxDouble onDemandPaymentGatewayFeePercent = 3.0.obs;
  final RxDouble onDemandPlatformFeePercent = 3.0.obs;
  final RxBool onDemandExtraFeeForCompetition = true.obs;
  final RxBool onDemandExtraFeeForParticipantReg = false.obs;
  final RxMap<String, bool> categoryIncludeFee = <String, bool>{}.obs;
  final RxString organizationPaymentModel =
      SubscriptionCatalogFilter.onDemandModeKey.obs;
  final RxBool isProcessingCompetitionPayment = false.obs;
  final RxBool maintenancePaidAsanas = false.obs;
  final RxBool maintenancePaidChallenge = false.obs;

  /// On Demand: pay when creating, or when edit adds a format that is not paid yet.
  bool get requiresPrepaidCompetitionPayment {
    if (isViewMode.value || !isOnDemandOrg.value) return false;
    return unpaidAsanasForPayment || unpaidChallengeForPayment;
  }

  String get createCompetitionButtonLabel =>
      requiresPrepaidCompetitionPayment
          ? 'Pay and Finalize'
          : (isEditMode.value ? 'Save changes' : 'Finalize');

  // Search controller and debounce
  final TextEditingController searchController = TextEditingController();
  Timer? _debounceTimer;

  // Pagination and sorting
  final RxInt currentPage = 1.obs;
  final RxInt itemsPerPage = 20.obs;
  final RxInt totalItems = 0.obs;
  final RxInt totalPages = 0.obs;
  final RxString sortBy =
      'createdAt'.obs; // createdAt, eventStartDate, eventEndDate
  final RxString sortOrder = 'desc'.obs; // asc, desc
  final Rx<DateTime?> eventStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> eventEndDate = Rx<DateTime?>(null);
  final Rx<TimeOfDay?> eventStartTime = Rx<TimeOfDay?>(null);
  final Rx<TimeOfDay?> eventEndTime = Rx<TimeOfDay?>(null);
  final Rx<DateTime?> displayAdFrom = Rx<DateTime?>(null);
  final RxBool publishResultNow = false.obs;
  final Rx<TimeOfDay?> resultsPublishTime = Rx<TimeOfDay?>(null);
  final RxBool spotRegistration = false.obs;
  final Rx<ChampionshipStyle?> championshipStyle =
      Rx<ChampionshipStyle?>(ChampionshipStyle.separateCategory);
  /// ONLINE | OFFLINE
  final RxString competitionMode = 'OFFLINE'.obs;
  final TextEditingController googleDriveFolderUrlController =
      TextEditingController();
  final RxString googleDriveServiceAccountEmail = ''.obs;
  final RxBool googleDriveServerConfigured = false.obs;

  /// Server explanation when Drive uploads cannot run at all.
  final RxString googleDriveServerReason = ''.obs;
  /// Per-category Asanas/Challenge drafts for the redesigned create flow.
  final RxList<CompetitionCategoryConfigModel> categoryConfigDrafts =
      <CompetitionCategoryConfigModel>[].obs;
  final RxInt participantsPerStage = RxInt(0);
  final RxInt minimumMarks = RxInt(0);
  final RxInt maximumMarks = RxInt(0);
  final RxInt skippedAsanaMarks = RxInt(0);
  final TextEditingController bestSchoolAwardMinParticipantsController =
      TextEditingController();
  // Track selected IDs (for API submission)
  final RxList<int> selectedPrizeIds = <int>[].obs;
  final RxList<int> selectedCategoryIds = <int>[].obs;
  final RxMap<String, double> categoryAmounts =
      <String, double>{}.obs;
  final RxMap<String, double> categorySpotAmounts =
      <String, double>{}.obs; // Key: category ID as string
  final RxList<int> selectedStageIds = <int>[].obs;
  final RxMap<String, List<int>> stageGroups = <String, List<int>>{}
      .obs; // Key: stage ID as string, Value: list of group IDs

  final RxList<CompetitionGradeEntry> gradeEntries =
      <CompetitionGradeEntry>[].obs;

  // Helper getters for backward compatibility (for UI display)
  List<String> get selectedPrizes => selectedPrizeIds
      .map((id) {
        final option = prizeOptions.firstWhereOrNull((opt) => opt.id == id);
        return option?.name ?? '';
      })
      .where((name) => name.isNotEmpty)
      .toList();

  List<String> get selectedCategories => selectedCategoryIds
      .map((id) {
        final option = categoryOptions.firstWhereOrNull((opt) => opt.id == id);
        return option?.name ?? '';
      })
      .where((name) => name.isNotEmpty)
      .toList();

  List<String> get selectedStages => selectedStageIds
      .map((id) {
        final option = stageOptions.firstWhereOrNull((opt) => opt.id == id);
        return option?.name ?? '';
      })
      .where((name) => name.isNotEmpty)
      .toList();

  // File handling
  final Rx<XFile?> brochureFile = Rx<XFile?>(null);
  final Rx<File?> brochureFileLocal = Rx<File?>(null);
  final Rx<Uint8List?> brochureBytes = Rx<Uint8List?>(null);
  final RxString brochureFileName = ''.obs;
  final RxString brochureUrl = ''.obs;

  bool get hasLocalBrochure =>
      brochureBytes.value != null ||
      brochureFile.value != null ||
      brochureFileLocal.value != null;

  /// Magic-byte sniffing (more reliable than filename alone).
  static bool brochureBytesLookLikePdf(Uint8List bytes) {
    final scanLength = bytes.length < 2048 ? bytes.length : 2048;
    for (var i = 0; i <= scanLength - 4; i++) {
      if (bytes[i] == 0x25 &&
          bytes[i + 1] == 0x50 &&
          bytes[i + 2] == 0x44 &&
          bytes[i + 3] == 0x46) {
        return true;
      }
    }
    return false;
  }

  /// True when the body looks like a JSON API error, not a file.
  static bool brochureBytesLookLikeJson(Uint8List bytes) {
    for (var i = 0; i < bytes.length && i < 64; i++) {
      final b = bytes[i];
      if (b <= 32) continue;
      return b == 0x7b || b == 0x5b; // { or [
    }
    return false;
  }

  static bool brochureBytesLookLikeImage(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return true; // PNG
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return true; // JPEG
    }
    return false;
  }

  static bool _pathLooksLikePdf(String path) {
    final lower = path.trim().toLowerCase();
    return lower.endsWith('.pdf');
  }

  static bool _pathLooksLikeImage(String path) {
    final lower = path.trim().toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  /// Resolved brochure type for the current selection / saved file.
  BrochureFileKind get brochureFileKind {
    final bytes = brochureBytes.value;
    if (bytes != null && bytes.isNotEmpty) {
      if (brochureBytesLookLikeImage(bytes)) return BrochureFileKind.image;
      if (brochureBytesLookLikePdf(bytes)) return BrochureFileKind.pdf;
    }

    final name = brochureFileName.value.trim().toLowerCase();
    if (_pathLooksLikePdf(name)) return BrochureFileKind.pdf;
    if (_pathLooksLikeImage(name)) return BrochureFileKind.image;

    if (hasLocalBrochure) {
      return BrochureFileKind.unknown;
    }

    final url = brochureUrl.value.trim().toLowerCase();
    if (_pathLooksLikePdf(url)) return BrochureFileKind.pdf;
    if (_pathLooksLikeImage(url)) return BrochureFileKind.image;

    final apiUrl =
        competitionToEdit.value?.brochureUrl?.trim().toLowerCase() ?? '';
    if (_pathLooksLikePdf(apiUrl)) return BrochureFileKind.pdf;
    if (_pathLooksLikeImage(apiUrl)) return BrochureFileKind.image;

    return BrochureFileKind.unknown;
  }

  bool get isBrochurePdf => brochureFileKind == BrochureFileKind.pdf;

  bool get isBrochureImage => brochureFileKind == BrochureFileKind.image;

  /// Detect type from downloaded brochure bytes (API preview).
  static BrochureFileKind brochureKindFromBytes(
    Uint8List bytes, {
    String? contentType,
    bool filenameHintPdf = false,
  }) {
    if (brochureBytesLookLikeImage(bytes)) return BrochureFileKind.image;
    if (brochureBytesLookLikePdf(bytes)) return BrochureFileKind.pdf;

    final ct = contentType?.toLowerCase() ?? '';
    if (ct.contains('image/')) return BrochureFileKind.image;
    if (ct.contains('pdf')) return BrochureFileKind.pdf;

    return filenameHintPdf ? BrochureFileKind.pdf : BrochureFileKind.image;
  }

  final RxInt brochureUpdateTimestamp =
      0.obs; // Track brochure updates for cache-busting

  // Available options (loaded from API)
  final RxList<CompetitionOptionModel> prizeOptions =
      <CompetitionOptionModel>[].obs;
  final RxList<CompetitionOptionModel> categoryOptions =
      <CompetitionOptionModel>[].obs;
  final RxList<CompetitionOptionModel> stageOptions =
      <CompetitionOptionModel>[].obs;
  final RxList<CompetitionOptionModel> groupOptions =
      <CompetitionOptionModel>[].obs;

  // Static options (not loaded from API)
  static const List<int> participantsPerStageOptions = [1, 2, 3, 4, 5];
  static final List<int> marksOptions = List.generate(
    11,
    (index) => index,
  ); // 0-10

  // Helper getters to get names as strings (for backward compatibility)
  List<String> get prizeOptionNames => prizeOptions.map((e) => e.name).toList();
  List<String> get categoryOptionNames =>
      categoryOptions.map((e) => e.name).toList();
  List<String> get stageOptionNames => stageOptions.map((e) => e.name).toList();
  List<String> get groupOptionNames => groupOptions.map((e) => e.name).toList();

  // Default stage mappings (pre-selected groups when stage is first selected)
  // This will be dynamically generated based on loaded groups
  Map<String, List<String>> get defaultStageMappings {
    // Try to map stages to groups based on common patterns
    // This is a fallback if no specific mapping exists
    final Map<String, List<String>> mappings = {};
    if (stageOptionNames.isNotEmpty && groupOptionNames.isNotEmpty) {
      // Simple mapping: assign first few groups to first stage, etc.
      final groupsPerStage = (groupOptionNames.length / stageOptionNames.length)
          .ceil();
      for (int i = 0; i < stageOptionNames.length; i++) {
        final start = i * groupsPerStage;
        final end = (start + groupsPerStage).clamp(0, groupOptionNames.length);
        if (start < groupOptionNames.length) {
          mappings[stageOptionNames[i]] = groupOptionNames.sublist(start, end);
        }
      }
    }
    return mappings;
  }

  /// Scope key for home list: anonymous users see all; logged-in users see
  /// branch/org-scoped competitions (backend filters when JWT is present).
  String _homeCompetitionsScopeKey() {
    try {
      final userJson = StorageService.getString(AppConstants.userKey);
      if (userJson == null || userJson.isEmpty) return 'anon';
      final user = UserManagementModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      final type = (user.userTypeName ?? user.type).toUpperCase();
      if (type == 'ORG_ADMIN') return 'org:${user.id}';
      return 'branch:${user.branchId ?? 'none'}:${user.id}';
    } catch (_) {
      return 'anon';
    }
  }

  void invalidateHomeCompetitionsScope() {
    _homeCompetitionsScope = null;
    homeCompetitions.clear();
    invalidateCompetitionChoicesScope();
  }

  void invalidateCompetitionChoicesScope() {
    _competitionChoicesScope = null;
    competitions.clear();
  }

  /// Loads home competitions when scope changes or cache was invalidated.
  Future<void> ensureHomeCompetitionsLoaded() async {
    await _yieldPastBuildIfNeeded();
    final scope = _homeCompetitionsScopeKey();
    if (_homeCompetitionsScope == scope) {
      if (isLoadingHomeCompetitions.value) return;
      return;
    }
    await loadCompetitionsForHome();
  }

  /// Load competitions for home screen (public API; branch-scoped when logged in)
  Future<void> loadCompetitionsForHome({bool force = false}) async {
    await _yieldPastBuildIfNeeded();
    final scope = _homeCompetitionsScopeKey();
    if (!force && _homeCompetitionsScope == scope) {
      return;
    }
    try {
      isLoadingHomeCompetitions.value = true;
      final response = await _repository.getCompetitionsPublic();
      if (response.success && response.data != null) {
        homeCompetitions.value = response.data!;
        _homeCompetitionsScope = scope;
      } else {
        homeCompetitions.clear();
        _homeCompetitionsScope = null;
      }
    } catch (e) {
      homeCompetitions.clear();
      _homeCompetitionsScope = null;
    } finally {
      await _yieldPastBuildIfNeeded();
      isLoadingHomeCompetitions.value = false;
    }
  }

  /// Populates [competitions] for registration/admin form dropdowns.
  /// Uses the branch/org-scoped public list; falls back to the admin list when empty.
  Future<void> ensureRegistrationCompetitionChoicesLoaded({
    bool force = false,
  }) async {
    final scope = _homeCompetitionsScopeKey();
    if (!force &&
        _competitionChoicesScope == scope &&
        competitions.isNotEmpty) {
      return;
    }

    await loadCompetitionsForHome(
      force: force || _homeCompetitionsScope != scope,
    );

    competitions.clear();
    for (final home in homeCompetitions) {
      final id = home.id?.toString();
      if (id == null || id.isEmpty) continue;
      _upsertCompetition(_competitionFromHome(home, null));
    }
    _competitionChoicesScope = scope;

    if (competitions.isEmpty && !isLoading.value) {
      await loadCompetitions(resetPage: true);
      _competitionChoicesScope = scope;
    }
  }

  final RxBool isLoadingRegistrationCompetition = false.obs;

  /// Loads full competition data for the public/admin registration form.
  /// Safe after logout: does not rely on a prior [loadCompetitions] admin list call.
  Future<void> ensureCompetitionLoadedForRegistration(
    String competitionId,
  ) async {
    final id = competitionId.trim();
    if (id.isEmpty) return;

    final existing = competitions.firstWhereOrNull((c) => c.id == id);
    final hasGroupData =
        existing != null &&
        ((existing.stageGroups != null && existing.stageGroups!.isNotEmpty) ||
            (existing.stageGroupLabels != null &&
                existing.stageGroupLabels!.isNotEmpty));
    final hasCategoryFeeData = existing != null &&
        ((existing.categoryAmounts != null &&
                existing.categoryAmounts!.isNotEmpty) ||
            (existing.categoryExtraFeeIncluded != null &&
                existing.categoryExtraFeeIncluded!.isNotEmpty));
    // categoryConfigs carries per-category stage allotment used to filter groups.
    final hasCategoryConfigs =
        existing != null && existing.categoryConfigs != null;
    if (hasGroupData && hasCategoryFeeData && hasCategoryConfigs) {
      _syncCategoryIncludeFeeFromModel(existing);
      return;
    }

    if (stageOptions.isEmpty || groupOptions.isEmpty) {
      await loadOptions();
    }

    isLoadingRegistrationCompetition.value = true;
    try {
      final numericId = int.tryParse(id);
      if (numericId != null) {
        final response = await _repository.getCompetitionById(numericId);
        if (response.success && response.data != null) {
          _upsertCompetition(response.data!);
          _syncCategoryIncludeFeeFromModel(response.data!);
          return;
        }
      }

      final home = homeCompetitions.firstWhereOrNull(
        (c) => c.id?.toString() == id,
      );
      if (home != null) {
        final merged = _competitionFromHome(home, existing);
        _upsertCompetition(merged);
        _syncCategoryIncludeFeeFromModel(merged);
      }
    } catch (e) {
      print('Error loading competition for registration: $e');
    } finally {
      isLoadingRegistrationCompetition.value = false;
    }
  }

  void _upsertCompetition(CompetitionModel competition) {
    final compId = competition.id;
    if (compId == null || compId.isEmpty) {
      competitions.add(competition);
    } else {
      final index = competitions.indexWhere((c) => c.id == compId);
      if (index >= 0) {
        competitions[index] = competition;
      } else {
        competitions.add(competition);
      }
    }
    competitions.refresh();
  }

  CompetitionModel _competitionFromHome(
    HomeCompetitionModel home,
    CompetitionModel? existing,
  ) {
    DateTime parseDate(String? value) {
      if (value == null || value.isEmpty) return DateTime.now();
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return CompetitionModel(
      id: home.id?.toString(),
      competitionName: home.competitionName,
      description: home.description,
      address: home.address,
      eventStartDate: parseDate(home.eventStartDate),
      eventEndDate: parseDate(home.eventEndDate),
      eventStartTime: existing?.eventStartTime,
      eventEndTime: existing?.eventEndTime,
      publishResultNow: existing?.resolvedPublishResultNow ?? false,
      spotRegistration: existing?.resolvedSpotRegistration ?? false,
      displayAdFrom: home.displayAdFrom != null
          ? parseDate(home.displayAdFrom)
          : null,
      categories: home.categories.isNotEmpty
          ? List<String>.from(home.categories)
          : existing?.categories,
      categoryIds: existing?.categoryIds,
      categoryAmounts: home.categoryAmounts.isNotEmpty
          ? Map<String, double>.from(home.categoryAmounts)
          : existing?.categoryAmounts,
      categoryExtraFeeIncluded: home.categoryExtraFeeIncluded.isNotEmpty
          ? Map<String, bool>.from(home.categoryExtraFeeIncluded)
          : existing?.categoryExtraFeeIncluded,
      stageGroups: existing?.stageGroups,
      stageIds: existing?.stageIds,
      stages: existing?.stages,
      brochureUrl: home.brochureUrl ?? existing?.brochureUrl,
    );
  }

  void enterFirstCompetitionOnboardingMode() {
    if (!isListView.value && !isEditMode.value && !isViewMode.value) {
      return;
    }
    isListView.value = false;
    isEditMode.value = false;
    isViewMode.value = false;
  }

  void onInit() {
    super.onInit();
    if (_isFirstCompetitionGateActive()) {
      enterFirstCompetitionOnboardingMode();
    }
    // Initialize search controller text
    searchController.text = searchQuery.value;
    // Initialize search controller listener
    searchController.addListener(_onSearchChanged);
    // Load options from API
    loadOptions();
    loadOnDemandContext();
    loadGoogleDriveConfig();
  }

  Future<void> loadGoogleDriveConfig() async {
    try {
      final response = await _repository.getGoogleDriveConfig();
      if (response.success && response.data != null) {
        googleDriveServiceAccountEmail.value =
            response.data!['serviceAccountEmail']?.toString() ?? '';
        googleDriveServerConfigured.value = response.data!['configured'] == true;
        googleDriveServerReason.value =
            response.data!['reason']?.toString() ?? '';
      }
    } catch (_) {
      // Hint text stays empty if the config endpoint is unavailable.
    }
  }

  Future<void> loadOnDemandContext() async {
    if (isLoadingOnDemandContext.value) return;
    try {
      isLoadingOnDemandContext.value = true;
      final response = await _paymentRepository.getOnDemandContext();
      if (response.success && response.data != null) {
        final data = response.data!;
        isOnDemandOrg.value =
            data['onDemand'] == true || data['requiresPrePayment'] == true;
        organizationPaymentModel.value =
            data['paymentModel']?.toString() ?? 'ORG_SUBSCRIPTION';
        final feePaise = data['maintenanceFeeAmountPaise'];
        onDemandMaintenanceFeePaise.value = feePaise is int
            ? feePaise
            : int.tryParse(feePaise?.toString() ?? '') ?? 0;
        onDemandAsanasFeePaise.value = _parsePaise(
          data['asanasMaintenanceFeeAmountPaise'],
          500000,
        );
        onDemandChallengeFeePaise.value = _parsePaise(
          data['challengeMaintenanceFeeAmountPaise'],
          100000,
        );
        onDemandPaymentGatewayFeePercent.value =
            _parsePercent(data['paymentGatewayFeePercent'], 3.0);
        onDemandPlatformFeePercent.value =
            _parsePercent(data['platformFeePercent'], 3.0);
        onDemandExtraFeeForCompetition.value =
            data['extraFeeIncludedForCompetition'] == true;
        onDemandExtraFeeForParticipantReg.value =
            data['extraFeeIncludedForParticipantReg'] == true;
        _syncCategoryPlatformFeeDefault();
      } else {
        _applyOnDemandDefaults();
      }
    } catch (_) {
      _applyOnDemandDefaults();
    } finally {
      isLoadingOnDemandContext.value = false;
    }
  }

  void _syncCategoryPlatformFeeDefault() {
    if (isEditMode.value || isViewMode.value) return;
    for (final id in selectedCategoryIds) {
      final key = id.toString();
      if (!categoryIncludeFee.containsKey(key)) {
        categoryIncludeFee[key] = onDemandExtraFeeForParticipantReg.value;
      }
    }
  }

  bool categoryExtraFeeIncludedFor(int categoryId) {
    return categoryIncludeFee[categoryId.toString()] ??
        onDemandExtraFeeForParticipantReg.value;
  }

  bool categoryExtraFeeIncludedForName(String categoryName) {
    final categoryId = getCategoryIdByName(categoryName);
    if (categoryId == null) return onDemandExtraFeeForParticipantReg.value;
    return categoryExtraFeeIncludedFor(categoryId);
  }

  Map<String, bool> buildCategoryExtraFeeIncludedForSubmit() {
    final result = <String, bool>{};
    for (final id in selectedCategoryIds) {
      result[id.toString()] = categoryExtraFeeIncludedFor(id);
    }
    return result;
  }

  void toggleCategoryIncludeFee(String categoryName, bool? value) {
    final categoryId = getCategoryIdByName(categoryName);
    if (categoryId == null) return;
    final key = categoryId.toString();
    final newInclude = value ?? false;
    final oldInclude = categoryExtraFeeIncludedFor(categoryId);
    if (newInclude != oldInclude) {
      final stored = categoryAmounts[key] ?? 0.0;
      if (stored > 0) {
        final gatewayRate = onDemandPaymentGatewayFeePercent.value / 100;
        final platformRate = onDemandPlatformFeePercent.value / 100;
        final feeMultiplier = 1 + gatewayRate + platformRate;
        categoryAmounts[key] = newInclude
            ? _roundMoney(stored * feeMultiplier)
            : _roundMoney(stored / feeMultiplier);
        categoryAmounts.refresh();
      }
    }
    categoryIncludeFee[key] = newInclude;
  }

  void _ensureCategoryIncludeFeeDefault(int categoryId) {
    final key = categoryId.toString();
    if (!categoryIncludeFee.containsKey(key)) {
      categoryIncludeFee[key] = onDemandExtraFeeForParticipantReg.value;
    }
  }

  double _roundMoney(double value) => double.parse(value.toStringAsFixed(2));

  /// Splits or totals a stored category amount based on include/exclude mode.
  ({
    double baseAmount,
    double platformFee,
    double gatewayFee,
    double totalFee,
    double totalAmount,
  }) breakdownCategoryAmount(
    double storedAmount, {
    bool? includePlatformFee,
    int? categoryId,
  }) {
    final include = includePlatformFee ??
        (categoryId != null
            ? categoryExtraFeeIncludedFor(categoryId)
            : onDemandExtraFeeForParticipantReg.value);
    final gatewayRate = onDemandPaymentGatewayFeePercent.value / 100;
    final platformRate = onDemandPlatformFeePercent.value / 100;
    final feeMultiplier = 1 + gatewayRate + platformRate;

    if (include) {
      final total = storedAmount;
      final base = total / feeMultiplier;
      final gateway = base * gatewayRate;
      final platform = base * platformRate;
      return (
        baseAmount: _roundMoney(base),
        platformFee: _roundMoney(platform),
        gatewayFee: _roundMoney(gateway),
        totalFee: _roundMoney(gateway + platform),
        totalAmount: _roundMoney(total),
      );
    }

    final base = storedAmount;
    final gateway = base * gatewayRate;
    final platform = base * platformRate;
    return (
      baseAmount: _roundMoney(base),
      platformFee: _roundMoney(platform),
      gatewayFee: _roundMoney(gateway),
      totalFee: _roundMoney(gateway + platform),
      totalAmount: _roundMoney(base + gateway + platform),
    );
  }

  double calculateCategoryAmountWithFees(
    double storedAmount, {
    bool? extraFeeIncluded,
    int? categoryId,
  }) {
    final include = extraFeeIncluded ??
        (categoryId != null
            ? categoryExtraFeeIncludedFor(categoryId)
            : onDemandExtraFeeForParticipantReg.value);
    if (include) {
      return storedAmount;
    }
    return breakdownCategoryAmount(
      storedAmount,
      includePlatformFee: false,
      categoryId: categoryId,
    ).totalAmount;
  }

  void _applyOnDemandDefaults() {
    isOnDemandOrg.value = true;
    organizationPaymentModel.value = SubscriptionCatalogFilter.onDemandModeKey;
    onDemandAsanasFeePaise.value = 500000;
    onDemandChallengeFeePaise.value = 100000;
    onDemandPaymentGatewayFeePercent.value = 3.0;
    onDemandPlatformFeePercent.value = 3.0;
    onDemandExtraFeeForCompetition.value = true;
    onDemandExtraFeeForParticipantReg.value = false;
  }

  int _parsePaise(dynamic raw, int fallback) {
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  double _parsePercent(dynamic raw, double fallback) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? fallback;
  }

  double calculateOnDemandTotalWithFees(
    double baseAmount, {
    bool forParticipantRegistration = false,
    bool? extraFeeIncludedOverride,
  }) {
    final feesIncluded = extraFeeIncludedOverride ??
        (forParticipantRegistration
            ? onDemandExtraFeeForParticipantReg.value
            : onDemandExtraFeeForCompetition.value);
    if (feesIncluded) {
      return baseAmount;
    }
    final gateway =
        baseAmount * onDemandPaymentGatewayFeePercent.value / 100;
    final platform = baseAmount * onDemandPlatformFeePercent.value / 100;
    return baseAmount + gateway + platform;
  }

  bool get hasAsanasCategoryDraft {
    if (categoryConfigDrafts.isEmpty) {
      return selectedCategoryIds.isNotEmpty;
    }
    return categoryConfigDrafts.any((c) => c.isAsanas);
  }

  bool get hasChallengeCategoryDraft =>
      categoryConfigDrafts.any((c) => c.isChallenge);

  bool get unpaidAsanasForPayment =>
      hasAsanasCategoryDraft && !maintenancePaidAsanas.value;

  bool get unpaidChallengeForPayment =>
      hasChallengeCategoryDraft && !maintenancePaidChallenge.value;

  double maintenanceFeeRupees() {
    double base = 0;
    if (unpaidAsanasForPayment) {
      base += onDemandAsanasFeePaise.value / 100.0;
    }
    if (unpaidChallengeForPayment) {
      base += onDemandChallengeFeePaise.value / 100.0;
    }
    return base;
  }

  ({double baseAmount, double feeAmount, double totalAmount})
      competitionMaintenanceBreakdown() {
    final base = maintenanceFeeRupees();
    final total = calculateOnDemandTotalWithFees(
      base,
      extraFeeIncludedOverride: false,
    );
    return (
      baseAmount: _roundMoney(base),
      feeAmount: _roundMoney(total - base),
      totalAmount: _roundMoney(total),
    );
  }

  double calculateCompetitionMaintenanceTotal() =>
      competitionMaintenanceBreakdown().totalAmount;

  // Load all options (categories, prizes, stages, groups) from API
  Future<void> loadOptions() async {
    if (isLoadingOptions.value) return;
    try {
      isLoadingOptions.value = true;
      // Load all options in parallel
      final results = await Future.wait([
        _repository.getAllCategories(),
        _repository.getAllPrizes(),
        _repository.getAllStages(),
        _repository.getAllGroups(),
      ]);

      // Update categories
      if (results[0].success && results[0].data != null) {
        categoryOptions.assignAll(results[0].data!);
      }

      // Update prizes
      if (results[1].success && results[1].data != null) {
        prizeOptions.assignAll(results[1].data!);
      }

      // Update stages
      if (results[2].success && results[2].data != null) {
        stageOptions.assignAll(results[2].data!);
      }

      // Update groups
      if (results[3].success && results[3].data != null) {
        groupOptions.assignAll(results[3].data!);
      }
    } catch (e) {
      print('Error loading options: $e');
      // Fallback to empty lists if API fails
    } finally {
      isLoadingOptions.value = false;
    }
  }

  // Load specific option type (optimized for single option reload)
  Future<void> reloadCategoryOptions() async {
    try {
      final response = await _repository.getAllCategories();
      if (response.success && response.data != null) {
        categoryOptions.value = response.data!;
      }
    } catch (e) {
      print('Error reloading categories: $e');
    }
  }

  Future<void> reloadPrizeOptions() async {
    try {
      final response = await _repository.getAllPrizes();
      if (response.success && response.data != null) {
        prizeOptions.value = response.data!;
      }
    } catch (e) {
      print('Error reloading prizes: $e');
    }
  }

  Future<void> reloadStageOptions() async {
    try {
      final response = await _repository.getAllStages();
      if (response.success && response.data != null) {
        stageOptions.value = response.data!;
      }
    } catch (e) {
      print('Error reloading stages: $e');
    }
  }

  Future<void> reloadGroupOptions() async {
    try {
      final response = await _repository.getAllGroups();
      if (response.success && response.data != null) {
        groupOptions.value = response.data!;
      }
    } catch (e) {
      print('Error reloading groups: $e');
    }
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _razorpayCheckout.dispose();
    clearGradeEntries();
    competitionNameFocusNode.dispose();
    descriptionFocusNode.dispose();
    addressFocusNode.dispose();
    competitionNameController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    googleDriveFolderUrlController.dispose();
    searchController.dispose();
    super.onClose();
  }

  SubscriptionPackageModel? get selectedSubscriptionPackage {
    final id = selectedSubscriptionPackageId.value;
    if (id == null) return null;
    return subscriptionPackages.firstWhereOrNull((p) => p.id == id);
  }

  bool _isSubscriptionCreditError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('no subscription credits remaining') ||
        lower.contains('purchase a package') ||
        lower.contains('purchase subscription credits') ||
        lower.contains('competition limit reached') ||
        lower.contains('no pack credits remaining') ||
        lower.contains('no subscription credits') ||
        lower.contains('yearly subscription has expired') ||
        lower.contains('subscription has expired') ||
        lower.contains('add-on does not match');
  }

  bool get shouldShowSubscriptionBuyNow {
    final message = errorMessage.value;
    return message.isNotEmpty && _isSubscriptionCreditError(message);
  }

  List<SubscriptionPackageModel> get subscriptionBasePackages {
    return SubscriptionCatalogFilter.sortPackages(
      subscriptionPackages.where((p) => !p.isAddon),
    );
  }

  List<SubscriptionPackageModel> get subscriptionAddonPackages {
    return SubscriptionCatalogFilter.sortPackages(
      subscriptionPackages.where((p) => p.isAddon),
    );
  }

  SubscriptionModeModel? get selectedSubscriptionMode {
    final id = selectedSubscriptionModeId.value;
    if (id == null) return null;
    return subscriptionModes.firstWhereOrNull((m) => m.id == id);
  }

  Future<void> prepareSubscriptionTopUpFlow() async {
    showSubscriptionTopUp.value = true;
    showSubscriptionAddonOptions.value = false;
    await loadSubscriptionModes();
    await loadAllSubscriptionPackages();
  }

  String get subscriptionPlanStepTitle {
    final mode = selectedSubscriptionMode?.modeKey ?? '';
    if (mode == 'PAY_PER_PARTICIPANT') {
      return 'Step 2 — Choose On Demand plan';
    }
    return 'Step 2 — Choose a plan';
  }

  Future<String?> _completeOnDemandPaymentBeforeCreate({
    required String description,
  }) async {
    if (!unpaidAsanasForPayment && !unpaidChallengeForPayment) {
      _notifyError('Add at least one Asanas or Challenge category before payment');
      return null;
    }
    final orderResponse = await _paymentRepository.createApiOrder(
      purpose: PaymentRepository.onDemandCompetitionPurpose,
      hasAsanas: unpaidAsanasForPayment,
      hasChallenge: unpaidChallengeForPayment,
    );
    if (!orderResponse.success || orderResponse.data == null) {
      _notifyError(orderResponse.message ?? 'Failed to create payment order');
      return null;
    }

    final order = orderResponse.data!;
    final orderId =
        order['orderId']?.toString() ?? order['order_id']?.toString() ?? '';
    final key = order['key']?.toString() ?? '';
    final amount = order['amount'] is int
        ? order['amount'] as int
        : int.tryParse(order['amount']?.toString() ?? '') ?? 0;
    final mockMode = order['mockMode'] == true;

    if (orderId.isEmpty || amount <= 0) {
      _notifyError('Invalid payment order details');
      return null;
    }
    if (!mockMode && key.isEmpty) {
      _notifyError('Payment gateway is not configured. Contact support.');
      return null;
    }

    Map<String, String> paymentResult;
    try {
      paymentResult = await _razorpayCheckout.openCheckout(
        keyId: key,
        orderId: orderId,
        amountPaise: amount,
        description: description,
        mockMode: mockMode,
      );
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      final cancelled = message.toLowerCase().contains('cancelled');
      await _paymentRepository.markPaymentFailed(
        orderId: orderId,
        reason: cancelled ? 'cancelled' : message,
      );
      _notifyError(cancelled ? 'Payment cancelled' : message);
      return null;
    }

    final verifyResponse = await _paymentRepository.verifyApiPayment(
      purpose: PaymentRepository.onDemandCompetitionPurpose,
      orderId: paymentResult['razorpay_order_id'] ?? orderId,
      paymentId: paymentResult['razorpay_payment_id'] ?? '',
      signature: paymentResult['razorpay_signature'] ?? '',
    );
    if (!verifyResponse.success) {
      await _paymentRepository.markPaymentFailed(
        orderId: paymentResult['razorpay_order_id'] ?? orderId,
        reason: verifyResponse.message ?? 'verification_failed',
      );
      _notifyError(verifyResponse.message ?? 'Payment verification failed');
      return null;
    }
    return paymentResult['razorpay_order_id']?.toString() ?? orderId;
  }

  void toggleSubscriptionAddonOptions() {
    showSubscriptionAddonOptions.value = !showSubscriptionAddonOptions.value;
    if (!showSubscriptionAddonOptions.value) {
      final selected = selectedSubscriptionPackage;
      if (selected?.isAddon == true) {
        final base = subscriptionBasePackages.isNotEmpty
            ? subscriptionBasePackages.first
            : null;
        if (base != null) {
          selectedSubscriptionPackageId.value = base.id;
        }
      }
    }
  }

  Future<void> loadSubscriptionModes() async {
    if (isLoadingSubscriptionModes.value) return;
    try {
      isLoadingSubscriptionModes.value = true;
      subscriptionModesError.value = '';
      final response = await _paymentRepository.listSubscriptionModes();
      if (response.success && response.data != null) {
        final modes = SubscriptionCatalogFilter.sortModes(response.data!);
        subscriptionModes.assignAll(modes);
        if (modes.isEmpty) {
          selectedSubscriptionModeId.value = null;
          subscriptionModesError.value = 'No subscription modes available';
        } else {
          final current = selectedSubscriptionModeId.value;
          final exists = current != null && modes.any((m) => m.id == current);
          if (!exists) {
            selectedSubscriptionModeId.value = modes.first.id;
          }
        }
      } else {
        subscriptionModes.clear();
        selectedSubscriptionModeId.value = null;
        subscriptionModesError.value =
            response.message ?? 'Failed to load subscription modes';
      }
    } catch (e) {
      subscriptionModes.clear();
      selectedSubscriptionModeId.value = null;
      subscriptionModesError.value =
          'Failed to load subscription modes: ${e.toString()}';
    } finally {
      isLoadingSubscriptionModes.value = false;
    }
  }

  Future<void> onSubscriptionModeSelected(SubscriptionModeModel mode) async {
    if (selectedSubscriptionModeId.value == mode.id) return;
    selectedSubscriptionModeId.value = mode.id;
    selectedSubscriptionPackageId.value = null;
    showSubscriptionAddonOptions.value = false;
    _applyPackagesForSelectedMode();
  }

  void onSubscriptionPackageSelected(SubscriptionPackageModel package) {
    selectedSubscriptionPackageId.value = package.id;
    if (!package.isAddon) {
      showSubscriptionAddonOptions.value = false;
    }
  }

  Future<void> loadAllSubscriptionPackages() async {
    final seq = ++_subscriptionPackageLoadSeq;
    try {
      isLoadingSubscriptionPackages.value = true;
      subscriptionPackagesError.value = '';
      final response = await _paymentRepository.listAllPackages();
      if (seq != _subscriptionPackageLoadSeq) return;

      if (response.success && response.data != null) {
        _allSubscriptionPackages.assignAll(
          response.data!.where((p) => p.isEligibleForCompetitionTopUp),
        );
        _applyPackagesForSelectedMode();
        if (subscriptionPackages.isEmpty &&
            subscriptionPackagesError.value.isEmpty) {
          subscriptionPackagesError.value =
              'No packages available. Check that the server is running.';
        }
      } else {
        _allSubscriptionPackages.clear();
        subscriptionPackages.clear();
        selectedSubscriptionPackageId.value = null;
        subscriptionPackagesError.value =
            response.message ?? 'Failed to load subscription packages';
      }
    } catch (e) {
      if (seq != _subscriptionPackageLoadSeq) return;
      _allSubscriptionPackages.clear();
      subscriptionPackages.clear();
      selectedSubscriptionPackageId.value = null;
      subscriptionPackagesError.value =
          'Failed to load subscription packages: ${e.toString()}';
    } finally {
      if (seq == _subscriptionPackageLoadSeq) {
        isLoadingSubscriptionPackages.value = false;
      }
    }
  }

  void _applyPackagesForSelectedMode() {
    final modeId = selectedSubscriptionModeId.value;
    if (modeId == null) {
      subscriptionPackages.clear();
      selectedSubscriptionPackageId.value = null;
      return;
    }
    final mode = selectedSubscriptionMode;
    final packages = SubscriptionCatalogFilter.sortPackages(
      _allSubscriptionPackages.where((p) {
        if (p.subscriptionModeId != null && p.subscriptionModeId != modeId) {
          return false;
        }
        if (mode != null &&
            p.paymentModel.isNotEmpty &&
            p.paymentModel != mode.modeKey) {
          return false;
        }
        return true;
      }),
    );
    subscriptionPackages.assignAll(packages);
    if (packages.isEmpty) {
      selectedSubscriptionPackageId.value = null;
      final modeName = mode?.name ?? 'this type';
      subscriptionPackagesError.value =
          'No plans found for $modeName. Try another subscription type.';
    } else {
      subscriptionPackagesError.value = '';
      final current = selectedSubscriptionPackageId.value;
      final exists = current != null && packages.any((p) => p.id == current);
      if (!exists) {
        selectedSubscriptionPackageId.value = null;
      }
    }
  }

  /// Retry loading packages (used by plan picker).
  Future<void> loadSubscriptionPackages() async {
    await loadAllSubscriptionPackages();
  }

  Future<bool> purchaseSubscriptionPackageAndRetryCreate() async {
    final packageId = selectedSubscriptionPackageId.value;
    if (packageId == null) {
      _notifyError('Please select a subscription package');
      return false;
    }

    try {
      isProcessingSubscriptionPayment.value = true;
      final packageName = selectedSubscriptionPackage?.name ?? 'Subscription';

      final orderResponse = await _paymentRepository
          .createSubscriptionOrderForCurrentOrg(packageId: packageId);
      if (!orderResponse.success || orderResponse.data == null) {
        _notifyError(orderResponse.message ?? 'Failed to create payment order');
        return false;
      }

      final order = orderResponse.data!;
      final orderId = order['orderId']?.toString() ?? '';
      final key = order['key']?.toString() ?? '';
      final amount = order['amount'] is int
          ? order['amount'] as int
          : int.tryParse(order['amount']?.toString() ?? '') ?? 0;
      final mockMode = order['mockMode'] == true;

      if (orderId.isEmpty || amount <= 0) {
        _notifyError('Invalid payment order details');
        return false;
      }
      if (!mockMode && key.isEmpty) {
        _notifyError('Payment gateway is not configured. Contact support.');
        return false;
      }

      final paymentResult = await _razorpayCheckout.openCheckout(
        keyId: key,
        orderId: orderId,
        amountPaise: amount,
        description: packageName,
        mockMode: mockMode,
      );

      final verifyResponse = await _paymentRepository
          .verifySubscriptionPaymentForCurrentOrg(
            orderId: paymentResult['razorpay_order_id'] ?? orderId,
            paymentId: paymentResult['razorpay_payment_id'] ?? '',
            signature: paymentResult['razorpay_signature'] ?? '',
          );
      if (!verifyResponse.success) {
        _notifyError(verifyResponse.message ?? 'Payment verification failed');
        return false;
      }

      _notifySuccess('Subscription activated. Retrying competition save...');
      showSubscriptionTopUp.value = false;
      errorMessage.value = '';
      return await createCompetition();
    } catch (e) {
      _notifyError('Payment failed: ${e.toString()}');
      return false;
    } finally {
      isProcessingSubscriptionPayment.value = false;
      _razorpayCheckout.dispose();
    }
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      updateSearch(searchController.text);
    });
  }

  // Pick brochure file (JPG, PNG, or PDF)
  Future<void> pickBrochure() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      final fileName = picked.name.trim();
      if (fileName.isEmpty) {
        _notifyError('Invalid brochure file name');
        return;
      }

      final lowerName = fileName.toLowerCase();
      const validExtensions = ['.jpg', '.jpeg', '.png', '.pdf'];
      final isValidType = validExtensions.any(lowerName.endsWith);
      if (!isValidType) {
        _notifyError('Brochure must be an image (JPG, PNG) or PDF file');
        return;
      }

      final fileBytes = await _readPickedFileBytes(picked);
      if (fileBytes == null) {
        _notifyError('Unable to read brochure file');
        return;
      }

      final isPdf = lowerName.endsWith('.pdf');
      if (isPdf) {
        if (fileBytes.length > brochureMaxPdfBytes) {
          _notifyError('PDF brochure must be 25 MB or smaller');
          return;
        }
        await _applyBrochureSelection(
          bytes: fileBytes,
          fileName: fileName,
          nativePath: picked.path,
        );
        return;
      }

      final processed = await PhotoUploadProcessor.processBytes(
        fileBytes,
        originalFileName: fileName,
        compressThresholdBytes:
            PhotoUploadProcessor.documentImageCompressThresholdBytes,
        targetBytes: PhotoUploadProcessor.documentImageTargetBytes,
      );
      if (processed == null) return;

      await _applyBrochureSelection(
        bytes: processed.bytes,
        fileName: processed.fileName,
        nativePath: processed.file?.path ?? picked.path,
        localFile: processed.file,
      );
    } on PhotoUploadException catch (e) {
      _notifyError(e.message);
    } catch (e) {
      _notifyError('Error picking brochure: ${e.toString()}');
    }
  }

  Future<Uint8List?> _readPickedFileBytes(PlatformFile picked) async {
    if (kIsWeb) {
      final bytes = picked.bytes;
      if (bytes == null || bytes.isEmpty) return null;
      return bytes;
    }
    if (picked.path == null) return null;
    return File(picked.path!).readAsBytes();
  }

  Future<void> _applyBrochureSelection({
    required Uint8List bytes,
    required String fileName,
    String? nativePath,
    File? localFile,
  }) async {
    brochureFileName.value = fileName;
    if (kIsWeb) {
      brochureBytes.value = bytes;
      brochureFile.value = null;
      brochureFileLocal.value = null;
      brochureUrl.value = 'web_file';
    } else {
      final file = localFile ?? (nativePath != null ? File(nativePath) : null);
      if (file == null) {
        _notifyError('Unable to access brochure file');
        return;
      }
      brochureFileLocal.value = file;
      brochureFile.value = XFile(file.path, name: fileName);
      brochureBytes.value = null;
      brochureUrl.value = file.path;
    }
    errorMessage.value = '';
  }

  // Validate brochure is uploaded
  bool validateBrochure() {
    final hasBrochure =
        brochureFile.value != null ||
        brochureFileLocal.value != null ||
        brochureBytes.value != null;

    if (!hasBrochure) {
      errorMessage.value = 'Please upload a brochure';
      return false;
    }
    return true;
  }

  // Helper methods to get ID from name
  int? getPrizeIdByName(String name) {
    try {
      return prizeOptions.firstWhere((opt) => opt.name == name).id;
    } catch (e) {
      return null;
    }
  }

  int? getCategoryIdByName(String name) {
    try {
      final target = name.trim().toUpperCase();
      return categoryOptions
          .firstWhere((opt) => opt.name.trim().toUpperCase() == target)
          .id;
    } catch (e) {
      return null;
    }
  }

  int? getStageIdByName(String name) {
    try {
      final option = stageOptions.firstWhere((opt) => opt.name == name);
      if (option.id == 0) {
        print(
          'getStageIdByName: Stage "$name" has invalid ID: ${option.id}. Available stages: ${stageOptions.map((e) => '${e.id}:${e.name}').toList()}',
        );
        return null;
      }
      return option.id;
    } catch (e) {
      print(
        'getStageIdByName: Stage "$name" not found. Available stages: ${stageOptions.map((e) => '${e.id}:${e.name}').toList()}',
      );
      return null;
    }
  }

  int? getGroupIdByName(String name) {
    try {
      final option = groupOptions.firstWhere((opt) => opt.name == name);
      if (option.id == 0) {
        print(
          'getGroupIdByName: Group "$name" has invalid ID: ${option.id}. Available groups: ${groupOptions.map((e) => '${e.id}:${e.name}').toList()}',
        );
        return null;
      }
      return option.id;
    } catch (e) {
      print(
        'getGroupIdByName: Group "$name" not found. Available groups: ${groupOptions.map((e) => '${e.id}:${e.name}').toList()}',
      );
      return null;
    }
  }

  // Helper methods to get name from ID
  String? getPrizeNameById(int id) {
    try {
      return prizeOptions.firstWhere((opt) => opt.id == id).name;
    } catch (e) {
      return null;
    }
  }

  String? getCategoryNameById(int id) {
    try {
      return categoryOptions.firstWhere((opt) => opt.id == id).name;
    } catch (e) {
      return null;
    }
  }

  double _feeFromAmountMap(Map<String, double>? amounts, int categoryId) {
    if (amounts == null || amounts.isEmpty) return 0;
    final byId = amounts[categoryId.toString()] ?? 0;
    if (byId > 0) return byId;
    final name = getCategoryNameById(categoryId);
    if (name != null) {
      return amounts[name] ?? 0;
    }
    return 0;
  }

  void _loadCategorySpotAmountsFromCompetition(CompetitionModel competition) {
    categorySpotAmounts.clear();
    final source = competition.categorySpotAmounts;
    if (source == null || source.isEmpty) {
      // Fall back to online fees when spot fees are not present.
      for (final entry in categoryAmounts.entries) {
        categorySpotAmounts[entry.key] = entry.value;
      }
      return;
    }
    for (final entry in source.entries) {
      final keyStr = entry.key.toString();
      int? categoryId = int.tryParse(keyStr);
      if (categoryId == null || !selectedCategoryIds.contains(categoryId)) {
        categoryId = getCategoryIdByName(keyStr);
      }
      if (categoryId != null) {
        categorySpotAmounts[categoryId.toString()] = entry.value;
      }
    }
    for (final id in selectedCategoryIds) {
      final key = id.toString();
      if (!categorySpotAmounts.containsKey(key)) {
        categorySpotAmounts[key] = categoryAmounts[key] ?? 0;
      }
    }
  }

  /// Registration fee in INR for [categoryId] on [competitionId].
  /// API category amounts use category name keys; home/public APIs may use IDs.
  /// When [spotRegistration] is true, uses spot fee (falls back to online fee).
  double resolveCategoryFeeRupees(
    String competitionId,
    int categoryId, {
    bool spotRegistration = false,
  }) {
    if (spotRegistration) {
      var spotFee = _feeFromAmountMap(
        categorySpotAmounts.isEmpty
            ? null
            : Map<String, double>.from(categorySpotAmounts),
        categoryId,
      );
      if (spotFee <= 0) {
        final competition = competitions.firstWhereOrNull(
          (c) => c.id == competitionId,
        );
        spotFee = _feeFromAmountMap(competition?.categorySpotAmounts, categoryId);
      }
      if (spotFee > 0) return spotFee;
    }

    var fee = _feeFromAmountMap(
      categoryAmounts.isEmpty
          ? null
          : Map<String, double>.from(categoryAmounts),
      categoryId,
    );
    if (fee > 0) return fee;

    final home = homeCompetitions.firstWhereOrNull(
      (c) => c.id?.toString() == competitionId,
    );
    fee = _feeFromAmountMap(home?.categoryAmounts, categoryId);
    if (fee > 0) return fee;

    final competition = competitions.firstWhereOrNull(
      (c) => c.id == competitionId,
    );
    return _feeFromAmountMap(competition?.categoryAmounts, categoryId);
  }

  bool resolveCategoryExtraFeeIncluded(String competitionId, int categoryId) {
    final key = categoryId.toString();
    if (categoryIncludeFee.containsKey(key)) {
      return categoryIncludeFee[key]!;
    }

    final competition = competitions.firstWhereOrNull(
      (c) => c.id == competitionId,
    );
    final byCompetition = competition?.categoryExtraFeeIncluded;
    if (byCompetition != null && byCompetition.isNotEmpty) {
      final byId = byCompetition[key];
      if (byId != null) return byId;
      final name = getCategoryNameById(categoryId);
      if (name != null && byCompetition.containsKey(name)) {
        return byCompetition[name]!;
      }
    }

    final home = homeCompetitions.firstWhereOrNull(
      (c) => c.id?.toString() == competitionId,
    );
    if (home != null) {
      if (home.categoryExtraFeeIncluded.containsKey(key)) {
        return home.categoryExtraFeeIncluded[key]!;
      }
    }

    return onDemandExtraFeeForParticipantReg.value;
  }

  /// Participant payable amount after applying per-category include/exclude fee.
  double resolveCategoryPayableFeeRupees(
    String competitionId,
    int categoryId, {
    bool spotRegistration = false,
  }) {
    final stored = resolveCategoryFeeRupees(
      competitionId,
      categoryId,
      spotRegistration: spotRegistration,
    );
    if (stored <= 0) return 0;
    final include = resolveCategoryExtraFeeIncluded(competitionId, categoryId);
    return calculateCategoryAmountWithFees(
      stored,
      extraFeeIncluded: include,
      categoryId: categoryId,
    );
  }

  void _syncCategoryIncludeFeeFromModel(CompetitionModel? competition) {
    if (competition?.categoryExtraFeeIncluded == null ||
        competition!.categoryExtraFeeIncluded!.isEmpty) {
      return;
    }
    for (final entry in competition.categoryExtraFeeIncluded!.entries) {
      final parsedId = int.tryParse(entry.key);
      final categoryId = parsedId ?? getCategoryIdByName(entry.key);
      if (categoryId != null) {
        categoryIncludeFee[categoryId.toString()] = entry.value;
      }
    }
    categoryIncludeFee.refresh();
  }

  String? getStageNameById(int id) {
    try {
      return stageOptions.firstWhere((opt) => opt.id == id).name;
    } catch (e) {
      return null;
    }
  }

  String? getGroupNameById(int id) {
    try {
      return groupOptions.firstWhere((opt) => opt.id == id).name;
    } catch (e) {
      return null;
    }
  }

  // Toggle prize selection (by name for UI, stores ID internally)
  void togglePrize(String prizeName) {
    final prizeId = getPrizeIdByName(prizeName);
    if (prizeId == null) return;

    if (selectedPrizeIds.contains(prizeId)) {
      selectedPrizeIds.remove(prizeId);
    } else {
      selectedPrizeIds.add(prizeId);
    }
  }

  // Add custom prize (by name for UI, stores ID internally)
  Future<bool> addCustomPrize(String prizeName, {String? description}) async {
    if (prizeName.isEmpty) return false;

    try {
      isAddingOption.value = true;
      errorMessage.value = '';

      final response = await _repository.createPrize(
        name: prizeName,
        description: description,
      );

      if (response.success && response.data != null) {
        final created = response.data!;
        final existingIndex = prizeOptions.indexWhere((p) => p.id == created.id);
        if (existingIndex >= 0) {
          prizeOptions[existingIndex] = created;
        } else {
          prizeOptions.add(created);
        }
        prizeOptions.refresh();
        if (!selectedPrizeIds.contains(created.id)) {
          selectedPrizeIds.add(created.id);
        }

        Get.snackbar('Success', 'Prize "$prizeName" created successfully');
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to create prize';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error creating prize: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
      return false;
    } finally {
      isAddingOption.value = false;
    }
  }

  void addGradeEntry() {
    gradeEntries.add(CompetitionGradeEntry());
  }

  /// Replaces empty grade rows with a common A+–F mark-range template.
  void applyStandardGradeEntries() {
    if (isViewMode.value) return;
    final hasUserInput = gradeEntries.any((entry) => entry.hasAnyInput);
    if (hasUserInput) {
      // Keep existing data; only fill when the section is unused.
      return;
    }
    clearGradeEntries();
    const standards = <(String, int, int)>[
      ('A+', 90, 100),
      ('A', 80, 89),
      ('B', 70, 79),
      ('C', 60, 69),
      ('D', 50, 59),
      ('E', 40, 49),
      ('F', 0, 39),
    ];
    for (final grade in standards) {
      gradeEntries.add(
        CompetitionGradeEntry(
          gradeName: grade.$1,
          markRangeMin: '${grade.$2}',
          markRangeMax: '${grade.$3}',
        ),
      );
    }
  }

  void removeGradeEntry(int index) {
    if (index < 0 || index >= gradeEntries.length) return;
    gradeEntries[index].dispose();
    gradeEntries.removeAt(index);
  }

  void clearGradeEntries() {
    for (final entry in gradeEntries) {
      entry.dispose();
    }
    gradeEntries.clear();
  }

  /// Replaces all grade rows. Callers must pass entries that this controller owns
  /// (previous entries are disposed).
  void replaceGradeEntries(List<CompetitionGradeEntry> entries) {
    clearGradeEntries();
    gradeEntries.addAll(entries);
    gradeEntries.refresh();
  }

  List<CompetitionGradeModel> buildGradesForSubmit() {
    final fromEntries = gradeEntries
        .map((entry) => entry.toModel())
        .whereType<CompetitionGradeModel>()
        .toList();
    if (fromEntries.isNotEmpty) return fromEntries;
    final grading = categoryConfigDrafts.firstWhereOrNull(
      (c) => c.isAsanas && c.isGradingScoring && c.grades.isNotEmpty,
    );
    return grading?.grades ?? const <CompetitionGradeModel>[];
  }

  String? validateGradeEntries([List<CompetitionGradeEntry>? entries]) {
    final list = entries ?? gradeEntries;
    final names = <String>{};
    for (final entry in list) {
      if (!entry.hasAnyInput) continue;
      if (!entry.isComplete) {
        return 'Please enter grade name and mark range for each grade row';
      }
      final model = entry.toModel();
      if (model == null) {
        return 'Mark range must be whole numbers between 0 and 999';
      }
      if (model.markRangeMin < 0 ||
          model.markRangeMin > 999 ||
          model.markRangeMax < 0 ||
          model.markRangeMax > 999) {
        return 'Mark range must be between 0 and 999 for grade "${model.gradeName}"';
      }
      if (model.markRangeMax < model.markRangeMin) {
        return 'Maximum mark must be greater than or equal to minimum for grade "${model.gradeName}"';
      }
      final normalized = model.gradeName.toLowerCase();
      if (names.contains(normalized)) {
        return 'Duplicate grade name: ${model.gradeName}';
      }
      names.add(normalized);
    }
    return null;
  }

  void _loadGradeEntries(List<CompetitionGradeModel>? grades) {
    clearGradeEntries();
    if (grades == null || grades.isEmpty) return;
    gradeEntries.addAll(grades.map(CompetitionGradeEntry.fromModel));
    gradeEntries.refresh();
  }

  static const String championsCategoryName = 'CHAMPIONS';

  bool isChampionsCategoryName(String categoryName) =>
      categoryName.trim().toUpperCase() == championsCategoryName;

  bool get canSelectChampionsCategory =>
      championshipStyle.value == ChampionshipStyle.separateCategory;

  void setChampionshipStyle(ChampionshipStyle? style) {
    championshipStyle.value = style;
    if (style == ChampionshipStyle.fromFirstPlaceWinners) {
      _deselectChampionsCategory();
    }
  }

  void _deselectChampionsCategory() {
    final championsId = getCategoryIdByName(championsCategoryName);
    if (championsId == null) return;
    if (selectedCategoryIds.contains(championsId)) {
      selectedCategoryIds.remove(championsId);
      categoryAmounts.remove(championsId.toString());
      categorySpotAmounts.remove(championsId.toString());
      categoryIncludeFee.remove(championsId.toString());
    }
  }

  String? validateCategoriesForChampionshipStyle() {
    if (championshipStyle.value != ChampionshipStyle.fromFirstPlaceWinners) {
      return null;
    }
    for (final id in selectedCategoryIds) {
      final name = getCategoryNameById(id);
      if (name != null && isChampionsCategoryName(name)) {
        return 'Remove the Champions category. For this championship style, '
            'Champions are derived from 1st-place winners in other categories.';
      }
    }
    return null;
  }

  Future<bool> confirmChampionshipStyleBeforeSave() async {
    // Championship style UI removed from create screen; default to separate category.
    championshipStyle.value ??= ChampionshipStyle.separateCategory;

    final categoryError = validateCategoriesForChampionshipStyle();
    if (categoryError != null) {
      _notifyError(categoryError);
      return false;
    }
    return true;
  }

  // Toggle category selection (by name for UI, stores ID internally)
  void toggleCategory(String categoryName) {
    if (isChampionsCategoryName(categoryName) && !canSelectChampionsCategory) {
      SnackbarHelper.showErrorMessage(
        championshipStyle.value == null
            ? 'Select the championship style above first.'
            : 'Champions cannot be selected when it is based on 1st-place winners.',
      );
      return;
    }

    final categoryId = getCategoryIdByName(categoryName);
    if (categoryId == null) return;

    final categoryIdStr = categoryId.toString();
    if (selectedCategoryIds.contains(categoryId)) {
      selectedCategoryIds.remove(categoryId);
      categoryAmounts.remove(categoryIdStr);
      categorySpotAmounts.remove(categoryIdStr);
      categoryIncludeFee.remove(categoryIdStr);
    } else {
      selectedCategoryIds.add(categoryId);
      categoryAmounts[categoryIdStr] = 0.0;
      categorySpotAmounts[categoryIdStr] = 0.0;
      _ensureCategoryIncludeFeeDefault(categoryId);
    }
  }

  // Add custom category (by name for UI, stores ID internally)
  Future<bool> addCustomCategory(
    String categoryName, {
    String? description,
  }) async {
    final id = await ensureCategoryPersisted(
      categoryName,
      description: description,
      showFeedback: true,
    );
    return id != null;
  }

  /// Creates or reuses a master category in DB. Returns category id, or null on failure.
  Future<int?> ensureCategoryPersisted(
    String categoryName, {
    String? description,
    bool showFeedback = false,
  }) async {
    final name = categoryName.trim().toUpperCase();
    if (name.isEmpty) return null;

    final existingId = getCategoryIdByName(name);
    if (existingId != null && existingId > 0) {
      return existingId;
    }

    try {
      isAddingOption.value = true;
      errorMessage.value = '';

      final response = await _repository.createCategory(
        name: name,
        description: description,
      );

      if (response.success && response.data != null) {
        final created = response.data!;
        final existingIndex =
            categoryOptions.indexWhere((c) => c.id == created.id);
        if (existingIndex >= 0) {
          categoryOptions[existingIndex] = created;
        } else {
          categoryOptions.add(created);
        }
        categoryOptions.refresh();
        if (!selectedCategoryIds.contains(created.id)) {
          selectedCategoryIds.add(created.id);
          categoryAmounts[created.id.toString()] = 0.0;
          categorySpotAmounts[created.id.toString()] = 0.0;
          _ensureCategoryIncludeFeeDefault(created.id);
        }

        if (showFeedback) {
          Get.snackbar(
            'Success',
            'Category "$name" created successfully',
          );
        }
        return created.id;
      } else {
        errorMessage.value = response.message ?? 'Failed to create category';
        Get.snackbar('Error', errorMessage.value);
        return null;
      }
    } catch (e) {
      errorMessage.value = 'Error creating category: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
      return null;
    } finally {
      isAddingOption.value = false;
    }
  }

  /// Quietly create/reuse a stage master. Returns id or null.
  Future<int?> ensureStagePersisted(String stageName) async {
    final name = stageName.trim();
    if (name.isEmpty) return null;
    final existingId = getStageIdByName(name);
    if (existingId != null && existingId > 0) return existingId;

    try {
      final response = await _repository.createStage(name: name);
      if (response.success && response.data != null) {
        final created = response.data!;
        final existingIndex = stageOptions.indexWhere((s) => s.id == created.id);
        if (existingIndex >= 0) {
          stageOptions[existingIndex] = created;
        } else {
          stageOptions.add(created);
        }
        stageOptions.refresh();
        if (!selectedStageIds.contains(created.id)) {
          selectedStageIds.add(created.id);
          stageGroups.putIfAbsent(created.id.toString(), () => <int>[]);
        }
        return created.id;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Quietly create/reuse a group master. Returns id or null.
  Future<int?> ensureGroupPersisted(String groupName) async {
    final name = groupName.trim();
    if (name.isEmpty) return null;
    final existingId = getGroupIdByName(name);
    if (existingId != null && existingId > 0) return existingId;

    try {
      final response = await _repository.createGroup(name: name);
      if (response.success && response.data != null) {
        final created = response.data!;
        final existingIndex = groupOptions.indexWhere((g) => g.id == created.id);
        if (existingIndex >= 0) {
          groupOptions[existingIndex] = created;
        } else {
          groupOptions.add(created);
        }
        groupOptions.refresh();
        return created.id;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Create category in DB, then add an in-memory draft linked to that category id.
  Future<CompetitionCategoryConfigModel?> createCategoryDraftPersisted({
    required String name,
    required String format,
    String mode = 'OFFLINE',
  }) async {
    final normalizedName = name.trim().toUpperCase();
    if (normalizedName.isEmpty) return null;
    final normalizedMode =
        mode.trim().toUpperCase() == 'ONLINE' ? 'ONLINE' : 'OFFLINE';

    final duplicate = categoryConfigDrafts.any(
      (c) =>
          c.categoryName.trim().toUpperCase() == normalizedName &&
          (c.mode.trim().toUpperCase() == 'ONLINE' ? 'ONLINE' : 'OFFLINE') ==
              normalizedMode,
    );
    if (duplicate) {
      final modeLabel = normalizedMode == 'ONLINE' ? 'Online' : 'Offline';
      Get.snackbar(
        'Duplicate category',
        'Category "$normalizedName" already exists for $modeLabel mode',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return null;
    }

    final categoryId = await ensureCategoryPersisted(
      normalizedName,
      description: 'Created from competition setup',
      showFeedback: true,
    );
    if (categoryId == null) return null;

    final draft = CompetitionCategoryConfigModel.freshAsanas(
      categoryId: categoryId,
      categoryName: normalizedName,
      format: format,
      mode: normalizedMode,
    );
    categoryConfigDrafts.add(draft);
    categoryConfigDrafts.refresh();
    _syncCategorySelectionFromDrafts();
    return draft;
  }

  /// Persist wizard config: masters always; competition_category_configs when editing.
  Future<CompetitionCategoryConfigModel?> persistCategoryConfigDraft(
    CompetitionCategoryConfigModel draft, {
    bool showFeedback = true,
  }) async {
    try {
      isAddingOption.value = true;
      errorMessage.value = '';
      draft.syncGeneratedStages(regenerateNames: false);
      draft.summary = draft.displaySummary;

      final categoryId = await ensureCategoryPersisted(draft.categoryName);
      if (categoryId == null) {
        if (showFeedback) {
          Get.snackbar(
            'Error',
            'Failed to save category "${draft.categoryName}"',
          );
        }
        return null;
      }
      draft.categoryId = categoryId;

      for (final stageName in draft.stageNames) {
        await ensureStagePersisted(stageName);
      }
      final groupNames = <String>{
        ...draft.selectedGroups,
        for (final groups in draft.stageAllotment.values) ...groups,
      };
      for (final groupName in groupNames) {
        await ensureGroupPersisted(groupName);
      }
      for (final entry in draft.stageAllotment.entries) {
        if (entry.value.isNotEmpty) {
          setStageGroups(entry.key, entry.value);
        }
      }

      if (draft.upgradeToCategoryName != null &&
          draft.upgradeToCategoryName!.trim().isNotEmpty &&
          draft.upgradeToCategoryId == null) {
        draft.upgradeToCategoryId = await ensureCategoryPersisted(
          draft.upgradeToCategoryName!,
        );
      }

      if (draft.categoryId != null) {
        if (!selectedCategoryIds.contains(draft.categoryId)) {
          selectedCategoryIds.add(draft.categoryId!);
        }
        categoryAmounts[draft.categoryId!.toString()] = draft.feeAmount;
        categorySpotAmounts[draft.categoryId!.toString()] =
            draft.spotFeeAmount > 0 ? draft.spotFeeAmount : draft.feeAmount;
        categoryIncludeFee[draft.categoryId!.toString()] =
            draft.includeFeeInRegistration;
      }

      upsertCategoryDraft(draft);

      final competitionId = int.tryParse(competitionToEdit.value?.id ?? '');
      final unpaidNewFormat = (draft.isChallenge && !maintenancePaidChallenge.value) ||
          (draft.isAsanas && !maintenancePaidAsanas.value);
      if (competitionId != null && competitionId > 0 && !unpaidNewFormat) {
        final response = await _repository.upsertCategoryConfig(
          competitionId: competitionId,
          config: draft,
        );
        if (!response.success) {
          errorMessage.value =
              response.message ?? 'Failed to save category configuration';
          if (showFeedback) {
            Get.snackbar('Error', errorMessage.value);
          }
          return null;
        }
        final saved = response.data;
        if (saved != null) {
          if (saved.categoryId != null) draft.categoryId = saved.categoryId;
          if (saved.summary != null) draft.summary = saved.summary;
          upsertCategoryDraft(draft);
        }
      }

      if (showFeedback) {
        Get.snackbar(
          'Success',
          'Configuration saved for "${draft.categoryName}"',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return draft;
    } catch (e) {
      errorMessage.value = 'Error saving configuration: ${e.toString()}';
      if (showFeedback) {
        Get.snackbar('Error', errorMessage.value);
      }
      return null;
    } finally {
      isAddingOption.value = false;
    }
  }

  // Update category amount (by name for UI, stores with ID as key)
  void updateCategoryAmount(String categoryName, double amount) {
    final categoryId = getCategoryIdByName(categoryName);
    if (categoryId != null) {
      categoryAmounts[categoryId.toString()] = amount;
    }
  }

  void setCompetitionMode(String mode) {
    final normalized = mode.trim().toUpperCase();
    competitionMode.value =
        normalized == 'ONLINE' ? 'ONLINE' : 'OFFLINE';
  }

  CompetitionCategoryConfigModel addCategoryDraft({
    required String name,
    required String format,
    String mode = 'OFFLINE',
  }) {
    final draft = CompetitionCategoryConfigModel.freshAsanas(
      categoryName: name,
      format: format,
      mode: mode,
    );
    categoryConfigDrafts.add(draft);
    categoryConfigDrafts.refresh();
    _syncCategorySelectionFromDrafts();
    return draft;
  }

  void removeCategoryDraft(String draftId) {
    categoryConfigDrafts.removeWhere((c) => c.draftId == draftId);
    categoryConfigDrafts.refresh();
    _syncCategorySelectionFromDrafts();
  }

  void upsertCategoryDraft(CompetitionCategoryConfigModel draft) {
    final index =
        categoryConfigDrafts.indexWhere((c) => c.draftId == draft.draftId);
    if (index >= 0) {
      categoryConfigDrafts[index] = draft;
    } else {
      categoryConfigDrafts.add(draft);
    }
    categoryConfigDrafts.refresh();
    _syncCategorySelectionFromDrafts();
    _applyFirstAsanasFlatFieldsFromDrafts();
  }

  CompetitionCategoryConfigModel? nextUnconfiguredAsanasDraft({
    String? afterDraftId,
  }) {
    final list = categoryConfigDrafts.where((c) => c.isAsanas && !c.configured);
    if (afterDraftId == null) {
      return list.isEmpty ? null : list.first;
    }
    final start = categoryConfigDrafts.indexWhere((c) => c.draftId == afterDraftId);
    for (var i = start + 1; i < categoryConfigDrafts.length; i++) {
      final c = categoryConfigDrafts[i];
      if (c.isAsanas && !c.configured) return c;
    }
    for (var i = 0; i <= start && i < categoryConfigDrafts.length; i++) {
      final c = categoryConfigDrafts[i];
      if (c.isAsanas && !c.configured) return c;
    }
    return null;
  }

  void _syncCategorySelectionFromDrafts() {
    if (categoryConfigDrafts.isEmpty) return;
    selectedCategoryIds.clear();
    categoryAmounts.clear();
    categorySpotAmounts.clear();
    categoryIncludeFee.clear();
    for (final draft in categoryConfigDrafts) {
      final existingId = draft.categoryId ??
          getCategoryIdByName(draft.categoryName);
      if (existingId == null) continue;
      draft.categoryId = existingId;
      if (!selectedCategoryIds.contains(existingId)) {
        selectedCategoryIds.add(existingId);
      }
      final key = existingId.toString();
      final spot = draft.spotFeeAmount > 0 ? draft.spotFeeAmount : draft.feeAmount;
      if (draft.isOnlineMode) {
        categoryAmounts[key] = draft.feeAmount;
        categorySpotAmounts.putIfAbsent(key, () => spot);
      } else {
        categorySpotAmounts[key] = spot;
        categoryAmounts.putIfAbsent(key, () => draft.feeAmount);
      }
      categoryIncludeFee.putIfAbsent(key, () => draft.includeFeeInRegistration);
    }
  }

  void _applyFirstAsanasFlatFieldsFromDrafts() {
    final first = categoryConfigDrafts.firstWhereOrNull((c) => c.isAsanas);
    if (first == null) return;
    if (first.participantsPerStage != null) {
      participantsPerStage.value = first.participantsPerStage!;
    }
    if (first.minimumMarks != null) {
      minimumMarks.value = first.minimumMarks!;
    }
    if (first.maximumMarks != null) {
      maximumMarks.value = first.maximumMarks!;
    }
    skippedAsanaMarks.value = first.skippedAsanaMarks;
    _syncGradeEntriesFromDrafts();
  }

  void _syncGradeEntriesFromDrafts() {
    final grading = categoryConfigDrafts.firstWhereOrNull(
      (c) => c.isAsanas && c.isGradingScoring && c.grades.isNotEmpty,
    );
    if (grading == null) return;
    clearGradeEntries();
    replaceGradeEntries(
      grading.grades.map(CompetitionGradeEntry.fromModel).toList(),
    );
  }

  List<CompetitionCategoryConfigModel> get categoryConfigsForSubmit =>
      categoryConfigDrafts
          .map((c) {
            c.syncGeneratedStages(regenerateNames: false);
            return c;
          })
          .toList();

  String? _validateCategoryConfigDraftsForSubmit() {
    if (categoryConfigDrafts.isEmpty) {
      return 'Please add at least one category';
    }
    final unconfigured = categoryConfigDrafts
        .where((c) => !c.configured)
        .map((c) => c.categoryName)
        .toList();
    if (unconfigured.isNotEmpty) {
      return 'Please configure rules for: ${unconfigured.join(', ')}';
    }
    return null;
  }

  // Toggle stage selection (by name for UI, stores ID internally)
  void toggleStage(String stageName) {
    final stageId = getStageIdByName(stageName);
    if (stageId == null) return;

    final stageIdStr = stageId.toString();
    if (selectedStageIds.contains(stageId)) {
      selectedStageIds.remove(stageId);
      stageGroups.remove(stageIdStr);
    } else {
      selectedStageIds.add(stageId);
      // Initialize with default mapping if available and not already set
      if (!stageGroups.containsKey(stageIdStr)) {
        if (defaultStageMappings.containsKey(stageName)) {
          // Check if default groups are already assigned to other stages
          final defaultGroupNames = defaultStageMappings[stageName]!;
          final defaultGroupIds = defaultGroupNames
              .map((name) => getGroupIdByName(name))
              .where((id) => id != null)
              .cast<int>()
              .where((groupId) {
                // Check if group is not assigned to any other stage
                return !stageGroups.values.any(
                  (groupIds) => groupIds.contains(groupId),
                );
              })
              .toList();
          stageGroups[stageIdStr] = defaultGroupIds;
        } else {
          // For custom stages, initialize with empty list
          stageGroups[stageIdStr] = [];
        }
      }
    }
  }

  // Add custom stage (by name for UI, stores ID internally)
  Future<bool> addCustomStage(String stageName, {String? description}) async {
    if (stageName.isEmpty) return false;

    try {
      isAddingOption.value = true;
      errorMessage.value = '';

      final response = await _repository.createStage(
        name: stageName,
        description: description,
      );

      if (response.success && response.data != null) {
        final created = response.data!;
        final existingIndex = stageOptions.indexWhere((s) => s.id == created.id);
        if (existingIndex >= 0) {
          stageOptions[existingIndex] = created;
        } else {
          stageOptions.add(created);
        }
        stageOptions.refresh();
        if (!selectedStageIds.contains(created.id)) {
          selectedStageIds.add(created.id);
          stageGroups[created.id.toString()] = [];
        }

        Get.snackbar('Success', 'Stage "$stageName" created successfully');
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to create stage';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error creating stage: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
      return false;
    } finally {
      isAddingOption.value = false;
    }
  }

  // Set groups for a stage (by name for UI, stores with ID as key)
  void setStageGroups(String stageName, List<String> groupNames) {
    final stageId = getStageIdByName(stageName);
    if (stageId == null || stageId == 0) {
      print(
        'setStageGroups: Stage name "$stageName" not found or invalid. Available stages: ${stageOptions.map((e) => '${e.id}:${e.name}').toList()}',
      );
      return;
    }

    final groupIds = groupNames
        .map((name) {
          final id = getGroupIdByName(name);
          if (id == null || id == 0) {
            print(
              'setStageGroups: Group name "$name" not found or invalid. Available groups: ${groupOptions.map((e) => '${e.id}:${e.name}').toList()}',
            );
          }
          return id;
        })
        .where((id) => id != null && id != 0)
        .cast<int>()
        .toList();

    stageGroups[stageId.toString()] = groupIds;
    print(
      'setStageGroups: Set groups for stage "$stageName" (ID: $stageId): $groupIds',
    );
  }

  // Get groups for a stage (by name, returns names)
  List<String> getStageGroups(String stageName) {
    if (stageName.isEmpty) {
      print('getStageGroups: Empty stage name');
      return [];
    }

    final stageId = getStageIdByName(stageName);
    if (stageId == null) {
      print(
        'getStageGroups: Stage name "$stageName" not found. Available stages: ${stageOptions.map((e) => e.name).toList()}',
      );
      return [];
    }

    print('getStageGroups: Stage "$stageName" -> ID: $stageId');
    print('getStageGroups: Current stageGroups map: $stageGroups');

    final groupIds = stageGroups[stageId.toString()] ?? [];
    print('getStageGroups: Group IDs for stage $stageId: $groupIds');

    if (groupIds.isEmpty) {
      print('getStageGroups: No groups assigned to stage $stageId');
      return [];
    }

    // Convert group IDs to names
    final groupNames = groupIds
        .map((id) {
          final name = getGroupNameById(id);
          if (name == null) {
            print(
              'getStageGroups: Group ID $id not found. Available groups: ${groupOptions.map((e) => '${e.id}:${e.name}').toList()}',
            );
          }
          return name;
        })
        .where((name) => name != null)
        .cast<String>()
        .toList();

    print(
      'getStageGroups: Final group names for stage "$stageName": $groupNames',
    );
    return groupNames;
  }

  // Get all available groups (all groups are available for all stages)
  List<String> getAllAvailableGroups() {
    return List<String>.from(groupOptionNames);
  }

  // Add custom group (by name for UI, stores ID internally)
  Future<bool> addCustomGroup(String groupName, {String? description}) async {
    if (groupName.isEmpty) return false;

    try {
      isAddingOption.value = true;
      errorMessage.value = '';

      final response = await _repository.createGroup(
        name: groupName,
        description: description,
      );

      if (response.success && response.data != null) {
        final created = response.data!;
        final existingIndex = groupOptions.indexWhere((g) => g.id == created.id);
        if (existingIndex >= 0) {
          groupOptions[existingIndex] = created;
        } else {
          groupOptions.add(created);
        }
        groupOptions.refresh();

        Get.snackbar('Success', 'Group "$groupName" created successfully');
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to create group';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error creating group: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
      return false;
    } finally {
      isAddingOption.value = false;
    }
  }

  // Check if a group is assigned to another stage (by name)
  String? getStageForGroup(String groupName) {
    final groupId = getGroupIdByName(groupName);
    if (groupId == null) return null;

    for (final entry in stageGroups.entries) {
      if (entry.value.contains(groupId)) {
        final stageId = int.tryParse(entry.key);
        if (stageId != null) {
          return getStageNameById(stageId);
        }
      }
    }
    return null;
  }

  // Check if a group is available (not assigned to any other stage)
  bool isGroupAvailable(String groupName, String currentStageName) {
    final groupId = getGroupIdByName(groupName);
    final currentStageId = getStageIdByName(currentStageName);
    if (groupId == null || currentStageId == null) return false;

    final assignedStage = getStageForGroup(groupName);
    return assignedStage == null || assignedStage == currentStageName;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String? validateEventStartDate(
    DateTime? value, {
    bool requireWhenEmpty = false,
  }) {
    if (value == null) {
      if (requireWhenEmpty || shouldShowCompetitionDateError(dateFieldStart)) {
        return 'Please select event start date';
      }
      return null;
    }
    final start = _dateOnly(value);
    final end = eventEndDate.value;
    if (end != null && _dateOnly(end).isBefore(start)) {
      return 'Start date must be on or before end date';
    }
    final ad = displayAdFrom.value;
    if (ad != null && _dateOnly(ad).isAfter(start)) {
      return 'Start date must be on or after display ad date';
    }
    return null;
  }

  String? validateEventEndDate(
    DateTime? value, {
    bool requireWhenEmpty = false,
  }) {
    if (value == null) {
      if (requireWhenEmpty || shouldShowCompetitionDateError(dateFieldEnd)) {
        return 'Please select event end date';
      }
      return null;
    }
    final end = _dateOnly(value);
    final start = eventStartDate.value;
    if (start != null && end.isBefore(_dateOnly(start))) {
      return 'End date must be on or after start date';
    }
    return null;
  }

  String? validateDisplayAdFrom(
    DateTime? value, {
    bool requireWhenEmpty = false,
  }) {
    if (value == null) {
      if (requireWhenEmpty ||
          shouldShowCompetitionDateError(dateFieldDisplayAd)) {
        return 'Please select display ad from date';
      }
      return null;
    }
    final ad = _dateOnly(value);
    final start = eventStartDate.value;
    if (start != null && ad.isAfter(_dateOnly(start))) {
      return 'Display ad date must be on or before event start date';
    }
    return null;
  }

  int _minutesFromMidnight(TimeOfDay time) => time.hour * 60 + time.minute;

  String? validateEventStartTime(
    TimeOfDay? value, {
    bool requireWhenEmpty = false,
  }) {
    if (value == null) {
      return null;
    }

    final startDate = eventStartDate.value;
    final endDate = eventEndDate.value;
    final endTime = eventEndTime.value;
    if (startDate != null &&
        endDate != null &&
        _dateOnly(startDate) == _dateOnly(endDate) &&
        endTime != null &&
        _minutesFromMidnight(value) >= _minutesFromMidnight(endTime)) {
      return 'Start time must be before end time on the same day';
    }
    return null;
  }

  String? validateEventEndTime(
    TimeOfDay? value, {
    bool requireWhenEmpty = false,
  }) {
    if (value == null) {
      if (requireWhenEmpty ||
          shouldShowCompetitionDateError(dateFieldEndTime)) {
        return 'Please select event end time';
      }
      return null;
    }

    final startDate = eventStartDate.value;
    final endDate = eventEndDate.value;
    final startTime = eventStartTime.value;
    if (startDate != null &&
        endDate != null &&
        _dateOnly(startDate) == _dateOnly(endDate) &&
        startTime != null &&
        _minutesFromMidnight(value) <= _minutesFromMidnight(startTime)) {
      return 'End time must be after start time on the same day';
    }
    return null;
  }

  String? validateResultsPublishTime(
    TimeOfDay? value, {
    bool requireWhenEmpty = false,
  }) {
    if (publishResultNow.value) {
      return null;
    }
    if (value == null) {
      if (requireWhenEmpty ||
          shouldShowCompetitionDateError(dateFieldResultsPublishTime)) {
        return 'Please select results publish time';
      }
      return null;
    }

    return null;
  }

  String? validateCompetitionDates({bool forSubmit = false}) {
    return validateEventStartDate(
          eventStartDate.value,
          requireWhenEmpty: forSubmit,
        ) ??
        validateEventEndDate(eventEndDate.value, requireWhenEmpty: forSubmit) ??
        validateEventStartTime(
          eventStartTime.value,
          requireWhenEmpty: forSubmit,
        ) ??
        validateEventEndTime(eventEndTime.value, requireWhenEmpty: forSubmit) ??
        validateResultsPublishTime(
          resultsPublishTime.value,
          requireWhenEmpty: forSubmit,
        ) ??
        validateDisplayAdFrom(displayAdFrom.value, requireWhenEmpty: forSubmit);
  }

  Future<bool> _ensureCompetitionNameIsAvailable() async {
    final name = competitionNameController.text.trim();
    if (name.isEmpty) {
      _notifyError('Competition name is required');
      scrollToSection(
        competitionNameFieldKey,
        focusNode: competitionNameFocusNode,
      );
      return false;
    }
    int? excludeId;
    if (isEditMode.value) {
      excludeId = int.tryParse(competitionToEdit.value?.id ?? '');
    }
    final response = await _repository.isCompetitionNameAvailable(
      name: name,
      excludeId: excludeId,
    );
    if (!response.success) {
      _notifyError(
        response.message ?? 'Could not verify competition name. Try again.',
      );
      scrollToSection(
        competitionNameFieldKey,
        focusNode: competitionNameFocusNode,
      );
      return false;
    }
    if (response.data == false) {
      _notifyError("Competition with name '$name' already exists!");
      scrollToSection(
        competitionNameFieldKey,
        focusNode: competitionNameFocusNode,
      );
      return false;
    }
    return true;
  }

  void alertCompetitionDateValidationIssue() {
    final message = validateCompetitionDates();
    if (message == null) return;
    final hasAnyDate =
        eventStartDate.value != null ||
        eventEndDate.value != null ||
        eventStartTime.value != null ||
        eventEndTime.value != null ||
        resultsPublishTime.value != null ||
        displayAdFrom.value != null;
    if (!hasAnyDate) return;
    Get.snackbar(
      'Invalid date',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  // Create competition
  Future<bool> createCompetition() async {
    if (isProcessingCompetitionPayment.value) {
      return false;
    }
    try {
      hasAttemptedSubmit.value = true;
      notifyCompetitionDatesChanged();
      if (!_validateFormState()) {
        return false;
      }

      final dateError = validateCompetitionDates(forSubmit: true);
      if (dateError != null) {
        _notifyError(dateError);
        scrollToFirstMissingMandatorySection(includeBrochure: true);
        return false;
      }

      final categoryConfigError = _validateCategoryConfigDraftsForSubmit();
      if (categoryConfigError != null) {
        _notifyError(categoryConfigError);
        scrollToSection(categoriesSectionKey);
        return false;
      }

      if (categoryConfigDrafts.isEmpty) {
        if (participantsPerStage.value <= 0) {
          _notifyError('Please select participants per stage');
          scrollToSection(participantsPerStageFieldKey);
          return false;
        }

        if (selectedCategoryIds.isEmpty) {
          _notifyError('Please select at least one category');
          scrollToSection(categoriesSectionKey);
          return false;
        }

        if (selectedStageIds.isEmpty) {
          _notifyError('Please select at least one stage');
          scrollToSection(stagesSectionKey);
          return false;
        }

        if (selectedPrizeIds.isEmpty) {
          _notifyError('Please select at least one prize');
          scrollToSection(prizesSectionKey);
          return false;
        }
      }

      final categoryStyleError = validateCategoriesForChampionshipStyle();
      if (categoryStyleError != null) {
        _notifyError(categoryStyleError);
        scrollToSection(categoriesSectionKey);
        return false;
      }

      if (!await confirmChampionshipStyleBeforeSave()) {
        return false;
      }

      final gradeError = validateGradeEntries();
      if (gradeError != null) {
        _notifyError(gradeError);
        scrollToSection(gradesSectionKey);
        return false;
      }

      // Validate brochure upload
      if (!validateBrochure()) {
        _notifyError(errorMessage.value);
        scrollToSection(brochureSectionKey);
        return false;
      }

      isLoading.value = true;
      errorMessage.value = '';

      if (!await _ensureCompetitionNameIsAvailable()) {
        isLoading.value = false;
        return false;
      }

      await loadOnDemandContext();

      String? maintenancePaymentOrderId;
      if (requiresPrepaidCompetitionPayment) {
        isLoading.value = false;
        isProcessingCompetitionPayment.value = true;
        try {
          maintenancePaymentOrderId =
              await _completeOnDemandPaymentBeforeCreate(
                description: competitionNameController.text.trim(),
              );
          if (maintenancePaymentOrderId == null) {
            return false;
          }
        } finally {
          isProcessingCompetitionPayment.value = false;
          _razorpayCheckout.dispose();
        }
        isLoading.value = true;
      }

      final configs = categoryConfigsForSubmit;
      if (configs.isNotEmpty) {
        _applyFirstAsanasFlatFieldsFromDrafts();
        _syncCategorySelectionFromDrafts();
      }

      final competition = CompetitionModel(
        competitionName: competitionNameController.text.trim(),
        description: descriptionController.text.trim(),
        address: addressController.text.trim(),
        eventStartDate: eventStartDate.value!,
        eventStartTime: CompetitionModel.formatTimeOfDay(eventStartTime.value),
        eventEndDate: eventEndDate.value!,
        eventEndTime: CompetitionModel.formatTimeOfDay(eventEndTime.value),
        publishResultNow: publishResultNow.value,
        resultsPublishDate: publishResultNow.value ? null : eventEndDate.value,
        resultsPublishTime: publishResultNow.value
            ? null
            : CompetitionModel.formatTimeOfDay(resultsPublishTime.value),
        displayAdFrom: displayAdFrom.value,
        spotRegistration: spotRegistration.value,
        participantsPerStage: participantsPerStage.value > 0
            ? participantsPerStage.value
            : null,
        minimumMarks: minimumMarks.value > 0 ? minimumMarks.value : null,
        maximumMarks: maximumMarks.value > 0 ? maximumMarks.value : null,
        skippedAsanaMarks: skippedAsanaMarks.value,
        prizeIds: selectedPrizeIds.where((id) => id > 0).toList(),
        categoryIds: selectedCategoryIds.where((id) => id > 0).toList(),
        categoryAmounts: Map<String, double>.from(categoryAmounts),
        categorySpotAmounts: Map<String, double>.from(categorySpotAmounts),
        categoryExtraFeeIncluded: isOnDemandOrg.value
            ? buildCategoryExtraFeeIncludedForSubmit()
            : null,
        stageIds: selectedStageIds.where((id) => id > 0).toList(),
        stageGroups: Map<String, List<int>>.from(stageGroups),
        championshipStyle: championshipStyle.value?.apiValue ??
            ChampionshipStyle.separateCategory.apiValue,
        competitionMode: competitionMode.value,
        googleDriveFolderUrl: googleDriveFolderUrlController.text.trim(),
        categoryConfigs: configs.isNotEmpty ? configs : null,
        bestSchoolAwardMinParticipants: _parsedBestSchoolAwardMinParticipants(),
        grades: buildGradesForSubmit(),
      );

      final response = await _repository.createCompetition(
        competition: competition,
        maintenancePaymentOrderId: maintenancePaymentOrderId,
        brochureFile: brochureFile.value,
        brochureFileLocal: brochureFileLocal.value,
        brochureBytes: brochureBytes.value,
        brochureFilename: brochureFileName.value.isNotEmpty
            ? brochureFileName.value
            : null,
      );

      if (response.success && response.data != null) {
        final created = response.data!.competition;
        lastSavedCompetitionForQr.value = created;
        await loadCompetitions(resetPage: true);
        if (Get.isRegistered<FirstCompetitionGateService>()) {
          await Get.find<FirstCompetitionGateService>().clear();
        }
        AppRouter.refresh();
        clearForm();
        _notifySuccess(
          requiresPrepaidCompetitionPayment
              ? 'Payment completed and competition created successfully'
              : 'Competition created successfully',
        );
        if (!_isFirstCompetitionGateActive()) {
          toggleViewMode(true);
        }
        return true;
      } else {
        lastSavedCompetitionForQr.value = null;
        final message = response.message ?? 'Failed to create competition';
        _notifyError(message);
        if (_isSubscriptionCreditError(message)) {
          await prepareSubscriptionTopUpFlow();
        }
        return false;
      }
    } catch (e) {
      lastSavedCompetitionForQr.value = null;
      final message = 'Error creating competition: ${e.toString()}';
      _notifyError(message);
      if (_isSubscriptionCreditError(message)) {
        await prepareSubscriptionTopUpFlow();
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void clearLastSavedCompetitionForQr() {
    lastSavedCompetitionForQr.value = null;
  }

  int? _parsedBestSchoolAwardMinParticipants() {
    final raw = bestSchoolAwardMinParticipantsController.text.trim();
    if (raw.isEmpty) return null;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  // Update competition
  Future<bool> updateCompetition() async {
    if (isProcessingCompetitionPayment.value) {
      return false;
    }
    try {
      if (competitionToEdit.value == null) {
        _notifyError('No competition selected for update');
        return false;
      }

      hasAttemptedSubmit.value = true;
      notifyCompetitionDatesChanged();
      if (!_validateFormState()) {
        return false;
      }

      final dateError = validateCompetitionDates(forSubmit: true);
      if (dateError != null) {
        _notifyError(dateError);
        scrollToFirstMissingMandatorySection(includeBrochure: false);
        return false;
      }

      final categoryConfigError = _validateCategoryConfigDraftsForSubmit();
      if (categoryConfigError != null) {
        _notifyError(categoryConfigError);
        scrollToSection(categoriesSectionKey);
        return false;
      }

      if (categoryConfigDrafts.isEmpty) {
        if (participantsPerStage.value <= 0) {
          _notifyError('Please select participants per stage');
          scrollToSection(participantsPerStageFieldKey);
          return false;
        }

        if (selectedCategoryIds.isEmpty) {
          _notifyError('Please select at least one category');
          scrollToSection(categoriesSectionKey);
          return false;
        }

        if (selectedStageIds.isEmpty) {
          _notifyError('Please select at least one stage');
          scrollToSection(stagesSectionKey);
          return false;
        }

        if (selectedPrizeIds.isEmpty) {
          _notifyError('Please select at least one prize');
          scrollToSection(prizesSectionKey);
          return false;
        }
      }

      final categoryStyleError = validateCategoriesForChampionshipStyle();
      if (categoryStyleError != null) {
        _notifyError(categoryStyleError);
        scrollToSection(categoriesSectionKey);
        return false;
      }

      if (!await confirmChampionshipStyleBeforeSave()) {
        return false;
      }

      final gradeError = validateGradeEntries();
      if (gradeError != null) {
        _notifyError(gradeError);
        scrollToSection(gradesSectionKey);
        return false;
      }

      // Brochure validation - optional for update (only if new file is selected)
      final hasNewBrochure =
          brochureFile.value != null ||
          brochureFileLocal.value != null ||
          brochureBytes.value != null;

      isLoading.value = true;
      errorMessage.value = '';

      if (!await _ensureCompetitionNameIsAvailable()) {
        isLoading.value = false;
        return false;
      }

      await loadOnDemandContext();

      String? maintenancePaymentOrderId;
      if (requiresPrepaidCompetitionPayment) {
        isLoading.value = false;
        isProcessingCompetitionPayment.value = true;
        try {
          maintenancePaymentOrderId =
              await _completeOnDemandPaymentBeforeCreate(
                description: competitionNameController.text.trim(),
              );
          if (maintenancePaymentOrderId == null) {
            return false;
          }
        } finally {
          isProcessingCompetitionPayment.value = false;
          _razorpayCheckout.dispose();
        }
        isLoading.value = true;
      }

      final configs = categoryConfigsForSubmit;
      if (configs.isNotEmpty) {
        _applyFirstAsanasFlatFieldsFromDrafts();
        _syncCategorySelectionFromDrafts();
      }

      final competition = CompetitionModel(
        id: competitionToEdit.value!.id,
        competitionName: competitionNameController.text.trim(),
        description: descriptionController.text.trim(),
        address: addressController.text.trim(),
        eventStartDate: eventStartDate.value!,
        eventStartTime: CompetitionModel.formatTimeOfDay(eventStartTime.value),
        eventEndDate: eventEndDate.value!,
        eventEndTime: CompetitionModel.formatTimeOfDay(eventEndTime.value),
        publishResultNow: publishResultNow.value,
        resultsPublishDate: publishResultNow.value ? null : eventEndDate.value,
        resultsPublishTime: publishResultNow.value
            ? null
            : CompetitionModel.formatTimeOfDay(resultsPublishTime.value),
        displayAdFrom: displayAdFrom.value,
        spotRegistration: spotRegistration.value,
        participantsPerStage: participantsPerStage.value > 0
            ? participantsPerStage.value
            : null,
        minimumMarks: minimumMarks.value > 0 ? minimumMarks.value : null,
        maximumMarks: maximumMarks.value > 0 ? maximumMarks.value : null,
        skippedAsanaMarks: skippedAsanaMarks.value,
        prizeIds: selectedPrizeIds.where((id) => id > 0).toList(),
        categoryIds: selectedCategoryIds.where((id) => id > 0).toList(),
        categoryAmounts: Map<String, double>.from(categoryAmounts),
        categorySpotAmounts: Map<String, double>.from(categorySpotAmounts),
        categoryExtraFeeIncluded: isOnDemandOrg.value
            ? buildCategoryExtraFeeIncludedForSubmit()
            : null,
        stageIds: selectedStageIds.where((id) => id > 0).toList(),
        stageGroups: Map<String, List<int>>.from(stageGroups),
        championshipStyle: championshipStyle.value?.apiValue ??
            ChampionshipStyle.separateCategory.apiValue,
        competitionMode: competitionMode.value,
        googleDriveFolderUrl: googleDriveFolderUrlController.text.trim(),
        categoryConfigs: configs.isNotEmpty ? configs : null,
        bestSchoolAwardMinParticipants: _parsedBestSchoolAwardMinParticipants(),
        grades: buildGradesForSubmit(),
      );

      final response = await _repository.updateCompetition(
        competition: competition,
        maintenancePaymentOrderId: maintenancePaymentOrderId,
        brochureFile: hasNewBrochure ? brochureFile.value : null,
        brochureFileLocal: hasNewBrochure ? brochureFileLocal.value : null,
        brochureBytes: hasNewBrochure ? brochureBytes.value : null,
        brochureFilename: hasNewBrochure && brochureFileName.value.isNotEmpty
            ? brochureFileName.value
            : null,
      );

      if (response.success) {
        if (response.data != null) {
          competitionToEdit.value = response.data;
          _applyPaidFormatsFromCompetition(response.data!);
        } else {
          if (unpaidAsanasForPayment) {
            maintenancePaidAsanas.value = true;
          }
          if (unpaidChallengeForPayment) {
            maintenancePaidChallenge.value = true;
          }
        }
        // Update timestamp to force brochure reload after update
        brochureUpdateTimestamp.value = DateTime.now().millisecondsSinceEpoch;

        if (hasNewBrochure) {
          brochureFile.value = null;
          brochureFileLocal.value = null;
          brochureBytes.value = null;
          final url = competitionToEdit.value?.brochureUrl;
          if (url != null && url.isNotEmpty) {
            brochureUrl.value = url;
            final segments = url.split('/');
            if (segments.isNotEmpty) {
              brochureFileName.value = segments.last;
            }
          }
        }

        await loadCompetitions(resetPage: false);
        _notifySuccess('Competition updated successfully');
        clearForm();
        toggleViewMode(true);
        return true;
      } else {
        _notifyError(response.message ?? 'Failed to update competition');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('updateCompetition error: $e\n$stackTrace');
      _notifyError('Error updating competition: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Load competitions list
  Future<void> loadCompetitions({bool resetPage = false}) async {
    await _yieldPastBuildIfNeeded();
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Reset to first page if requested
      if (resetPage) {
        currentPage.value = 1;
      }

      final response = await _repository.getAllCompetitions(
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        status: selectedFilter.value.isNotEmpty ? selectedFilter.value : null,
        page: currentPage.value > 0
            ? currentPage.value - 1
            : 0, // API uses 0-based indexing
        limit: itemsPerPage.value,
        sortBy: sortBy.value,
        order: sortOrder.value,
      );

      if (response.success && response.data != null) {
        final listResponse = response.data!;
        competitions.value = listResponse.competitions;

        // Update pagination info from API response
        if (listResponse.pagination != null) {
          final pagination = listResponse.pagination!;
          currentPage.value =
              (pagination['page'] as int? ?? 0) + 1; // Convert to 1-based
          totalItems.value = pagination['total'] as int? ?? 0;
          totalPages.value = pagination['totalPages'] as int? ?? 0;
          itemsPerPage.value = pagination['limit'] as int? ?? 20;
        } else {
          // Fallback: estimate pagination if not provided
          if (competitions.isNotEmpty) {
            if (competitions.length < itemsPerPage.value) {
              totalPages.value = currentPage.value;
            } else {
              totalPages.value = currentPage.value + 1;
            }
            totalItems.value = competitions.length;
          } else {
            totalPages.value = 0;
            totalItems.value = 0;
          }
        }

        // If no competitions returned and not first page, go back to first page
        if (competitions.isEmpty && currentPage.value > 1) {
          currentPage.value = 1;
          return loadCompetitions();
        }
      } else {
        errorMessage.value = response.message ?? 'Failed to fetch competitions';
        competitions.value = [];
        totalPages.value = 0;
        totalItems.value = 0;
      }
    } catch (e) {
      errorMessage.value = 'Error fetching competitions: ${e.toString()}';
      competitions.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// When [loadCompetitions] is started from [StatelessWidget.build], the HTTP
  /// stack on web can resolve in the same frame; GetX then notifies [Obx]
  /// during build ("markNeedsBuild called during build").
  static Future<void> _yieldPastBuildIfNeeded() async {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      return;
    }
    await SchedulerBinding.instance.endOfFrame;
  }

  // Go to next page
  void nextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      loadCompetitions();
    }
  }

  // Go to previous page
  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      loadCompetitions();
    }
  }

  // Go to specific page
  void goToPage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      loadCompetitions();
    }
  }

  // Update sort
  void updateSort(String newSortBy, String newOrder) {
    sortBy.value = newSortBy;
    sortOrder.value = newOrder;
    loadCompetitions(resetPage: true);
  }

  // Update search query and reload
  void updateSearch(String query) {
    searchQuery.value = query;
    loadCompetitions(resetPage: true);
  }

  // Update filter and reload
  void updateFilter(String filter) {
    selectedFilter.value = filter;
    loadCompetitions(resetPage: true);
  }

  // Clear search
  void clearSearch() {
    searchController.clear();
    updateSearch('');
  }

  // Load competition data into form for editing/viewing
  Future<void> loadCompetitionForEdit(
    CompetitionModel competition, {
    bool isView = false,
  }) async {
    // Ensure options are loaded before converting IDs to names.
    // (Prizes/Categories/Stagers are needed to map IDs -> labels and populate checkboxes.)
    if (categoryOptions.isEmpty ||
        prizeOptions.isEmpty ||
        stageOptions.isEmpty ||
        groupOptions.isEmpty) {
      print('loadCompetitionForEdit: Options not loaded yet, loading now...');
      await loadOptions(); // GET: prizes, categories, stages, groups
    }

    var competitionToLoad = competition;
    final numericId = int.tryParse(competition.id ?? '');
    if (numericId != null) {
      final response = await _repository.getCompetitionById(numericId);
      if (response.success && response.data != null) {
        competitionToLoad = response.data!;
        _upsertCompetition(competitionToLoad);
      }
    }

    _loadCompetitionData(competitionToLoad, isView: isView);
  }

  void _loadCompetitionData(
    CompetitionModel competition, {
    bool isView = false,
  }) {
    isEditMode.value = !isView; // true for edit, false for view
    isViewMode.value = isView; // true for view-only
    competitionToEdit.value = competition;
    _applyPaidFormatsFromCompetition(competition);

    // Load data into form fields
    competitionNameController.text = competition.competitionName;
    descriptionController.text = competition.description;
    descriptionTouched.value = false;
    descriptionText.value = competition.description;
    addressController.text = competition.address;
    addressTouched.value = false;
    addressText.value = competition.address;
    eventStartDate.value = competition.eventStartDate;
    eventEndDate.value = competition.eventEndDate;
    eventStartTime.value = CompetitionModel.parseTime(
      competition.eventStartTime,
    );
    eventEndTime.value = CompetitionModel.parseTime(competition.eventEndTime);
    displayAdFrom.value = competition.displayAdFrom;
    publishResultNow.value = competition.resolvedPublishResultNow;
    resultsPublishTime.value = CompetitionModel.parseTime(
      competition.resultsPublishTime,
    );
    spotRegistration.value = competition.resolvedSpotRegistration;
    championshipStyle.value =
        ChampionshipStyle.fromApiValue(competition.championshipStyle) ??
        ChampionshipStyle.separateCategory;
    competitionMode.value =
        (competition.competitionMode ?? 'OFFLINE').toUpperCase() == 'ONLINE'
            ? 'ONLINE'
            : 'OFFLINE';
    googleDriveFolderUrlController.text =
        competition.googleDriveFolderUrl?.trim() ?? '';
    if ((competition.googleDriveServiceAccountEmail ?? '').trim().isNotEmpty) {
      googleDriveServiceAccountEmail.value =
          competition.googleDriveServiceAccountEmail!.trim();
    }
    googleDriveServerConfigured.value = competition.googleDriveConfigured;
    participantsPerStage.value = competition.participantsPerStage ?? 0;
    minimumMarks.value = competition.minimumMarks ?? 0;
    maximumMarks.value = competition.maximumMarks ?? 0;
    skippedAsanaMarks.value = competition.skippedAsanaMarks ?? 0;
    bestSchoolAwardMinParticipantsController.text =
        competition.bestSchoolAwardMinParticipants != null &&
            competition.bestSchoolAwardMinParticipants! > 0
        ? '${competition.bestSchoolAwardMinParticipants}'
        : '';
    // Load IDs if available, otherwise convert names to IDs
    if (competition.prizeIds != null && competition.prizeIds!.isNotEmpty) {
      selectedPrizeIds.value = List<int>.from(competition.prizeIds!);
    } else if (competition.prizes != null && competition.prizes!.isNotEmpty) {
      // Convert names to IDs
      selectedPrizeIds.value = competition.prizes!
          .map((name) => getPrizeIdByName(name))
          .where((id) => id != null)
          .cast<int>()
          .toList();
    } else {
      selectedPrizeIds.clear();
    }

    if (competition.categoryIds != null &&
        competition.categoryIds!.isNotEmpty) {
      selectedCategoryIds.value = List<int>.from(competition.categoryIds!);
      // Load category amounts with IDs as keys
      // API might return categoryAmounts with names or IDs as keys, convert to IDs
      if (competition.categoryAmounts != null &&
          competition.categoryAmounts!.isNotEmpty) {
        categoryAmounts.value = {};
        for (final entry in competition.categoryAmounts!.entries) {
          final keyStr = entry.key.toString();
          int? categoryId;

          // Try to parse as int first (if it's already an ID)
          final parsedId = int.tryParse(keyStr);
          if (parsedId != null && selectedCategoryIds.contains(parsedId)) {
            // Key is already a category ID
            categoryId = parsedId;
          } else {
            // Key is likely a category name, convert to ID
            categoryId = getCategoryIdByName(keyStr);
          }

          if (categoryId != null) {
            categoryAmounts[categoryId.toString()] = entry.value;
          }
        }
      } else {
        categoryAmounts.clear();
      }
      _loadCategorySpotAmountsFromCompetition(competition);
    } else if (competition.categories != null &&
        competition.categories!.isNotEmpty) {
      // Convert names to IDs
      selectedCategoryIds.value = competition.categories!
          .map((name) => getCategoryIdByName(name))
          .where((id) => id != null)
          .cast<int>()
          .toList();
      // Convert category amounts from names to IDs
      if (competition.categoryAmounts != null) {
        categoryAmounts.value = {};
        for (final entry in competition.categoryAmounts!.entries) {
          final categoryId = getCategoryIdByName(entry.key);
          if (categoryId != null) {
            categoryAmounts[categoryId.toString()] = entry.value;
          }
        }
      } else {
        categoryAmounts.clear();
      }
      _loadCategorySpotAmountsFromCompetition(competition);
    } else {
      selectedCategoryIds.clear();
      categoryAmounts.clear();
      categorySpotAmounts.clear();
    }

    categoryIncludeFee.clear();
    if (competition.categoryExtraFeeIncluded != null &&
        competition.categoryExtraFeeIncluded!.isNotEmpty) {
      for (final entry in competition.categoryExtraFeeIncluded!.entries) {
        final parsedId = int.tryParse(entry.key);
        int? categoryId = parsedId;
        if (categoryId == null) {
          categoryId = getCategoryIdByName(entry.key);
        }
        if (categoryId != null) {
          categoryIncludeFee[categoryId.toString()] = entry.value;
        }
      }
    }

    if (competition.categoryConfigs != null &&
        competition.categoryConfigs!.isNotEmpty) {
      categoryConfigDrafts.value = competition.categoryConfigs!
          .map((c) => CompetitionCategoryConfigModel.fromJson(c.toJson()))
          .toList();
    } else if (selectedCategoryIds.isNotEmpty) {
      // Backfill drafts from flat category selection for older competitions
      categoryConfigDrafts.value = selectedCategoryIds.map((id) {
        final name = categoryOptions
                .firstWhereOrNull((o) => o.id == id)
                ?.name ??
            'CATEGORY $id';
        final amount = categoryAmounts[id.toString()] ?? 0.0;
        final include = categoryIncludeFee[id.toString()] ?? true;
        return CompetitionCategoryConfigModel(
          draftId: 'cat-$id',
          categoryId: id,
          categoryName: name,
          format: 'ASANAS',
          configured: true,
          participantsPerStage: competition.participantsPerStage ?? 5,
          minimumMarks: competition.minimumMarks ?? 1,
          maximumMarks: competition.maximumMarks ?? 10,
          skippedAsanaMarks: competition.skippedAsanaMarks ?? 0,
          feeAmount: amount,
          includeFeeInRegistration: include,
          stageAllotment: competition.stageGroupLabels != null
              ? Map<String, List<String>>.from(
                  competition.stageGroupLabels!.map(
                    (k, v) => MapEntry(k, List<String>.from(v)),
                  ),
                )
              : {},
        );
      }).toList();
    } else {
      categoryConfigDrafts.clear();
    }
    for (final id in selectedCategoryIds) {
      _ensureCategoryIncludeFeeDefault(id);
    }

    if (championshipStyle.value == ChampionshipStyle.fromFirstPlaceWinners) {
      _deselectChampionsCategory();
    }

    if (competition.stageIds != null && competition.stageIds!.isNotEmpty) {
      selectedStageIds.value = List<int>.from(competition.stageIds!);
      // Load stage groups with IDs
      // API returns stageGroupsById with stage IDs as keys (already in correct format)
      if (competition.stageGroups != null &&
          competition.stageGroups!.isNotEmpty) {
        // Since stageGroupsById already has stage IDs as keys, we can use them directly
        stageGroups.value = Map<String, List<int>>.from(
          competition.stageGroups!,
        );
        print('_loadCompetitionData: Loaded stageGroups: $stageGroups');
        print('_loadCompetitionData: Selected stage IDs: $selectedStageIds');
        print(
          '_loadCompetitionData: Available stage options: ${stageOptions.map((e) => '${e.id}:${e.name}').toList()}',
        );
        print(
          '_loadCompetitionData: Available group options: ${groupOptions.map((e) => '${e.id}:${e.name}').toList()}',
        );
      } else {
        stageGroups.clear();
        print('_loadCompetitionData: No stageGroups found in competition data');
      }
    } else if (competition.stages != null && competition.stages!.isNotEmpty) {
      // Convert names to IDs
      selectedStageIds.value = competition.stages!
          .map((name) => getStageIdByName(name))
          .where((id) => id != null)
          .cast<int>()
          .toList();
      // Convert stage groups from names to IDs
      if (competition.stageGroups != null) {
        stageGroups.value = {};
        for (final entry in competition.stageGroups!.entries) {
          final stageId = getStageIdByName(entry.key);
          if (stageId != null) {
            // Convert group names to IDs
            final groupIds = (entry.value as List)
                .map((item) {
                  if (item is String) {
                    return getGroupIdByName(item);
                  } else if (item is int) {
                    return item;
                  }
                  return null;
                })
                .where((id) => id != null)
                .cast<int>()
                .toList();
            stageGroups[stageId.toString()] = groupIds;
          }
        }
      } else {
        stageGroups.clear();
      }
    } else {
      selectedStageIds.clear();
      stageGroups.clear();
    }

    _loadGradeEntries(competition.grades);

    // If category configs are GRADING but missing grades_json, use competition grades.
    if (competition.grades != null && competition.grades!.isNotEmpty) {
      for (final draft in categoryConfigDrafts) {
        if (draft.isGradingScoring && draft.grades.isEmpty) {
          draft.grades = List<CompetitionGradeModel>.from(competition.grades!);
        }
      }
      categoryConfigDrafts.refresh();
    }

    // Load brochure URL if available
    if (competition.brochureUrl != null &&
        competition.brochureUrl!.isNotEmpty) {
      brochureUrl.value = competition.brochureUrl!;
      final segments = competition.brochureUrl!.split('/');
      if (segments.isNotEmpty) {
        brochureFileName.value = segments.last;
      }
    } else {
      brochureFileName.value = '';
    }

    // Switch to create view
    isListView.value = false;
    _refreshFormKeys();
  }

  // View competition details - redirect to form with data (read-only)
  Future<void> viewCompetition(
    BuildContext context,
    CompetitionModel competition,
  ) async {
    await loadCompetitionForEdit(competition, isView: true);
  }

  // Edit competition - redirect to form with data (editable)
  Future<void> editCompetition(
    BuildContext context,
    CompetitionModel competition,
  ) async {
    await loadCompetitionForEdit(competition, isView: false);
  }

  // Delete competition — DELETE /competition/{id}
  Future<void> deleteCompetition(
    BuildContext context,
    CompetitionModel competition,
  ) async {
    final competitionId = competition.id?.trim();
    if (competitionId == null || competitionId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid competition ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    String selectedReason = 'REFUND';
    final reasonController = TextEditingController();
    List<Map<String, dynamic>> paidRegistrations = [];
    bool loadingPaid = true;
    String? loadError;

    final info = await _repository.getCompetitionDeletionInfo(competitionId);
    if (info.success && info.data != null) {
      final raw = info.data!['paidRegistrations'];
      if (raw is List) {
        paidRegistrations = raw
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
      }
      loadingPaid = false;
    } else {
      loadError = info.message ?? 'Could not load paid participant list';
      loadingPaid = false;
    }

    if (!context.mounted) {
      reasonController.dispose();
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final showReasonField = selectedReason == 'OTHERS';
          return AlertDialog(
            title: const Text('Delete Competition'),
            content: SizedBox(
              width: 480,
              child: PinnedVerticalScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Delete "${competition.competitionName}"? '
                      'All competition-related data will be removed. '
                      'This cannot be undone.',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Refunds are handled by the organizer. '
                      'The app does not process refunds.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      decoration: const InputDecoration(
                        labelText: 'Reason for deletion',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'REFUND',
                          child: Text('Refund'),
                        ),
                        DropdownMenuItem(
                          value: 'OTHERS',
                          child: Text('Others'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => selectedReason = value);
                      },
                    ),
                    if (showReasonField) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Reason (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    if (selectedReason == 'REFUND') ...[
                      const SizedBox(height: 16),
                      Text(
                        'Participants with paid registration '
                        '(${paidRegistrations.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      if (loadingPaid)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (loadError != null)
                        Text(
                          loadError,
                          style: const TextStyle(color: Colors.orange),
                        )
                      else if (paidRegistrations.isEmpty)
                        const Text(
                          'No paid registrations found for this competition.',
                          style: TextStyle(fontSize: 13),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: paidRegistrations.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, index) {
                              final row = paidRegistrations[index];
                              final name =
                                  row['participantName']?.toString() ?? '—';
                              final regNo =
                                  row['registrationNo']?.toString() ?? '';
                              final amount = row['amount'];
                              final teacherCell =
                                  row['yogaTeacherCell']?.toString() ?? '';
                              final amountLabel = amount == null
                                  ? ''
                                  : ' • ₹${amount.toString()}';
                              return ListTile(
                                dense: true,
                                title: Text(name),
                                subtitle: Text(
                                  [
                                    if (regNo.isNotEmpty) 'Reg: $regNo',
                                    if (teacherCell.isNotEmpty)
                                      'Teacher cell: $teacherCell',
                                  ].join(' • '),
                                ),
                                trailing: Text(
                                  amountLabel,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  isLoading.value = true;
                  try {
                    final result = await _repository.deleteCompetition(
                      competitionId,
                      deletionReasonType: selectedReason,
                      deletionReasonNote: showReasonField
                          ? reasonController.text
                          : null,
                    );
                    if (result.success) {
                      await loadCompetitions();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result.message ??
                                  'Competition deleted successfully',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result.message ?? 'Failed to delete competition',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    isLoading.value = false;
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          );
        },
      ),
    );

    reasonController.dispose();
  }

  // Get filtered competitions (now handled by API, but kept for backward compatibility)
  List<CompetitionModel> get filteredCompetitions {
    // API now handles filtering, so just return the competitions list
    return List<CompetitionModel>.from(competitions);
  }

  // Toggle view mode
  void toggleViewMode(bool isList) {
    if (isList && _isFirstCompetitionGateActive()) {
      return;
    }
    isListView.value = isList;
    if (isList) {
      // Reset edit mode when switching to list view
      isEditMode.value = false;
      competitionToEdit.value = null;
      loadCompetitions();
    } else {
      _refreshFormKeys();
      // Clear form when switching to create view (if not in edit mode)
      if (!isEditMode.value) {
        clearForm(refreshFormKeys: false);
      }
    }
  }

  // Clear form
  void clearForm({bool refreshFormKeys = true}) {
    if (refreshFormKeys) {
      _refreshFormKeys();
    }

    // Clear text controllers first
    competitionNameController.clear();
    descriptionController.clear();
    descriptionTouched.value = false;
    descriptionText.value = '';
    addressController.clear();
    addressTouched.value = false;
    addressText.value = '';

    // Clear reactive values
    eventStartDate.value = null;
    eventEndDate.value = null;
    eventStartTime.value = null;
    eventEndTime.value = null;
    displayAdFrom.value = null;
    publishResultNow.value = false;
    resultsPublishTime.value = null;
    spotRegistration.value = false;
    championshipStyle.value = ChampionshipStyle.separateCategory;
    competitionMode.value = 'OFFLINE';
    googleDriveFolderUrlController.clear();
    categoryConfigDrafts.clear();
    participantsPerStage.value = 0;
    minimumMarks.value = 0;
    maximumMarks.value = 0;
    skippedAsanaMarks.value = 0;
    bestSchoolAwardMinParticipantsController.clear();
    selectedPrizeIds.clear();
    selectedCategoryIds.clear();
    categoryAmounts.clear();
    categorySpotAmounts.clear();
    categoryIncludeFee.clear();
    selectedStageIds.clear();
    stageGroups.clear();
    clearGradeEntries();
    brochureFile.value = null;
    brochureFileLocal.value = null;
    brochureBytes.value = null;
    brochureFileName.value = '';
    brochureUrl.value = '';
    errorMessage.value = '';
    hasAttemptedSubmit.value = false;
    clearCompetitionDateFieldTouches();
    isEditMode.value = false;
    isViewMode.value = false;
    competitionToEdit.value = null;
    maintenancePaidAsanas.value = false;
    maintenancePaidChallenge.value = false;
  }

  void _applyPaidFormatsFromCompetition(CompetitionModel competition) {
    var paidAsanas = competition.maintenancePaidAsanas;
    var paidChallenge = competition.maintenancePaidChallenge;
    if (!paidAsanas && !paidChallenge) {
      final configs = competition.categoryConfigs;
      if (configs != null && configs.isNotEmpty) {
        paidAsanas = configs.any((c) => c.isAsanas);
        paidChallenge = configs.any((c) => c.isChallenge);
      }
    }
    maintenancePaidAsanas.value = paidAsanas;
    maintenancePaidChallenge.value = paidChallenge;
  }

  bool _isFirstCompetitionGateActive() {
    if (StorageService.getBool(AppConstants.firstCompetitionRequiredKey) ==
        true) {
      return true;
    }
    if (!Get.isRegistered<FirstCompetitionGateService>()) return false;
    return Get.find<FirstCompetitionGateService>().isGateActive();
  }
}
