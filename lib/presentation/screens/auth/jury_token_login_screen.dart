import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/user_management_controller.dart';
import '../../widgets/custom_loader.dart';

class JuryTokenLoginScreen extends StatefulWidget {
  final String? token;

  const JuryTokenLoginScreen({super.key, this.token});

  @override
  State<JuryTokenLoginScreen> createState() => _JuryTokenLoginScreenState();
}

class _JuryTokenLoginScreenState extends State<JuryTokenLoginScreen> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _exchangeToken());
  }

  Future<void> _exchangeToken() async {
    final token = widget.token?.trim();
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'Missing login link. Please scan the QR code again.';
      });
      return;
    }

    final controller = Get.put(UserManagementController());
    final success = await controller.loginWithToken(token: token);

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.juryScoring);
      return;
    }

    setState(() {
      _errorMessage =
          controller.errorMessage.value.isNotEmpty
              ? controller.errorMessage.value
              : 'Invalid or expired login link';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _errorMessage == null;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 56,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  isLoading ? 'Signing you in...' : 'Login link failed',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (isLoading) ...[
                  const CustomLoader(),
                  const SizedBox(height: 12),
                  const Text(
                    'Please wait while we verify your jury login link.',
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.go(AppRoutes.login),
                    child: const Text('Go to manual login'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
