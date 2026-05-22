import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/layout/home_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/competition_brochure_banner_url.dart';
import '../../../data/models/competition_model.dart';
import '../../../core/utils/competition_registration_url.dart';
import '../../../routes/app_routes.dart';
import 'primary_button.dart';

class CompetitionCard extends StatelessWidget {
  final HomeCompetitionModel competition;
  final VoidCallback? onTap;
  final bool showShareLinkOption;

  const CompetitionCard({
    super.key,
    required this.competition,
    this.onTap,
    this.showShareLinkOption = false,
  });

  String? _bannerImageUrl() => competitionBrochureBannerUrl(competition);

  double _effectiveCardWidth(BoxConstraints constraints, BuildContext context) {
    if (constraints.hasBoundedWidth && constraints.maxWidth.isFinite) {
      return constraints.maxWidth;
    }
    return MediaQuery.sizeOf(context).width;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = _effectiveCardWidth(constraints, context);
        final bannerH = competitionCardBannerHeight(maxW);
        final contentPad = competitionCardContentPadding(maxW);
        final btnH = competitionCardRegistrationButtonHeight(maxW);
        final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
          fontSize: maxW < 360 ? 15 : (maxW < 480 ? 16 : null),
        );
        final addressMaxLines = maxW < 400 ? 1 : 2;

        final startDate = competition.eventStartDate != null
            ? _tryParseDate(competition.eventStartDate!)
            : null;
        final bannerUrl = _bannerImageUrl();

        // Scroll when parent height is fixed (e.g. horizontal ListView / GridView cell).
        final cardBody = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBanner(context, bannerUrl, bannerH),
            Padding(
              padding: contentPad,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            competition.competitionName,
                            style: titleStyle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (competition.status.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: competition.status == 'ongoing'
                                  ? AppTheme.secondaryColor
                                  : competition.status == 'upcoming'
                                  ? Colors.orange
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              competition.status.toUpperCase(),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      competition.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (startDate != null)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(startDate),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    if (competition.address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              competition.address,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                              maxLines: addressMaxLines,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (competition.categories.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: competition.categories
                                  .take(3)
                                  .map((c) => _CategoryPill(label: c))
                                  .toList(),
                            ),
                          ),
                          if (showShareLinkOption) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 36,
                              width: 36,
                              child: IconButton(
                                onPressed: () => _copyRegistrationLink(context),
                                icon: const Icon(Icons.share, size: 16),
                                tooltip: 'Share registration link',
                                padding: EdgeInsets.zero,
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor
                                      .withOpacity(0.08),
                                  foregroundColor: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final innerW = constraints.maxWidth;
                        final maxBtn = math.min(
                          360.0,
                          innerW > 16 ? innerW - 16 : innerW,
                        );
                        final btnWidth = (innerW * 0.88)
                            .clamp(140.0, maxBtn)
                            .toDouble();
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PrimaryButton(
                              text: 'Registration Now',
                              icon: Icons.person_add,
                              width: btnWidth,
                              height: btnH,
                              onPressed: () {
                                final id =
                                    competition.idStr ?? '${competition.id}';
                                context.pushNamed(
                                  'register-competition',
                                  pathParameters: {'competitionId': id},
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: onTap != null
                ? InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: cardBody,
                  )
                : cardBody,
          ),
        );
      },
    );
  }

  Widget _buildBanner(
    BuildContext context,
    String? bannerUrl,
    double bannerHeight,
  ) {
    final radius = const BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
    );

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: double.infinity,
        height: bannerHeight,
        child: bannerUrl != null
            ? Image.network(
                bannerUrl,
                key: ValueKey<String>(
                  'brochure_banner_${competition.idStr ?? '${competition.id}'}',
                ),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildDefaultBanner(context, bannerHeight),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildDefaultBanner(context, bannerHeight);
                },
              )
            : _buildDefaultBanner(context, bannerHeight),
      ),
    );
  }

  Widget _buildDefaultBanner(BuildContext context, double bannerHeight) {
    return Container(
      height: bannerHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.9),
            AppTheme.secondaryColor,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: (bannerHeight * 0.24).clamp(28.0, 44.0),
            ),
            const SizedBox(height: 2),
            Text(
              'Yogasana',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static DateTime? _tryParseDate(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  static String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  void _copyRegistrationLink(BuildContext context) {
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

/// Category tag for competition cards (outlined pill, primary theme).
class _CategoryPill extends StatelessWidget {
  final String label;

  const _CategoryPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.45),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 10.5,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
