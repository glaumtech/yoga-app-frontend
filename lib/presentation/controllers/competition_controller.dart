import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/championship_style.dart';
import '../../core/utils/dialog_helper.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/repositories/competition_repository.dart';
import '../../data/models/competition_model.dart';
import '../../data/models/competition_option_model.dart';
import '../../core/utils/subscription_catalog_filter.dart';
import '../../data/models/subscription_mode_model.dart';
import '../../data/models/subscription_package_model.dart';
import '../../data/repositories/payment_repository.dart';
import '../../services/razorpay_checkout_service.dart';

enum BrochureFileKind { image, pdf, unknown }

class CompetitionController extends GetxController {
  static const int brochureMaxImageBytes = 10 * 1024 * 1024;
  static const int brochureMaxPdfBytes = 25 * 1024 * 1024;
  static const String brochureUploadNotes =
      'Accepted: JPG, PNG, or PDF\n'
      '• Images: max 10 MB\n'
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

  final RxSet<String> touchedCompetitionDateFields = <String>{}.obs;

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

  bool _validateFormState() {
    final state = formKey.currentState;
    if (state == null) {
      _notifyError('Form is not ready. Please try again.');
      return false;
    }
    return state.validate();
  }

  final competitionNameController = TextEditingController();
  final descriptionController = TextEditingController();
  final addressController = TextEditingController();

  // Observable state
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<CompetitionModel> competitions = <CompetitionModel>[].obs;

  /// Public list for home screen (from GET /competition/public)
  final RxList<HomeCompetitionModel> homeCompetitions =
      <HomeCompetitionModel>[].obs;
  final RxBool isLoadingHomeCompetitions = false.obs;
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
  final RxBool spotRegistration = false.obs;
  final Rx<ChampionshipStyle?> championshipStyle = Rx<ChampionshipStyle?>(null);
  final RxInt participantsPerStage = RxInt(0);
  final RxInt minimumMarks = RxInt(0);
  final RxInt maximumMarks = RxInt(0);
  final TextEditingController bestSchoolAwardMinParticipantsController =
      TextEditingController();
  // Track selected IDs (for API submission)
  final RxList<int> selectedPrizeIds = <int>[].obs;
  final RxList<int> selectedCategoryIds = <int>[].obs;
  final RxMap<String, double> categoryAmounts =
      <String, double>{}.obs; // Key: category ID as string
  final RxList<int> selectedStageIds = <int>[].obs;
  final RxMap<String, List<int>> stageGroups = <String, List<int>>{}
      .obs; // Key: stage ID as string, Value: list of group IDs

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

  /// Load competitions for home screen (public API, no auth required for display)
  Future<void> loadCompetitionsForHome() async {
    try {
      isLoadingHomeCompetitions.value = true;
      final response = await _repository.getCompetitionsPublic();
      if (response.success && response.data != null) {
        homeCompetitions.value = response.data!;
      } else {
        homeCompetitions.clear();
      }
    } catch (e) {
      homeCompetitions.clear();
    } finally {
      isLoadingHomeCompetitions.value = false;
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
    if (hasGroupData) {
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
          return;
        }
      }

      final home = homeCompetitions.firstWhereOrNull(
        (c) => c.id?.toString() == id,
      );
      if (home != null) {
        _upsertCompetition(_competitionFromHome(home, existing));
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
      stageGroups: existing?.stageGroups,
      stageIds: existing?.stageIds,
      stages: existing?.stages,
      brochureUrl: home.brochureUrl ?? existing?.brochureUrl,
    );
  }

  void onInit() {
    super.onInit();
    // Initialize search controller text
    searchController.text = searchQuery.value;
    // Initialize search controller listener
    searchController.addListener(_onSearchChanged);
    // Load options from API
    loadOptions();
  }

  // Load all options (categories, prizes, stages, groups) from API
  Future<void> loadOptions() async {
    try {
      // Load all options in parallel
      final results = await Future.wait([
        _repository.getAllCategories(),
        _repository.getAllPrizes(),
        _repository.getAllStages(),
        _repository.getAllGroups(),
      ]);

      // Update categories
      if (results[0].success && results[0].data != null) {
        categoryOptions.value = results[0].data!;
      }

      // Update prizes
      if (results[1].success && results[1].data != null) {
        prizeOptions.value = results[1].data!;
      }

      // Update stages
      if (results[2].success && results[2].data != null) {
        stageOptions.value = results[2].data!;
      }

      // Update groups
      if (results[3].success && results[3].data != null) {
        groupOptions.value = results[3].data!;
      }
    } catch (e) {
      print('Error loading options: $e');
      // Fallback to empty lists if API fails
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
    competitionNameController.dispose();
    descriptionController.dispose();
    addressController.dispose();
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
      return 'Step 2 — Choose maintenance plan';
    }
    return 'Step 2 — Choose a plan';
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

      int fileSize = picked.size;
      if (kIsWeb) {
        if (picked.bytes == null || picked.bytes!.isEmpty) {
          _notifyError('Unable to read brochure file');
          return;
        }
        fileSize = picked.bytes!.length;
      } else if (picked.path != null) {
        fileSize = await File(picked.path!).length();
      }

      final isPdf = lowerName.endsWith('.pdf');
      final maxSize = isPdf ? brochureMaxPdfBytes : brochureMaxImageBytes;
      if (fileSize > maxSize) {
        _notifyError(
          isPdf
              ? 'PDF brochure must be 25 MB or smaller'
              : 'Image brochure must be 10 MB or smaller',
        );
        return;
      }

      brochureFileName.value = fileName;
      if (kIsWeb) {
        brochureBytes.value = picked.bytes;
        brochureFile.value = null;
        brochureFileLocal.value = null;
        brochureUrl.value = 'web_file';
      } else if (picked.path != null) {
        final path = picked.path!;
        brochureFile.value = XFile(path, name: fileName);
        brochureFileLocal.value = File(path);
        brochureBytes.value = null;
        brochureUrl.value = path;
      } else {
        _notifyError('Unable to access brochure file');
        return;
      }

      errorMessage.value = '';
    } catch (e) {
      _notifyError('Error picking brochure: ${e.toString()}');
    }
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
      return categoryOptions.firstWhere((opt) => opt.name == name).id;
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
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _repository.createPrize(
        name: prizeName,
        description: description,
      );

      if (response.success && response.data != null) {
        // Reload only prizes to include the new one
        await reloadPrizeOptions();
        // Force UI update of options list
        prizeOptions.refresh();

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
      isLoading.value = false;
    }
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
    final style = championshipStyle.value;
    if (style == null) {
      _notifyError(
        'Please select how the Champions category will be determined',
      );
      return false;
    }

    final categoryError = validateCategoriesForChampionshipStyle();
    if (categoryError != null) {
      _notifyError(categoryError);
      return false;
    }

    return DialogHelper.confirm(
      title: 'Confirm Champions setup',
      message: style.confirmationMessage,
    );
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
    } else {
      selectedCategoryIds.add(categoryId);
      categoryAmounts[categoryIdStr] = 0.0;
    }
  }

  // Add custom category (by name for UI, stores ID internally)
  Future<bool> addCustomCategory(
    String categoryName, {
    String? description,
  }) async {
    if (categoryName.isEmpty) return false;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _repository.createCategory(
        name: categoryName,
        description: description,
      );

      if (response.success && response.data != null) {
        // Reload only categories to include the new one
        await reloadCategoryOptions();
        // Force UI update of options list
        categoryOptions.refresh();

        Get.snackbar(
          'Success',
          'Category "$categoryName" created successfully',
        );
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to create category';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error creating category: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update category amount (by name for UI, stores with ID as key)
  void updateCategoryAmount(String categoryName, double amount) {
    final categoryId = getCategoryIdByName(categoryName);
    if (categoryId != null) {
      categoryAmounts[categoryId.toString()] = amount;
    }
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
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _repository.createStage(
        name: stageName,
        description: description,
      );

      if (response.success && response.data != null) {
        // Reload only stages to include the new one
        await reloadStageOptions();
        // Force UI update of options list
        stageOptions.refresh();

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
      isLoading.value = false;
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
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _repository.createGroup(
        name: groupName,
        description: description,
      );

      if (response.success && response.data != null) {
        // Reload only groups to include the new one
        await reloadGroupOptions();
        // Force UI update of options list
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
      isLoading.value = false;
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
        validateDisplayAdFrom(displayAdFrom.value, requireWhenEmpty: forSubmit);
  }

  void alertCompetitionDateValidationIssue() {
    final message = validateCompetitionDates();
    if (message == null) return;
    final hasAnyDate =
        eventStartDate.value != null ||
        eventEndDate.value != null ||
        eventStartTime.value != null ||
        eventEndTime.value != null ||
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
    try {
      hasAttemptedSubmit.value = true;
      notifyCompetitionDatesChanged();
      if (!_validateFormState()) {
        return false;
      }

      final dateError = validateCompetitionDates(forSubmit: true);
      if (dateError != null) {
        _notifyError(dateError);
        return false;
      }

      if (participantsPerStage.value <= 0) {
        _notifyError('Please select participants per stage');
        return false;
      }

      if (selectedCategoryIds.isEmpty) {
        _notifyError('Please select at least one category');
        return false;
      }

      final categoryStyleError = validateCategoriesForChampionshipStyle();
      if (categoryStyleError != null) {
        _notifyError(categoryStyleError);
        return false;
      }

      if (!await confirmChampionshipStyleBeforeSave()) {
        return false;
      }

      if (selectedStageIds.isEmpty) {
        _notifyError('Please select at least one stage');
        return false;
      }

      if (selectedPrizeIds.isEmpty) {
        _notifyError('Please select at least one prize');
        return false;
      }

      // Validate brochure upload
      if (!validateBrochure()) {
        _notifyError(errorMessage.value);
        return false;
      }

      isLoading.value = true;
      errorMessage.value = '';

      final competition = CompetitionModel(
        competitionName: competitionNameController.text.trim(),
        description: descriptionController.text.trim(),
        address: addressController.text.trim(),
        eventStartDate: eventStartDate.value!,
        eventStartTime: CompetitionModel.formatTimeOfDay(eventStartTime.value),
        eventEndDate: eventEndDate.value!,
        eventEndTime: CompetitionModel.formatTimeOfDay(eventEndTime.value),
        publishResultNow: publishResultNow.value,
        displayAdFrom: displayAdFrom.value,
        spotRegistration: spotRegistration.value,
        participantsPerStage: participantsPerStage.value > 0
            ? participantsPerStage.value
            : null,
        minimumMarks: minimumMarks.value > 0 ? minimumMarks.value : null,
        maximumMarks: maximumMarks.value > 0 ? maximumMarks.value : null,
        prizeIds: selectedPrizeIds.where((id) => id > 0).toList(),
        categoryIds: selectedCategoryIds.where((id) => id > 0).toList(),
        categoryAmounts: Map<String, double>.from(categoryAmounts),
        stageIds: selectedStageIds.where((id) => id > 0).toList(),
        stageGroups: Map<String, List<int>>.from(stageGroups),
        championshipStyle: championshipStyle.value?.apiValue,
        bestSchoolAwardMinParticipants: _parsedBestSchoolAwardMinParticipants(),
      );

      final response = await _repository.createCompetition(
        competition: competition,
        brochureFile: brochureFile.value,
        brochureFileLocal: brochureFileLocal.value,
        brochureBytes: brochureBytes.value,
        brochureFilename: brochureFileName.value.isNotEmpty
            ? brochureFileName.value
            : null,
      );

      if (response.success && response.data != null) {
        lastSavedCompetitionForQr.value = response.data;
        await loadCompetitions(resetPage: true);
        clearForm();
        _notifySuccess('Competition created successfully');
        toggleViewMode(true);
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
        return false;
      }

      if (participantsPerStage.value <= 0) {
        _notifyError('Please select participants per stage');
        return false;
      }

      if (selectedCategoryIds.isEmpty) {
        _notifyError('Please select at least one category');
        return false;
      }

      final categoryStyleError = validateCategoriesForChampionshipStyle();
      if (categoryStyleError != null) {
        _notifyError(categoryStyleError);
        return false;
      }

      if (!await confirmChampionshipStyleBeforeSave()) {
        return false;
      }

      if (selectedStageIds.isEmpty) {
        _notifyError('Please select at least one stage');
        return false;
      }

      if (selectedPrizeIds.isEmpty) {
        _notifyError('Please select at least one prize');
        return false;
      }

      // Brochure validation - optional for update (only if new file is selected)
      final hasNewBrochure =
          brochureFile.value != null ||
          brochureFileLocal.value != null ||
          brochureBytes.value != null;

      isLoading.value = true;
      errorMessage.value = '';

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
        displayAdFrom: displayAdFrom.value,
        spotRegistration: spotRegistration.value,
        participantsPerStage: participantsPerStage.value > 0
            ? participantsPerStage.value
            : null,
        minimumMarks: minimumMarks.value > 0 ? minimumMarks.value : null,
        maximumMarks: maximumMarks.value > 0 ? maximumMarks.value : null,
        prizeIds: selectedPrizeIds.where((id) => id > 0).toList(),
        categoryIds: selectedCategoryIds.where((id) => id > 0).toList(),
        categoryAmounts: Map<String, double>.from(categoryAmounts),
        stageIds: selectedStageIds.where((id) => id > 0).toList(),
        stageGroups: Map<String, List<int>>.from(stageGroups),
        championshipStyle: championshipStyle.value?.apiValue,
        bestSchoolAwardMinParticipants: _parsedBestSchoolAwardMinParticipants(),
      );

      final response = await _repository.updateCompetition(
        competition: competition,
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
    // Ensure options are loaded before converting IDs to names
    if (stageOptions.isEmpty || groupOptions.isEmpty) {
      print('loadCompetitionForEdit: Options not loaded yet, loading now...');
      await loadOptions();
    }

    _loadCompetitionData(competition, isView: isView);
  }

  void _loadCompetitionData(
    CompetitionModel competition, {
    bool isView = false,
  }) {
    isEditMode.value = !isView; // true for edit, false for view
    isViewMode.value = isView; // true for view-only
    competitionToEdit.value = competition;

    // Load data into form fields
    competitionNameController.text = competition.competitionName;
    descriptionController.text = competition.description;
    addressController.text = competition.address;
    eventStartDate.value = competition.eventStartDate;
    eventEndDate.value = competition.eventEndDate;
    eventStartTime.value = CompetitionModel.parseTime(
      competition.eventStartTime,
    );
    eventEndTime.value = CompetitionModel.parseTime(competition.eventEndTime);
    displayAdFrom.value = competition.displayAdFrom;
    publishResultNow.value = competition.resolvedPublishResultNow;
    spotRegistration.value = competition.resolvedSpotRegistration;
    championshipStyle.value =
        ChampionshipStyle.fromApiValue(competition.championshipStyle) ??
        ChampionshipStyle.separateCategory;
    participantsPerStage.value = competition.participantsPerStage ?? 0;
    minimumMarks.value = competition.minimumMarks ?? 0;
    maximumMarks.value = competition.maximumMarks ?? 0;
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
    } else {
      selectedCategoryIds.clear();
      categoryAmounts.clear();
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
  void deleteCompetition(BuildContext context, CompetitionModel competition) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Competition'),
        content: Text(
          'Are you sure you want to delete "${competition.competitionName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final id = competition.id?.trim();
              if (id == null || id.isEmpty) {
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

              isLoading.value = true;
              try {
                final result = await _repository.deleteCompetition(id);
                if (result.success) {
                  await loadCompetitions();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.message ?? 'Competition deleted successfully',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.message ?? 'Failed to delete competition',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } finally {
                isLoading.value = false;
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Get filtered competitions (now handled by API, but kept for backward compatibility)
  List<CompetitionModel> get filteredCompetitions {
    // API now handles filtering, so just return the competitions list
    return List<CompetitionModel>.from(competitions);
  }

  // Toggle view mode
  void toggleViewMode(bool isList) {
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
    addressController.clear();

    // Clear reactive values
    eventStartDate.value = null;
    eventEndDate.value = null;
    eventStartTime.value = null;
    eventEndTime.value = null;
    displayAdFrom.value = null;
    publishResultNow.value = false;
    spotRegistration.value = false;
    championshipStyle.value = null;
    participantsPerStage.value = 0;
    minimumMarks.value = 0;
    maximumMarks.value = 0;
    bestSchoolAwardMinParticipantsController.clear();
    selectedPrizeIds.clear();
    selectedCategoryIds.clear();
    categoryAmounts.clear();
    selectedStageIds.clear();
    stageGroups.clear();
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
  }
}
