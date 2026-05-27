import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/api_response.dart';
import '../../data/models/app_permission_record_model.dart';
import '../../data/models/organization_setup_model.dart';
import '../../data/models/subscription_package_model.dart';
import '../../data/repositories/organization_setup_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/permission_repository.dart';
import '../../services/razorpay_checkout_service.dart';

class OrganizationSetupController extends GetxController {
  final OrganizationSetupRepository _repo = OrganizationSetupRepository();
  final PermissionRepository _permissionRepo = PermissionRepository();
  final PaymentRepository _paymentRepo = PaymentRepository();
  final RazorpayCheckoutService _razorpayCheckout = RazorpayCheckoutService();
  final ImagePicker _imagePicker = ImagePicker();

  /// 0 = org/branch/package, 1 = subscription payment, 2 = admin users
  final RxInt currentStep = 0.obs;
  final Rx<OrganizationSetupFoundationResponseModel?> foundationResult =
      Rx<OrganizationSetupFoundationResponseModel?>(null);
  final RxBool subscriptionPaymentCompleted = false.obs;
  final RxBool isProcessingPayment = false.obs;
  final RxString selectedCheckoutMethod = 'RAZORPAY'.obs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<OrganizationSetupResponseModel?> lastResult =
      Rx<OrganizationSetupResponseModel?>(null);

  final RxBool isLoadingPermissions = false.obs;
  final RxString permissionsError = ''.obs;
  final RxList<AppPermissionRecord> permissions = <AppPermissionRecord>[].obs;

  // Selected permission IDs for each admin type (saved as user-type permissions for the created branch).
  final RxSet<int> orgAdminPermissionIds = <int>{}.obs;
  final RxSet<int> branchAdminPermissionIds = <int>{}.obs;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Organization
  final TextEditingController organizationNameController =
      TextEditingController();
  final TextEditingController organizationCodeController =
      TextEditingController();
  final RxBool isLoadingPackages = false.obs;
  final RxString packagesError = ''.obs;
  final RxList<SubscriptionPackageModel> subscriptionPackages =
      <SubscriptionPackageModel>[].obs;
  final RxnInt selectedPackageId = RxnInt();
  final RxString selectedPaymentModel = ''.obs;
  final TextEditingController manualPaymentUpiIdController =
      TextEditingController();
  final TextEditingController manualPaymentQrPathController =
      TextEditingController();
  final TextEditingController subscriptionCreditsController =
      TextEditingController();
  final TextEditingController packCreditsController = TextEditingController();

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
  final TextEditingController stateIdController = TextEditingController();
  final TextEditingController cityIdController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
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
  final TextEditingController branchAdminPasswordController =
      TextEditingController();

  // Logo
  final Rx<Uint8List?> logoBytes = Rx<Uint8List?>(null);
  final RxString logoFileName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadPermissions();
    loadSubscriptionPackages();
  }

  @override
  void onClose() {
    organizationNameController.dispose();
    organizationCodeController.dispose();
    manualPaymentUpiIdController.dispose();
    manualPaymentQrPathController.dispose();
    subscriptionCreditsController.dispose();
    packCreditsController.dispose();
    branchNameController.dispose();
    branchCodeController.dispose();
    commencingYearController.dispose();
    emailController.dispose();
    phoneNoController.dispose();
    mobileNoController.dispose();
    websiteUrlController.dispose();
    countryController.dispose();
    stateIdController.dispose();
    cityIdController.dispose();
    addressController.dispose();
    pincodeController.dispose();
    themeController.dispose();
    orgAdminNameController.dispose();
    orgAdminUserNameController.dispose();
    orgAdminPasswordController.dispose();
    branchAdminNameController.dispose();
    branchAdminUserNameController.dispose();
    branchAdminPasswordController.dispose();
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

  void resetForm() {
    formKey.currentState?.reset();

    organizationNameController.clear();
    organizationCodeController.clear();
    selectedPackageId.value = null;
    selectedPaymentModel.value = '';
    manualPaymentUpiIdController.clear();
    manualPaymentQrPathController.clear();
    subscriptionCreditsController.clear();
    packCreditsController.clear();

    branchNameController.clear();
    branchCodeController.clear();
    commencingYearController.clear();
    emailController.clear();
    phoneNoController.clear();
    mobileNoController.clear();
    websiteUrlController.clear();
    countryController.clear();
    stateIdController.clear();
    cityIdController.clear();
    addressController.clear();
    pincodeController.clear();
    themeController.clear();

    orgAdminNameController.clear();
    orgAdminUserNameController.clear();
    orgAdminPasswordController.clear();

    branchAdminNameController.clear();
    branchAdminUserNameController.clear();
    branchAdminPasswordController.clear();

    clearLogo();

    orgAdminPermissionIds.clear();
    branchAdminPermissionIds.clear();

    errorMessage.value = '';
    currentStep.value = 0;
    foundationResult.value = null;
    subscriptionPaymentCompleted.value = false;
    selectedCheckoutMethod.value = 'RAZORPAY';
  }

  SubscriptionPackageModel? get selectedPackage =>
      packageById(selectedPackageId.value);

  bool get requiresSubscriptionPayment =>
      selectedPackage?.requiresSubscriptionPayment ?? false;

  String get stepTitle {
    switch (currentStep.value) {
      case 1:
        return 'Subscription Payment';
      case 2:
        return 'Admin Users';
      default:
        return 'Organization & Payment Plan';
    }
  }

  Future<void> loadSubscriptionPackages() async {
    if (isLoadingPackages.value) return;
    try {
      isLoadingPackages.value = true;
      packagesError.value = '';
      final res = await _paymentRepo.listAllPackages();
      if (res.success && res.data != null) {
        subscriptionPackages.assignAll(res.data!);
        if (subscriptionPackages.isNotEmpty) {
          final current = selectedPackageId.value;
          final stillValid = current != null &&
              subscriptionPackages.any((p) => p.id == current);
          if (!stillValid) {
            applySelectedPackage(subscriptionPackages.first.id);
          }
        } else {
          selectedPackageId.value = null;
          selectedPaymentModel.value = '';
        }
      } else {
        packagesError.value =
            res.message ?? 'Failed to load subscription packages';
        subscriptionPackages.clear();
      }
    } catch (e) {
      packagesError.value =
          'Failed to load subscription packages: ${e.toString()}';
      subscriptionPackages.clear();
    } finally {
      isLoadingPackages.value = false;
    }
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
    if (pkg.paymentModel == 'USER_PACK_SUBSCRIPTION') {
      packCreditsController.text = pkg.credits.toString();
      subscriptionCreditsController.clear();
    } else if (pkg.paymentModel == 'ORG_SUBSCRIPTION') {
      subscriptionCreditsController.text = pkg.credits.toString();
      packCreditsController.clear();
    } else {
      subscriptionCreditsController.clear();
      packCreditsController.clear();
    }
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
      } else {
        permissionsError.value =
            res.message ?? 'Failed to load permissions';
      }
    } catch (e) {
      permissionsError.value = 'Failed to load permissions: ${e.toString()}';
    } finally {
      isLoadingPermissions.value = false;
    }
  }

  OrganizationSetupFoundationRequestModel buildFoundationRequest() {
    final org = OrganizationRequestModel(
      organizationName: organizationNameController.text.trim(),
      organizationCode: organizationCodeController.text.trim().isEmpty
          ? null
          : organizationCodeController.text.trim(),
      paymentModel: selectedPaymentModel.value.isEmpty
          ? null
          : selectedPaymentModel.value,
      manualPaymentUpiId: manualPaymentUpiIdController.text.trim().isEmpty
          ? null
          : manualPaymentUpiIdController.text.trim(),
      manualPaymentQrImagePath: manualPaymentQrPathController.text.trim().isEmpty
          ? null
          : manualPaymentQrPathController.text.trim(),
      subscriptionCreditsRemaining:
          _tryParseNullableInt(subscriptionCreditsController.text),
      packCreditsRemaining: _tryParseNullableInt(packCreditsController.text),
    );

    final branch = BranchRequestModel(
      branchName: branchNameController.text.trim(),
      branchCode: branchCodeController.text.trim().isEmpty
          ? null
          : branchCodeController.text.trim(),
      commencingYear: _tryParseNullableInt(commencingYearController.text),
      email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
      phoneNo: phoneNoController.text.trim().isEmpty ? null : phoneNoController.text.trim(),
      mobileNo: mobileNoController.text.trim().isEmpty ? null : mobileNoController.text.trim(),
      websiteUrl: websiteUrlController.text.trim().isEmpty
          ? null
          : websiteUrlController.text.trim(),
      country: countryController.text.trim().isEmpty ? null : countryController.text.trim(),
      stateId: _tryParseNullableInt(stateIdController.text),
      cityId: _tryParseNullableInt(cityIdController.text),
      address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
      pincode: pincodeController.text.trim().isEmpty ? null : pincodeController.text.trim(),
      theme: themeController.text.trim().isEmpty ? null : themeController.text.trim(),
    );

    return OrganizationSetupFoundationRequestModel(
      organization: org,
      branch: branch,
      selectedPackageId: selectedPackageId.value,
    );
  }

  OrganizationSetupAdminsRequestModel? buildAdminsRequest() {
    final foundation = foundationResult.value;
    if (foundation == null) return null;

    return OrganizationSetupAdminsRequestModel(
      organizationId: foundation.organization.id,
      branchId: foundation.branch.id,
      orgAdminUser: SetupAdminUserRequestModel(
        name: orgAdminNameController.text.trim(),
        userName: orgAdminUserNameController.text.trim(),
        password: orgAdminPasswordController.text,
      ),
      branchAdminUser: SetupAdminUserRequestModel(
        name: branchAdminNameController.text.trim(),
        userName: branchAdminUserNameController.text.trim(),
        password: branchAdminPasswordController.text,
      ),
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
    final branchName = requiredValidator(
      branchNameController.text,
      fieldName: 'Branch name',
    );
    if (branchName != null) {
      errorMessage.value = branchName;
      return false;
    }
    final pkgErr = subscriptionPackageValidator(selectedPackageId.value);
    if (pkgErr != null) {
      errorMessage.value = pkgErr;
      return false;
    }
    return true;
  }

  bool validateAdminStep() {
    return formKey.currentState?.validate() ?? false;
  }

  Future<bool> continueFromOrganizationStep() async {
    if (!validateStep0()) return false;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final request = buildFoundationRequest();
      final res = await _repo.setupFoundation(
        request: request,
        logoBytes: logoBytes.value,
        logoFileName: logoFileName.value.isEmpty ? null : logoFileName.value,
      );

      if (!res.success || res.data == null) {
        errorMessage.value = res.message ?? 'Failed to create organization';
        return false;
      }

      foundationResult.value = res.data;
      subscriptionPaymentCompleted.value = !requiresSubscriptionPayment;

      if (requiresSubscriptionPayment) {
        currentStep.value = 1;
      } else {
        currentStep.value = 2;
      }
      return true;
    } catch (e) {
      errorMessage.value = 'Setup failed: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> completeSubscriptionPayment() async {
    final foundation = foundationResult.value;
    final packageId = selectedPackageId.value;
    if (foundation == null || packageId == null) {
      errorMessage.value = 'Organization or package is missing';
      return false;
    }

    // Manual/offline confirmation path for branch operators.
    if (selectedCheckoutMethod.value == 'CASH') {
      subscriptionPaymentCompleted.value = true;
      currentStep.value = 2;
      Get.snackbar(
        'Payment marked complete',
        'Cash payment marked as received. Continue to create admin users.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    }

    try {
      isProcessingPayment.value = true;
      errorMessage.value = '';

      final orderResp = await _paymentRepo.createSubscriptionOrder(
        organizationId: foundation.organization.id,
        packageId: packageId,
      );
      if (!orderResp.success || orderResp.data == null) {
        errorMessage.value = orderResp.message ?? 'Failed to create payment order';
        return false;
      }

      final order = orderResp.data!;
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
        description: selectedCheckoutMethod.value == 'GPAY'
            ? '${selectedPackage?.name ?? 'Subscription'} (UPI)'
            : (selectedPackage?.name ?? 'Subscription'),
        mockMode: mockMode,
      );

      final verifyResp = await _paymentRepo.verifySubscriptionPayment(
        organizationId: foundation.organization.id,
        orderId: paymentResult['razorpay_order_id'] ?? orderId,
        paymentId: paymentResult['razorpay_payment_id'] ?? '',
        signature: paymentResult['razorpay_signature'] ?? '',
      );

      if (!verifyResp.success) {
        errorMessage.value = verifyResp.message ?? 'Payment verification failed';
        return false;
      }

      subscriptionPaymentCompleted.value = true;
      currentStep.value = 2;
      Get.snackbar(
        'Payment successful',
        'Subscription activated. Continue to create admin users.',
        snackPosition: SnackPosition.BOTTOM,
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
    if (currentStep.value == 2 && requiresSubscriptionPayment) {
      currentStep.value = 1;
    } else {
      currentStep.value = 0;
    }
  }

  Future<bool> submitAdminUsers() async {
    if (!validateAdminStep()) return false;
    if (foundationResult.value == null) {
      errorMessage.value = 'Complete organization setup first';
      return false;
    }
    if (requiresSubscriptionPayment && !subscriptionPaymentCompleted.value) {
      errorMessage.value = 'Complete subscription payment first';
      return false;
    }

    final adminsRequest = buildAdminsRequest();
    if (adminsRequest == null) {
      errorMessage.value = 'Invalid admin request';
      return false;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final res = await _repo.setupAdmins(request: adminsRequest);
      if (!res.success) {
        errorMessage.value = res.message ?? 'Failed to create admin users';
        return false;
      }

      final orgName = foundationResult.value!.organization.organizationName;
      Get.snackbar(
        'Success',
        'Setup completed for $orgName',
        snackPosition: SnackPosition.BOTTOM,
      );
      resetForm();
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to create users: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  OrganizationSetupRequestModel buildRequestFromForm() {
    final org = OrganizationRequestModel(
      organizationName: organizationNameController.text.trim(),
      organizationCode: organizationCodeController.text.trim().isEmpty
          ? null
          : organizationCodeController.text.trim(),
      paymentModel: selectedPaymentModel.value.isEmpty
          ? null
          : selectedPaymentModel.value,
      manualPaymentUpiId: manualPaymentUpiIdController.text.trim().isEmpty
          ? null
          : manualPaymentUpiIdController.text.trim(),
      manualPaymentQrImagePath: manualPaymentQrPathController.text.trim().isEmpty
          ? null
          : manualPaymentQrPathController.text.trim(),
      subscriptionCreditsRemaining:
          _tryParseNullableInt(subscriptionCreditsController.text),
      packCreditsRemaining: _tryParseNullableInt(packCreditsController.text),
    );

    final branch = BranchRequestModel(
      branchName: branchNameController.text.trim(),
      branchCode: branchCodeController.text.trim().isEmpty
          ? null
          : branchCodeController.text.trim(),
      commencingYear: _tryParseNullableInt(commencingYearController.text),
      email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
      phoneNo: phoneNoController.text.trim().isEmpty ? null : phoneNoController.text.trim(),
      mobileNo: mobileNoController.text.trim().isEmpty ? null : mobileNoController.text.trim(),
      websiteUrl: websiteUrlController.text.trim().isEmpty
          ? null
          : websiteUrlController.text.trim(),
      country: countryController.text.trim().isEmpty ? null : countryController.text.trim(),
      stateId: _tryParseNullableInt(stateIdController.text),
      cityId: _tryParseNullableInt(cityIdController.text),
      address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
      pincode: pincodeController.text.trim().isEmpty ? null : pincodeController.text.trim(),
      theme: themeController.text.trim().isEmpty ? null : themeController.text.trim(),
    );

    final orgAdmin = SetupAdminUserRequestModel(
      name: orgAdminNameController.text.trim(),
      userName: orgAdminUserNameController.text.trim(),
      password: orgAdminPasswordController.text,
    );

    final branchAdmin = SetupAdminUserRequestModel(
      name: branchAdminNameController.text.trim(),
      userName: branchAdminUserNameController.text.trim(),
      password: branchAdminPasswordController.text,
    );

    return OrganizationSetupRequestModel(
      organization: org,
      branch: branch,
      orgAdminUser: orgAdmin,
      branchAdminUser: branchAdmin,
      orgAdminPermissionIds: orgAdminPermissionIds.toList()..sort(),
      branchAdminPermissionIds: branchAdminPermissionIds.toList()..sort(),
    );
  }

  Future<bool> submitSetup() async {
    if (currentStep.value == 0) {
      return continueFromOrganizationStep();
    }
    if (currentStep.value == 1) {
      return completeSubscriptionPayment();
    }
    return submitAdminUsers();
  }

  Future<bool> setupOrganization({
    required OrganizationSetupRequestModel setupRequest,
    File? logoFile,
    Uint8List? logoBytes,
    String? logoFileName,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      lastResult.value = null;

      final ApiResponse<OrganizationSetupResponseModel> res =
          await _repo.setupOrganization(
        setupRequest: setupRequest,
        logoFile: logoFile,
        logoBytes: logoBytes,
        logoFileName: logoFileName,
      );

      if (res.success && res.data != null) {
        lastResult.value = res.data;
        final orgName =
            res.data!.organization.organizationName.trim().isNotEmpty
                ? res.data!.organization.organizationName.trim()
                : null;
        Get.snackbar(
          'Success',
          orgName == null
              ? 'Organization setup completed'
              : 'Organization setup completed for $orgName',
          snackPosition: SnackPosition.BOTTOM,
        );
        resetForm();
        return true;
      }

      errorMessage.value = res.message ?? 'Setup failed';
      return false;
    } catch (e) {
      errorMessage.value = 'Setup failed: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}

