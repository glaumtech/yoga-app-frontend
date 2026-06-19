import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/home_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/competition_brochure_banner_url.dart';
import '../../../data/models/competition_model.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/competition_controller.dart';
import '../../controllers/participant_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/user_management_controller.dart';
import '../../widgets/footer_section.dart';
import '../../widgets/registration_success_panel.dart';
import '../home/home_landing_sections.dart';
import 'participant_registration_form_screen.dart';
import 'registration_event_landing.dart';

/// Public registration screen styled like an event landing page.
class UserCompetitionRegistrationScreen extends StatefulWidget {
  final String competitionId;

  const UserCompetitionRegistrationScreen({
    super.key,
    required this.competitionId,
  });

  @override
  State<UserCompetitionRegistrationScreen> createState() =>
      _UserCompetitionRegistrationScreenState();
}

class _UserCompetitionRegistrationScreenState
    extends State<UserCompetitionRegistrationScreen> {
  final GlobalKey _formSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final competitionController = Get.isRegistered<CompetitionController>()
          ? Get.find<CompetitionController>()
          : Get.put(CompetitionController());
      final participantController = Get.isRegistered<ParticipantController>()
          ? Get.find<ParticipantController>()
          : Get.put(ParticipantController());

      participantController.clearRegistrationConfirmation();
      participantController.selectedEventId.value = widget.competitionId;

      if (competitionController.homeCompetitions.isEmpty &&
          !competitionController.isLoadingHomeCompetitions.value) {
        await competitionController.ensureHomeCompetitionsLoaded();
      }
      await competitionController.loadOnDemandContext();
      await competitionController.ensureCompetitionLoadedForRegistration(
        widget.competitionId,
      );
    });
  }

  void _scrollToRegistrationForm() {
    final context = _formSectionKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    final competitionController = Get.put(CompetitionController());
    final participantController = Get.isRegistered<ParticipantController>()
        ? Get.find<ParticipantController>()
        : Get.put(ParticipantController());
    final userController = Get.put(UserManagementController());
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());

    competitionController.ensureHomeCompetitionsLoaded();

    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < HomeLayout.mobile;
    final padH = HomeLayout.sectionHorizontalPadding(width);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Obx(() {
          return HomeLandingNavBar(
            isAuthenticated: userController.isAuthenticated,
            onLogin: () => context.go(AppRoutes.login),
            onLogout: userController.isAuthenticated
                ? () async {
                    await authController.signOut();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  }
                : null,
          );
        }),
      ),
      body: Obx(() {
        final isLoading = competitionController.isLoadingHomeCompetitions.value &&
            competitionController.homeCompetitions.isEmpty;

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final competition = competitionController.homeCompetitions
            .firstWhereOrNull((c) => c.idStr == widget.competitionId);
        final fullCompetition = competitionController.competitions
            .firstWhereOrNull((c) => c.id == widget.competitionId);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(padH, 24, padH, 32),
                    child: competition == null
                        ? _buildMissingCompetition(context)
                        : isMobile
                            ? _buildMobileContent(
                                context,
                                competition,
                                fullCompetition,
                                competitionController,
                                participantController,
                              )
                            : _buildDesktopContent(
                                context,
                                competition,
                                fullCompetition,
                                competitionController,
                                participantController,
                              ),
                  ),
                ),
              ),
              const FooterSection(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMissingCompetition(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Competition not found',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'This registration link may be invalid or the competition is no longer available.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => context.go(AppRoutes.home),
          child: const Text('Back to Home'),
        ),
      ],
    );
  }

  Widget _buildMobileContent(
    BuildContext context,
    HomeCompetitionModel competition,
    CompetitionModel? fullCompetition,
    CompetitionController competitionController,
    ParticipantController participantController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegistrationEventHeader(competition: competition),
        const SizedBox(height: 20),
        _buildBanner(competition, isMobile: true),
        const SizedBox(height: 24),
        RegistrationEventSidebar(
          competition: competition,
          fullCompetition: fullCompetition,
          onRegisterTap: _scrollToRegistrationForm,
        ),
        const SizedBox(height: 32),
        if (competition.description.trim().isNotEmpty) ...[
          _buildDescription(context, competition.description),
          const SizedBox(height: 32),
        ],
        const RegistrationEventHighlights(),
        const SizedBox(height: 32),
        RegistrationCategoryCards(
          competition: competition,
          fullCompetition: fullCompetition,
          competitionController: competitionController,
          participantController: participantController,
          onRegisterTap: _scrollToRegistrationForm,
        ),
        const SizedBox(height: 32),
        _buildRegistrationSection(
          context,
          participantController,
        ),
      ],
    );
  }

  Widget _buildDesktopContent(
    BuildContext context,
    HomeCompetitionModel competition,
    CompetitionModel? fullCompetition,
    CompetitionController competitionController,
    ParticipantController participantController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegistrationEventHeader(competition: competition),
        const SizedBox(height: 24),
        _buildBanner(competition, isMobile: false),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (competition.description.trim().isNotEmpty) ...[
                    _buildDescription(context, competition.description),
                    const SizedBox(height: 36),
                  ],
                  const RegistrationEventHighlights(),
                  const SizedBox(height: 36),
                  RegistrationCategoryCards(
                    competition: competition,
                    fullCompetition: fullCompetition,
                    competitionController: competitionController,
                    participantController: participantController,
                    onRegisterTap: _scrollToRegistrationForm,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 28),
            SizedBox(
              width: 300,
              child: RegistrationEventSidebar(
                competition: competition,
                fullCompetition: fullCompetition,
                onRegisterTap: _scrollToRegistrationForm,
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),
        _buildRegistrationSection(
          context,
          participantController,
        ),
      ],
    );
  }

  Widget _buildBanner(HomeCompetitionModel competition, {required bool isMobile}) {
    final bannerUrl = competitionBrochureBannerUrl(competition);
    final height = isMobile ? 220.0 : 320.0;

    if (bannerUrl != null && bannerUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Image.network(
            bannerUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _buildDefaultBanner(height, competition.competitionName),
          ),
        ),
      );
    }
    return _buildDefaultBanner(height, competition.competitionName);
  }

  Widget _buildDefaultBanner(double height, String title) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.9),
            AppTheme.secondaryColor,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RegistrationSectionTitle('About the Event'),
        Text(
          description,
          style: TextStyle(
            fontSize: 15,
            height: 1.65,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationSection(
    BuildContext context,
    ParticipantController participantController,
  ) {
    return Container(
      key: _formSectionKey,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RegistrationSectionTitle('Participant Registration'),
          Obx(() {
            if (participantController.registrationSaved.value) {
              return RegistrationSuccessPanel(
                participantController: participantController,
                participant: participantController.lastRegisteredParticipant.value,
                onRegisterAnother: () {
                  participantController.clearRegistrationConfirmation();
                  participantController.resetForm();
                },
              );
            }
            return ParticipantRegistrationFormScreen(
              initialCompetitionId: widget.competitionId,
              showCompetitionDropdown: false,
              embeddedInLandingPage: true,
            );
          }),
        ],
      ),
    );
  }
}
