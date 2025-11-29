import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:yoga_champ/core/utils/storage_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../core/constants/app_constants.dart';
import '../../routes/app_routes.dart';
import 'admin_controller.dart';
import 'participant_controller.dart';
import 'event_controller.dart';
import 'judge_controller.dart';
import 'scoring_controller.dart';
import 'team_controller.dart';
import 'participant_assignment_controller.dart';
import 'judge_assigned_participants_controller.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Login form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  // Login form state
  final selectedRole = AppConstants.roleUser.obs;
  final obscurePassword = true.obs;

  // Signup form controllers
  final signUpNameController = TextEditingController();
  final signUpEmailController = TextEditingController();
  final signUpPasswordController = TextEditingController();
  final signUpConfirmPasswordController = TextEditingController();
  final signUpPhoneController = TextEditingController();
  final signUpFormKey = GlobalKey<FormState>();

  // Signup form state
  final signUpSelectedRole = AppConstants.roleUser.obs;
  final signUpObscurePassword = true.obs;
  final signUpObscureConfirmPassword = true.obs;

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    signUpNameController.dispose();
    signUpEmailController.dispose();
    signUpPasswordController.dispose();
    signUpConfirmPasswordController.dispose();
    signUpPhoneController.dispose();
    super.onClose();
  }

  Future<void> checkAuthStatus() async {
    final user = await _authRepository.getCurrentUser();
    if (user != null) {
      currentUser.value = user;

      // Reload events if user is authenticated
      try {
        if (Get.isRegistered<EventController>()) {
          final eventController = Get.find<EventController>();
          if (eventController.events.isEmpty) {
            eventController.loadEvents();
          }
        }
      } catch (e) {
        // EventController might not be registered, ignore
      }
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    required String username,
    required String role,
    String? phoneNo,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _authRepository.signUp(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        username: username,
        role: role,
        phoneNo: phoneNo,
      );

      if (response.success && response.data != null) {
        currentUser.value = response.data;
        isLoading.value = false;
        return true;
      } else {
        errorMessage.value = response.message ?? 'Sign up failed';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _authRepository.signIn(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        currentUser.value = response.data;
        isLoading.value = false;

        // Reload events after successful login
        try {
          if (Get.isRegistered<EventController>()) {
            Get.find<EventController>().loadEvents();
          }
        } catch (e) {
          // EventController might not be registered, ignore
        }

        return true;
      } else {
        errorMessage.value = response.message ?? 'Sign in failed';
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: ${e.toString()}';
      isLoading.value = false;
      return false;
    }
  }

  // Login form validation
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void setSelectedRole(String role) {
    selectedRole.value = role;
  }

  // Signup form validation
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value != null && value.isNotEmpty) {
      if (!GetUtils.isPhoneNumber(value)) {
        return 'Please enter a valid phone number';
      }
    }
    return null;
  }

  String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  void toggleSignUpPasswordVisibility() {
    signUpObscurePassword.value = !signUpObscurePassword.value;
  }

  void toggleSignUpConfirmPasswordVisibility() {
    signUpObscureConfirmPassword.value = !signUpObscureConfirmPassword.value;
  }

  void setSignUpSelectedRole(String role) {
    signUpSelectedRole.value = role;
  }

  Future<void> handleSignUp(BuildContext context) async {
    if (signUpFormKey.currentState!.validate()) {
      final success = await signUp(
        email: signUpEmailController.text.trim(),
        password: signUpPasswordController.text,
        confirmPassword: signUpConfirmPasswordController.text,
        username: signUpNameController.text.trim(),
        role: signUpSelectedRole.value,
        phoneNo: signUpPhoneController.text.trim().isNotEmpty
            ? signUpPhoneController.text.trim()
            : null,
      );

      if (success && context.mounted) {
        // // Small delay to ensure token is saved
        // await Future.delayed(const Duration(milliseconds: 100));

        // final token = StorageService.getString(AppConstants.tokenKey);
        // print('Token before navigation: ${token != null ? "exists" : "null"}');

        // Navigate to home
        if (context.mounted) {
          try {
            context.go(AppRoutes.login);
          } catch (e) {
            print('Navigation error: $e');
            // Fallback: use GetX navigation
            Get.offAllNamed(AppRoutes.login);
          }
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage.value),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> handleLogin(BuildContext context) async {
    print('handleLogin called ${isLoading.value}');
    // Clear previous error message
    errorMessage.value = '';

    // Ensure form key is initialized
    if (formKey.currentState == null) {
      errorMessage.value = 'Form not initialized. Please refresh the page.';
      return;
    }

    if (formKey.currentState!.validate()) {
      final success = await signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (success && context.mounted) {
        // Small delay to ensure token is saved
        await Future.delayed(const Duration(milliseconds: 100));

        final token = StorageService.getString(AppConstants.tokenKey);
        print('Token before navigation: ${token != null ? "exists" : "null"}');

        // Navigate to home
        if (context.mounted) {
          context.go(AppRoutes.home);
        }
      }
      // Error message is already set in signIn method and will be displayed in the UI
    }
  }

  Future<void> clearLoginData() async {
    emailController.clear();
    passwordController.clear();
    formKey.currentState?.reset();
  }

  Future<void> clearSignUpData() async {
    signUpNameController.clear();
    signUpEmailController.clear();
    signUpPasswordController.clear();
    signUpConfirmPasswordController.clear();
    signUpPhoneController.clear();
    signUpFormKey.currentState?.reset();
  }

  Future<void> signOut() async {
    // Clear current user state first
    currentUser.value = null;
    isLoading.value = false;
    errorMessage.value = '';

    // Reset all controllers to clear app data
    try {
      // Reset Admin Controller
      if (Get.isRegistered<AdminController>()) {
        Get.find<AdminController>().reset();
      }
    } catch (e) {
      // Controller might not be registered, ignore
    }

    try {
      // Reset Participant Controller
      if (Get.isRegistered<ParticipantController>()) {
        Get.find<ParticipantController>().reset();
      }
    } catch (e) {
      // Controller might not be registered, ignore
    }

    // try {
    //   // Reset Event Controller
    //   if (Get.isRegistered<EventController>()) {
    //     Get.find<EventController>().reset();
    //   }
    // } catch (e) {
    //   // Controller might not be registered, ignore
    // }

    try {
      // Reset Judge Controller
      if (Get.isRegistered<JudgeController>()) {
        Get.find<JudgeController>().reset();
      }
    } catch (e) {
      // Controller might not be registered, ignore
    }

    try {
      // Reset Scoring Controller
      if (Get.isRegistered<ScoringController>()) {
        Get.find<ScoringController>().reset();
      }
    } catch (e) {
      // Controller might not be registered, ignore
    }

    try {
      // Reset Team Controller
      if (Get.isRegistered<TeamController>()) {
        Get.find<TeamController>().reset();
      }
    } catch (e) {
      // Controller might not be registered, ignore
    }

    try {
      // Reset Participant Assignment Controller (temporary, but reset if exists)
      if (Get.isRegistered<ParticipantAssignmentController>()) {
        Get.find<ParticipantAssignmentController>().reset();
      }
    } catch (e) {
      // Controller might not be registered, ignore
    }

    try {
      // Reset Judge Assigned Participants Controller (temporary, but reset if exists)
      if (Get.isRegistered<JudgeAssignedParticipantsController>()) {
        Get.find<JudgeAssignedParticipantsController>().reset();
      }
    } catch (e) {
      // Controller might not be registered, ignore
    }

    // Call repository signOut (calls API and clears storage)
    await _authRepository.signOut();

    // Clear all login form data
    clearLoginData();
    clearSignUpData();

    // Reset all form states to defaults
    selectedRole.value = AppConstants.roleUser;
    signUpSelectedRole.value = AppConstants.roleUser;
    obscurePassword.value = true;
    signUpObscurePassword.value = true;
    signUpObscureConfirmPassword.value = true;
  }

  bool get isAuthenticated => currentUser.value != null;
  bool get isAdmin =>
      currentUser.value?.roleName.toUpperCase().contains('ADMIN') ?? false;
  bool get isUser =>
      currentUser.value?.roleName.toUpperCase().contains('USER') ?? false;
}
