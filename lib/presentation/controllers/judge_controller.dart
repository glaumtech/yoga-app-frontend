import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/judge_model.dart';
import '../../data/repositories/judge_repository.dart';
import 'auth_controller.dart';

class JudgeController extends GetxController {
  final JudgeRepository _judgeRepository = JudgeRepository();
  final AuthController _authController = Get.find<AuthController>();
  final RxList<JudgeModel> judges = <JudgeModel>[].obs;
  final Rx<JudgeModel?> selectedJudge = Rx<JudgeModel?>(null);
  final Rx<JudgeModel?> currentJudge = Rx<JudgeModel?>(null);
  final RxString currentUserId =
      ''.obs; // Track current user ID to detect changes
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Search
  final RxString searchQuery = ''.obs;

  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Edit mode state
  final Rx<JudgeModel?> judgeToEdit = Rx<JudgeModel?>(null);
  bool get isEditMode => judgeToEdit.value != null;

  @override
  void onInit() {
    super.onInit();
    // Clear any existing data
    judges.clear();
    searchQuery.value = '';
    errorMessage.value = '';
    // Don't load judges automatically - only load when needed
  }

  @override
  void onClose() {
    nameController.dispose();
    addressController.dispose();
    designationController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Initialize form for editing a judge
  void initializeFormForEdit(JudgeModel judge) {
    judgeToEdit.value = judge;
    nameController.text = judge.name;
    addressController.text = judge.address;
    designationController.text = judge.designation;
    usernameController.text = judge.username;
    emailController.text = judge.email ?? '';
    passwordController.clear();
    confirmPasswordController.clear();
    errorMessage.value = '';
  }

  /// Reset form to initial state
  void resetForm() {
    judgeToEdit.value = null;
    nameController.clear();
    addressController.clear();
    designationController.clear();
    usernameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    errorMessage.value = '';
  }

  /// Validate form fields
  String? validateForm() {
    if (nameController.text.trim().isEmpty) {
      return 'Name is required';
    }
    if (designationController.text.trim().isEmpty) {
      return 'Designation is required';
    }
    if (usernameController.text.trim().isEmpty) {
      return 'Username is required';
    }
    // Address is optional - no validation needed

    // Validate password for new judges
    if (!isEditMode) {
      if (passwordController.text.isEmpty) {
        return 'Password is required for new judges';
      }
      if (confirmPasswordController.text.isEmpty) {
        return 'Please confirm password';
      }
    }

    // Validate password match
    if (passwordController.text.isNotEmpty &&
        passwordController.text != confirmPasswordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Build JudgeModel from form data
  JudgeModel buildJudgeModelFromForm() {
    return JudgeModel(
      id: judgeToEdit.value?.id,
      name: nameController.text.trim(),
      address: addressController.text.trim(),
      designation: designationController.text.trim(),
      username: usernameController.text.trim(),
      email: emailController.text.trim().isNotEmpty
          ? emailController.text.trim()
          : null,
      password: passwordController.text.isNotEmpty
          ? passwordController.text
          : null,
      confirmPassword: confirmPasswordController.text.isNotEmpty
          ? confirmPasswordController.text
          : null,
      role: 'judge',
    );
  }

  /// Submit form (create or update)
  Future<bool> submitForm() async {
    // Clear previous error
    errorMessage.value = '';

    // Validate form
    final validationError = validateForm();
    if (validationError != null) {
      errorMessage.value = validationError;
      return false;
    }

    // Build judge model from form
    final judge = buildJudgeModelFromForm();

    // Create or update
    bool success;
    if (isEditMode) {
      success = await updateJudge(judge);
    } else {
      success = await createJudge(judge);
    }

    // Reset form if successful
    if (success) {
      errorMessage.value = '';
      resetForm();
    }

    return success;
  }

  Future<void> loadJudges() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _judgeRepository.getAllJudges();

      if (response.success && response.data != null) {
        judges.value = response.data!;
      } else {
        errorMessage.value = response.message ?? 'Failed to load judges';
        Get.snackbar('Error', errorMessage.value);
      }
    } catch (e) {
      errorMessage.value = 'Failed to load judges: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadJudgeById(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _judgeRepository.getJudgeById(id);

      if (response.success && response.data != null) {
        selectedJudge.value = response.data!;
      } else {
        errorMessage.value = response.message ?? 'Failed to load judge';
        Get.snackbar('Error', errorMessage.value);
      }
    } catch (e) {
      errorMessage.value = 'Failed to load judge: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createJudge(JudgeModel judge) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _judgeRepository.createJudge(judge);

      if (response.success) {
        await loadJudges(); // Reload list after creation
        Get.snackbar('Success', 'Judge created successfully');
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to create judge';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Failed to create judge: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateJudge(JudgeModel judge) async {
    try {
      if (judge.id == null) {
        errorMessage.value = 'Judge ID is required for update';
        return false;
      }

      isLoading.value = true;
      errorMessage.value = '';

      final response = await _judgeRepository.updateJudge(
        id: judge.id!,
        judge: judge,
      );

      if (response.success) {
        await loadJudges(); // Reload list after update
        Get.snackbar('Success', 'Judge updated successfully');
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to update judge';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Failed to update judge: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteJudge(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _judgeRepository.deleteJudge(id);

      if (response.success) {
        await loadJudges(); // Reload list after deletion
        Get.snackbar('Success', 'Judge deleted successfully');
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to delete judge';
        Get.snackbar('Error', errorMessage.value);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Failed to delete judge: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void selectJudge(JudgeModel judge) {
    selectedJudge.value = judge;
  }

  List<JudgeModel> get filteredJudges {
    if (searchQuery.value.isEmpty) {
      return judges;
    }
    final query = searchQuery.value.toLowerCase();
    return judges.where((judge) {
      return judge.name.toLowerCase().contains(query) ||
          judge.username.toLowerCase().contains(query) ||
          judge.designation.toLowerCase().contains(query) ||
          judge.address.toLowerCase().contains(query) ||
          (judge.email != null && judge.email!.toLowerCase().contains(query));
    }).toList();
  }

  /// Get judge by user ID
  Future<JudgeModel?> getJudgeByUserId(String userId) async {
    try {
      final response = await _judgeRepository.getJudgeByUserId(userId);
      if (response.success && response.data != null) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Error getting judge by user ID: $e');
      return null;
    }
  }

  /// Load current judge for the logged-in user
  Future<void> loadCurrentJudge() async {
    final user = _authController.currentUser.value;
    if (user != null) {
      final userId = user.id.toString();
      // Always reload if user has changed or judge is null
      if (currentUserId.value != userId || currentJudge.value == null) {
        currentUserId.value = userId;
        final judge = await getJudgeByUserId(userId);
        currentJudge.value = judge;
      }
    } else {
      currentJudge.value = null;
      currentUserId.value = '';
    }
  }

  /// Clear current judge
  void clearCurrentJudge() {
    currentJudge.value = null;
    currentUserId.value = '';
  }

  void reset() {
    judges.clear();
    selectedJudge.value = null;
    currentJudge.value = null;
    currentUserId.value = '';
    isLoading.value = false;
    errorMessage.value = '';
    searchQuery.value = '';
    resetForm();
  }
}
