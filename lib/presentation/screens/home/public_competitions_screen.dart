import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/home_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/competition_model.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/competition_controller.dart';
import '../../widgets/footer_section.dart';
import 'home_landing_sections.dart';
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

  String get _loadingMessage =>
      _isPast ? 'Loading results...' : 'Loading competitions...';

  Widget _buildPageHeader(
    BuildContext context,
    double padH, {
    int? count,
    bool loading = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(padH, 16, padH, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (loading)
                Container(
                  width: 110,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                )
              else
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
                    '${count ?? 0} competition${count == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (!loading) ...[
                const Spacer(),
                Icon(Icons.unfold_more, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Scroll',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _pageTitle,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            loading ? _loadingMessage : _subtitle,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLine({required double width, double height = 14}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSkeletonCard(double width) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: PublicCompetitionHorizontalCard.bannerHeight,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSkeletonLine(width: width * 0.85),
                const SizedBox(height: 8),
                _buildSkeletonLine(width: width * 0.55, height: 10),
                const SizedBox(height: 8),
                _buildSkeletonLine(width: width * 0.45, height: 10),
                const SizedBox(height: 12),
                Container(
                  height: PublicCompetitionHorizontalCard.actionButtonHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid(
    BuildContext context,
    double w,
    double padH,
    int crossCount,
    double cardW,
    bool isMobile,
  ) {
    final skeletonCount = isMobile ? 3 : crossCount * 2;
    if (isMobile) {
      return Column(
        children: [
          for (var i = 0; i < skeletonCount; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            _buildSkeletonCard(cardW),
          ],
        ],
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < skeletonCount; i += crossCount) {
      if (i > 0) rows.add(const SizedBox(height: 16));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < crossCount; j++) ...[
              if (j > 0) const SizedBox(width: 16),
              Expanded(
                child: i + j < skeletonCount
                    ? _buildSkeletonCard(cardW)
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildLoadingBody(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final w = constraints.maxWidth;
    final padH = HomeLayout.sectionHorizontalPadding(w);
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
          _buildPageHeader(context, padH, loading: true),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(padH, 0, padH, 16),
              child: Column(
                children: [
                  _buildLoadingGrid(
                    context,
                    w,
                    padH,
                    crossCount,
                    cardW,
                    isMobile,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _loadingMessage,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const FooterSection(),
        ],
      ),
    );
  }

  double _gridCardWidth(double screenWidth, int crossAxisCount, double padH) {
    const spacing = 16.0;
    return (screenWidth - 2 * padH - spacing * (crossAxisCount - 1)) /
        crossAxisCount;
  }

  Widget _buildDesktopGrid(
    BuildContext context,
    List<HomeCompetitionModel> list,
    int crossCount,
    double cardW,
    String Function(HomeCompetitionModel) idOf,
  ) {
    final rows = <Widget>[];
    for (var i = 0; i < list.length; i += crossCount) {
      if (i > 0) rows.add(const SizedBox(height: 16));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < crossCount; j++) ...[
              if (j > 0) const SizedBox(width: 16),
              Expanded(
                child: i + j < list.length
                    ? _buildEventCard(
                        context,
                        list[i + j],
                        cardW,
                        i + j,
                        idOf,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

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
      appBar: const HomeLandingAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Obx(() {
            final isLoading =
                competitionController.isLoadingHomeCompetitions.value;
            final allCompetitions = competitionController.homeCompetitions;

            if (isLoading && allCompetitions.isEmpty) {
              return _buildLoadingBody(context, constraints);
            }

            final list = _filteredList(allCompetitions);

            if (!isLoading && list.isEmpty) {
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
                  _buildPageHeader(context, padH, count: list.length),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(padH, 0, padH, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isMobile)
                            Column(
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
                          else
                            _buildDesktopGrid(
                              context,
                              list,
                              crossCount,
                              cardW,
                              idOf,
                            ),
                          const SizedBox(height: 16),
                          _buildHintCard(context),
                        ],
                      ),
                    ),
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
