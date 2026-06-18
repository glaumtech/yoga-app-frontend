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
        return 'Past Competitions';
      default:
        return 'All Competitions';
    }
  }

  String get _subtitle {
    switch (statusFilter?.toLowerCase()) {
      case 'ongoing':
        return 'Live competitions you can join now';
      case 'upcoming':
        return 'Scheduled competitions — register early';
      case 'completed':
        return 'Browse results and participants';
      default:
        return 'Scroll to explore all competitions';
    }
  }

  List<HomeCompetitionModel> _filteredList(List<HomeCompetitionModel> all) {
    final status = statusFilter?.trim().toLowerCase();
    if (status == null || status.isEmpty) {
      return List<HomeCompetitionModel>.from(all);
    }
    final filtered = all
        .where((c) => c.status.toLowerCase() == status)
        .toList();
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
    final isPast = _isPast || c.status.toLowerCase() == 'completed';
    context.push(
      AppRoutes.publicCompetitionParticipantsPath(
        id,
        competitionName: c.competitionName,
        isPastCompetition: isPast,
      ),
    );
  }

  double _gridCardWidth(double screenWidth, int crossAxisCount, double padH) {
    const spacing = 16.0;
    return (screenWidth - 2 * padH - spacing * (crossAxisCount - 1)) /
        crossAxisCount;
  }

  double _gridRowHeight() => _isPast ? 380.0 : 430.0;

  Widget _buildEventCard(
    BuildContext context,
    HomeCompetitionModel c,
    double width,
    int index,
    String Function(HomeCompetitionModel) idOf,
  ) {
    return Align(
      alignment: Alignment.topCenter,
      child: PublicCompetitionHorizontalCard(
        key: ValueKey('public_h_${idOf(c)}_$index'),
        competition: c,
        width: width,
        onViewParticipants: () => _openParticipants(context, c),
        showShareLinkOption: _isUpcoming,
        showRegistrationQr: _isOngoing || _isUpcoming,
        showRegistrationButton: !_isPast,
        showResultsButton: _isOngoing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final competitionController = Get.put(CompetitionController());

    competitionController.ensureHomeCompetitionsLoaded();

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

            final list = _filteredList(competitionController.homeCompetitions);

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
            final idOf = (HomeCompetitionModel c) => c.idStr ?? '${c.id}';
            final isMobile = w < HomeLayout.mobile;
            final crossCount = isMobile
                ? 1
                : HomeLayout.competitionGridCrossAxisCount(w);
            final cardW = isMobile
                ? w - 2 * padH
                : _gridCardWidth(w, crossCount, padH);

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
                                color: AppTheme.primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${list.length} competition${list.length == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.unfold_more,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Scroll',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _subtitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(padH, 0, padH, 16),
                      child: isMobile
                          ? Column(
                              children: [
                                for (var i = 0; i < list.length; i++) ...[
                                  if (i > 0) const SizedBox(height: 16),
                                  _buildEventCard(
                                    context,
                                    list[i],
                                    cardW,
                                    i,
                                    idOf,
                                  ),
                                ],
                              ],
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossCount,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    mainAxisExtent: _gridRowHeight(),
                                  ),
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                return _buildEventCard(
                                  context,
                                  list[index],
                                  cardW,
                                  index,
                                  idOf,
                                );
                              },
                            ),
                    ),
                  ),
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
            Icon(
              Icons.touch_app,
              color: AppTheme.primaryColor.withOpacity(0.8),
            ),
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
