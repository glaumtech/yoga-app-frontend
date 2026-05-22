import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/competition_brochure_banner_url.dart';
import '../../core/utils/competition_registration_url.dart';
import '../../data/models/competition_model.dart';
import 'competition_registration_qr_image.dart';
import 'primary_button.dart';

/// Compact competition card for horizontal carousels (public competitions list).
class PublicCompetitionHorizontalCard extends StatelessWidget {
  final HomeCompetitionModel competition;
  final double width;
  final VoidCallback onViewParticipants;
  final bool showRegistrationQr;
  final bool showShareLinkOption;
  final bool showRegistrationButton;

  const PublicCompetitionHorizontalCard({
    super.key,
    required this.competition,
    required this.width,
    required this.onViewParticipants,
    this.showRegistrationQr = false,
    this.showShareLinkOption = false,
    this.showRegistrationButton = true,
  });

  static const double bannerHeight = 180;
  static const double actionButtonHeight = 44;

  /// Taller when QR + register row are shown; shorter for past events.
  double get computedHeight {
    final hasQr = showRegistrationQr &&
        (competition.idStr ?? '${competition.id}').isNotEmpty;
    if (!showRegistrationButton && !hasQr) return 400;
    if (hasQr) return 488;
    return 448;
  }

  String? get _bannerUrl => competitionBrochureBannerUrl(competition);

  DateTime? get _startDate {
    final s = competition.eventStartDate;
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  @override
  Widget build(BuildContext context) {
    final id = competition.idStr ?? '${competition.id}';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        height: computedHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBanner(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: onViewParticipants,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            competition.competitionName,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          _buildDateAddressQrSection(context, id),
                          if (competition.categories.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: competition.categories
                                  .take(3)
                                  .map((c) => _tag(context, c))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildActions(context, id),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    final h = bannerHeight;
    final url = _bannerUrl;

    Widget bannerChild;
    if (url != null) {
      bannerChild = Image.network(
        url,
        width: double.infinity,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultBanner(context, h),
      );
    } else {
      bannerChild = _defaultBanner(context, h);
    }

    return SizedBox(
      height: h,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          bannerChild,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.45),
                  ],
                ),
              ),
            ),
          ),
          if (showShareLinkOption)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.white.withOpacity(0.92),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _copyLink(context),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.share, size: 18, color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _defaultBanner(BuildContext context, double h) {
    return Container(
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
      ),
      child: const Center(
        child: Icon(Icons.emoji_events, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _metaRow(
    BuildContext context,
    IconData icon,
    String text, {
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[700],
              height: 1.25,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _tag(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.35)),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 9,
        ),
      ),
    );
  }

  Widget _buildDateAddressQrSection(BuildContext context, String id) {
    final hasDate = _startDate != null;
    final hasAddress = competition.address.isNotEmpty;
    final hasQr = showRegistrationQr && id.isNotEmpty;

    if (!hasDate && !hasAddress && !hasQr) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasDate)
                _metaRow(
                  context,
                  Icons.calendar_today,
                  DateFormat('dd/MM/yyyy').format(_startDate!),
                ),
              if (hasAddress) ...[
                if (hasDate) const SizedBox(height: 4),
                _metaRow(
                  context,
                  Icons.location_on,
                  competition.address,
                  maxLines: 3,
                ),
              ],
            ],
          ),
        ),
        if (hasQr) ...[
          const SizedBox(width: 8),
          _buildQrAside(context, id),
        ],
      ],
    );
  }

  Widget _buildQrAside(BuildContext context, String competitionId) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.25)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CompetitionRegistrationQrImage(
            competitionId: competitionId,
            size: 72,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Scan to\nregister',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 9,
            height: 1.15,
          ),
        ),
      ],
    );
  }

  ButtonStyle get _actionButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryColor,
        minimumSize: const Size(0, actionButtonHeight),
        fixedSize: Size.fromHeight(actionButtonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
      );

  void _navigateToParticipants(BuildContext context) {
    onViewParticipants();
  }

  void _navigateToRegister(BuildContext context, String id) {
    if (id.isEmpty) return;
    context.pushNamed(
      'register-competition',
      pathParameters: {'competitionId': id},
    );
  }

  Widget _buildActions(BuildContext context, String id) {
    if (!showRegistrationButton) {
      return SizedBox(
        width: double.infinity,
        height: actionButtonHeight,
        child: OutlinedButton.icon(
          onPressed: () => _navigateToParticipants(context),
          icon: const Icon(Icons.people_outline, size: 18),
          label: const Text('View participants'),
          style: _actionButtonStyle,
        ),
      );
    }

    return SizedBox(
      height: actionButtonHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _navigateToParticipants(context),
              style: _actionButtonStyle,
              child: const Text('Participants', style: TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: PrimaryButton(
              text: 'Register',
              icon: Icons.person_add,
              height: actionButtonHeight,
              width: double.infinity,
              onPressed: () => _navigateToRegister(context, id),
            ),
          ),
        ],
      ),
    );
  }

  void _copyLink(BuildContext context) {
    final id = competition.idStr ?? '${competition.id}';
    final link = registrationShareUrlForCompetition(
      registrationUrl: competition.registrationUrl,
      competitionId: id,
    );
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registration link copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
