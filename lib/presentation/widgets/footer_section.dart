import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  static const String _contactEmail = 'praveen.sekar@glaum.in';
  static const String _contactPhone = '+91 9952825358';
  static const String _contactAddress =
      'Glaum Technologies, Kulithalai, Karur - 639 104, Tamilnadu, India.';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppConstants.appName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '© ${DateTime.now().year} All rights reserved',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(
                context,
                icon: Icons.email,
                tooltip: _contactEmail,
                onTap: () => _launchEmail(context),
              ),
              const SizedBox(width: 16),
              _buildSocialIcon(
                context,
                icon: Icons.phone,
                tooltip: _contactPhone,
                onTap: () => _launchPhone(context),
              ),
              const SizedBox(width: 16),
              _buildSocialIcon(
                context,
                icon: Icons.location_on,
                tooltip: _contactAddress,
                onTap: () => _launchMap(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPoweredBy(context),
        ],
      ),
    );
  }

  Widget _buildPoweredBy(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white70,
        );
    final linkStyle = bodyStyle?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: Colors.white70,
    );

    return Text.rich(
      TextSpan(
        style: bodyStyle,
        children: [
          const TextSpan(text: 'Powered by '),
          TextSpan(
            text: 'Glaum Technologies',
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _openGlaumSite(context),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSocialIcon(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _contactEmail,
    );
    await _launchUri(context, uri, 'Could not open email app');
  }

  Future<void> _launchPhone(BuildContext context) async {
    final digits = _contactPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    await _launchUri(context, uri, 'Could not open phone dialer');
  }

  Future<void> _launchMap(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_contactAddress)}',
    );
    await _launchUri(
      context,
      uri,
      'Could not open maps',
      external: true,
    );
  }

  Future<void> _openGlaumSite(BuildContext context) async {
    await _launchUri(
      context,
      Uri.parse('https://glaum.in'),
      'Could not open glaum.in',
      external: true,
    );
  }

  Future<void> _launchUri(
    BuildContext context,
    Uri uri,
    String errorMessage, {
    bool external = false,
  }) async {
    final launched = await launchUrl(
      uri,
      mode: external ? LaunchMode.externalApplication : LaunchMode.platformDefault,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }
}
