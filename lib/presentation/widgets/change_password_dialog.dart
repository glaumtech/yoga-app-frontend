import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../../../data/repositories/password_reset_repository.dart';
import 'auth_flow_scaffold.dart';
import 'primary_button.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ChangePasswordDialog(),
    );
  }

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _stepOneFormKey = GlobalKey<FormState>();
  final _stepTwoFormKey = GlobalKey<FormState>();
  final _stepThreeFormKey = GlobalKey<FormState>();
  final _repository = PasswordResetRepository();
  final _currentPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  int _step = 1;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String _errorMessage = '';
  String _maskedEmail = '';
  String _resetToken = '';

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.isEmpty) {
      return 'Please enter your $label';
    }
    return null;
  }

  String? _validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the OTP';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return 'OTP must be a 6-digit number';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
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

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _sendOtp() async {
    if (_stepOneFormKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await _repository.sendChangePasswordOtp(
      currentPassword: _currentPasswordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (response.success) {
      setState(() {
        _step = 2;
        _maskedEmail = response.data?.trim() ?? '';
      });
      SnackbarHelper.showSuccess(
        context,
        response.message ?? 'OTP has been sent to your registered email.',
      );
      return;
    }

    setState(() {
      _errorMessage =
          response.message ?? 'Unable to send OTP. Please try again.';
    });
  }

  Future<void> _verifyOtp() async {
    if (_stepTwoFormKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await _repository.verifyChangePasswordOtp(
      otp: _otpController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (response.success && (response.data?.isNotEmpty ?? false)) {
      setState(() {
        _step = 3;
        _resetToken = response.data!.trim();
      });
      SnackbarHelper.showSuccess(
        context,
        response.message ?? 'OTP verified successfully.',
      );
      return;
    }

    setState(() {
      _errorMessage =
          response.message ?? 'Invalid or expired OTP. Please try again.';
    });
  }

  Future<void> _updatePassword() async {
    if (_stepThreeFormKey.currentState?.validate() != true) return;
    if (_resetToken.isEmpty) {
      setState(() {
        _errorMessage =
            'Session expired. Please restart the password reset flow.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await _repository.confirmChangePassword(
      resetToken: _resetToken,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (response.success) {
      Navigator.of(context).pop();
      SnackbarHelper.showSuccess(
        context,
        response.message ?? 'Password changed successfully.',
      );
      return;
    }

    setState(() {
      _errorMessage =
          response.message ?? 'Unable to update password. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Reset Password'),
      content: SizedBox(
        width: 420,
        child: switch (_step) {
          1 => _buildStepOne(),
          2 => _buildStepTwo(),
          _ => _buildStepThree(),
        },
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_step == 3)
          PrimaryButton(
            text: _isLoading ? 'Updating...' : 'Update',
            onPressed: _isLoading ? null : _updatePassword,
            width: 110,
            height: 40,
          ),
      ],
    );
  }

  Widget _buildStepOne() {
    return Form(
      key: _stepOneFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter your current password to verify your identity.',
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _currentPasswordController,
            obscureText: _obscureCurrent,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: authInputDecoration(
              label: 'Current Password',
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrent
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
            ),
            validator: (value) =>
                _validateRequired(value, 'current password'),
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            authErrorBanner(_errorMessage),
          ],
          const SizedBox(height: 16),
          authPrimaryButton(
            isLoading: _isLoading,
            label: 'Send OTP to Registered Email',
            onPressed: _isLoading ? null : _sendOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildStepTwo() {
    return Form(
      key: _stepTwoFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _maskedEmail.isNotEmpty
                ? 'Enter the OTP sent to $_maskedEmail.'
                : 'Enter the OTP sent to your registered email.',
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: authInputDecoration(
              label: 'OTP',
              icon: Icons.pin_outlined,
            ),
            validator: _validateOtp,
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            authErrorBanner(_errorMessage),
          ],
          const SizedBox(height: 16),
          authPrimaryButton(
            isLoading: _isLoading,
            label: 'Verify OTP',
            onPressed: _isLoading ? null : _verifyOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildStepThree() {
    return Form(
      key: _stepThreeFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'OTP verified. Enter your new password below.',
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: authInputDecoration(
              label: 'New Password',
              icon: Icons.lock_reset,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            validator: _validateNewPassword,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: authInputDecoration(
              label: 'Confirm Password',
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: _validateConfirmPassword,
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            authErrorBanner(_errorMessage),
          ],
        ],
      ),
    );
  }
}
