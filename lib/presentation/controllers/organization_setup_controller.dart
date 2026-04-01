import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/api_response.dart';
import '../../data/models/organization_setup_model.dart';
import '../../data/repositories/organization_setup_repository.dart';

class OrganizationSetupController extends GetxController {
  final OrganizationSetupRepository _repo = OrganizationSetupRepository();
  final ImagePicker _imagePicker = ImagePicker();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<OrganizationSetupResponseModel?> lastResult =
      Rx<OrganizationSetupResponseModel?>(null);

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Organization
  final TextEditingController organizationNameController =
      TextEditingController();
  final TextEditingController organizationCodeController =
      TextEditingController();

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

    errorMessage.value = '';
  }

  OrganizationSetupRequestModel buildRequestFromForm() {
    final org = OrganizationRequestModel(
      organizationName: organizationNameController.text.trim(),
      organizationCode: organizationCodeController.text.trim().isEmpty
          ? null
          : organizationCodeController.text.trim(),
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
    );
  }

  Future<bool> submitSetup() async {
    final valid = formKey.currentState?.validate() ?? false;
    if (!valid) return false;

    final setupRequest = buildRequestFromForm();
    return setupOrganization(
      setupRequest: setupRequest,
      logoBytes: logoBytes.value,
      logoFileName: logoFileName.value.isEmpty ? null : logoFileName.value,
    );
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

