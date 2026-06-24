import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/password_reset_repository.dart';
import '../../routes/app_routes.dart';

class PasswordResetController extends GetxController {
  final PasswordResetRepository _repository = PasswordResetRepository();

  final forgotPasswordFormKey = GlobalKey<FormState>();
  final verifyOtpFormKey = GlobalKey<FormState>();
  final resetPasswordFormKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString resetUsername = ''.obs;
  final RxString resetEmail = ''.obs;
  final RxString resetToken = ''.obs;

  final RxBool obscureNewPassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;

  final RxInt resendSecondsRemaining = 0.obs;
  Timer? _resendTimer;

  static const int resendCooldownSeconds = 60;

  @override
  void onClose() {
    _resendTimer?.cancel();
    usernameController.dispose();
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void setEmailFromRoute(String? email) {
    if (email != null && email.trim().isNotEmpty) {
      resetEmail.value = email.trim();
      if (emailController.text.trim().isEmpty) {
        emailController.text = email.trim();
      }
    }
  }

  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your username';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!GetUtils.isEmail(value.trim())) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the OTP';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'OTP must be a 6-digit number';
    }
    return null;
  }

  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain an uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain a lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain a special character';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void toggleNewPasswordVisibility() {
    obscureNewPassword.value = !obscureNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  void startResendTimer() {
    _resendTimer?.cancel();
    resendSecondsRemaining.value = resendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSecondsRemaining.value <= 1) {
        resendSecondsRemaining.value = 0;
        timer.cancel();
      } else {
        resendSecondsRemaining.value--;
      }
    });
  }

  void clearForgotPasswordForm({bool endFlow = false}) {
    usernameController.clear();
    emailController.clear();
    errorMessage.value = '';

    if (endFlow) {
      resetUsername.value = '';
      resetEmail.value = '';
      resetToken.value = '';
      otpController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      _resendTimer?.cancel();
      resendSecondsRemaining.value = 0;
    }
  }

  static const String usernameEmailMismatchMessage =
      'Username and email do not match. Please verify your details and try again.';

  Future<void> handleForgotPassword(BuildContext context) async {
    if (forgotPasswordFormKey.currentState?.validate() != true) return;

    isLoading.value = true;
    errorMessage.value = '';

    final userName = usernameController.text.trim();
    final email = emailController.text.trim();
    final response = await _repository.forgotPassword(
      userName: userName,
      email: email,
    );

    isLoading.value = false;

    if (response.success) {
      resetUsername.value = userName;
      resetEmail.value = email;
      startResendTimer();
      clearForgotPasswordForm();
      if (context.mounted) {
        await _showSuccessDialog(
          context,
          title: 'OTP Sent',
          message: response.message ?? 'OTP has been sent to your email.',
        );
        if (context.mounted) {
          context.go(AppRoutes.verifyOtp);
        }
      }
    } else if (_isUsernameEmailMismatch(response.message)) {
      if (context.mounted) {
        await _showMismatchDialog(context);
      }
    } else {
      errorMessage.value =
          response.message ?? 'Unable to send OTP. Please try again.';
    }
  }

  bool _isUsernameEmailMismatch(String? message) {
    if (message == null || message.trim().isEmpty) {
      return false;
    }
    final normalized = message.toLowerCase();
    return normalized.contains('do not match') ||
        normalized.contains('username and email');
  }

  Future<void> _showMismatchDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Details Mismatch'),
        content: const Text(usernameEmailMismatchMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              clearForgotPasswordForm();
              if (context.mounted) {
                context.go(AppRoutes.forgotPassword);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> handleResendOtp(BuildContext context) async {
    if (resendSecondsRemaining.value > 0) return;

    final userName = resetUsername.value.isNotEmpty
        ? resetUsername.value
        : usernameController.text.trim();
    final email = resetEmail.value.isNotEmpty
        ? resetEmail.value
        : emailController.text.trim();
    if (userName.isEmpty || email.isEmpty) {
      errorMessage.value = 'Username and email are required to resend OTP';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    final response = await _repository.forgotPassword(
      userName: userName,
      email: email,
    );
    isLoading.value = false;

    if (response.success) {
      resetUsername.value = userName;
      resetEmail.value = email;
      startResendTimer();
      if (context.mounted) {
        await _showSuccessDialog(
          context,
          title: 'OTP Resent',
          message: response.message ?? 'A new OTP has been sent to your email.',
        );
      }
    } else {
      errorMessage.value =
          response.message ?? 'Unable to resend OTP. Please try again.';
    }
  }

  Future<void> handleVerifyOtp(BuildContext context) async {
    if (verifyOtpFormKey.currentState?.validate() != true) return;

    final email = resetEmail.value.isNotEmpty
        ? resetEmail.value
        : emailController.text.trim();
    if (email.isEmpty) {
      errorMessage.value = 'Email is required';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    final response = await _repository.verifyOtp(
      email: email,
      otp: otpController.text.trim(),
    );

    isLoading.value = false;

    if (response.success && response.data != null && response.data!.isNotEmpty) {
      resetEmail.value = email;
      resetToken.value = response.data!;
      if (context.mounted) {
        await _showSuccessDialog(
          context,
          title: 'OTP Verified',
          message: response.message ?? 'OTP verified successfully.',
        );
        if (context.mounted) {
          context.go(AppRoutes.resetPassword);
        }
      }
    } else {
      errorMessage.value =
          response.message ?? 'Invalid or expired OTP. Please try again.';
    }
  }

  Future<void> handleResetPassword(BuildContext context) async {
    if (resetPasswordFormKey.currentState?.validate() != true) return;

    final userName = resetUsername.value;
    final email = resetEmail.value;
    final token = resetToken.value;
    if (userName.isEmpty || email.isEmpty || token.isEmpty) {
      errorMessage.value =
          'Session expired. Please restart the password reset flow.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    final response = await _repository.resetPassword(
      userName: userName,
      email: email,
      resetToken: token,
      newPassword: newPasswordController.text,
      confirmPassword: confirmPasswordController.text,
    );

    isLoading.value = false;

    if (response.success) {
      _clearFlowState();
      if (context.mounted) {
        await _showSuccessDialog(
          context,
          title: 'Password Reset',
          message: response.message ?? 'Password reset successfully.',
          onOk: () {
            if (context.mounted) {
              context.go(AppRoutes.login);
            }
          },
        );
        if (context.mounted) {
          context.go(AppRoutes.login);
        }
      }
    } else if (_isUsernameEmailMismatch(response.message)) {
      if (context.mounted) {
        await _showMismatchDialog(context);
      }
    } else {
      errorMessage.value =
          response.message ?? 'Unable to reset password. Please try again.';
    }
  }

  void _clearFlowState() {
    resetUsername.value = '';
    resetEmail.value = '';
    resetToken.value = '';
    usernameController.clear();
    emailController.clear();
    otpController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    _resendTimer?.cancel();
    resendSecondsRemaining.value = 0;
  }

  Future<void> _showSuccessDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onOk,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onOk?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
