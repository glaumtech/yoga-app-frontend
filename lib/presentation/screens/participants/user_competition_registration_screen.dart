import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/competition_brochure_banner_url.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/competition_controller.dart';
import '../../../data/models/competition_model.dart';
import 'participant_registration_form_screen.dart';

/// Public registration screen for unknown/unauthenticated users.
/// Left: competition details. Right: registration form.
class UserCompetitionRegistrationScreen extends StatelessWidget {
  final String competitionId;

  const UserCompetitionRegistrationScreen({
    super.key,
    required this.competitionId,
  });

  @override
  Widget build(BuildContext context) {
    final competitionController = Get.put(CompetitionController());

    // Load public competitions (no auth required)
    if (competitionController.homeCompetitions.isEmpty &&
        !competitionController.isLoadingHomeCompetitions.value) {
      competitionController.loadCompetitionsForHome();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Register for Competition'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: isMobile
          ? _buildMobileLayout(context, competitionController, isMobile)
          : _buildDesktopLayout(context, competitionController, isMobile),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    CompetitionController competitionController,
    bool isMobile,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(
              () => _buildCompetitionDetailsContent(
                context,
                competitionController,
                isMobile,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: ParticipantRegistrationFormScreen(
              initialCompetitionId: competitionId,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    CompetitionController competitionController,
    bool isMobile,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: competition details (full width of left side, white box)
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 16, 24),
            child: Obx(
              () => _buildCompetitionDetailsContent(
                context,
                competitionController,
                isMobile,
              ),
            ),
          ),
        ),
        // Right: registration form
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 32, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: ParticipantRegistrationFormScreen(
                  initialCompetitionId: competitionId,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompetitionDetailsContent(
    BuildContext context,
    CompetitionController competitionController,
    bool isMobile,
  ) {
    Widget content;
    if (competitionController.isLoadingHomeCompetitions.value &&
        competitionController.homeCompetitions.isEmpty) {
      content = const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      final competition = competitionController.homeCompetitions
          .firstWhereOrNull((c) => c.idStr == competitionId);
      content = competition == null
          ? _buildDetailsPlaceholder(context, isMobile)
          : _buildCompetitionDetailsPanel(context, competition, isMobile);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: content,
    );
  }

  /// Competition details with banner (image or default icon/logo).
  Widget _buildCompetitionDetailsPanel(
    BuildContext context,
    HomeCompetitionModel competition,
    bool isMobile,
  ) {
    final startDate = competition.eventStartDate != null
        ? _tryParseDate(competition.eventStartDate!)
        : null;
    final endDate = competition.eventEndDate != null
        ? _tryParseDate(competition.eventEndDate!)
        : null;
    final dateText = startDate != null
        ? (endDate != null && endDate != startDate
              ? '${_formatDate(startDate)} – ${_formatDate(endDate)}'
              : _formatDate(startDate))
        : (competition.eventStartDate ?? 'Date TBA');

    final grey = Colors.grey.shade700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompetitionBanner(context, competition, isMobile),
        const SizedBox(height: 20),
        Text(
          'Competition',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: grey,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        if (competition.status.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Text(
              competition.status.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Text(
          competition.competitionName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (competition.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            competition.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: grey, height: 1.4),
            maxLines: isMobile ? 2 : 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.calendar_today, size: 16, color: grey),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                dateText,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: grey),
              ),
            ),
          ],
        ),
        if (competition.address.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 16, color: grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  competition.address,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: grey),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (competition.categories.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: competition.categories.take(5).map((c) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Text(
                  c,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textColor,
                    fontSize: 11,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  /// Banner: show image if URL available, otherwise default icon/logo.
  Widget _buildCompetitionBanner(
    BuildContext context,
    HomeCompetitionModel competition,
    bool isMobile,
  ) {
    final bannerUrl = competitionBrochureBannerUrl(competition);
    final height = isMobile ? 210.0 : 400.0;

    if (bannerUrl != null && bannerUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Image.network(
            bannerUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildDefaultBanner(
              context,
              height,
              competition.competitionName,
            ),
          ),
        ),
      );
    }
    return _buildDefaultBanner(context, height, competition.competitionName);
  }

  Widget _buildDefaultBanner(
    BuildContext context,
    double height,
    String competitionName,
  ) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.85),
            AppTheme.secondaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events,
            size: 56,
            color: Colors.white.withOpacity(0.95),
          ),
          const SizedBox(height: 8),
          Icon(
            Icons.self_improvement,
            size: 36,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              competitionName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPlaceholder(BuildContext context, bool isMobile) {
    final grey = Colors.grey.shade700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDefaultBanner(context, isMobile ? 120.0 : 160.0, 'Competition'),
        const SizedBox(height: 20),
        Text(
          'Competition',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Competition Registration',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Fill in the form to register.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: grey),
        ),
      ],
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
