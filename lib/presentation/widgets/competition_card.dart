import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/competition_model.dart';
import 'primary_button.dart';

class CompetitionCard extends StatelessWidget {
  final HomeCompetitionModel competition;
  final VoidCallback? onTap;

  const CompetitionCard({super.key, required this.competition, this.onTap});

  static String _fullBrochureUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final base = BaseUrl.baseUrl.replaceAll(RegExp(r'/$'), '');
    final p = path.startsWith('/') ? path : '/$path';
    return '$base$p';
  }

  bool _isImageUrl(String? url) {
    if (url == null) return false;
    final lower = url.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }

  String? _bannerImageUrl() {
    final raw = competition.brochureUrl ?? competition.brochureFilePath;
    if (!_isImageUrl(raw)) return null;
    return raw == null || raw.isEmpty ? null : _fullBrochureUrl(raw);
  }

  @override
  Widget build(BuildContext context) {
    final startDate = competition.eventStartDate != null
        ? _tryParseDate(competition.eventStartDate!)
        : null;
    final bannerUrl = _bannerImageUrl();

    final cardBody = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Banner image/logo at the top
        _buildBanner(context, bannerUrl),
        Padding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            top: 12,
            bottom: 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            competition.competitionName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (competition.categories.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: competition.categories.take(3).map((c) {
                          return Chip(
                            label: Text(
                              c,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontSize: 11),
                            ),
                            backgroundColor: AppTheme.accentColor,
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 0,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: 'Registration Now',
                        icon: Icons.person_add,
                        height: 40,
                        onPressed: () {
                          final id = competition.idStr ?? '${competition.id}';
                          context.pushNamed(
                            'register-competition',
                            pathParameters: {'competitionId': id},
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  }

  Widget _buildBanner(BuildContext context, String? bannerUrl) {
    const bannerHeight = 92.0;
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
            Icon(Icons.emoji_events, color: Colors.white, size: 36),
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
}
