import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/home_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/competition_model.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/competition_controller.dart';
import '../../widgets/app_navbar.dart';
import '../../widgets/footer_section.dart';
import '../../widgets/public_competition_horizontal_card.dart';

/// Public competitions list — horizontal carousel with compact cards.
class PublicCompetitionsScreen extends StatelessWidget {
  final String? statusFilter;

  const PublicCompetitionsScreen({super.key, this.statusFilter});

  String get _pageTitle {
    switch (statusFilter?.toLowerCase()) {
      case 'ongoing':
        return 'Current Competitions';
      case 'upcoming':
        return 'Upcoming Competitions';
      case 'completed':
        return 'Past Events';
      default:
        return 'All Competitions';
    }
  }

  String get _subtitle {
    switch (statusFilter?.toLowerCase()) {
      case 'ongoing':
        return 'Live events you can join now';
      case 'upcoming':
        return 'Scheduled events — register early';
      case 'completed':
        return 'Browse results and participants';
      default:
        return 'Swipe to explore all events';
    }
  }

  List<HomeCompetitionModel> _filteredList(List<HomeCompetitionModel> all) {
    final status = statusFilter?.trim().toLowerCase();
    if (status == null || status.isEmpty) {
      return List<HomeCompetitionModel>.from(all);
    }
    final filtered =
        all.where((c) => c.status.toLowerCase() == status).toList();
    if (status == 'completed') {
      filtered.sort((a, b) {
        final endA = DateTime.tryParse(a.eventEndDate ?? '') ?? DateTime(1970);
        final endB = DateTime.tryParse(b.eventEndDate ?? '') ?? DateTime(1970);
        return endB.compareTo(endA);
      });
    }
    return filtered;
  }

  bool get _isPast => statusFilter?.toLowerCase() == 'completed';
  bool get _isUpcoming => statusFilter?.toLowerCase() == 'upcoming';
  bool get _isOngoing => statusFilter?.toLowerCase() == 'ongoing';

  void _openParticipants(BuildContext context, HomeCompetitionModel c) {
    final id = c.idStr ?? '${c.id}';
    if (id.isEmpty) return;
    final isPast =
        _isPast || c.status.toLowerCase() == 'completed';
    context.push(
      AppRoutes.publicCompetitionParticipantsPath(
        id,
        competitionName: c.competitionName,
        isPastCompetition: isPast,
      ),
    );
  }

  double _cardWidth(double screenWidth) {
    if (screenWidth < HomeLayout.mobile) {
      return (screenWidth * 0.82).clamp(280.0, 340.0);
    }
    return HomeLayout.competitionCarouselItemExtent(screenWidth);
  }

  @override
  Widget build(BuildContext context) {
    final competitionController = Get.put(CompetitionController());

    if (competitionController.homeCompetitions.isEmpty &&
        !competitionController.isLoadingHomeCompetitions.value) {
      competitionController.loadCompetitionsForHome();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppNavbar(title: _pageTitle),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Obx(() {
            if (competitionController.isLoadingHomeCompetitions.value &&
                competitionController.homeCompetitions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final list =
                _filteredList(competitionController.homeCompetitions);

            if (list.isEmpty) {
              return SizedBox(
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    Expanded(child: _buildEmpty(context)),
                    const FooterSection(),
                  ],
                ),
              );
            }

            final w = constraints.maxWidth;
            final padH = HomeLayout.sectionHorizontalPadding(w);
            final cardW = _cardWidth(w);
            final carouselH = (_isPast ? 408.0 : 496.0);
            final idOf = (HomeCompetitionModel c) => c.idStr ?? '${c.id}';

            return SizedBox(
              height: constraints.maxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(padH, 16, padH, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${list.length} event${list.length == 1 ? '' : 's'}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.swipe,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Swipe',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _subtitle,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: carouselH,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: padH),
                      physics: const BouncingScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final c = list[index];
                        return PublicCompetitionHorizontalCard(
                          key: ValueKey('public_h_${idOf(c)}_$index'),
                          competition: c,
                          width: cardW,
                          onViewParticipants: () {
                            _openParticipants(context, c);
                          },
                          showShareLinkOption: _isUpcoming,
                          showRegistrationQr: _isOngoing || _isUpcoming,
                          showRegistrationButton: !_isPast,
                          showResultsButton: _isOngoing,
                        );
                      },
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(padH, 0, padH, 12),
                    child: _buildHintCard(context),
                  ),
                  const FooterSection(),
                ],
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildHintCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.touch_app, color: AppTheme.primaryColor.withOpacity(0.8)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tap a card to view registered participants and download e-certificates (when available).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[800],
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No competitions found',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to home'),
            ),
          ],
        ),
      ),
    );
  }
}
