import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/password_reset_controller.dart';
import '../../widgets/auth_flow_scaffold.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  late final PasswordResetController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<PasswordResetController>()) {
      controller = Get.find<PasswordResetController>();
    } else {
      controller = Get.put(PasswordResetController(), permanent: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && controller.resetEmail.value.isEmpty) {
          context.go(AppRoutes.forgotPassword);
        }
      });
    }
    if (controller.resetEmail.value.isNotEmpty &&
        controller.emailController.text.isEmpty) {
      controller.emailController.text = controller.resetEmail.value;
    }
    if (controller.resendSecondsRemaining.value == 0 &&
        controller.resetEmail.value.isNotEmpty) {
      controller.startResendTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFlowScaffold(
      title: 'Verify OTP',
      subtitle: 'Enter the 6-digit code sent to your email',
      child: Form(
        key: controller.verifyOtpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => controller.resetEmail.value.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'OTP sent to: ${controller.resetEmail.value}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : TextFormField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: authInputDecoration(
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                      ),
                      validator: controller.validateEmail,
                    ),
            ),
            TextFormField(
              controller: controller.otpController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: authInputDecoration(
                label: 'OTP',
                icon: Icons.pin_outlined,
              ).copyWith(hintText: '000000'),
              validator: controller.validateOtp,
              onFieldSubmitted: (_) {
                if (!controller.isLoading.value) {
                  controller.handleVerifyOtp(context);
                }
              },
            ),
            const SizedBox(height: 16),
            Obx(
              () {
                final seconds = controller.resendSecondsRemaining.value;
                final canResend = seconds == 0 && !controller.isLoading.value;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      seconds > 0
                          ? 'Resend OTP in ${seconds}s'
                          : "Didn't receive the code?",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    TextButton(
                      onPressed: canResend
                          ? () => controller.handleResendOtp(context)
                          : null,
                      child: Text(
                        'Resend OTP',
                        style: TextStyle(
                          color: canResend
                              ? AppTheme.primaryColor
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Obx(
              () => controller.errorMessage.value.isNotEmpty
                  ? authErrorBanner(controller.errorMessage.value)
                  : const SizedBox.shrink(),
            ),
            Obx(
              () => authPrimaryButton(
                isLoading: controller.isLoading.value,
                label: 'Verify OTP',
                onPressed: controller.isLoading.value
                    ? null
                    : () => controller.handleVerifyOtp(context),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                controller.clearForgotPasswordForm(endFlow: true);
                context.go(AppRoutes.forgotPassword);
              },
              child: Text(
                'Change Email',
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
