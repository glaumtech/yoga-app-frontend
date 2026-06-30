import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/district_model.dart';
import '../../data/models/organization_setup_model.dart';
import '../../data/models/state_model.dart';
import '../../data/repositories/branch_repository.dart';
import '../../data/repositories/location_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/organization_mandatory_gate_service.dart';
import '../../core/utils/organization_mandatory_checker.dart';
import '../../core/utils/state_defaults.dart';
import '../../core/utils/storage_service.dart';
import '../../presentation/widgets/organization/organization_proof_document_utils.dart';
import '../../presentation/widgets/organization/organization_proof_image_upload.dart';
import '../controllers/user_management_controller.dart';

class OrganizationUpdateController extends GetxController {
  final BranchRepository _branchRepo = BranchRepository();
  final OrganizationRepository _orgRepo = OrganizationRepository();
  final LocationRepository _locationRepo = LocationRepository();
  final ImagePicker _imagePicker = ImagePicker();

  /// 0 = organization details, 1 = documents
  final RxInt currentStep = 0.obs;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString loadError = ''.obs;
  final RxBool mandatoryMode = false.obs;

  int? _branchId;
  int? _organizationId;
  bool _hasExistingPanDocument = false;
  bool _hasExistingAadharDocument = false;

  final TextEditingController organizationNameController =
      TextEditingController();
  final TextEditingController commencingYearController =
      TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNoController = TextEditingController();
  final TextEditingController mobileNoController = TextEditingController();
  final TextEditingController websiteUrlController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController stateSearchTextController =
      TextEditingController();
  final FocusNode stateSearchFocusNode = FocusNode();
  final TextEditingController districtSearchTextController =
      TextEditingController();
  final FocusNode districtSearchFocusNode = FocusNode();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();

  final TextEditingController panNumberController = TextEditingController();
  final TextEditingController aadharNumberController = TextEditingController();
  final TextEditingController bankAccountNumberController =
      TextEditingController();
  final TextEditingController bankIfscController = TextEditingController();
  final TextEditingController bankBranchController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController gstNumberController = TextEditingController();

  final RxList<StateModel> states = <StateModel>[].obs;
  final RxList<DistrictModel> districts = <DistrictModel>[].obs;
  final RxInt selectedStateId = 0.obs;
  final RxInt selectedDistrictId = 0.obs;
  final RxBool isLoadingStates = false.obs;
  final RxBool isLoadingDistricts = false.obs;

  final Rx<Uint8List?> logoBytes = Rx<Uint8List?>(null);
  final RxString logoFileName = ''.obs;
  final RxBool logoChanged = false.obs;

  final Rx<Uint8List?> panImageBytes = Rx<Uint8List?>(null);
  final Rx<Uint8List?> aadharDocumentBytes = Rx<Uint8List?>(null);
  final RxString panDocumentFileName = ''.obs;
  final RxString aadharDocumentFileName = ''.obs;
  final RxBool panDocumentChanged = false.obs;
  final RxBool aadharDocumentChanged = false.obs;

  /// Bumped when organization step fields change (enables Continue button).
  final RxInt organizationStepRevision = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _initMandatoryMode();
    _bindOrganizationStepListeners();
    _initData();
  }

  void _initMandatoryMode() {
    final gate = Get.isRegistered<OrganizationMandatoryGateService>()
        ? Get.find<OrganizationMandatoryGateService>()
        : null;
    mandatoryMode.value =
        gate?.requiresMandatoryUpdate.value == true ||
        StorageService.getBool(AppConstants.orgMandatoryUpdateRequiredKey) ==
            true;
  }

  void _bumpOrganizationStepRevision() {
    organizationStepRevision.value++;
  }

  void _bindOrganizationStepListeners() {
    void bump() => _bumpOrganizationStepRevision();
    for (final controller in [
      organizationNameController,
      commencingYearController,
      emailController,
      phoneNoController,
      mobileNoController,
      websiteUrlController,
      countryController,
      stateSearchTextController,
      districtSearchTextController,
      addressController,
      pincodeController,
    ]) {
      controller.addListener(bump);
    }
    ever(selectedStateId, (_) => bump());
    ever(selectedDistrictId, (_) => bump());
    ever(logoBytes, (_) => bump());
  }

  bool get canContinueToDocuments {
    organizationStepRevision.value;
    return _isOrganizationStepComplete();
  }

  Future<void> _initData() async {
    await loadStates();
    await loadCurrentBranch();
    await _applyDefaultCountryAndStateIfEmpty();
    _bumpOrganizationStepRevision();
  }

  Future<void> _applyDefaultCountryAndStateIfEmpty() async {
    if (countryController.text.trim().isEmpty) {
      countryController.text = StateDefaults.defaultCountry;
    }
    if (selectedStateId.value <= 0) {
      final stateText = stateSearchTextController.text.trim();
      if (stateText.isNotEmpty) {
        final match = states.firstWhereOrNull(
          (s) => s.stateName.trim().toLowerCase() == stateText.toLowerCase(),
        );
        if (match != null) {
          await setSelectedState(match.id);
        }
      } else {
        final tn = StateDefaults.findTamilNadu(states);
        if (tn != null) {
          await setSelectedState(tn.id);
        }
      }
    }
  }

  @override
  void onClose() {
    organizationNameController.dispose();
    commencingYearController.dispose();
    emailController.dispose();
    phoneNoController.dispose();
    mobileNoController.dispose();
    websiteUrlController.dispose();
    countryController.dispose();
    stateSearchTextController.dispose();
    stateSearchFocusNode.dispose();
    districtSearchTextController.dispose();
    districtSearchFocusNode.dispose();
    addressController.dispose();
    pincodeController.dispose();
    panNumberController.dispose();
    aadharNumberController.dispose();
    bankAccountNumberController.dispose();
    bankIfscController.dispose();
    bankBranchController.dispose();
    bankNameController.dispose();
    gstNumberController.dispose();
    super.onClose();
  }

  String? requiredValidator(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  String? emailValidator(String? value, {String fieldName = 'Email'}) {
    final required = requiredValidator(value, fieldName: fieldName);
    if (required != null) return required;
    if (!GetUtils.isEmail(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? phoneValidator(String? value,
      {required String fieldName, bool required = true}) {
    final v = value?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
    if (v.isEmpty) {
      return required ? '$fieldName is required' : null;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(v)) {
      return 'Enter a valid 10-digit $fieldName';
    }
    return null;
  }

  String? commencingYearValidator(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Commencing year is required';
    final year = int.tryParse(v);
    if (year == null || v.length != 4) {
      return 'Enter a valid 4-digit year';
    }
    if (year < 1900 || year > 2100) {
      return 'Enter a valid year';
    }
    return null;
  }

  String? websiteValidator(String? value, {bool required = true}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return required ? 'Website URL is required' : null;
    }
    final urlPattern = RegExp(
      r'^(https?:\/\/)?([\w-]+\.)+[\w-]{2,}(\/\S*)?$',
      caseSensitive: false,
    );
    if (!urlPattern.hasMatch(v)) {
      return 'Enter a valid website URL';
    }
    return null;
  }

  String? pincodeValidator(String? value) {
    final digits = _normalizePincode(value);
    if (digits.isEmpty) return 'Pincode is required';
    if (digits.length != 6) {
      return 'Enter a valid 6-digit pincode';
    }
    return null;
  }

  String _normalizePincode(String? value) =>
      value?.replaceAll(RegExp(r'\D'), '') ?? '';

  int? _findStateIdFromText() {
    if (selectedStateId.value > 0) return selectedStateId.value;
    final text = stateSearchTextController.text.trim().toLowerCase();
    if (text.isEmpty) return null;
    return states
        .firstWhereOrNull(
          (s) => s.stateName.trim().toLowerCase() == text,
        )
        ?.id;
  }

  int? _findDistrictIdFromText() {
    if (selectedDistrictId.value > 0) return selectedDistrictId.value;
    final text = districtSearchTextController.text.trim().toLowerCase();
    if (text.isEmpty) return null;
    return districts
        .firstWhereOrNull(
          (d) => d.districtName.trim().toLowerCase() == text,
        )
        ?.id;
  }

  Future<void> _syncLocationSelectionsFromText() async {
    if (selectedStateId.value <= 0) {
      final stateId = _findStateIdFromText();
      if (stateId != null && stateId > 0) {
        await setSelectedState(stateId);
      }
    }
    if (selectedDistrictId.value <= 0) {
      final districtId = _findDistrictIdFromText();
      if (districtId != null && districtId > 0) {
        final district =
            districts.firstWhereOrNull((d) => d.id == districtId);
        if (district != null) {
          onDistrictSelected(district);
        }
      }
    }
  }

  String? stateValidator(String? value) {
    if (_findStateIdFromText() == null) {
      return requiredValidator(value, fieldName: 'State');
    }
    return null;
  }

  String? districtValidator(String? value) {
    if (_findDistrictIdFromText() == null) {
      return requiredValidator(value, fieldName: 'District');
    }
    return null;
  }

  bool _isOrganizationStepComplete() {
    if (requiredValidator(
          organizationNameController.text,
          fieldName: 'Organization name',
        ) !=
        null) {
      return false;
    }
    if (commencingYearValidator(commencingYearController.text) != null) {
      return false;
    }
    if (emailValidator(emailController.text) != null) return false;
    if (phoneValidator(phoneNoController.text, fieldName: 'phone number') !=
        null) {
      return false;
    }
    if (phoneValidator(
          mobileNoController.text,
          fieldName: 'mobile number',
          required: false,
        ) !=
        null) {
      return false;
    }
    if (websiteValidator(websiteUrlController.text, required: false) != null) {
      return false;
    }
    if (requiredValidator(countryController.text, fieldName: 'Country') !=
        null) {
      return false;
    }
    if (_findStateIdFromText() == null) return false;
    if (_findDistrictIdFromText() == null) return false;
    if (pincodeValidator(pincodeController.text) != null) return false;
    if (requiredValidator(addressController.text, fieldName: 'Address') !=
        null) {
      return false;
    }
    return true;
  }

  int? _tryParseNullableInt(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
  }

  Future<void> loadStates() async {
    if (isLoadingStates.value) return;
    try {
      isLoadingStates.value = true;
      final response = await _locationRepo.getAllStates();
      if (response.success && response.data != null) {
        states.assignAll(response.data!);
        states.sort((a, b) => a.stateName.compareTo(b.stateName));
      }
    } catch (e) {
      loadError.value = 'Failed to load states: ${e.toString()}';
    } finally {
      isLoadingStates.value = false;
    }
  }

  Future<void> loadDistrictsByStateId(int stateId) async {
    if (stateId <= 0) {
      districts.clear();
      return;
    }
    isLoadingDistricts.value = true;
    try {
      final response = await _locationRepo.getDistrictsByStateId(stateId);
      if (response.success && response.data != null) {
        districts.assignAll(response.data!);
        districts.sort((a, b) => a.districtName.compareTo(b.districtName));
      } else {
        districts.clear();
      }
    } catch (e) {
      districts.clear();
      loadError.value = 'Failed to load districts: ${e.toString()}';
    } finally {
      isLoadingDistricts.value = false;
    }
  }

  Future<void> setSelectedState(int stateId) async {
    selectedDistrictId.value = 0;
    districtSearchTextController.clear();
    districts.clear();

    if (stateId <= 0) {
      selectedStateId.value = 0;
      stateSearchTextController.clear();
      return;
    }

    final state = states.firstWhereOrNull((s) => s.id == stateId);
    if (state != null) {
      selectedStateId.value = state.id;
      stateSearchTextController.text = state.stateName;
    }
    await loadDistrictsByStateId(stateId);
    _bumpOrganizationStepRevision();
  }

  void onDistrictSelected(DistrictModel district) {
    selectedDistrictId.value = district.id;
    districtSearchTextController.text = district.districtName;
    _bumpOrganizationStepRevision();
  }

  Future<void> pickLogoFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      logoBytes.value = await picked.readAsBytes();
      logoFileName.value = picked.name;
      logoChanged.value = true;
    } catch (e) {
      errorMessage.value = 'Failed to pick logo: ${e.toString()}';
    }
  }

  void clearLogo() {
    logoBytes.value = null;
    logoFileName.value = '';
    logoChanged.value = true;
  }

  Future<void> pickPanDocument() async {
    try {
      errorMessage.value = '';
      final picked = await pickOrganizationProofPdf(documentLabel: 'e-PAN');
      if (picked == null) return;
      panImageBytes.value = picked.bytes;
      panDocumentFileName.value = picked.fileName;
      panDocumentChanged.value = true;
    } catch (e) {
      final message = formatOrganizationProofPickError(e);
      errorMessage.value = message;
      handleOrganizationProofPickFailure(e);
    }
  }

  void clearPanDocument() {
    panImageBytes.value = null;
    panDocumentFileName.value = '';
    panDocumentChanged.value = true;
    _hasExistingPanDocument = false;
  }

  Future<void> pickAadharDocument() async {
    try {
      errorMessage.value = '';
      final picked = await pickOrganizationProofPdf(documentLabel: 'e-AADHAR');
      if (picked == null) return;
      aadharDocumentBytes.value = picked.bytes;
      aadharDocumentFileName.value = picked.fileName;
      aadharDocumentChanged.value = true;
    } catch (e) {
      final message = formatOrganizationProofPickError(e);
      errorMessage.value = message;
      handleOrganizationProofPickFailure(e);
    }
  }

  void clearAadharDocument() {
    aadharDocumentBytes.value = null;
    aadharDocumentFileName.value = '';
    aadharDocumentChanged.value = true;
    _hasExistingAadharDocument = false;
  }

  Future<void> loadCurrentBranch() async {
    final userController = Get.isRegistered<UserManagementController>()
        ? Get.find<UserManagementController>()
        : null;
    final branchId = userController?.currentUser.value?.branchId;

    if (branchId == null || branchId <= 0) {
      loadError.value =
          'Your account is not linked to a branch. Cannot load organization details.';
      return;
    }

    isLoading.value = true;
    loadError.value = '';
    try {
      final response = await _branchRepo.getBranch(branchId);
      if (!response.success || response.data == null) {
        loadError.value =
            response.message ?? 'Failed to load organization details';
        return;
      }

      final branch = response.data!;
      _branchId = branch.id;
      _organizationId = branch.organizationId;

      organizationNameController.text =
          (branch.organizationName ?? branch.branchName).trim();
      if (branch.commencingYear != null) {
        commencingYearController.text = branch.commencingYear.toString();
      }
      emailController.text = branch.email ?? '';
      phoneNoController.text = branch.phoneNo ?? '';
      mobileNoController.text = branch.mobileNo ?? '';
      websiteUrlController.text = branch.websiteUrl ?? '';
      countryController.text = branch.country ?? '';
      addressController.text = branch.address ?? '';
      pincodeController.text = branch.pincode ?? '';

      panNumberController.text = branch.panNumber ?? '';
      aadharNumberController.text = branch.aadharNumber ?? '';
      bankAccountNumberController.text = branch.bankAccountNumber ?? '';
      bankIfscController.text = branch.bankIfsc ?? '';
      bankBranchController.text = branch.bankBranch ?? '';
      bankNameController.text = branch.bankName ?? '';
      gstNumberController.text = branch.gstNumber ?? '';

      if (branch.stateId != null && branch.stateId! > 0) {
        await setSelectedState(branch.stateId!);
        if (branch.cityId != null && branch.cityId! > 0) {
          selectedDistrictId.value = branch.cityId!;
          final districtName = branch.cityName?.trim();
          if (districtName != null && districtName.isNotEmpty) {
            districtSearchTextController.text = districtName;
          } else {
            final district = districts.firstWhereOrNull(
              (d) => d.id == branch.cityId,
            );
            if (district != null) {
              districtSearchTextController.text = district.districtName;
            }
          }
        } else if ((branch.cityName ?? '').trim().isNotEmpty) {
          districtSearchTextController.text = branch.cityName!.trim();
          final match = districts.firstWhereOrNull(
            (d) =>
                d.districtName.trim().toLowerCase() ==
                branch.cityName!.trim().toLowerCase(),
          );
          if (match != null) {
            onDistrictSelected(match);
          }
        }
      } else if ((branch.stateName ?? '').trim().isNotEmpty) {
        stateSearchTextController.text = branch.stateName!.trim();
        final match = states.firstWhereOrNull(
          (s) =>
              s.stateName.trim().toLowerCase() ==
              branch.stateName!.trim().toLowerCase(),
        );
        if (match != null) {
          await setSelectedState(match.id);
          if ((branch.cityName ?? '').trim().isNotEmpty) {
            districtSearchTextController.text = branch.cityName!.trim();
            final districtMatch = districts.firstWhereOrNull(
              (d) =>
                  d.districtName.trim().toLowerCase() ==
                  branch.cityName!.trim().toLowerCase(),
            );
            if (districtMatch != null) {
              onDistrictSelected(districtMatch);
            }
          }
        }
      }

      logoChanged.value = false;
      panDocumentChanged.value = false;
      aadharDocumentChanged.value = false;
      _hasExistingPanDocument =
          (branch.panImagePath ?? '').trim().isNotEmpty;
      _hasExistingAadharDocument =
          (branch.aadharFrontImagePath ?? branch.aadharImagePath ?? '')
              .trim()
              .isNotEmpty;

      final existingLogo = await _branchRepo.fetchLogoBytes(branch.id);
      logoBytes.value = existingLogo;
      logoFileName.value = existingLogo != null ? 'existing-logo' : '';

      if (_hasExistingPanDocument) {
        final fetched = await _branchRepo.fetchPanImageBytes(branch.id);
        panImageBytes.value =
            fetched != null ? organizationProofNormalizeBytes(fetched) : null;
        panDocumentFileName.value =
            organizationProofFileNameFromPath(branch.panImagePath) ??
            (panImageBytes.value != null ? 'existing-epan.pdf' : '');
      }
      if (_hasExistingAadharDocument) {
        final fetched = await _branchRepo.fetchAadharFrontImageBytes(branch.id);
        aadharDocumentBytes.value =
            fetched != null ? organizationProofNormalizeBytes(fetched) : null;
        aadharDocumentFileName.value =
            organizationProofFileNameFromPath(
              branch.aadharFrontImagePath ?? branch.aadharImagePath,
            ) ??
            (aadharDocumentBytes.value != null ? 'existing-eaadhar.pdf' : '');
      }

      if (mandatoryMode.value) {
        final gate = Get.isRegistered<OrganizationMandatoryGateService>()
            ? Get.find<OrganizationMandatoryGateService>()
            : null;
        currentStep.value =
            gate?.initialStepForBranch(branch) ??
            (hasOrganizationStepMissing(branch) ? 0 : 1);
      }
    } catch (e) {
      loadError.value = 'Failed to load organization details: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateOrganizationFieldsOnly() {
    errorMessage.value = '';
    final orgName = requiredValidator(
      organizationNameController.text,
      fieldName: 'Organization name',
    );
    if (orgName != null) {
      errorMessage.value = orgName;
      return false;
    }
    final yearErr = commencingYearValidator(commencingYearController.text);
    if (yearErr != null) {
      errorMessage.value = yearErr;
      return false;
    }
    final emailErr = emailValidator(emailController.text);
    if (emailErr != null) {
      errorMessage.value = emailErr;
      return false;
    }
    final phoneErr =
        phoneValidator(phoneNoController.text, fieldName: 'phone number');
    if (phoneErr != null) {
      errorMessage.value = phoneErr;
      return false;
    }
    final mobileErr = phoneValidator(
      mobileNoController.text,
      fieldName: 'mobile number',
      required: false,
    );
    if (mobileErr != null) {
      errorMessage.value = mobileErr;
      return false;
    }
    final websiteErr =
        websiteValidator(websiteUrlController.text, required: false);
    if (websiteErr != null) {
      errorMessage.value = websiteErr;
      return false;
    }
    final countryErr =
        requiredValidator(countryController.text, fieldName: 'Country');
    if (countryErr != null) {
      errorMessage.value = countryErr;
      return false;
    }
    if (_findStateIdFromText() == null) {
      errorMessage.value = 'State is required';
      return false;
    }
    if (_findDistrictIdFromText() == null) {
      errorMessage.value = 'District is required';
      return false;
    }
    final pincodeErr = pincodeValidator(pincodeController.text);
    if (pincodeErr != null) {
      errorMessage.value = pincodeErr;
      return false;
    }
    final addressErr =
        requiredValidator(addressController.text, fieldName: 'Address');
    if (addressErr != null) {
      errorMessage.value = addressErr;
      return false;
    }
    return true;
  }

  bool validateOrganizationStep() {
    if (!_validateOrganizationFieldsOnly()) return false;
    final formOk = formKey.currentState?.validate() ?? true;
    if (!formOk) {
      errorMessage.value = 'Please fix the highlighted fields';
      return false;
    }
    return true;
  }

  bool validateDocumentStep() {
    errorMessage.value = '';
    final panErr = validatePanNumber(panNumberController.text);
    if (panErr != null) {
      errorMessage.value = panErr;
      return false;
    }
    final aadharErr = validateAadharNumber(aadharNumberController.text);
    if (aadharErr != null) {
      errorMessage.value = aadharErr;
      return false;
    }
    final ifscErr = validateIfsc(bankIfscController.text);
    if (ifscErr != null) {
      errorMessage.value = ifscErr;
      return false;
    }
    final accountErr = validateRequiredField(
      bankAccountNumberController.text,
      fieldName: 'Account number',
    );
    if (accountErr != null) {
      errorMessage.value = accountErr;
      return false;
    }
    final branchErr = validateRequiredField(
      bankBranchController.text,
      fieldName: 'Bank branch',
    );
    if (branchErr != null) {
      errorMessage.value = branchErr;
      return false;
    }
    final bankNameErr = validateRequiredField(
      bankNameController.text,
      fieldName: 'Bank name',
    );
    if (bankNameErr != null) {
      errorMessage.value = bankNameErr;
      return false;
    }
    final gstErr = validateGstNumber(gstNumberController.text);
    if (gstErr != null) {
      errorMessage.value = gstErr;
      return false;
    }
    if (!_hasPanDocument()) {
      errorMessage.value = 'e-PAN document is required';
      return false;
    }
    if (!_hasAadharDocument()) {
      errorMessage.value = 'e-AADHAR document is required';
      return false;
    }
    if (panImageBytes.value != null &&
        organizationProofPdfContainsEncryptMarker(panImageBytes.value!)) {
      errorMessage.value = organizationProofPasswordProtectedMessage;
      return false;
    }
    if (aadharDocumentBytes.value != null &&
        organizationProofPdfContainsEncryptMarker(aadharDocumentBytes.value!)) {
      errorMessage.value = organizationProofPasswordProtectedMessage;
      return false;
    }
    final formOk = formKey.currentState?.validate() ?? true;
    if (!formOk) {
      if (errorMessage.value.isEmpty) {
        errorMessage.value = 'Please fix the highlighted fields';
      }
      return false;
    }
    return true;
  }

  bool _hasPanDocument() =>
      panImageBytes.value != null || _hasExistingPanDocument;

  bool _hasAadharDocument() =>
      aadharDocumentBytes.value != null || _hasExistingAadharDocument;

  Future<bool> continueToDocumentsStep() async {
    await _syncLocationSelectionsFromText();
    if (!validateOrganizationStep()) return false;
    errorMessage.value = '';
    currentStep.value = 1;
    return true;
  }

  void goBackStep() {
    if (currentStep.value <= 0) return;
    currentStep.value = currentStep.value - 1;
  }

  BranchRequestModel _buildBranchRequest() {
    final orgName = organizationNameController.text.trim();
    return BranchRequestModel(
      organizationId: _organizationId,
      branchName: orgName,
      commencingYear: _tryParseNullableInt(commencingYearController.text),
      email: emailController.text.trim().isEmpty
          ? null
          : emailController.text.trim(),
      phoneNo: phoneNoController.text.trim().isEmpty
          ? null
          : phoneNoController.text.trim(),
      mobileNo: mobileNoController.text.trim().isEmpty
          ? null
          : mobileNoController.text.trim(),
      websiteUrl: websiteUrlController.text.trim().isEmpty
          ? null
          : websiteUrlController.text.trim(),
      country: countryController.text.trim().isEmpty
          ? null
          : countryController.text.trim(),
      stateId: _findStateIdFromText(),
      cityId: _findDistrictIdFromText(),
      address: addressController.text.trim().isEmpty
          ? null
          : addressController.text.trim(),
      pincode: _normalizePincode(pincodeController.text).isEmpty
          ? null
          : _normalizePincode(pincodeController.text),
      panNumber: panNumberController.text.trim().toUpperCase(),
      aadharNumber: aadharNumberController.text.trim().replaceAll(' ', ''),
      bankAccountNumber: bankAccountNumberController.text.trim().isEmpty
          ? null
          : bankAccountNumberController.text.trim(),
      bankIfsc: bankIfscController.text.trim().isEmpty
          ? null
          : bankIfscController.text.trim().toUpperCase(),
      bankBranch: bankBranchController.text.trim().isEmpty
          ? null
          : bankBranchController.text.trim(),
      bankName: bankNameController.text.trim().isEmpty
          ? null
          : bankNameController.text.trim(),
      gstNumber: gstNumberController.text.trim().isEmpty
          ? null
          : gstNumberController.text.trim().toUpperCase(),
    );
  }

  Future<bool> save() async {
    errorMessage.value = '';
    await _syncLocationSelectionsFromText();
    selectedStateId.value = _findStateIdFromText() ?? selectedStateId.value;
    selectedDistrictId.value =
        _findDistrictIdFromText() ?? selectedDistrictId.value;
    if (!_validateOrganizationFieldsOnly()) {
      currentStep.value = 0;
      return false;
    }
    if (!validateDocumentStep()) {
      currentStep.value = 1;
      return false;
    }

    final branchId = _branchId;
    final organizationId = _organizationId;
    if (branchId == null || branchId <= 0 || organizationId == null) {
      errorMessage.value =
          'Organization context is missing. Please reload the page.';
      return false;
    }

    isSaving.value = true;
    try {
      final orgName = organizationNameController.text.trim();
      final orgResponse = await _orgRepo.updateOrganization(
        id: organizationId,
        request: OrganizationRequestModel(organizationName: orgName),
      );
      if (!orgResponse.success) {
        errorMessage.value =
            orgResponse.message ?? 'Failed to update organization name';
        return false;
      }

      final branchResponse = await _branchRepo.updateBranch(
        id: branchId,
        request: _buildBranchRequest(),
        logoBytes: logoChanged.value ? logoBytes.value : null,
        logoFileName: logoFileName.value.isEmpty ? 'logo.png' : logoFileName.value,
        panImageBytes: panDocumentChanged.value ? panImageBytes.value : null,
        panImageFileName: panDocumentFileName.value.isEmpty
            ? 'epan.pdf'
            : panDocumentFileName.value,
        aadharFrontImageBytes: aadharDocumentChanged.value
            ? aadharDocumentBytes.value
            : null,
        aadharFrontImageFileName: aadharDocumentFileName.value.isEmpty
            ? 'eaadhar.pdf'
            : aadharDocumentFileName.value,
      );
      if (!branchResponse.success) {
        errorMessage.value =
            branchResponse.message ?? 'Failed to update organization details';
        return false;
      }

      logoChanged.value = false;
      panDocumentChanged.value = false;
      aadharDocumentChanged.value = false;
      _hasExistingPanDocument =
          (branchResponse.data?.panImagePath ?? '').trim().isNotEmpty;
      _hasExistingAadharDocument =
          (branchResponse.data?.aadharFrontImagePath ??
                  branchResponse.data?.aadharImagePath ??
                  '')
              .trim()
              .isNotEmpty;

      if (mandatoryMode.value &&
          Get.isRegistered<OrganizationMandatoryGateService>()) {
        final stillRequired = await Get.find<OrganizationMandatoryGateService>()
            .evaluateForCurrentUser();
        if (!stillRequired) {
          mandatoryMode.value = false;
          await Get.find<OrganizationMandatoryGateService>().clear();
        }
      }
      return true;
    } catch (e) {
      errorMessage.value = 'Update failed: ${e.toString()}';
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
