import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../data/repositories/participant_repository.dart';
import '../../data/repositories/school_repository.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/models/participant_model.dart';
import '../../data/models/api_response.dart';
import '../../data/models/score_response_model.dart';
import '../../data/models/school_model.dart';
import '../../data/models/state_model.dart';
import '../../data/models/institution_type_model.dart';
import '../../data/models/competition_model.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../core/utils/storage_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/bulk_registration_row.dart';
import 'competition_controller.dart';

// Web-specific imports
import 'dart:html' as html show AnchorElement, Blob, Url;

class ParticipantController extends GetxController {
  final ParticipantRepository _participantRepository = ParticipantRepository();
  final SchoolRepository _schoolRepository = SchoolRepository();
  final LocationRepository _locationRepository = LocationRepository();
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxList<ParticipantModel> participants = <ParticipantModel>[].obs;
  final RxList<ParticipantModel> myRegistrations =
      <ParticipantModel>[].obs; // User's registrations
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<ParticipantModel?> selectedParticipant = Rx<ParticipantModel?>(null);
  final RxBool isListView = false.obs; // Toggle between create and list view
  final RxBool isBulkMode =
      false.obs; // Toggle between single and bulk registration
  final RxBool isViewMode =
      false.obs; // Toggle for view-only mode (non-editable)
  final RxString searchQuery =
      ''.obs; // Search query for filtering participants

  // Filter state
  final Rx<ParticipantFilterRequest> currentFilter =
      Rx<ParticipantFilterRequest>(ParticipantFilterRequest());
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 0.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasMorePages = false.obs;

  // Sorting state
  final RxString sortBy =
      'createdAt'.obs; // createdAt, participantName, age, category, groupName
  final RxString sortOrder = 'desc'.obs; // asc, desc

  // Form state
  final TextEditingController nameController = TextEditingController();
  final TextEditingController schoolNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController yogaMasterNameController =
      TextEditingController();
  final TextEditingController yogaMasterContactController =
      TextEditingController();

  final Rx<DateTime?> dateOfBirth = Rx<DateTime?>(null);
  final RxString gender = ''.obs;
  final RxBool isSpotRegistration = false.obs;
  final RxBool optForECertificate = false.obs;
  final RxList<String> selectedCategories = <String>[].obs;
  final RxString selectedStage = ''.obs; // Selected stage name
  final RxString standard = ''.obs;
  final RxInt formResetTrigger =
      0.obs; // Trigger to force widget rebuilds on form reset
  final Rx<File?> photoFile = Rx<File?>(null);
  final Rx<XFile?> selectedImage = Rx<XFile?>(null);
  final Rx<File?> bonafideFile = Rx<File?>(null);
  final Rx<XFile?> bonafideImage = Rx<XFile?>(null);
  final Rx<Uint8List?> bonafideBytes = Rx<Uint8List?>(null);
  final RxString bonafideFileName = ''.obs;
  final Rx<ParticipantModel?> participantToEdit = Rx<ParticipantModel?>(null);
  final RxString existingPhotoUrl = ''.obs;
  final RxString existingCertificateUrl = ''.obs;
  final RxBool isLoadingParticipant = false.obs;
  final RxString selectedEventId = ''.obs; // Selected competition/event ID

  // Institution search state
  final RxList<SchoolModel> institutionSuggestions = <SchoolModel>[].obs;
  final RxBool isLoadingInstitutions = false.obs;
  final RxnString selectedInstitutionId = RxnString();
  final Rxn<SchoolModel> selectedInstitution = Rxn<SchoolModel>();

  /// Optional filters for institution autocomplete (registration form).
  final RxInt institutionSearchFilterStateId = 0.obs;
  final RxInt institutionSearchFilterTypeId = 0.obs;
  final RxList<StateModel> institutionSearchStates = <StateModel>[].obs;
  final RxList<String> institutionSearchDistricts = <String>[].obs;
  final RxList<InstitutionTypeModel> institutionSearchTypes =
      <InstitutionTypeModel>[].obs;
  final RxBool isLoadingInstitutionSearchLocations = false.obs;
  final RxBool isLoadingInstitutionSearchDistricts = false.obs;
  Future<void>? _institutionSearchFilterDataFuture;

  /// Owned by this controller; passed to [StateSearchField] / [DistrictSearchField] (stateless).
  final TextEditingController institutionFilterStateTextController =
      TextEditingController();
  final FocusNode institutionFilterStateFocusNode = FocusNode();
  final TextEditingController institutionFilterDistrictTextController =
      TextEditingController();
  final FocusNode institutionFilterDistrictFocusNode = FocusNode();

  // Store institutionId from API response for edit mode
  final RxnString participantInstitutionId = RxnString();

  // Bulk registration state
  final TextEditingController bulkYogaTeacherNameController =
      TextEditingController();
  final TextEditingController bulkYogaTeacherCellController =
      TextEditingController();
  final TextEditingController bulkInstitutionNameController =
      TextEditingController();
  final RxString bulkCategory = ''.obs;
  final RxList<BulkRegistrationRow> bulkRegistrationRows =
      <BulkRegistrationRow>[].obs;

  // Registration success state for the public competition registration flow.
  // Used to hide the form after successful save and show details instead.
  final RxBool registrationSaved = false.obs;
  final Rxn<ParticipantModel> lastRegisteredParticipant =
      Rxn<ParticipantModel>();

  void clearRegistrationConfirmation() {
    registrationSaved.value = false;
    lastRegisteredParticipant.value = null;
  }

  /// Get participant image URL using the participantImage API endpoint
  String? getParticipantImageUrl(String? participantId) {
    if (participantId == null || participantId.isEmpty) {
      return null;
    }
    // Use the participantImage API endpoint from app_constants
    return '${BaseUrl.baseUrl}${EndPoints.participantImage(participantId)}';
  }

  /// Get participant registration photo URL using the new API endpoint
  String? getParticipantRegistrationPhotoUrl(
    String? registrationId, {
    String? cacheBuster,
  }) {
    if (registrationId == null || registrationId.isEmpty) {
      return null;
    }
    // Use the participant registration photo API endpoint
    final baseUrl =
        '${BaseUrl.baseUrl}${EndPoints.participantRegistrationPhoto(registrationId)}';
    return cacheBuster != null ? '$baseUrl?t=$cacheBuster' : baseUrl;
  }

  /// Get participant registration bonafied certificate URL using the new API endpoint
  String? getParticipantRegistrationCertificateUrl(
    String? registrationId, {
    String? cacheBuster,
  }) {
    if (registrationId == null || registrationId.isEmpty) {
      return null;
    }
    // Use the participant registration bonafied certificate API endpoint
    final baseUrl =
        '${BaseUrl.baseUrl}${EndPoints.participantRegistrationBonafiedCertificate(registrationId)}';
    return cacheBuster != null ? '$baseUrl?t=$cacheBuster' : baseUrl;
  }

  Future<void> ensureInstitutionSearchFiltersLoaded() {
    _institutionSearchFilterDataFuture ??= _loadInstitutionSearchFilterData();
    return _institutionSearchFilterDataFuture!;
  }

  /// Force reload of institution search filter data (types/states/districts source cities).
  /// Useful when institution types/categories are updated in Settings.
  Future<void> refreshInstitutionSearchFilters() async {
    _institutionSearchFilterDataFuture = null;
    await ensureInstitutionSearchFiltersLoaded();
  }

  Future<void> _loadInstitutionSearchFilterData() async {
    isLoadingInstitutionSearchLocations.value = true;
    try {
      final statesRes = await _locationRepository.getAllStates();
      final typesRes = await _schoolRepository.getAllInstitutionTypes();
      if (statesRes.success && statesRes.data != null) {
        institutionSearchStates.assignAll(statesRes.data!);
        institutionSearchStates.sort(
          (a, b) => a.stateName.compareTo(b.stateName),
        );
      }
      if (typesRes.success && typesRes.data != null) {
        institutionSearchTypes.assignAll(typesRes.data!);
        // Keep API response order (backend sorts by displayOrder).
      }
    } finally {
      isLoadingInstitutionSearchLocations.value = false;
    }
  }

  Future<void> setInstitutionSearchFilterState(int stateId) async {
    institutionSearchFilterStateId.value = stateId;
    institutionSearchDistricts.clear();
    institutionFilterDistrictTextController.clear();

    if (stateId <= 0) {
      institutionFilterStateTextController.clear();
      return;
    }

    final st = institutionSearchStates.firstWhereOrNull((s) => s.id == stateId);
    if (st != null) {
      institutionFilterStateTextController.text = st.stateName;
    }

    isLoadingInstitutionSearchDistricts.value = true;
    try {
      final res = await _locationRepository.getDistrictsByStateId(stateId);
      if (res.success && res.data != null) {
        institutionSearchDistricts.assignAll(res.data!);
      } else {
        institutionSearchDistricts.clear();
      }
    } finally {
      isLoadingInstitutionSearchDistricts.value = false;
    }
  }

  /// Exact district string for API, or null if field empty / no exact match to known districts.
  String? _resolvedInstitutionSearchDistrict() {
    final typed = institutionFilterDistrictTextController.text.trim();
    if (typed.isEmpty) return null;
    return institutionSearchDistricts.firstWhereOrNull(
      (d) => d.toLowerCase() == typed.toLowerCase(),
    );
  }

  void _resetInstitutionSearchFilters() {
    institutionSearchFilterStateId.value = 0;
    institutionSearchFilterTypeId.value = 0;
    institutionSearchDistricts.clear();
    institutionFilterStateTextController.clear();
    institutionFilterDistrictTextController.clear();
  }

  void setInstitutionSearchFilterType(int typeId) {
    institutionSearchFilterTypeId.value = typeId;
  }

  // Search institutions
  Future<void> searchInstitutions(
    String query, {
    bool useInstitutionSearchFilters = true,
  }) async {
    if (query.trim().isEmpty) {
      institutionSuggestions.clear();
      return;
    }

    if (query.trim().length < 2) {
      // Don't search if query is too short
      return;
    }

    try {
      isLoadingInstitutions.value = true;
      final String? districtFilter = useInstitutionSearchFilters
          ? _resolvedInstitutionSearchDistrict()
          : null;
      final response = await _schoolRepository.searchInstitutions(
        query: query.trim(),
        stateId:
            useInstitutionSearchFilters &&
                institutionSearchFilterStateId.value > 0
            ? institutionSearchFilterStateId.value
            : null,
        cityId: null,
        cityName: null,
        district: districtFilter,
        institutionTypeId:
            useInstitutionSearchFilters &&
                institutionSearchFilterTypeId.value > 0
            ? institutionSearchFilterTypeId.value
            : null,
      );

      if (response.success && response.data != null) {
        institutionSuggestions.value = response.data!.institutions;
      } else {
        institutionSuggestions.clear();
      }
    } catch (e) {
      print('Error searching institutions: $e');
      institutionSuggestions.clear();
    } finally {
      isLoadingInstitutions.value = false;
    }
  }

  static bool isPrivateInstitution(SchoolModel? school) {
    if (school == null) return false;
    final typeKey = school.institutionType.trim().toUpperCase();
    if (typeKey.contains('PRIVATE')) return true;
    final display =
        (school.institutionTypeDisplayName ?? '').trim().toLowerCase();
    return display.contains('private');
  }

  /// Bonafide upload applies only to Govt / Govt Aided **School** institutions.
  static bool isGovtAidedSchoolInstitution(SchoolModel? school) {
    if (school == null) return false;

    final typeKey = school.institutionType.trim().toUpperCase();
    if (typeKey == 'GOVT_SCHOOL' || typeKey == 'GOVT_AIDED_SCHOOL') {
      return true;
    }
    if (typeKey.contains('GOVT') &&
        typeKey.contains('SCHOOL') &&
        !typeKey.contains('COLLEGE')) {
      return true;
    }

    final display =
        (school.institutionTypeDisplayName ?? '').trim().toLowerCase();
    if (display.contains('govt') &&
        display.contains('school') &&
        !display.contains('college')) {
      return true;
    }

    return false;
  }

  bool get isBonafideCertificateApplicable {
    return isGovtAidedSchoolInstitution(selectedInstitution.value);
  }

  CompetitionModel? selectedCompetition() {
    if (!Get.isRegistered<CompetitionController>()) return null;
    if (selectedEventId.value.isEmpty) return null;
    return Get.find<CompetitionController>().competitions.firstWhereOrNull(
      (c) => c.id == selectedEventId.value,
    );
  }

  /// Spot registration is only allowed while the event is in progress.
  bool get isSpotRegistrationOptionVisible {
    final competition = selectedCompetition();
    return competition != null && competition.isEventOngoing;
  }

  void applySpotRegistrationRulesForSelectedEvent() {
    if (!isSpotRegistrationOptionVisible) {
      isSpotRegistration.value = false;
    }
  }

  void _clearBonafideCertificateFiles() {
    bonafideFile.value = null;
    bonafideImage.value = null;
    bonafideBytes.value = null;
    bonafideFileName.value = '';
    existingCertificateUrl.value = '';
  }

  bool get hasBonafideCertificateSelected =>
      bonafideFile.value != null ||
      bonafideImage.value != null ||
      bonafideBytes.value != null ||
      existingCertificateUrl.value.trim().isNotEmpty;

  Future<bool> pickBonafideCertificate() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file == null) return false;

      bonafideFileName.value = file.name;
      existingCertificateUrl.value = '';

      if (kIsWeb) {
        bonafideBytes.value = await file.readAsBytes();
        bonafideImage.value = file;
        bonafideFile.value = null;
      } else {
        bonafideImage.value = file;
        bonafideFile.value = File(file.path);
        bonafideBytes.value = null;
      }
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to pick certificate: ${e.toString()}';
      return false;
    }
  }

  void _applyBonafideRulesForSelectedInstitution() {
    if (!isBonafideCertificateApplicable) {
      _clearBonafideCertificateFiles();
    }
  }

  Future<void> _syncSelectedInstitutionFromId() async {
    if (selectedInstitution.value != null) return;
    final id = selectedInstitutionId.value;
    if (id == null || id.isEmpty) return;

    final fromSuggestions = institutionSuggestions.firstWhereOrNull(
      (institution) => institution.id == id,
    );
    if (fromSuggestions != null) {
      selectedInstitution.value = fromSuggestions;
      _applyBonafideRulesForSelectedInstitution();
      return;
    }

    try {
      final response = await _schoolRepository.getInstitutionById(id);
      if (response.success && response.data != null) {
        selectedInstitution.value = response.data;
        _applyBonafideRulesForSelectedInstitution();
      }
    } catch (e) {
      print('Error loading institution details: $e');
    }
  }

  Future<void> _loadSelectedInstitutionForEdit() async {
    await _syncSelectedInstitutionFromId();
  }

  Future<bool> validateBonafideBeforeSave() async {
    await _syncSelectedInstitutionFromId();

    final school = selectedInstitution.value;
    if (school == null) {
      errorMessage.value = 'Please select an institution from the list';
      return false;
    }

    if (!isGovtAidedSchoolInstitution(school)) {
      _clearBonafideCertificateFiles();
      return true;
    }

    final hasCertificate = hasBonafideCertificateSelected;
    if (!hasCertificate) {
      errorMessage.value =
          'Bonafied certificate is required for Govt / Govt Aided School';
      return false;
    }

    return true;
  }

  // Select institution
  void selectInstitution(SchoolModel institution) {
    schoolNameController.text = institution.institutionName;
    selectedInstitutionId.value = institution.id;
    selectedInstitution.value = institution;
    institutionSuggestions.clear();
    _applyBonafideRulesForSelectedInstitution();
  }

  @override
  void onInit() {
    super.onInit();
    // Participants are now loaded by event ID only
    // Initialize bulk registration with 5 rows
    resetBulkRegistrationForm();
  }

  // Bulk registration methods
  void addBulkRegistrationRow() {
    bulkRegistrationRows.add(BulkRegistrationRow());
  }

  void removeBulkRegistrationRow(int index) {
    if (index >= 0 && index < bulkRegistrationRows.length) {
      bulkRegistrationRows[index].dispose();
      bulkRegistrationRows.removeAt(index);
    }
  }

  void resetBulkRegistrationForm() {
    bulkYogaTeacherNameController.clear();
    bulkYogaTeacherCellController.clear();
    bulkInstitutionNameController.clear();
    bulkCategory.value = '';
    for (final row in bulkRegistrationRows) {
      row.dispose();
    }
    bulkRegistrationRows.clear();
    // Initialize with 5 rows by default
    for (int i = 0; i < 5; i++) {
      addBulkRegistrationRow();
    }
  }

  Future<void> submitBulkRegistration() async {
    if (selectedEventId.value.isEmpty) {
      errorMessage.value = 'Please select a competition';
      return;
    }

    if (bulkYogaTeacherNameController.text.trim().isEmpty) {
      errorMessage.value = 'Please enter yoga teacher name';
      return;
    }

    if (bulkYogaTeacherCellController.text.trim().isEmpty) {
      errorMessage.value = 'Please enter yoga teacher cell number';
      return;
    }

    if (bulkInstitutionNameController.text.trim().isEmpty) {
      errorMessage.value = 'Please enter institution name';
      return;
    }

    if (bulkCategory.value.isEmpty) {
      errorMessage.value = 'Please select a category';
      return;
    }

    // Validate at least one row has data
    final validRows = bulkRegistrationRows.where((row) => row.isValid).toList();
    if (validRows.isEmpty) {
      errorMessage.value = 'Please enter at least one participant';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      int successCount = 0;
      int failureCount = 0;

      for (final row in validRows) {
        final age = app_date_utils.AppDateUtils.calculateAge(
          row.dateOfBirth.value!,
        );

        final participant = ParticipantModel(
          participantName: row.nameController.text.trim().toUpperCase(),
          dateOfBirth: row.dateOfBirth.value!,
          age: age,
          gender: row.gender.value,
          category: bulkCategory.value,
          standard: row.group.value,
          schoolName: bulkInstitutionNameController.text.trim(),
          address: '', // Not required in bulk registration
          yogaMasterName: bulkYogaTeacherNameController.text.trim(),
          yogaMasterContact: bulkYogaTeacherCellController.text.trim(),
        );

        final success = await createParticipant(
          participant: participant,
          photoFile: row.photoFile.value,
          photoXFile: row.photoXFile.value,
          eventId: selectedEventId.value,
        );

        if (success) {
          successCount++;
        } else {
          failureCount++;
        }
      }

      isLoading.value = false;

      if (successCount > 0) {
        Get.snackbar(
          'Success',
          '$successCount participant(s) registered successfully${failureCount > 0 ? '. $failureCount failed.' : ''}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        resetBulkRegistrationForm();
        await loadParticipantsByEventId(selectedEventId.value, resetPage: true);
      } else {
        errorMessage.value = 'Failed to register participants';
        Get.snackbar(
          'Error',
          errorMessage.value,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Error registering participants: ${e.toString()}';
      Get.snackbar(
        'Error',
        errorMessage.value,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    schoolNameController.dispose();
    addressController.dispose();
    yogaMasterNameController.dispose();
    yogaMasterContactController.dispose();
    bulkYogaTeacherNameController.dispose();
    bulkYogaTeacherCellController.dispose();
    bulkInstitutionNameController.dispose();
    institutionFilterStateTextController.dispose();
    institutionFilterStateFocusNode.dispose();
    institutionFilterDistrictTextController.dispose();
    institutionFilterDistrictFocusNode.dispose();
    for (final row in bulkRegistrationRows) {
      row.dispose();
    }
    bulkRegistrationRows.clear();
    super.onClose();
  }

  /// Load user's registrations for a specific event
  Future<void> loadMyRegistrations(String eventId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final filter = ParticipantFilterRequest(page: 0, size: 50);
      final response = await _participantRepository.getParticipantsByEventId(
        eventId: eventId,
        filter: filter,
      );

      if (response.success && response.data != null) {
        myRegistrations.value = response.data!.participants;
      } else {
        errorMessage.value = response.message ?? 'Failed to load registrations';
      }

      isLoading.value = false;
    } catch (e) {
      errorMessage.value = 'Failed to load registrations: ${e.toString()}';
      isLoading.value = false;
    }
  }

  Future<void> loadParticipantsByEventId(
    String eventId, {
    ParticipantFilterRequest? filter,
    bool resetPage = false,
    bool replaceItems = false,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Reset page if needed
      if (resetPage) {
        currentPage.value = 1;
      }

      // Convert 1-indexed currentPage to 0-indexed API page
      final apiPage = currentPage.value > 0 ? currentPage.value - 1 : 0;
      final competitionId = int.tryParse(eventId);

      if (competitionId == null) {
        errorMessage.value = 'Invalid competition ID';
        isLoading.value = false;
        return;
      }

      // Use search query if available
      final searchTerm = searchQuery.value.isNotEmpty
          ? searchQuery.value
          : null;

      final response = await _participantRepository
          .listParticipantRegistrations(
            search: searchTerm,
            competitionId: competitionId,
            page: apiPage,
            limit: 20,
            sortBy: sortBy.value,
            order: sortOrder.value,
          );

      if (response.success && response.data != null) {
        final data = response.data!;

        // The API response structure: { "data": { "registrations": [...], "pagination": {...} } }
        // But APIService already extracts the "data" field, so we get { "registrations": [...], "pagination": {...} }
        final registrations = data['registrations'] as List<dynamic>?;
        final pagination = data['pagination'] as Map<String, dynamic>?;

        if (registrations != null) {
          // Convert registration data to ParticipantModel
          final participantList = registrations.map((reg) {
            return _mapRegistrationToParticipant(reg as Map<String, dynamic>);
          }).toList();

          // When navigating with explicit pagination controls, we want to replace the list
          // with the selected page's items (not append like infinite scroll).
          final shouldReplace =
              resetPage || replaceItems || currentPage.value == 1;

          if (shouldReplace) {
            participants.value = participantList;
          } else {
            // Append for pagination
            participants.addAll(participantList);
          }
        } else {
          if (resetPage || currentPage.value == 1) {
            participants.clear();
          }
        }

        // Update pagination info
        if (pagination != null) {
          currentPage.value = (pagination['page'] as int? ?? 0) + 1;
          totalPages.value = pagination['totalPages'] as int? ?? 0;
          totalItems.value = pagination['total'] as int? ?? 0;
          hasMorePages.value = currentPage.value < totalPages.value;
        } else {
          // Fallback pagination if not provided
          if (registrations != null) {
            if (registrations.length < 20) {
              totalPages.value = currentPage.value;
            } else {
              totalPages.value = currentPage.value + 1;
            }
            totalItems.value = registrations.length;
          }
        }
      } else {
        errorMessage.value = response.message ?? 'Failed to load participants';
        if (resetPage || currentPage.value == 1) {
          participants.clear();
        }
      }

      isLoading.value = false;
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      isLoading.value = false;
    }
  }

  // Map registration response to ParticipantModel
  // Also stores institutionId for edit mode
  ParticipantModel _mapRegistrationToParticipant(Map<String, dynamic> reg) {
    // Store institutionId for edit mode (will be used when initializing form for edit)
    // Check multiple possible field names
    if (reg['institutionId'] != null) {
      participantInstitutionId.value = reg['institutionId']?.toString();
    } else if (reg['institution_id'] != null) {
      participantInstitutionId.value = reg['institution_id']?.toString();
    } else if (reg['institution'] != null && reg['institution'] is Map) {
      // If institution is an object, try to get the ID
      final institution = reg['institution'] as Map<String, dynamic>;
      if (institution['id'] != null) {
        participantInstitutionId.value = institution['id']?.toString();
      }
    }

    // Parse date of birth
    DateTime dob;
    if (reg['dateOfBirth'] != null) {
      try {
        dob = DateTime.parse(reg['dateOfBirth'] as String);
      } catch (e) {
        print('Error parsing dateOfBirth: $e');
        dob = DateTime.now(); // Fallback
      }
    } else {
      dob = DateTime.now(); // Fallback
    }

    // Parse createdAt
    DateTime createdAt;
    if (reg['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(reg['createdAt'] as String);
      } catch (e) {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }

    // Parse updatedAt
    DateTime? updatedAt;
    if (reg['updatedAt'] != null) {
      try {
        updatedAt = DateTime.parse(reg['updatedAt'] as String);
      } catch (e) {
        updatedAt = null;
      }
    }

    return ParticipantModel(
      id: reg['id']?.toString(),
      participantName: reg['participantName'] as String? ?? '',
      dateOfBirth: dob,
      age: reg['age'] as int? ?? 0,
      gender: _normalizeGender(
        reg['sex'] as String? ?? reg['gender'] as String?,
      ),
      category:
          reg['categoryName'] as String? ?? reg['category'] as String? ?? '',
      standard: reg['groupName'] as String? ?? reg['standard'] as String? ?? '',
      schoolName:
          reg['institutionName'] as String? ??
          reg['schoolName'] as String? ??
          '',
      address: reg['address'] as String? ?? '',
      yogaMasterName:
          reg['yogaTeacherName'] as String? ??
          reg['yogaMasterName'] as String? ??
          '',
      yogaMasterContact:
          reg['yogaTeacherCell'] as String? ??
          reg['yogaMasterContact'] as String? ??
          '',
      photoUrl: reg['photo'] as String?,
      participantCode:
          reg['participantCode'] as String? ??
          reg['participant_code'] as String?,
      registrationNo:
          reg['registrationNo'] as String? ??
          reg['registration_no'] as String? ??
          reg['registrationNumber'] as String? ??
          reg['registration_number'] as String?,
      status: reg['status'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: reg['createdBy']?.toString(),
      updatedBy: reg['updatedBy']?.toString(),
      eventId: reg['competitionId']?.toString(),
      isSpotRegistration:
          _parseRegBool(reg['isSpotRegistration']) ||
          _parseRegBool(reg['is_spot_registration']) ||
          _parseRegBool(reg['spotRegistration']),
      optForECertificate:
          _parseRegBool(reg['optForECertificate']) ||
          _parseRegBool(reg['opt_for_e_certificate']),
    );
  }

  /// Normalize API/UI gender variants into values used by the form radio group.
  /// The form expects exactly 'MALE' or 'FEMALE' (empty string means "not selected").
  String _normalizeGender(String? raw) {
    if (raw == null) return '';
    final v = raw.trim();
    if (v.isEmpty) return '';
    final upper = v.toUpperCase();

    // Common backend variants
    if (upper == 'MALE' || upper == 'M' || upper == 'BOY' || upper == 'B') {
      return 'MALE';
    }
    if (upper == 'FEMALE' || upper == 'F' || upper == 'GIRL' || upper == 'G') {
      return 'FEMALE';
    }

    // Handle title-case variants like "Male"/"Female"
    if (upper.startsWith('MALE')) return 'MALE';
    if (upper.startsWith('FEMALE')) return 'FEMALE';

    return '';
  }

  bool _parseRegBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  // Sorting methods
  void setSorting(String newSortBy, String newOrder) {
    sortBy.value = newSortBy;
    sortOrder.value = newOrder;
    final eventId = selectedEventId.value;
    if (eventId.isNotEmpty) {
      loadParticipantsByEventId(eventId, resetPage: true);
    }
  }

  // Pagination methods
  void nextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      final eventId = selectedEventId.value;
      if (eventId.isNotEmpty) {
        loadParticipantsByEventId(eventId, replaceItems: true);
      }
    }
  }

  void previousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      final eventId = selectedEventId.value;
      if (eventId.isNotEmpty) {
        loadParticipantsByEventId(eventId, replaceItems: true);
      }
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages.value) {
      currentPage.value = page;
      final eventId = selectedEventId.value;
      if (eventId.isNotEmpty) {
        loadParticipantsByEventId(eventId, replaceItems: true);
      }
    }
  }

  Future<void> loadNextPage(String eventId) async {
    if (hasMorePages.value && !isLoading.value) {
      currentPage.value++;
      await loadParticipantsByEventId(eventId, resetPage: false);
    }
  }

  void resetFilter() {
    currentFilter.value = ParticipantFilterRequest();
    currentPage.value = 1;
    totalPages.value = 1;
    totalItems.value = 0;
    hasMorePages.value = false;
    participants.clear();
  }

  Future<bool> createParticipant({
    required ParticipantModel participant,
    File? photoFile,
    XFile? photoXFile,
    required String eventId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _participantRepository.createParticipant(
        participant: participant,
        photoFile: photoFile,
        photoXFile: photoXFile,
        eventId: eventId,
      );

      if (response.success && response.data != null) {
        participants.add(response.data!);
        isLoading.value = false;
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to create participant';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> updateParticipant({
    required String id,
    required ParticipantModel participant,
    dynamic photoFile, // File on mobile, null on web
    XFile? photoXFile,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _participantRepository.updateParticipant(
        id: id,
        participant: participant,
        photoFile: photoFile,
        photoXFile: photoXFile,
      );

      if (response.success && response.data != null) {
        final index = participants.indexWhere((p) => p.id == id);
        if (index != -1) {
          participants[index] = response.data!;
        }
        isLoading.value = false;
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to update participant';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> deleteParticipant(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Use the new registration API for deletion
      final response = await _participantRepository
          .deleteParticipantRegistration(id);

      if (response.success) {
        participants.removeWhere((p) => p.id == id);
        isLoading.value = false;
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to delete participant';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> updateScores({
    required String id,
    required Map<String, double> juryScores,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _participantRepository.updateScores(
        id: id,
        juryScores: juryScores,
      );

      if (response.success && response.data != null) {
        final index = participants.indexWhere((p) => p.id == id);
        if (index != -1) {
          participants[index] = response.data!;
        }
        isLoading.value = false;
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to update scores';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      isLoading.value = false;
      return false;
    }
  }

  Future<ApiResponse<ScoreResponseModel>> getParticipantScoresByEventId(
    String eventId,
  ) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _participantRepository
          .getParticipantScoresByEventId(eventId);

      isLoading.value = false;
      return response;
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      isLoading.value = false;
      return ApiResponse(
        success: false,
        message: 'Error fetching scores: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<SingleParticipantScoreResponseModel>>
  getParticipantScoresByParticipantId(
    String eventId,
    String participantId,
  ) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _participantRepository
          .getParticipantScoresByParticipantId(eventId, participantId);

      isLoading.value = false;
      return response;
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      isLoading.value = false;
      return ApiResponse(
        success: false,
        message: 'Error fetching participant score: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> saveScores({
    required String eventId,
    required List<Map<String, dynamic>> scoreOfParticipants,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _participantRepository.saveScores(
        eventId: eventId,
        scoreOfParticipants: scoreOfParticipants,
      );

      isLoading.value = false;
      return response;
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      isLoading.value = false;
      return ApiResponse(
        success: false,
        message: 'Error saving scores: ${e.toString()}',
      );
    }
  }

  Future<bool> updateParticipantStatus(String id, String status) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _participantRepository.updateParticipantStatus(
        id: id,
        status: status,
      );

      if (response.success) {
        // Note: Participants reload should be handled by the calling screen with eventId
        Get.snackbar(
          'Success',
          'Participant status updated to ${status.toUpperCase()}',
        );
        isLoading.value = false;
        return true;
      } else {
        errorMessage.value =
            response.message ?? 'Failed to update participant status';
        Get.snackbar('Error', errorMessage.value);
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value =
          'Failed to update participant status: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
      isLoading.value = false;
      return false;
    }
  }

  void setSelectedParticipant(ParticipantModel? participant) {
    selectedParticipant.value = participant;
  }

  // Form management methods
  Future<void> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        selectedImage.value = image;
        photoFile.value = File(image.path);
      }
    } catch (e) {
      errorMessage.value = 'Failed to pick image: ${e.toString()}';
    }
  }

  Future<void> takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        selectedImage.value = image;
        photoFile.value = File(image.path);
      }
    } catch (e) {
      errorMessage.value = 'Failed to take photo: ${e.toString()}';
    }
  }

  Future<void> selectDateOfBirth(BuildContext context) async {
    // Use existing dateOfBirth if available, otherwise default to 10 years ago
    final DateTime initialDate =
        dateOfBirth.value ??
        DateTime.now().subtract(const Duration(days: 365 * 10));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );

    if (picked != null) {
      dateOfBirth.value = picked;
    }
  }

  void setGender(String? value) {
    gender.value = _normalizeGender(value);
  }

  void toggleCategory(String categoryValue) {
    if (selectedCategories.contains(categoryValue)) {
      selectedCategories.remove(categoryValue);
    } else {
      selectedCategories.add(categoryValue);
    }
  }

  bool isCategorySelected(String categoryValue) {
    return selectedCategories.contains(categoryValue);
  }

  void setStandard(String? value) {
    standard.value = value ?? '';
  }

  void toggleViewMode(bool showList) {
    isListView.value = showList;
  }

  void resetForm() {
    // Clear all reactive values first - this will trigger Obx rebuilds
    dateOfBirth.value = null;
    gender.value = '';
    optForECertificate.value = false;
    selectedCategories.clear();
    selectedStage.value = '';
    standard.value = '';
    photoFile.value = null;
    selectedImage.value = null;
    existingPhotoUrl.value = '';
    _clearBonafideCertificateFiles();
    selectedInstitutionId.value = null;
    selectedInstitution.value = null;
    participantInstitutionId.value = null;
    institutionSuggestions.clear(); // Clear institution suggestions
    _resetInstitutionSearchFilters();

    // Clear all text controllers - set to empty string explicitly
    nameController.text = '';
    schoolNameController.text = '';
    addressController.text = '';
    yogaMasterNameController.text = '';
    yogaMasterContactController.text = '';

    // Clear other state
    errorMessage.value = '';
    participantToEdit.value = null;
    isLoadingParticipant.value = false;
    isViewMode.value = false;

    // Increment reset trigger to force widget rebuilds (especially for Autocomplete)
    formResetTrigger.value = formResetTrigger.value + 1;

    // Don't clear selectedEventId - keep the competition selected for convenience
    // selectedEventId.value = '';

    // Reset form state - this must happen after clearing values
    // Use a safe callback that checks if the form key is still valid
    if (formKey.currentContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (formKey.currentState != null && formKey.currentContext != null) {
          formKey.currentState?.reset();
          // Force clear text controllers again after form reset to ensure they're empty
          nameController.text = '';
          schoolNameController.text = '';
          addressController.text = '';
          yogaMasterNameController.text = '';
          yogaMasterContactController.text = '';
        }
      });
    } else {
      // If context is not available, still clear the controllers
      nameController.text = '';
      schoolNameController.text = '';
      addressController.text = '';
      yogaMasterNameController.text = '';
      yogaMasterContactController.text = '';
    }
  }

  /// Initialize form for registration screen
  /// Handles reset logic for both new registration and edit mode
  void initializeRegistrationForm(String? participantId) {
    if (participantId != null && participantId.isNotEmpty) {
      // For edit mode: only reset if this is a different participant
      final currentEditId = participantToEdit.value?.id;
      if (currentEditId != participantId) {
        // Clear all form data first
        _clearFormData();

        // Fetch participant data after first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (formKey.currentState != null && formKey.currentContext != null) {
            formKey.currentState?.reset();
            fetchParticipantById(participantId);
          }
        });
      }
    } else {
      // For new registration: always reset form
      _clearFormData();

      // Reset form state after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (formKey.currentState != null && formKey.currentContext != null) {
          formKey.currentState?.reset();
        }
      });
    }
  }

  /// Initialize form directly from ParticipantModel without API call
  /// Used when participant data is already available (e.g., from list)
  void initializeFormFromModel(ParticipantModel participant) {
    // Clear all form data first
    _clearFormData();

    // Initialize form with participant data directly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (formKey.currentState != null && formKey.currentContext != null) {
        formKey.currentState?.reset();
        initializeFormForEdit(participant);
      }
    });
  }

  /// Clear all form controllers and reactive values
  void _clearFormData() {
    nameController.clear();
    schoolNameController.clear();
    addressController.clear();
    yogaMasterNameController.clear();
    yogaMasterContactController.clear();
    _resetInstitutionSearchFilters();
    dateOfBirth.value = null;
    gender.value = '';
    optForECertificate.value = false;
    isSpotRegistration.value = false;
    selectedCategories.clear();
    selectedStage.value = '';
    standard.value = '';
    photoFile.value = null;
    selectedImage.value = null;
    errorMessage.value = '';
    existingPhotoUrl.value = '';
    _clearBonafideCertificateFiles();
    selectedInstitutionId.value = null;
    selectedInstitution.value = null;
    participantInstitutionId.value = null;
    isLoadingParticipant.value = false;
    participantToEdit.value = null;
    isViewMode.value = false;
  }

  /// Fetch participant details by ID from API
  Future<bool> fetchParticipantById(String participantId) async {
    try {
      isLoadingParticipant.value = true;
      errorMessage.value = '';

      final response = await _participantRepository.getParticipantById(
        participantId,
      );

      if (response.success && response.data != null) {
        initializeFormForEdit(response.data!);
        isLoadingParticipant.value = false;
        return true;
      } else {
        errorMessage.value =
            response.message ?? 'Failed to fetch participant details';
        isLoadingParticipant.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error loading participant: ${e.toString()}';
      isLoadingParticipant.value = false;
      return false;
    }
  }

  /// Initialize form with participant data for viewing (non-editable)
  void initializeFormForView(ParticipantModel participant) {
    // Clear all form data first
    _clearFormData();

    // Set view mode flag
    isViewMode.value = true;

    // Initialize form with participant data directly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (formKey.currentState != null && formKey.currentContext != null) {
        formKey.currentState?.reset();
      }

      print('Initializing form for view: ${participant.participantName}');
      print('Participant ID: ${participant.id}');

      // DO NOT set participantToEdit - this keeps isEditMode as false
      // This ensures all fields remain non-editable

      // Set competition/event ID first (needed for category dropdown)
      if (participant.eventId != null && participant.eventId!.isNotEmpty) {
        selectedEventId.value = participant.eventId!;
      }

      // Use participant registration photo API endpoint to get image URL
      if (participant.id != null && participant.id!.isNotEmpty) {
        // Use the new participant registration photo API with cache-busting
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final imageUrl = getParticipantRegistrationPhotoUrl(
          participant.id,
          cacheBuster: timestamp,
        );
        existingPhotoUrl.value = imageUrl ?? '';

        // Get bonafied certificate URL with cache-busting
        final certificateUrl = getParticipantRegistrationCertificateUrl(
          participant.id,
          cacheBuster: timestamp,
        );
        existingCertificateUrl.value = certificateUrl ?? '';

        print('Photo URL from API: ${existingPhotoUrl.value}');
        print('Certificate URL from API: ${existingCertificateUrl.value}');
        print('Participant ID: ${participant.id}');
        print('Is Edit Mode: ${isEditMode}');
      } else {
        // Fallback to photoUrl if ID is not available
        existingPhotoUrl.value = participant.photoUrl ?? '';
        existingCertificateUrl.value = '';
        print('Photo URL from model: ${existingPhotoUrl.value}');
      }

      // Set form fields
      nameController.text = participant.participantName;
      // Set institution name - use a small delay to ensure Autocomplete widget is ready
      Future.microtask(() {
        schoolNameController.text = participant.schoolName;
      });
      // Set institution ID from participantInstitutionId (stored from API response)
      if (participantInstitutionId.value != null &&
          participantInstitutionId.value!.isNotEmpty) {
        selectedInstitutionId.value = participantInstitutionId.value;
      }
      addressController.text = participant.address;
      standard.value = participant.standard;
      gender.value = _normalizeGender(participant.gender);
      isSpotRegistration.value = participant.isSpotRegistration;
      optForECertificate.value = participant.optForECertificate;
      dateOfBirth.value = participant.dateOfBirth;

      // Extract stage from group value if it's in the format "GroupName (GROUP StageName)"
      // Otherwise, try to find the stage from competition data
      if (participant.standard.isNotEmpty) {
        final standardValue = participant.standard;

        // Check if standard contains stage info in format "II (GROUP A)"
        if (standardValue.contains('(GROUP')) {
          // Extract stage name (between "GROUP " and ")")
          final stagePart = standardValue
              .split('GROUP ')
              .last
              .replaceAll(')', '')
              .trim();
          selectedStage.value = stagePart;

          // Extract just the group name (before " (GROUP")
          final groupName = standardValue.split(' (GROUP').first.trim();
          standard.value = groupName;
        } else {
          // Standard is just the group name, need to find which stage contains this group
          // Get CompetitionController to find the stage
          try {
            final compController = Get.find<CompetitionController>();
            final selectedCompetition = compController.competitions
                .firstWhereOrNull((c) => c.id == selectedEventId.value);

            if (selectedCompetition != null &&
                selectedCompetition.stageGroups != null) {
              // Find which stage contains this group
              String? foundStageName;
              selectedCompetition.stageGroups!.forEach((stageIdStr, groupIds) {
                final stageId = int.tryParse(stageIdStr);
                if (stageId != null) {
                  final stageName = compController.getStageNameById(stageId);
                  if (stageName != null && stageName.isNotEmpty) {
                    // Check if any group in this stage matches
                    for (final groupId in groupIds) {
                      final groupName = compController.getGroupNameById(
                        groupId,
                      );
                      if (groupName != null && groupName == standardValue) {
                        foundStageName = stageName;
                        break;
                      }
                    }
                  }
                }
              });

              if (foundStageName != null && foundStageName!.isNotEmpty) {
                selectedStage.value = foundStageName!;
              }
            }
          } catch (e) {
            print('Error finding stage for group: $e');
            // If we can't find the stage, leave it empty - user will need to select it
          }
        }
      }

      // Set category - use the category name directly from participant
      selectedCategories.clear();
      if (participant.category.isNotEmpty) {
        // Use the category name as-is (it should match competition categories)
        selectedCategories.add(participant.category.trim());
      }

      // Set yoga master info
      yogaMasterNameController.text = participant.yogaMasterName;
      yogaMasterContactController.text = participant.yogaMasterContact;

      print(
        'Form initialized for view - Name: ${nameController.text}, Category: ${selectedCategories.join(", ")}, Institution: ${schoolNameController.text}, Institution ID: ${selectedInstitutionId.value}, Stage: ${selectedStage.value}, Group: ${standard.value}, Photo URL: ${existingPhotoUrl.value}',
      );
    });
  }

  /// Initialize form with participant data for editing
  void initializeFormForEdit(ParticipantModel participant) {
    print('Initializing form for edit: ${participant.participantName}');
    print('Participant ID: ${participant.id}');

    // Clear view mode flag
    isViewMode.value = false;

    // Set participant to edit first (this sets isEditMode to true)
    participantToEdit.value = participant;

    // Set competition/event ID first (needed for category dropdown)
    if (participant.eventId != null && participant.eventId!.isNotEmpty) {
      selectedEventId.value = participant.eventId!;
    }

    // Use participant registration photo API endpoint to get image URL
    // Set photo URL after participantToEdit to ensure isEditMode is true
    if (participant.id != null && participant.id!.isNotEmpty) {
      // Use the new participant registration photo API with cache-busting
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final imageUrl = getParticipantRegistrationPhotoUrl(
        participant.id,
        cacheBuster: timestamp,
      );
      existingPhotoUrl.value = imageUrl ?? '';

      // Get bonafied certificate URL with cache-busting
      final certificateUrl = getParticipantRegistrationCertificateUrl(
        participant.id,
        cacheBuster: timestamp,
      );
      existingCertificateUrl.value = certificateUrl ?? '';

      print('Photo URL from API: ${existingPhotoUrl.value}');
      print('Certificate URL from API: ${existingCertificateUrl.value}');
      print('Participant ID: ${participant.id}');
      print('Is Edit Mode: ${isEditMode}');
    } else {
      // Fallback to photoUrl if ID is not available
      existingPhotoUrl.value = participant.photoUrl ?? '';
      existingCertificateUrl.value = '';
      print('Photo URL from model: ${existingPhotoUrl.value}');
    }

    // Set form fields
    nameController.text = participant.participantName;
    // Set institution name - use a small delay to ensure Autocomplete widget is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (formKey.currentContext != null) {
        schoolNameController.text = participant.schoolName;
      }
    });
    // Set institution ID from participantInstitutionId (stored from API response)
    // This is critical - must be set before validation
    if (participantInstitutionId.value != null &&
        participantInstitutionId.value!.isNotEmpty) {
      selectedInstitutionId.value = participantInstitutionId.value;
      print(
        'Set selectedInstitutionId from participantInstitutionId: ${selectedInstitutionId.value}',
      );
      _loadSelectedInstitutionForEdit();
    } else {
      // If participantInstitutionId is not set, try to find it by name
      // Note: This is async and might complete after widget disposal, so we check if still needed
      if (participant.schoolName.isNotEmpty) {
        // Search for the institution and set the ID
        searchInstitutions(
              participant.schoolName,
              useInstitutionSearchFilters: false,
            )
            .then((_) {
              // Check if we're still in edit mode and the value hasn't been set
              if (participantToEdit.value?.id == participant.id &&
                  (selectedInstitutionId.value == null ||
                      selectedInstitutionId.value!.isEmpty)) {
                final matchingInstitution = institutionSuggestions
                    .firstWhereOrNull(
                      (institution) =>
                          institution.institutionName.trim().toLowerCase() ==
                          participant.schoolName.trim().toLowerCase(),
                    );
                if (matchingInstitution != null &&
                    matchingInstitution.id != null) {
                  selectedInstitutionId.value = matchingInstitution.id;
                  participantInstitutionId.value = matchingInstitution.id;
                  selectedInstitution.value = matchingInstitution;
                  _applyBonafideRulesForSelectedInstitution();
                  print(
                    'Found and set institution ID by name: ${selectedInstitutionId.value}',
                  );
                }
              }
            })
            .catchError((error) {
              // Silently handle errors to avoid assertion failures
              print('Error searching institution: $error');
            });
      }
    }
    addressController.text = participant.address;
    standard.value = participant.standard;
    gender.value = _normalizeGender(participant.gender);
    isSpotRegistration.value = participant.isSpotRegistration;
    optForECertificate.value = participant.optForECertificate;
    dateOfBirth.value = participant.dateOfBirth;
    // Extract stage from group value if it's in the format "GroupName (GROUP StageName)"
    // Otherwise, try to find the stage from competition data
    if (participant.standard.isNotEmpty) {
      final standardValue = participant.standard;

      // Check if standard contains stage info in format "II (GROUP A)"
      if (standardValue.contains('(GROUP')) {
        // Extract stage name (between "GROUP " and ")")
        final stagePart = standardValue
            .split('GROUP ')
            .last
            .replaceAll(')', '')
            .trim();
        selectedStage.value = stagePart;

        // Extract just the group name (before " (GROUP")
        final groupName = standardValue.split(' (GROUP').first.trim();
        standard.value = groupName;
      } else {
        // Standard is just the group name, need to find which stage contains this group
        // Get CompetitionController to find the stage
        try {
          final compController = Get.find<CompetitionController>();
          final selectedCompetition = compController.competitions
              .firstWhereOrNull((c) => c.id == selectedEventId.value);

          if (selectedCompetition != null &&
              selectedCompetition.stageGroups != null) {
            // Find which stage contains this group
            String? foundStageName;
            selectedCompetition.stageGroups!.forEach((stageIdStr, groupIds) {
              final stageId = int.tryParse(stageIdStr);
              if (stageId != null) {
                final stageName = compController.getStageNameById(stageId);
                if (stageName != null && stageName.isNotEmpty) {
                  // Check if any group in this stage matches
                  for (final groupId in groupIds) {
                    final groupName = compController.getGroupNameById(groupId);
                    if (groupName != null && groupName == standardValue) {
                      foundStageName = stageName;
                      break;
                    }
                  }
                }
              }
            });

            if (foundStageName != null && foundStageName!.isNotEmpty) {
              selectedStage.value = foundStageName!;
            }
          }
        } catch (e) {
          print('Error finding stage for group: $e');
          // If we can't find the stage, leave it empty - user will need to select it
        }
      }
    }

    // Set category - use the category name directly from participant
    selectedCategories.clear();
    if (participant.category.isNotEmpty) {
      // Use the category name as-is (it should match competition categories)
      selectedCategories.add(participant.category.trim());
    }

    // Set yoga master info
    yogaMasterNameController.text = participant.yogaMasterName;
    yogaMasterContactController.text = participant.yogaMasterContact;

    print(
      'Form initialized - Name: ${nameController.text}, Category: ${selectedCategories.join(", ")}, Institution: ${schoolNameController.text}, Stage: ${selectedStage.value}, Group: ${standard.value}, Photo URL: ${existingPhotoUrl.value}',
    );
  }

  /// Build ParticipantModel from current form data
  ParticipantModel buildParticipantModelFromForm(String? participantId) {
    final age = app_date_utils.AppDateUtils.calculateAge(dateOfBirth.value!);

    // Combine selected categories into a comma-separated string
    final categoryString = selectedCategories.join(', ');

    return ParticipantModel(
      id: participantId,
      participantName: nameController.text.trim().toUpperCase(),
      dateOfBirth: dateOfBirth.value!,
      age: age,
      gender: gender.value,
      category: categoryString,
      standard: standard.value,
      schoolName: schoolNameController.text.trim(),
      address: addressController.text.trim(),
      yogaMasterName: yogaMasterNameController.text.trim(),
      yogaMasterContact: yogaMasterContactController.text.trim(),
    );
  }

  /// Get image bytes from selected image
  Future<Uint8List?> getImageBytes() async {
    try {
      // Use selectedImage (XFile) which works on both web and mobile
      if (selectedImage.value != null) {
        return await selectedImage.value!.readAsBytes();
      }
    } catch (e) {
      print('Error reading image bytes: $e');
    }
    return null;
  }

  /// Submit update form for existing participant
  Future<bool> submitUpdateForm(String participantId) async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (dateOfBirth.value == null) {
      errorMessage.value = 'Please select date of birth';
      return false;
    }

    if (gender.value.isEmpty) {
      errorMessage.value = 'Please select gender';
      return false;
    }

    if (selectedCategories.isEmpty) {
      errorMessage.value = 'Please select at least one category';
      return false;
    }

    if (standard.value.isEmpty) {
      errorMessage.value = 'Please select standard/group';
      return false;
    }

    if (!await validateBonafideBeforeSave()) {
      return false;
    }

    final participant = buildParticipantModelFromForm(participantId);

    final success = await updateParticipant(
      id: participantId,
      participant: participant,
      photoFile: photoFile.value,
      photoXFile: selectedImage.value,
    );

    // Don't reload participants list after update
    // The calling screen (e.g., event details) will handle refreshing its own list
    // This prevents unnecessary API calls to event-based endpoints

    return success;
  }

  /// Check if form is in edit mode
  bool get isEditMode => participantToEdit.value != null;

  /// Generate next registration number based on existing registrations
  /// Format: [Category][Gender][Stage][Number]
  /// Example: CBA001 (Common Boys Stage A, number 001)
  ///          CGA001 (Common Girls Stage A, number 001)
  ///          SBA001 (Special Boys Stage A, number 001)
  ///          SGA001 (Special Girls Stage A, number 001)
  ///
  /// NOTE: This method calls the eventbased API to fetch existing participants.
  /// Currently disabled to avoid unnecessary API calls - backend should generate registration numbers.
  /// Uncomment the call in submitRegistrationForm if frontend generation is needed.
  // ignore: unused_element
  Future<String?> _generateNextRegistrationNumber({
    required int competitionId,
    required String categoryName,
    required String gender,
    required String stageName,
    required CompetitionController compController,
  }) async {
    try {
      // Build prefix: Category + Gender + Stage
      // Category: C = Common, S = Special
      final categoryPrefix = categoryName.toUpperCase().startsWith('C')
          ? 'C'
          : 'S';

      // Gender: B = Boy/Male, G = Girl/Female
      final genderPrefix =
          gender.toUpperCase().startsWith('M') || gender.toUpperCase() == 'MALE'
          ? 'B'
          : 'G';

      // Stage: A, B, C, D, E, F (first letter of stage name)
      final stagePrefix = stageName.isNotEmpty
          ? stageName[0].toUpperCase()
          : 'A';

      final prefix = '$categoryPrefix$genderPrefix$stagePrefix';

      // Fetch existing participants with same competition, category, gender, and stage
      final categoryId = compController.getCategoryIdByName(categoryName);
      final stageId = compController.getStageIdByName(stageName);

      if (categoryId == null || stageId == null) {
        print(
          'Warning: Could not find category or stage ID for registration number generation',
        );
        return null;
      }

      // Create filter to get participants with same competition, category, gender, and stage
      final filter = ParticipantFilterRequest(
        page: 0,
        size: 1000, // Get a large number to find all matching participants
        category: categoryName,
        sortBy: 'registrationNo',
        sortDirection: 'desc',
      );

      // Fetch participants
      final response = await _participantRepository.getParticipantsByEventId(
        eventId: competitionId.toString(),
        filter: filter,
      );

      if (!response.success || response.data == null) {
        print(
          'Warning: Could not fetch participants for registration number generation',
        );
        // Return first number if we can't fetch
        return '${prefix}001';
      }

      final participants = response.data!.participants;

      // Filter participants by gender and stage
      final matchingParticipants = participants.where((p) {
        final matchesGender =
            p.gender.toUpperCase().startsWith('M') ==
                gender.toUpperCase().startsWith('M') ||
            (p.gender.toUpperCase() == 'MALE' &&
                (gender.toUpperCase() == 'MALE' ||
                    gender.toUpperCase().startsWith('M'))) ||
            (p.gender.toUpperCase() == 'FEMALE' &&
                (gender.toUpperCase() == 'FEMALE' ||
                    gender.toUpperCase().startsWith('F')));

        // Check if participant's stage matches (we need to check by stage name or ID)
        // Since we don't have direct stage info in ParticipantModel, we'll check registration number prefix
        final matchesStage =
            p.registrationNo != null &&
            p.registrationNo!.length >= 3 &&
            p.registrationNo![2] == stagePrefix;

        return matchesGender && matchesStage;
      }).toList();

      // Find the highest registration number
      int maxNumber = 0;
      for (final participant in matchingParticipants) {
        if (participant.registrationNo != null &&
            participant.registrationNo!.startsWith(prefix) &&
            participant.registrationNo!.length > prefix.length) {
          try {
            final numberPart = participant.registrationNo!.substring(
              prefix.length,
            );
            final number = int.tryParse(numberPart);
            if (number != null && number > maxNumber) {
              maxNumber = number;
            }
          } catch (e) {
            // Skip invalid registration numbers
            continue;
          }
        }
      }

      // Increment and format
      final nextNumber = maxNumber + 1;
      final formattedNumber = nextNumber.toString().padLeft(3, '0');

      return '$prefix$formattedNumber';
    } catch (e) {
      print('Error generating registration number: $e');
      // Return first number on error
      final categoryPrefix = categoryName.toUpperCase().startsWith('C')
          ? 'C'
          : 'S';
      final genderPrefix =
          gender.toUpperCase().startsWith('M') || gender.toUpperCase() == 'MALE'
          ? 'B'
          : 'G';
      final stagePrefix = stageName.isNotEmpty
          ? stageName[0].toUpperCase()
          : 'A';
      return '${categoryPrefix}${genderPrefix}${stagePrefix}001';
    }
  }

  Future<bool> submitRegistrationForm({
    required String eventId,
    CompetitionController? competitionController,
  }) async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    if (dateOfBirth.value == null) {
      errorMessage.value = 'Please select date of birth';
      return false;
    }

    if (gender.value.isEmpty) {
      errorMessage.value = 'Please select gender';
      return false;
    }

    if (selectedCategories.isEmpty) {
      errorMessage.value = 'Please select at least one category';
      return false;
    }

    if (standard.value.isEmpty) {
      errorMessage.value = 'Please select standard/group';
      return false;
    }

    if (selectedStage.value.isEmpty) {
      errorMessage.value = 'Please select a stage';
      return false;
    }

    // Check if institution is selected
    if (selectedInstitutionId.value == null ||
        selectedInstitutionId.value!.isEmpty) {
      // If institution name is provided but ID is not set, try to find it
      if (schoolNameController.text.trim().isNotEmpty) {
        // Search for the institution by name
        await searchInstitutions(
          schoolNameController.text.trim(),
          useInstitutionSearchFilters: false,
        );

        // Check if we found a matching institution
        final matchingInstitution = institutionSuggestions.firstWhereOrNull(
          (institution) =>
              institution.institutionName.trim().toLowerCase() ==
              schoolNameController.text.trim().toLowerCase(),
        );

        if (matchingInstitution != null && matchingInstitution.id != null) {
          selectedInstitutionId.value = matchingInstitution.id;
          selectedInstitution.value = matchingInstitution;
          _applyBonafideRulesForSelectedInstitution();
        } else {
          // If still not found, check if participantInstitutionId is available (from edit mode)
          if (participantInstitutionId.value != null &&
              participantInstitutionId.value!.isNotEmpty) {
            selectedInstitutionId.value = participantInstitutionId.value;
          } else {
            errorMessage.value = 'Please select an institution from the list';
            return false;
          }
        }
      } else {
        errorMessage.value = 'Please select an institution from the list';
        return false;
      }
    }

    if (!await validateBonafideBeforeSave()) {
      return false;
    }

    final age = app_date_utils.AppDateUtils.calculateAge(dateOfBirth.value!);

    // Get CompetitionController if not provided
    final compController =
        competitionController ?? Get.find<CompetitionController>();

    // Convert names to IDs
    final competitionId = int.tryParse(eventId);
    if (competitionId == null) {
      errorMessage.value = 'Invalid competition ID';
      return false;
    }

    // Keep selected competition in sync for UI flows (public registration screen).
    if (selectedEventId.value.isEmpty) {
      selectedEventId.value = eventId;
    }
    applySpotRegistrationRulesForSelectedEvent();

    final categoryName = selectedCategories.first;
    final categoryId = compController.getCategoryIdByName(categoryName);
    if (categoryId == null) {
      errorMessage.value = 'Invalid category selected';
      return false;
    }

    final institutionId = int.tryParse(selectedInstitutionId.value!);
    if (institutionId == null) {
      errorMessage.value = 'Invalid institution selected';
      return false;
    }

    final groupId = compController.getGroupIdByName(standard.value);
    if (groupId == null) {
      errorMessage.value = 'Invalid group selected';
      return false;
    }

    // Get stage ID from stage name
    final stageId = compController.getStageIdByName(selectedStage.value);
    if (stageId == null) {
      errorMessage.value = 'Invalid stage selected';
      return false;
    }

    // Format date as YYYY-MM-DD
    final dobString =
        '${dateOfBirth.value!.year}-'
        '${dateOfBirth.value!.month.toString().padLeft(2, '0')}-'
        '${dateOfBirth.value!.day.toString().padLeft(2, '0')}';

    // Note: Registration number should be auto-generated by backend
    // We don't need to generate it on frontend to avoid unnecessary API calls
    // If backend doesn't generate it, uncomment the code below
    // String? nextRegistrationNo;
    // if (!isEditMode) {
    //   nextRegistrationNo = await _generateNextRegistrationNumber(...);
    // }

    // Prepare registration data
    final registrationData = <String, dynamic>{
      'competitionId': competitionId,
      'dateOfBirth': dobString,
      'age': age,
      'categoryId': categoryId,
      'stageId': stageId,
      'yogaTeacherName': yogaMasterNameController.text.trim(),
      'institutionId': institutionId,
      'participantName': nameController.text.trim().toUpperCase(),
      'sex': gender.value,
      'groupId': groupId,
      'yogaTeacherCell': yogaMasterContactController.text.trim(),
      'paymentMode': 'ONLINE', // Default payment mode
      'isSpotRegistration': isSpotRegistration.value,
      'optForECertificate': optForECertificate.value,
      // Registration number will be auto-generated by backend based on competition, category, gender, and stage
    };

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Check if we're in edit mode
      if (isEditMode && participantToEdit.value?.id != null) {
        // Use PUT API for update
        final participantId = participantToEdit.value!.id!;
        final response = await _participantRepository
            .updateParticipantRegistration(
              id: participantId,
              registrationData: registrationData,
              photoFile: photoFile.value,
              photoXFile: selectedImage.value,
              bonafiedCertificateFile: bonafideFile.value,
              bonafiedCertificateXFile: bonafideImage.value,
            );

        isLoading.value = false;

        if (response.success) {
          // Don't refresh image URLs here - they will be refreshed when form is re-initialized
          // The resetForm() will clear everything, and if we're staying in edit mode,
          // the form will be re-initialized with fresh data

          // Reload participants list if we have an event ID selected
          if (selectedEventId.value.isNotEmpty) {
            await loadParticipantsByEventId(
              selectedEventId.value,
              resetPage: true,
            );
          }

          // Store the latest registered/updated participant for UI flows.
          if (participants.isNotEmpty) {
            lastRegisteredParticipant.value = participants.first;
          }
          registrationSaved.value = true;

          // Reset form immediately after successful update
          resetForm();
          return true;
        } else {
          errorMessage.value =
              response.message ?? 'Failed to update participant';
          return false;
        }
      } else {
        // Use POST API for create
        final response = await _participantRepository
            .createParticipantRegistration(
              registrationData: registrationData,
              photoFile: photoFile.value,
              photoXFile: selectedImage.value,
              bonafiedCertificateFile: bonafideFile.value,
              bonafiedCertificateXFile: bonafideImage.value,
            );

        isLoading.value = false;

        if (response.success) {
          // Reload participants list if we have an event ID selected
          if (selectedEventId.value.isNotEmpty) {
            await loadParticipantsByEventId(
              selectedEventId.value,
              resetPage: true,
            );
          }

          // Store the latest registered participant for UI flows.
          if (participants.isNotEmpty) {
            lastRegisteredParticipant.value = participants.first;
          }
          registrationSaved.value = true;

          // Reset form immediately after successful save
          resetForm();
          return true;
        } else {
          errorMessage.value =
              response.message ?? 'Failed to register participant';
          return false;
        }
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = isEditMode
          ? 'Error updating participant: ${e.toString()}'
          : 'Error registering participant: ${e.toString()}';
      return false;
    }
  }

  // Get filtered participants based on search query
  // Note: Search is now handled by the API, so this just returns the participants list
  List<ParticipantModel> get filteredParticipants {
    return List<ParticipantModel>.from(participants);
  }

  void reset() {
    participants.clear();
    myRegistrations.clear();
    selectedParticipant.value = null;
    participantToEdit.value = null;
    isLoading.value = false;
    errorMessage.value = '';
    currentFilter.value = ParticipantFilterRequest();
    currentPage.value = 1;
    totalPages.value = 0;
    totalItems.value = 0;
    hasMorePages.value = false;
    resetForm();
  }

  /// Download participant certificate
  Future<void> downloadParticipantCertificate(String participantId) async {
    try {
      Get.snackbar(
        'Downloading',
        'Preparing certificate download...',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );

      final url =
          '${BaseUrl.baseUrl}${EndPoints.participantCertificate(participantId)}';
      final uri = Uri.parse(url);

      // Include auth token if available
      final token = StorageService.getString(AppConstants.tokenKey);
      final headers = <String, String>{
        'Accept': 'application/pdf',
        'Content-Type': 'application/pdf',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        if (kIsWeb) {
          // Web: Create blob and trigger download
          final blob = html.Blob([response.bodyBytes]);
          final blobUrl = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: blobUrl)
            ..setAttribute('download', 'certificate_$participantId.pdf')
            ..click();
          html.Url.revokeObjectUrl(blobUrl);

          Get.snackbar(
            'Success',
            'Certificate download started',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          // Mobile: Save file and open it
          // For mobile, we'll use the data URI approach which should work
          final dataUri = Uri.dataFromBytes(
            response.bodyBytes,
            mimeType: 'application/pdf',
          );
          if (await canLaunchUrl(dataUri)) {
            await launchUrl(dataUri, mode: LaunchMode.externalApplication);
            Get.snackbar(
              'Success',
              'Certificate opened',
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
          } else {
            Get.snackbar(
              'Error',
              'Could not open certificate',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          }
        }
      } else {
        Get.snackbar(
          'Error',
          'Failed to download certificate (status ${response.statusCode})',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to download certificate: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
