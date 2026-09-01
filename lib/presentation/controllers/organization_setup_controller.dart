import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/utils/organization_setup_credentials.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../data/models/app_permission_record_model.dart';
import '../../data/models/district_model.dart';
import '../../data/models/organization_setup_model.dart';
import '../../data/models/state_model.dart';
import '../../core/utils/state_defaults.dart';
import '../../core/utils/subscription_catalog_filter.dart';
import '../../data/models/subscription_mode_model.dart';
import '../../data/models/subscription_package_model.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/organization_setup_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/permission_repository.dart';
import '../../services/razorpay_checkout_service.dart';
import '../widgets/organization/organization_proof_image_upload.dart';

class OrganizationSetupController extends GetxController {
  final OrganizationSetupRepository _repo = OrganizationSetupRepository();
  final PermissionRepository _permissionRepo = PermissionRepository();
  final PaymentRepository _paymentRepo = PaymentRepository();
  final LocationRepository _locationRepo = LocationRepository();
  final RazorpayCheckoutService _razorpayCheckout = RazorpayCheckoutService();
  final ImagePicker _imagePicker = ImagePicker();

  /// 0 = org/branch, 1 = documents, 2 = plan & payment, 3 = admin users (final submit)
  final RxInt currentStep = 0.obs;
  final Rx<OrganizationSetupFoundationResponseModel?> foundationResult =
      Rx<OrganizationSetupFoundationResponseModel?>(null);
  final RxBool adminsCreated = false.obs;
  final RxBool subscriptionPaymentCompleted = false.obs;
  final RxBool isProcessingPayment = false.obs;
  final RxString selectedCheckoutMethod = 'RAZORPAY'.obs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxBool isLoadingPermissions = false.obs;
  final RxString permissionsError = ''.obs;
  final RxList<AppPermissionRecord> permissions = <AppPermissionRecord>[].obs;

  // Selected permission IDs for each admin type (saved as user-type permissions for the created branch).
  final RxSet<int> orgAdminPermissionIds = <int>{}.obs;
  final RxSet<int> branchAdminPermissionIds = <int>{}.obs;

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RxInt formRevision = 0.obs;

  // Organization
  final TextEditingController organizationNameController =
      TextEditingController();
  final TextEditingController organizationCodeController =
      TextEditingController();
  final RxBool isLoadingModes = false.obs;
  final RxString modesError = ''.obs;
  final RxList<SubscriptionModeModel> subscriptionModes =
      <SubscriptionModeModel>[].obs;
  final RxnInt selectedSubscriptionModeId = RxnInt();

  final RxBool isLoadingPackages = false.obs;
  final RxString packagesError = ''.obs;
  final RxList<SubscriptionPackageModel> subscriptionPackages =
      <SubscriptionPackageModel>[].obs;
  final RxnInt selectedPackageId = RxnInt();
  final RxString selectedPaymentModel = ''.obs;
  final Rx<XFile?> paymentProofImage = Rx<XFile?>(null);

  // Branch
  final TextEditingController branchNameController = TextEditingController();
  final TextEditingController branchCodeController = TextEditingController();
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

  final RxList<StateModel> states = <StateModel>[].obs;
  final RxList<DistrictModel> districts = <DistrictModel>[].obs;
  final RxInt selectedStateId = 0.obs;
  final RxInt selectedDistrictId = 0.obs;
  final RxBool isLoadingStates = false.obs;
  final RxBool isLoadingDistricts = false.obs;
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController themeController = TextEditingController();

  // Org Admin User
  final TextEditingController orgAdminNameController = TextEditingController();
  final TextEditingController orgAdminUserNameController =
      TextEditingController();
  final TextEditingController orgAdminPasswordController =
      TextEditingController();

  // Branch Admin User
  final TextEditingController branchAdminNameController =
      TextEditingController();
  final TextEditingController branchAdminUserNameController =
      TextEditingController();
  final TextEditingController branchAdminEmailController =
      TextEditingController();
  final TextEditingController branchAdminPasswordController =
      TextEditingController();
  final RxBool branchAdminPasswordVisible = false.obs;

  final Rx<XFile?> orgAdminPhoto = Rx<XFile?>(null);
  final Rx<XFile?> branchAdminPhoto = Rx<XFile?>(null);
  final Rx<Uint8List?> orgAdminPhotoBytes = Rx<Uint8List?>(null);
  final Rx<Uint8List?> branchAdminPhotoBytes = Rx<Uint8List?>(null);

  // Logo
  final Rx<Uint8List?> logoBytes = Rx<Uint8List?>(null);
  final RxString logoFileName = ''.obs;

  // Documents
  final TextEditingController panNumberController = TextEditingController();
  final TextEditingController aadharNumberController = TextEditingController();
  final TextEditingController bankAccountNumberController =
      TextEditingController();
  final TextEditingController bankIfscController = TextEditingController();
  final TextEditingController bankBranchController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController gstNumberController = TextEditingController();
  final Rx<Uint8List?> panImageBytes = Rx<Uint8List?>(null);
  final Rx<Uint8List?> aadharDocumentBytes = Rx<Uint8List?>(null);
  final RxString panDocumentFileName = ''.obs;
  final RxString aadharDocumentFileName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadPermissions();
    loadSubscriptionModes();
    loadStates();
  }

  @override
  void onClose() {
    organizationNameController.dispose();
    organizationCodeController.dispose();
    branchNameController.dispose();
    branchCodeController.dispose();
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
    themeController.dispose();
    orgAdminNameController.dispose();
    orgAdminUserNameController.dispose();
    orgAdminPasswordController.dispose();
    branchAdminNameController.dispose();
    branchAdminUserNameController.dispose();
    branchAdminEmailController.dispose();
    branchAdminPasswordController.dispose();
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
        await _applyDefaultCountryAndStateIfEmpty();
      }
    } catch (e) {
      errorMessage.value = 'Failed to load states: ${e.toString()}';
    } finally {
      isLoadingStates.value = false;
    }
  }

  Future<void> _applyDefaultCountryAndStateIfEmpty() async {
    if (countryController.text.trim().isEmpty) {
      countryController.text = StateDefaults.defaultCountry;
    }
    if (selectedStateId.value <= 0 &&
        stateSearchTextController.text.trim().isEmpty) {
      final tn = StateDefaults.findTamilNadu(states);
      if (tn != null) {
        await setSelectedState(tn.id);
      }
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
      errorMessage.value = 'Failed to load districts: ${e.toString()}';
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
  }

  void onDistrictSelected(DistrictModel district) {
    selectedDistrictId.value = district.id;
    districtSearchTextController.text = district.districtName;
  }

  Future<void> pickLogoFromGallery() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      logoBytes.value = bytes;
      logoFileName.value = picked.name;
    } catch (e) {
      errorMessage.value = 'Failed to pick logo: ${e.toString()}';
    }
  }

  void clearLogo() {
    logoBytes.value = null;
    logoFileName.value = '';
  }

  Future<void> pickPanDocument() async {
    try {
      errorMessage.value = '';
      final picked = await pickOrganizationProofPdf(documentLabel: 'e-PAN');
      if (picked == null) return;
      panImageBytes.value = picked.bytes;
      panDocumentFileName.value = picked.fileName;
    } catch (e) {
      final message = formatOrganizationProofPickError(e);
      errorMessage.value = message;
      handleOrganizationProofPickFailure(e);
    }
  }

  void clearPanDocument() {
    panImageBytes.value = null;
    panDocumentFileName.value = '';
  }

  Future<void> pickAadharDocument() async {
    try {
      errorMessage.value = '';
      final picked = await pickOrganizationProofPdf(documentLabel: 'e-AADHAR');
      if (picked == null) return;
      aadharDocumentBytes.value = picked.bytes;
      aadharDocumentFileName.value = picked.fileName;
    } catch (e) {
      final message = formatOrganizationProofPickError(e);
      errorMessage.value = message;
      handleOrganizationProofPickFailure(e);
    }
  }

  void clearAadharDocument() {
    aadharDocumentBytes.value = null;
    aadharDocumentFileName.value = '';
  }

  Map<String, dynamic> get _documentUploadParams => {
    'panImageBytes': panImageBytes.value,
    'panImageFileName': panDocumentFileName.value.isEmpty
        ? 'epan.pdf'
        : panDocumentFileName.value,
    'aadharFrontImageBytes': aadharDocumentBytes.value,
    'aadharFrontImageFileName': aadharDocumentFileName.value.isEmpty
        ? 'eaadhar.pdf'
        : aadharDocumentFileName.value,
  };

  Future<void> pickPaymentProof() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        paymentProofImage.value = picked;
      }
    } catch (e) {
      errorMessage.value = 'Failed to pick payment proof: ${e.toString()}';
    }
  }

  void clearPaymentProof() {
    paymentProofImage.value = null;
  }

  void resetForm() {
    organizationNameController.clear();
    organizationCodeController.clear();
    paymentProofImage.value = null;

    branchNameController.clear();
    branchCodeController.clear();
    commencingYearController.clear();
    emailController.clear();
    phoneNoController.clear();
    mobileNoController.clear();
    websiteUrlController.clear();
    countryController.clear();
    stateSearchTextController.clear();
    districtSearchTextController.clear();
    selectedStateId.value = 0;
    selectedDistrictId.value = 0;
    districts.clear();
    addressController.clear();
    pincodeController.clear();
    themeController.clear();

    orgAdminNameController.clear();
    orgAdminUserNameController.clear();
    orgAdminPasswordController.clear();

    branchAdminNameController.clear();
    branchAdminUserNameController.clear();
    branchAdminEmailController.clear();
    branchAdminPasswordController.clear();
    branchAdminPasswordVisible.value = false;
    orgAdminPhoto.value = null;
    branchAdminPhoto.value = null;
    orgAdminPhotoBytes.value = null;
    branchAdminPhotoBytes.value = null;

    clearLogo();
    panNumberController.clear();
    aadharNumberController.clear();
    bankAccountNumberController.clear();
    bankIfscController.clear();
    bankBranchController.clear();
    bankNameController.clear();
    gstNumberController.clear();
    panImageBytes.value = null;
    aadharDocumentBytes.value = null;
    panDocumentFileName.value = '';
    aadharDocumentFileName.value = '';

    orgAdminPermissionIds.clear();
    branchAdminPermissionIds.clear();

    errorMessage.value = '';
    currentStep.value = 0;
    foundationResult.value = null;
    adminsCreated.value = false;
    subscriptionPaymentCompleted.value = false;

    selectedCheckoutMethod.value = 'RAZORPAY';

    selectedSubscriptionModeId.value = null;
    selectedPackageId.value = null;
    selectedPaymentModel.value = '';
    subscriptionPackages.clear();

    formKey = GlobalKey<FormState>();
    formRevision.value++;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      formKey.currentState?.reset();
    });

    _applyDefaultCountryAndStateIfEmpty();
  }

  SubscriptionPackageModel? get selectedPackage =>
      packageById(selectedPackageId.value);

  bool get requiresSubscriptionPayment =>
      selectedPackage?.requiresSubscriptionPayment ?? false;

  String get stepTitle {
    switch (currentStep.value) {
      case 1:
        return 'Documents';
      case 2:
        return 'Plan & Payment';
      case 3:
        return 'Admin Users';
      default:
        return 'Organization Details';
    }
  }

  SubscriptionModeModel? get selectedSubscriptionMode {
    final id = selectedSubscriptionModeId.value;
    if (id == null) return null;
    return subscriptionModes.firstWhereOrNull((m) => m.id == id);
  }

  Future<void> loadSubscriptionModes() async {
    if (isLoadingModes.value) return;
    try {
      isLoadingModes.value = true;
      modesError.value = '';
      final res = await _paymentRepo.listSubscriptionModes();
      if (res.success && res.data != null) {
        subscriptionModes.assignAll(
          SubscriptionCatalogFilter.modesForOrganizationSetup(res.data!),
        );
        if (subscriptionModes.isEmpty) {
          modesError.value = 'On Demand subscription mode is not configured on the server';
        } else {
          final mode = subscriptionModes.first;
          if (selectedSubscriptionModeId.value != mode.id) {
            selectedSubscriptionModeId.value = mode.id;
            await loadSubscriptionPackagesForMode(mode);
          }
        }
      } else {
        modesError.value = res.message ?? 'Failed to load subscription modes';
        subscriptionModes.clear();
      }
    } catch (e) {
      modesError.value = 'Failed to load subscription modes: ${e.toString()}';
      subscriptionModes.clear();
    } finally {
      isLoadingModes.value = false;
    }
  }

  Future<void> selectSubscriptionMode(SubscriptionModeModel mode) async {
    if (selectedSubscriptionModeId.value == mode.id) return;
    selectedSubscriptionModeId.value = mode.id;
    selectedPackageId.value = null;
    selectedPaymentModel.value = '';
    await loadSubscriptionPackagesForMode(mode);
  }

  Future<void> loadSubscriptionPackagesForMode(
    SubscriptionModeModel mode,
  ) async {
    if (isLoadingPackages.value) return;
    try {
      isLoadingPackages.value = true;
      packagesError.value = '';
      final res = await _paymentRepo.listPackages(
        subscriptionModeId: mode.id,
        paymentModel: mode.modeKey,
      );
      if (res.success && res.data != null) {
        final filtered = SubscriptionCatalogFilter.forOrganizationSetup(
          res.data!,
          subscriptionModeId: mode.id,
          paymentModel: mode.modeKey,
        );
        subscriptionPackages.assignAll(filtered);
        final current = selectedPackageId.value;
        final stillValid =
            current != null && subscriptionPackages.any((p) => p.id == current);
        if (!stillValid && subscriptionPackages.isNotEmpty) {
          applySelectedPackage(subscriptionPackages.first.id);
        } else if (!stillValid) {
          selectedPackageId.value = null;
          selectedPaymentModel.value = '';
        }
      } else {
        packagesError.value =
            res.message ?? 'Failed to load subscription packages';
        subscriptionPackages.clear();
        selectedPackageId.value = null;
        selectedPaymentModel.value = '';
      }
    } catch (e) {
      packagesError.value =
          'Failed to load subscription packages: ${e.toString()}';
      subscriptionPackages.clear();
      selectedPackageId.value = null;
      selectedPaymentModel.value = '';
    } finally {
      isLoadingPackages.value = false;
    }
  }

  Future<void> reloadSubscriptionPackages() async {
    final mode = selectedSubscriptionMode;
    if (mode == null) return;
    await loadSubscriptionPackagesForMode(mode);
  }

  bool validatePlanStep() {
    if (selectedSubscriptionModeId.value == null) {
      errorMessage.value = 'Please select a subscription mode';
      return false;
    }
    if (selectedPackageId.value == null) {
      errorMessage.value = 'Please select a subscription package';
      return false;
    }
    return true;
  }

  SubscriptionPackageModel? packageById(int? id) {
    if (id == null) return null;
    return subscriptionPackages.firstWhereOrNull((p) => p.id == id);
  }

  void applySelectedPackage(int? packageId) {
    selectedPackageId.value = packageId;
    final pkg = packageById(packageId);
    if (pkg == null) {
      selectedPaymentModel.value = '';
      return;
    }
    selectedPaymentModel.value = pkg.paymentModel;
  }

  String? subscriptionPackageValidator(int? value) {
    if (subscriptionPackages.isEmpty) {
      return packagesError.value.isNotEmpty
          ? packagesError.value
          : 'No subscription packages available';
    }
    if (value == null) return 'Please select a subscription package';
    return null;
  }

  Future<void> loadPermissions() async {
    if (isLoadingPermissions.value) return;
    try {
      isLoadingPermissions.value = true;
      permissionsError.value = '';
      final res = await _permissionRepo.getAllPermissions();
      if (res.success && res.data != null) {
        permissions.assignAll(res.data!);
        assignAllPermissions();
      } else {
        permissionsError.value = res.message ?? 'Failed to load permissions';
      }
    } catch (e) {
      permissionsError.value = 'Failed to load permissions: ${e.toString()}';
    } finally {
      isLoadingPermissions.value = false;
    }
  }

  void assignAllPermissions() {
    final ids = permissions
        .map((p) => p.id)
        .whereType<int>()
        .where((id) => id > 0)
        .toList();
    orgAdminPermissionIds
      ..clear()
      ..addAll(ids);
    branchAdminPermissionIds
      ..clear()
      ..addAll(ids);
  }

  String get organizationNameTrimmed => organizationNameController.text.trim();

  void prepareAdminStep() {
    final orgName = organizationNameTrimmed;
    orgAdminNameController.text =
        OrganizationSetupCredentials.orgAdminDisplayName(orgName);
    orgAdminUserNameController.text =
        OrganizationSetupCredentials.orgAdminUsername(orgName);
    orgAdminPasswordController.text =
        OrganizationSetupCredentials.generatePassword();
    if (branchAdminPasswordController.text.trim().isEmpty) {
      branchAdminPasswordController.text =
          OrganizationSetupCredentials.generatePassword();
    }
    if (branchAdminEmailController.text.trim().isEmpty &&
        emailController.text.trim().isNotEmpty) {
      branchAdminEmailController.text = emailController.text.trim();
    }
    assignAllPermissions();
  }

  String? emailValidator(String? value, {String fieldName = 'Email'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final email = value.trim();
    if (!GetUtils.isEmail(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String _branchAdminEmailTrimmed() => branchAdminEmailController.text.trim();

  SetupAdminUserRequestModel _buildOrgAdminUserRequest() {
    return SetupAdminUserRequestModel(
      name: orgAdminNameController.text.trim(),
      userName: orgAdminUserNameController.text.trim(),
      email: _branchAdminEmailTrimmed(),
      password: orgAdminPasswordController.text,
    );
  }

  SetupAdminUserRequestModel _buildBranchAdminUserRequest() {
    return SetupAdminUserRequestModel(
      name: branchAdminNameController.text.trim(),
      userName: branchAdminUserNameController.text.trim(),
      email: _branchAdminEmailTrimmed(),
      password: branchAdminPasswordController.text,
    );
  }

  Future<void> pickOrgAdminPhoto(
    ImageSource source,
    BuildContext context,
  ) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked == null) return;
      orgAdminPhoto.value = picked;
      orgAdminPhotoBytes.value = await picked.readAsBytes();
    } catch (e) {
      errorMessage.value = 'Failed to pick org admin photo: ${e.toString()}';
    }
  }

  Future<void> pickBranchAdminPhoto(
    ImageSource source,
    BuildContext context,
  ) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked == null) return;
      branchAdminPhoto.value = picked;
      branchAdminPhotoBytes.value = await picked.readAsBytes();
    } catch (e) {
      errorMessage.value = 'Failed to pick branch admin photo: ${e.toString()}';
    }
  }

  void clearBranchAdminPhoto() {
    branchAdminPhoto.value = null;
    branchAdminPhotoBytes.value = null;
  }

  void regenerateBranchAdminPassword() {
    branchAdminPasswordController.text =
        OrganizationSetupCredentials.generatePassword();
  }

  void toggleBranchAdminPasswordVisibility() {
    branchAdminPasswordVisible.value = !branchAdminPasswordVisible.value;
  }

  OrganizationSetupFoundationRequestModel buildFoundationRequest() {
    final pkg = selectedPackage;
    final orgName = organizationNameTrimmed;
    final org = OrganizationRequestModel(
      organizationName: orgName,
      paymentModel: selectedPaymentModel.value.isEmpty
          ? null
          : selectedPaymentModel.value,
      subscriptionCreditsRemaining: 0,
      packCreditsRemaining: 0,
      maintenanceFeeAmount:
          pkg != null && pkg.paymentModel == 'PAY_PER_PARTICIPANT'
          ? pkg.price
          : null,
    );

    final branch = BranchRequestModel(
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
      stateId: selectedStateId.value > 0 ? selectedStateId.value : null,
      cityId: selectedDistrictId.value > 0 ? selectedDistrictId.value : null,
      address: addressController.text.trim().isEmpty
          ? null
          : addressController.text.trim(),
      pincode: pincodeController.text.trim().isEmpty
          ? null
          : pincodeController.text.trim(),
      theme: themeController.text.trim().isEmpty
          ? null
          : themeController.text.trim(),
      panNumber: panNumberController.text.trim().isEmpty
          ? null
          : panNumberController.text.trim().toUpperCase(),
      aadharNumber: aadharNumberController.text.trim().isEmpty
          ? null
          : aadharNumberController.text.trim().replaceAll(' ', ''),
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

    return OrganizationSetupFoundationRequestModel(
      organization: org,
      branch: branch,
      selectedPackageId: selectedPackageId.value,
      checkoutMethod: selectedCheckoutMethod.value,
    );
  }

  OrganizationSetupCompleteRequestModel buildCompleteRequest() {
    final foundation = buildFoundationRequest();
    return OrganizationSetupCompleteRequestModel(
      organization: foundation.organization,
      branch: foundation.branch,
      selectedPackageId: foundation.selectedPackageId,
      checkoutMethod: foundation.checkoutMethod,
      orgAdminUser: _buildOrgAdminUserRequest(),
      branchAdminUser: _buildBranchAdminUserRequest(),
      orgAdminPermissionIds: orgAdminPermissionIds.toList()..sort(),
      branchAdminPermissionIds: branchAdminPermissionIds.toList()..sort(),
    );
  }

  OrganizationSetupAdminsRequestModel? buildAdminsRequest() {
    final foundation = foundationResult.value;
    if (foundation == null) return null;

    final branchId = foundation.branch.id;
    if (branchId <= 0) {
      errorMessage.value =
          'Branch was not created correctly. Please go back and complete organization setup again.';
      return null;
    }

    return OrganizationSetupAdminsRequestModel(
      organizationId: foundation.organization.id,
      branchId: branchId,
      orgAdminUser: _buildOrgAdminUserRequest(),
      branchAdminUser: _buildBranchAdminUserRequest(),
      orgAdminPermissionIds: orgAdminPermissionIds.toList()..sort(),
      branchAdminPermissionIds: branchAdminPermissionIds.toList()..sort(),
    );
  }

  bool validateStep0() {
    errorMessage.value = '';
    final orgName = requiredValidator(
      organizationNameController.text,
      fieldName: 'Organization name',
    );
    if (orgName != null) {
      errorMessage.value = orgName;
      return false;
    }
    return true;
  }

  bool validateDocumentStep() {
    errorMessage.value = '';
    final panErr = _panValidator(panNumberController.text);
    if (panErr != null) {
      errorMessage.value = panErr;
      return false;
    }
    final aadharErr = _aadharValidator(aadharNumberController.text);
    if (aadharErr != null) {
      errorMessage.value = aadharErr;
      return false;
    }
    final ifscErr = _ifscValidator(bankIfscController.text);
    if (ifscErr != null) {
      errorMessage.value = ifscErr;
      return false;
    }
    final accountErr = requiredValidator(
      bankAccountNumberController.text,
      fieldName: 'Account number',
    );
    if (accountErr != null) {
      errorMessage.value = accountErr;
      return false;
    }
    final branchErr = requiredValidator(
      bankBranchController.text,
      fieldName: 'Bank branch',
    );
    if (branchErr != null) {
      errorMessage.value = branchErr;
      return false;
    }
    final bankNameErr = requiredValidator(
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
    return formKey.currentState?.validate() ?? true;
  }

  String? _panValidator(String? value) {
    final v = value?.trim().toUpperCase() ?? '';
    if (v.isEmpty) return 'PAN number is required';
    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(v)) {
      return 'Enter a valid PAN (e.g. ABCDE1234F)';
    }
    return null;
  }

  String? _aadharValidator(String? value) {
    final v = value?.trim().replaceAll(' ', '') ?? '';
    if (v.isEmpty) return 'Aadhar number is required';
    if (!RegExp(r'^\d{12}$').hasMatch(v)) {
      return 'Enter a valid 12-digit Aadhar number';
    }
    return null;
  }

  String? _ifscValidator(String? value) {
    final v = value?.trim().toUpperCase() ?? '';
    if (v.isEmpty) return 'IFSC number is required';
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(v)) {
      return 'Enter a valid IFSC code';
    }
    return null;
  }

  bool validateAdminStep() {
    errorMessage.value = '';
    final name = requiredValidator(
      branchAdminNameController.text,
      fieldName: 'Name',
    );
    if (name != null) {
      errorMessage.value = name;
      return false;
    }
    final username = requiredValidator(
      branchAdminUserNameController.text,
      fieldName: 'Username',
    );
    if (username != null) {
      errorMessage.value = username;
      return false;
    }
    final emailError = emailValidator(
      branchAdminEmailController.text,
      fieldName: 'Email',
    );
    if (emailError != null) {
      errorMessage.value = emailError;
      return false;
    }
    if (branchAdminPasswordController.text.trim().isEmpty) {
      errorMessage.value = 'Password is required';
      return false;
    }
    if (orgAdminPasswordController.text.trim().isEmpty) {
      prepareAdminStep();
    }
    return formKey.currentState?.validate() ?? true;
  }

  Future<bool> continueFromOrganizationStep() async {
    if (!validateStep0()) return false;
    errorMessage.value = '';
    currentStep.value = 1;
    return true;
  }

  Future<bool> continueFromDocumentsStep() async {
    if (!validateDocumentStep()) return false;
    errorMessage.value = '';
    if (subscriptionModes.isEmpty && !isLoadingModes.value) {
      await loadSubscriptionModes();
    }
    currentStep.value = 2;
    return true;
  }

  void _finishSetup(String organizationName) {
    subscriptionPaymentCompleted.value = true;
    adminsCreated.value = true;
    SnackbarHelper.show(
      title: 'Success',
      message: 'Setup completed for $organizationName',
      backgroundColor: Colors.green,
    );
    resetForm();
  }

  /// Creates organization + branch if not already created (e.g. cash flow on final step).
  Future<bool> _ensureFoundation() async {
    if (foundationResult.value != null) return true;
    if (!validateStep0()) return false;
    if (!validateDocumentStep()) return false;

    if (!validatePlanStep()) return false;

    if (requiresSubscriptionPayment && !subscriptionPaymentCompleted.value) {
      errorMessage.value = 'Complete subscription payment first';
      return false;
    }

    try {
      final docs = _documentUploadParams;
      final res = await _repo.setupFoundation(
        request: buildFoundationRequest(),
        logoBytes: logoBytes.value,
        logoFileName: logoFileName.value.isEmpty ? null : logoFileName.value,
        panImageBytes: docs['panImageBytes'] as Uint8List?,
        panImageFileName: docs['panImageFileName'] as String?,
        aadharFrontImageBytes: docs['aadharFrontImageBytes'] as Uint8List?,
        aadharFrontImageFileName: docs['aadharFrontImageFileName'] as String?,
      );
      if (!res.success || res.data == null) {
        errorMessage.value = res.message ?? 'Failed to create organization';
        return false;
      }
      foundationResult.value = res.data!;
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to create organization: ${e.toString()}';
      return false;
    }
  }

  Future<bool> _createAdminsAfterFoundation() async {
    if (adminsCreated.value) return true;
    if (!validateAdminStep()) {
      errorMessage.value = 'Please complete admin user details';
      return false;
    }
    final adminsRequest = buildAdminsRequest();
    if (adminsRequest == null) {
      errorMessage.value = 'Invalid admin request';
      return false;
    }
    final res = await _repo.setupAdmins(
      request: adminsRequest,
      orgAdminPhoto: orgAdminPhoto.value,
      branchAdminPhoto: branchAdminPhoto.value,
    );
    if (!res.success) {
      errorMessage.value = res.message ?? 'Failed to create admin users';
      return false;
    }
    adminsCreated.value = true;
    return true;
  }

  Future<bool> completeSubscriptionPayment() async {
    if (!validatePlanStep()) return false;
    final packageId = selectedPackageId.value!;

    try {
      isProcessingPayment.value = true;
      errorMessage.value = '';

      OrganizationSetupFoundationResponseModel? foundation =
          foundationResult.value;
      Map<String, dynamic>? order;

      if (foundation == null) {
        final method = selectedCheckoutMethod.value;

        if (method != 'CASH' && requiresSubscriptionPayment) {
          final docs = _documentUploadParams;
          final res = await _repo.setupFoundationWithPaymentOrder(
            request: buildFoundationRequest(),
            logoBytes: logoBytes.value,
            logoFileName: logoFileName.value.isEmpty
                ? null
                : logoFileName.value,
            panImageBytes: docs['panImageBytes'] as Uint8List?,
            panImageFileName: docs['panImageFileName'] as String?,
            aadharFrontImageBytes: docs['aadharFrontImageBytes'] as Uint8List?,
            aadharFrontImageFileName:
                docs['aadharFrontImageFileName'] as String?,
          );
          if (!res.success || res.data == null) {
            errorMessage.value =
                res.message ?? 'Failed to create organization/payment order';
            return false;
          }
          foundation = res.data!.foundation;
          order = res.data!.paymentOrder;
          foundationResult.value = foundation;
        }
      }

      if (!requiresSubscriptionPayment ||
          selectedCheckoutMethod.value == 'CASH') {
        subscriptionPaymentCompleted.value = true;
        prepareAdminStep();
        currentStep.value = 3;
        SnackbarHelper.show(
          title: 'Payment recorded',
          message: 'Create admin users to complete setup.',
          backgroundColor: Colors.green,
        );
        return true;
      }

      if (foundation == null) {
        errorMessage.value = 'Organization was not created for payment';
        return false;
      }

      if (order == null) {
        final orderResp = await _paymentRepo.createSubscriptionOrder(
          organizationId: foundation.organization.id,
          packageId: packageId,
          branchId: foundation.branch.id,
        );
        if (!orderResp.success || orderResp.data == null) {
          errorMessage.value =
              orderResp.message ?? 'Failed to create payment order';
          return false;
        }
        order = orderResp.data!;
      }
      if (order.isEmpty) {
        errorMessage.value = 'Failed to create payment order';
        return false;
      }

      final orderId = order['orderId']?.toString() ?? '';
      final key = order['key']?.toString() ?? '';
      final amount = order['amount'] is int
          ? order['amount'] as int
          : int.tryParse(order['amount']?.toString() ?? '') ?? 0;
      final mockMode = order['mockMode'] == true;

      final paymentResult = await _razorpayCheckout.openCheckout(
        keyId: key,
        orderId: orderId,
        amountPaise: amount,
        description: selectedPackage?.name ?? 'Subscription',
        mockMode: mockMode,
      );

      final verifyResp = await _paymentRepo.verifySubscriptionPayment(
        organizationId: foundation.organization.id,
        orderId: paymentResult['razorpay_order_id'] ?? orderId,
        paymentId: paymentResult['razorpay_payment_id'] ?? '',
        signature: paymentResult['razorpay_signature'] ?? '',
      );

      if (!verifyResp.success) {
        errorMessage.value =
            verifyResp.message ?? 'Payment verification failed';
        return false;
      }

      subscriptionPaymentCompleted.value = true;
      prepareAdminStep();
      currentStep.value = 3;
      SnackbarHelper.show(
        title: 'Payment successful',
        message: 'Create admin users to complete setup.',
        backgroundColor: Colors.green,
      );
      return true;
    } catch (e) {
      errorMessage.value = 'Payment failed: ${e.toString()}';
      return false;
    } finally {
      isProcessingPayment.value = false;
      _razorpayCheckout.dispose();
    }
  }

  void goBackStep() {
    if (currentStep.value <= 0) return;
    currentStep.value = currentStep.value - 1;
  }

  bool get canOpenAdminStep {
    if (requiresSubscriptionPayment && !subscriptionPaymentCompleted.value) {
      return false;
    }
    return true;
  }

  void continueToAdminStep() {
    if (!canOpenAdminStep) {
      errorMessage.value = 'Complete subscription payment first';
      return;
    }
    errorMessage.value = '';
    prepareAdminStep();
    currentStep.value = 3;
  }

  Future<void> goToStep(int step) async {
    if (step == currentStep.value) return;
    if (step < 0 || step > 3) return;

    if (step == 0) {
      currentStep.value = 0;
      errorMessage.value = '';
      return;
    }

    if (step == 1) {
      if (currentStep.value > 1) {
        currentStep.value = 1;
        errorMessage.value = '';
        return;
      }
      await continueFromOrganizationStep();
      return;
    }

    if (step == 2) {
      if (currentStep.value > 2) {
        currentStep.value = 2;
        errorMessage.value = '';
        return;
      }
      if (currentStep.value == 0) {
        final okOrg = await continueFromOrganizationStep();
        if (!okOrg) return;
      }
      await continueFromDocumentsStep();
      return;
    }

    if (step == 3) {
      if (currentStep.value == 0) {
        final okOrg = await continueFromOrganizationStep();
        if (!okOrg) return;
      }
      if (currentStep.value <= 1) {
        final okDocs = await continueFromDocumentsStep();
        if (!okDocs) return;
      }
      if (!canOpenAdminStep) {
        errorMessage.value = 'Complete subscription payment first';
        return;
      }
      prepareAdminStep();
      currentStep.value = 3;
      errorMessage.value = '';
    }
  }

  Future<bool> submitAdminUsers() async {
    if (!validateAdminStep()) return false;
    if (requiresSubscriptionPayment && !subscriptionPaymentCompleted.value) {
      errorMessage.value = 'Complete subscription payment first';
      return false;
    }

    if (adminsCreated.value && foundationResult.value != null) {
      _finishSetup(foundationResult.value!.organization.organizationName);
      return true;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // 1) Foundation API — organization + branch
      if (!await _ensureFoundation()) return false;

      // 2) Setup API — admin users
      if (!await _createAdminsAfterFoundation()) return false;

      final orgName = foundationResult.value!.organization.organizationName;
      isLoading.value = false;
      _finishSetup(orgName);
      return true;
    } catch (e) {
      errorMessage.value = 'Setup failed: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> submitSetup() async {
    if (currentStep.value == 0) {
      return continueFromOrganizationStep();
    }
    if (currentStep.value == 1) {
      return continueFromDocumentsStep();
    }
    if (currentStep.value == 3) {
      return submitAdminUsers();
    }
    return completeSubscriptionPayment();
  }
}
