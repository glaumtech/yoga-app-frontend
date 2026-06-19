import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/password_reset_controller.dart';
import '../../widgets/auth_flow_scaffold.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final PasswordResetController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<PasswordResetController>()) {
      controller = Get.find<PasswordResetController>();
    } else {
      controller = Get.put(PasswordResetController(), permanent: false);
    }
    if (controller.resetUsername.value.isEmpty ||
        controller.resetEmail.value.isEmpty ||
        controller.resetToken.value.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(AppRoutes.forgotPassword);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFlowScaffold(
      title: 'Reset Password',
      subtitle: 'Create a new secure password for your account',
      child: Form(
        key: controller.resetPasswordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => (controller.resetUsername.value.isNotEmpty ||
                      controller.resetEmail.value.isNotEmpty)
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          if (controller.resetUsername.value.isNotEmpty)
                            Text(
                              'Username: ${controller.resetUsername.value}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          if (controller.resetEmail.value.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Email: ${controller.resetEmail.value}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Obx(
              () => TextFormField(
                controller: controller.newPasswordController,
                obscureText: controller.obscureNewPassword.value,
                textInputAction: TextInputAction.next,
                decoration: authInputDecoration(
                  label: 'New Password',
                  icon: Icons.lock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscureNewPassword.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey[600],
                    ),
                    onPressed: controller.toggleNewPasswordVisibility,
                  ),
                ),
                validator: controller.validateNewPassword,
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => TextFormField(
                controller: controller.confirmPasswordController,
                obscureText: controller.obscureConfirmPassword.value,
                textInputAction: TextInputAction.done,
                decoration: authInputDecoration(
                  label: 'Confirm Password',
                  icon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscureConfirmPassword.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey[600],
                    ),
                    onPressed: controller.toggleConfirmPasswordVisibility,
                  ),
                ),
                validator: controller.validateConfirmPassword,
                onFieldSubmitted: (_) {
                  if (!controller.isLoading.value) {
                    controller.handleResetPassword(context);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Password must be at least 8 characters with uppercase, lowercase, number, and special character.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 16),
            Obx(
              () => controller.errorMessage.value.isNotEmpty
                  ? authErrorBanner(controller.errorMessage.value)
                  : const SizedBox.shrink(),
            ),
            Obx(
              () => authPrimaryButton(
                isLoading: controller.isLoading.value,
                label: 'Reset Password',
                onPressed: controller.isLoading.value
                    ? null
                    : () => controller.handleResetPassword(context),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go(AppRoutes.login),
              child: Text(
                'Back to Sign In',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
