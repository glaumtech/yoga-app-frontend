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
/// Opened via opaque [registrationCode] (not sequential competition id).
class UserCompetitionRegistrationScreen extends StatefulWidget {
  final String registrationCode;

  /// When set, loads this registration into the form for public edit.
  final String? editRegistrationId;

  const UserCompetitionRegistrationScreen({
    super.key,
    required this.registrationCode,
    this.editRegistrationId,
  });

  @override
  State<UserCompetitionRegistrationScreen> createState() =>
      _UserCompetitionRegistrationScreenState();
}

class _UserCompetitionRegistrationScreenState
    extends State<UserCompetitionRegistrationScreen> {
  final GlobalKey _formSectionKey = GlobalKey();

  /// Wide event banner aspect (similar to NovaRace / Metro Kidathon posters).
  static const double _bannerAspectRatio = 16 / 9;
  static const double _sidebarWidth = 320;

  bool _isResolving = true;
  bool _resolveFailed = false;
  bool _registrationSaved = false;
  String? _resolvedCompetitionId;
  HomeCompetitionModel? _competition;
  CompetitionModel? _fullCompetition;
  Worker? _registrationSavedWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveRegistrationLink();
    });
  }

  @override
  void dispose() {
    _registrationSavedWorker?.dispose();
    _registrationSavedWorker = null;
    super.dispose();
  }

  Future<void> _resolveRegistrationLink() async {
    final competitionController = Get.isRegistered<CompetitionController>()
        ? Get.find<CompetitionController>()
        : Get.put(CompetitionController());
    final participantController = Get.isRegistered<ParticipantController>()
        ? Get.find<ParticipantController>()
        : Get.put(ParticipantController());

    participantController.clearRegistrationConfirmation();
    _registrationSavedWorker?.dispose();
    _registrationSavedWorker = ever<bool>(
      participantController.registrationSaved,
      (saved) {
        if (!mounted) return;
        setState(() => _registrationSaved = saved);
      },
    );

    if (competitionController.homeCompetitions.isEmpty &&
        !competitionController.isLoadingHomeCompetitions.value) {
      await competitionController.ensureHomeCompetitionsLoaded();
    }
    await competitionController.loadOnDemandContext();

    final resolvedId = await competitionController
        .ensureCompetitionLoadedForRegistrationCode(widget.registrationCode);

    if (!mounted) return;

    if (resolvedId == null || resolvedId.isEmpty) {
      setState(() {
        _isResolving = false;
        _resolveFailed = true;
        _resolvedCompetitionId = null;
        _competition = null;
        _fullCompetition = null;
      });
      return;
    }

    participantController.selectedEventId.value = resolvedId;

    final editId = widget.editRegistrationId?.trim();
    if (editId != null && editId.isNotEmpty) {
      participantController.clearRegistrationConfirmation();
      await participantController.fetchParticipantById(editId);
    } else if (participantController.isEditMode ||
        participantController.isViewMode.value) {
      // Fresh registration link should not keep a prior edit/view session.
      participantController.resetForm();
    }

    final code = widget.registrationCode.trim();
    final competition = competitionController.homeCompetitions.firstWhereOrNull(
      (c) =>
          (c.registrationCode?.trim() ?? '') == code || c.idStr == resolvedId,
    );
    final fullCompetition = competitionController.competitions
        .firstWhereOrNull((c) => c.id == resolvedId);

    setState(() {
      _isResolving = false;
      _resolveFailed = competition == null;
      _resolvedCompetitionId = resolvedId;
      _competition = competition;
      _fullCompetition = fullCompetition;
      _registrationSaved = participantController.registrationSaved.value;
    });

    if (editId != null && editId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollToRegistrationForm();
      });
    }
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
    final competitionController = Get.isRegistered<CompetitionController>()
        ? Get.find<CompetitionController>()
        : Get.put(CompetitionController());
    final participantController = Get.isRegistered<ParticipantController>()
        ? Get.find<ParticipantController>()
        : Get.put(ParticipantController());
    final userController = Get.isRegistered<UserManagementController>()
        ? Get.find<UserManagementController>()
        : Get.put(UserManagementController());
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());

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
      body: _isResolving
          ? const Center(child: CircularProgressIndicator())
          // SingleChildScrollView avoids LayoutBuilder remount conflicts with
          // Form GlobalKeys on Flutter web (PinnedVerticalScrollView uses it).
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(padH, 24, padH, 32),
                        child: _resolveFailed || _competition == null
                            ? _buildMissingCompetition(context)
                            : isMobile
                            ? _buildMobileContent(
                                context,
                                _competition!,
                                _fullCompetition,
                                competitionController,
                                participantController,
                              )
                            : _buildDesktopContent(
                                context,
                                _competition!,
                                _fullCompetition,
                                competitionController,
                                participantController,
                              ),
                      ),
                    ),
                  ),
                  const FooterSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildMissingCompetition(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Competition not found',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
        _buildEventBanner(competition),
        const SizedBox(height: 20),
        RegistrationEventSidebar(
          competition: competition,
          fullCompetition: fullCompetition,
          onRegisterTap: _scrollToRegistrationForm,
        ),
        const SizedBox(height: 20),
        ..._buildEventDetailsSections(
          context,
          competition,
          fullCompetition,
          competitionController,
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
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEventBanner(competition),
                  const SizedBox(height: 16),
                  ..._buildEventDetailsSections(
                    context,
                    competition,
                    fullCompetition,
                    competitionController,
                    participantController,
                    includeRegistration: false,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: _sidebarWidth,
              child: RegistrationEventSidebar(
                competition: competition,
                fullCompetition: fullCompetition,
                onRegisterTap: _scrollToRegistrationForm,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _buildRegistrationSection(context, participantController),
      ],
    );
  }

  List<Widget> _buildEventDetailsSections(
    BuildContext context,
    HomeCompetitionModel competition,
    CompetitionModel? fullCompetition,
    CompetitionController competitionController,
    ParticipantController participantController, {
    bool includeRegistration = true,
  }) {
    return [
      if (competition.description.trim().isNotEmpty) ...[
        _buildDescription(context, competition.description),
        const SizedBox(height: 24),
      ],
      const RegistrationEventHighlights(),
      const SizedBox(height: 24),
      RegistrationCategoryCards(
        competition: competition,
        fullCompetition: fullCompetition,
        competitionController: competitionController,
        participantController: participantController,
        onRegisterTap: _scrollToRegistrationForm,
      ),
      if (includeRegistration) ...[
        const SizedBox(height: 28),
        _buildRegistrationSection(context, participantController),
      ],
    ];
  }

  Widget _buildEventBanner(HomeCompetitionModel competition) {
    final bannerUrl = competitionBrochureBannerUrl(competition);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _bannerAspectRatio,
        child: bannerUrl != null && bannerUrl.isNotEmpty
            ? Image.network(
                bannerUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) =>
                    _buildDefaultEventBanner(competition.competitionName),
              )
            : _buildDefaultEventBanner(competition.competitionName),
      ),
    );
  }

  Widget _buildDefaultEventBanner(String title) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
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
      padding: const EdgeInsets.all(24),
      child: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.2,
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
          if (_registrationSaved)
            RegistrationSuccessPanel(
              participantController: participantController,
              participant: participantController.lastRegisteredParticipant.value,
              onRegisterAnother: () {
                participantController.clearRegistrationConfirmation();
                participantController.resetForm();
              },
            )
          else
            ParticipantRegistrationFormScreen(
              key: ValueKey(
                'embedded-reg-form-${_resolvedCompetitionId ?? ''}',
              ),
              initialCompetitionId: _resolvedCompetitionId ?? '',
              showCompetitionDropdown: false,
              embeddedInLandingPage: true,
            ),
        ],
      ),
    );
  }
}
