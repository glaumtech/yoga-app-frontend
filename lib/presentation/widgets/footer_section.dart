import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/layout/home_layout.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  static const String _contactEmail = 'praveen.sekar@glaum.in';
  static const String _companyName = 'Glaum Technologies';

  static const _navLinks = [
    _FooterNavLink('About Us', AppRoutes.about),
    _FooterNavLink('Online Participant login', AppRoutes.participantVideoUpload),
    _FooterNavLink('Privacy Policy', '/legal/privacy'),
    _FooterNavLink('Refund and Cancellation policy', '/legal/refund'),
    _FooterNavLink('Terms and Conditions', '/legal/terms'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < HomeLayout.mobile;
    final padH = isMobile ? 16.0 : 32.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
      ),
      padding: EdgeInsets.fromLTRB(padH, 28, padH, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNavLinksSection(),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.25), height: 1),
          const SizedBox(height: 16),
          if (isMobile)
            _buildMobileBottomSection(context)
          else
            _buildDesktopBottomSection(context),
        ],
      ),
    );
  }

  Widget _buildNavLinksSection() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: _navLinks
            .map((link) => _FooterLinkButton(link: link))
            .toList(),
      ),
    );
  }

  Widget _buildDesktopBottomSection(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _copyrightText()),
        _socialIcons(context),
        const SizedBox(width: 12),
        _backToTopButton(context),
      ],
    );
  }

  Widget _buildMobileBottomSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _copyrightText(),
        const SizedBox(height: 16),
        Row(
          children: [
            _socialIcons(context),
            const Spacer(),
            _backToTopButton(context),
          ],
        ),
      ],
    );
  }

  Widget _copyrightText() {
    return Text(
      '© ${DateTime.now().year} $_companyName. All Rights Reserved',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.75),
        fontSize: 12,
      ),
    );
  }

  Widget _socialIcons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SocialIconButton(
          icon: Icons.public,
          tooltip: 'Website',
          onTap: () => _launchExternal(context, 'https://glaum.in'),
        ),
        const SizedBox(width: 10),
        _SocialIconButton(
          icon: Icons.email_outlined,
          tooltip: _contactEmail,
          onTap: () => _launchEmail(context),
        ),
        const SizedBox(width: 10),
        _SocialIconButton(
          icon: Icons.phone_outlined,
          tooltip: '+91 9952825358',
          onTap: () => _launchPhone(context),
        ),
      ],
    );
  }

  Widget _backToTopButton(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: () => _scrollToTop(context),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            Icons.keyboard_arrow_up,
            color: AppTheme.primaryColor,
            size: 22,
          ),
        ),
      ),
    );
  }

  void _scrollToTop(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null && scrollable.position.hasPixels) {
      scrollable.position.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: _contactEmail);
    await _launchUri(context, uri, 'Could not open email app');
  }

  Future<void> _launchPhone(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: '+919952825358');
    await _launchUri(context, uri, 'Could not open phone dialer');
  }

  Future<void> _launchExternal(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await _launchUri(context, uri, 'Could not open link', external: true);
  }

  Future<void> _launchUri(
    BuildContext context,
    Uri uri,
    String errorMessage, {
    bool external = false,
  }) async {
    final launched = await launchUrl(
      uri,
      mode: external
          ? LaunchMode.externalApplication
          : LaunchMode.platformDefault,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }
}

class _FooterNavLink {
  final String label;
  final String path;

  const _FooterNavLink(this.label, this.path);
}

class _FooterLinkButton extends StatelessWidget {
  final _FooterNavLink link;

  const _FooterLinkButton({required this.link});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.push(link.path),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        link.label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SocialIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
