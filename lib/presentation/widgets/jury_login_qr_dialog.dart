import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/user_management_model.dart';
import '../controllers/user_management_controller.dart';
import 'custom_loader.dart';

class JuryLoginQrDialog extends StatefulWidget {
  final UserManagementModel user;

  const JuryLoginQrDialog({super.key, required this.user});

  @override
  State<JuryLoginQrDialog> createState() => _JuryLoginQrDialogState();
}

class _JuryLoginQrDialogState extends State<JuryLoginQrDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _loginUrl;
  String? _expiresAt;

  @override
  void initState() {
    super.initState();
    _generateLink();
  }

  Future<void> _generateLink() async {
    final userId = widget.user.id?.toString();
    if (userId == null || userId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User id is missing';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final controller = Get.find<UserManagementController>();
    final result = await controller.generateJuryLoginToken(userId);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result != null) {
        _loginUrl = result['loginUrl']?.toString();
        _expiresAt = result['expiresAt']?.toString();
        if (_loginUrl == null || _loginUrl!.isEmpty) {
          _errorMessage = 'Login URL was not returned by the server';
        }
      } else {
        _errorMessage =
            controller.errorMessage.value.isNotEmpty
                ? controller.errorMessage.value
                : 'Failed to generate login link';
      }
    });
  }

  Future<void> _copyUrl() async {
    final url = _loginUrl;
    if (url == null || url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login link copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.user.name.trim().isNotEmpty
        ? widget.user.name
        : (widget.user.userName ?? 'Jury user');

    return AlertDialog(
      title: const Text('Jury Login QR'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_isLoading) ...[
              const CustomLoader(),
              const SizedBox(height: 12),
              const Text('Generating secure login link...'),
            ] else if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[700]),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: _loginUrl!,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                _loginUrl!,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              if (_expiresAt != null && _expiresAt!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Expires: $_expiresAt',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (!_isLoading && _loginUrl != null) ...[
          TextButton(
            onPressed: _copyUrl,
            child: const Text('Copy link'),
          ),
          FilledButton(
            onPressed: _generateLink,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Regenerate'),
          ),
        ],
        if (!_isLoading && _errorMessage != null)
          FilledButton(
            onPressed: _generateLink,
            child: const Text('Retry'),
          ),
      ],
    );
  }
}
