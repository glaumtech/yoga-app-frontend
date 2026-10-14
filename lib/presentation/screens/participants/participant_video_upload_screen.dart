import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/layout/home_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/online_participant_login_url.dart';
import '../../../data/models/participant_video_model.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/participant_video_controller.dart';
import '../../controllers/user_management_controller.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/footer_section.dart';
import '../../widgets/pinned_scroll_views.dart';
import '../../widgets/primary_button.dart';
import '../home/home_landing_sections.dart';

/// Dark gaming palette for the Online Participant arena (brand green + gold).
class _ArenaTheme {
  static const Color panel = Color(0xFF121A2B);
  static const Color panelEdge = Color(0xFF1E2A44);
  static const Color gold = Color(0xFFEAB308);
  static const Color silver = Color(0xFFCBD5E1);
  static const Color bronze = Color(0xFFD97706);
  static const Color text = Color(0xFFF8FAFC);
  static const Color muted = Color(0xFF94A3B8);
  static const Color youHighlight = Color(0xFF14532D);
}

class ParticipantVideoUploadScreen extends StatefulWidget {
  final String? registrationNo;

  const ParticipantVideoUploadScreen({super.key, this.registrationNo});

  @override
  State<ParticipantVideoUploadScreen> createState() =>
      _ParticipantVideoUploadScreenState();
}

class _ParticipantVideoUploadScreenState
    extends State<ParticipantVideoUploadScreen> {
  String? _lastAppliedRegistrationNo;
  bool _registrationApplyScheduled = false;

  ParticipantVideoController get _videoController {
    if (!Get.isRegistered<ParticipantVideoController>()) {
      Get.put(ParticipantVideoController(), permanent: true);
    }
    return Get.find<ParticipantVideoController>();
  }

  @override
  void initState() {
    super.initState();
    final controller = _videoController;
    controller.restoreLoginDraft();
    _scheduleApplyResolvedRegistrationNo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleApplyResolvedRegistrationNo();
  }

  @override
  void didUpdateWidget(covariant ParticipantVideoUploadScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleApplyResolvedRegistrationNo();
  }

  /// Applying QR/login Rx updates during build/update triggers Flutter web
  /// window assertions. Always run after the current frame.
  void _scheduleApplyResolvedRegistrationNo() {
    if (_registrationApplyScheduled) return;
    _registrationApplyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registrationApplyScheduled = false;
      if (!mounted) return;
      _applyResolvedRegistrationNo();
    });
  }

  void _applyResolvedRegistrationNo() {
    if (!Get.isRegistered<ParticipantVideoController>()) return;
    final controller = Get.find<ParticipantVideoController>();
    controller.restoreLoginDraft();
    final regNo = _resolveRegistrationNo();
    final normalized = regNo?.trim();
    if (controller.preferFullLoginForm.value) {
      final current = controller.registrationNoController.text.trim();
      final sameAsCurrent =
          normalized != null &&
          normalized.isNotEmpty &&
          current.isNotEmpty &&
          normalized.toUpperCase() == current.toUpperCase();
      if (normalized == null || normalized.isEmpty || sameAsCurrent) {
        controller.loginFromQr.value = false;
        return;
      }
      controller.preferFullLoginForm.value = false;
    }
    if (normalized != null && normalized.isNotEmpty) {
      final sameAsLast =
          _lastAppliedRegistrationNo?.toUpperCase() == normalized.toUpperCase();
      final alreadyQr =
          controller.loginFromQr.value &&
          controller.registrationNoController.text.trim().toUpperCase() ==
              normalized.toUpperCase();
      if (sameAsLast && alreadyQr) return;
      _lastAppliedRegistrationNo = normalized;
      controller.applyQrRegistrationNo(normalized);
    } else if (controller.loginFromQr.value) {
      // Left a QR deep-link (Home / another tab). Keep saved DOB + ID.
      _lastAppliedRegistrationNo = null;
      controller.applyQrRegistrationNo(null);
    }
  }

  String? _resolveRegistrationNo() {
    if (widget.registrationNo != null &&
        widget.registrationNo!.trim().isNotEmpty) {
      return widget.registrationNo!.trim();
    }
    try {
      return registrationNoFromGoRouterState(GoRouterState.of(context));
    } catch (_) {
      return registrationNoFromBrowserUri(Uri.base);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _videoController;
    final userController = Get.put(UserManagementController());
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController());

    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < HomeLayout.mobile;
    final padH = HomeLayout.sectionHorizontalPadding(width);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F6),
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
        if (controller.isRestoringSession.value &&
            controller.session.value == null) {
          return const Center(child: CustomLoader(message: 'Loading...'));
        }
        return PinnedVerticalScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0B1220),
                      Color(0xFF111827),
                      Color(0xFF0F172A),
                    ],
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(padH, 24, padH, 32),
                      child: _ArenaLayout(
                        controller: controller,
                        isMobile: isMobile,
                      ),
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
}

class _ArenaLayout extends StatelessWidget {
  final ParticipantVideoController controller;
  final bool isMobile;

  const _ArenaLayout({
    required this.controller,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loggedIn = controller.isLoggedIn;
      final center = loggedIn
          ? _UploadPanel(controller: controller, isMobile: isMobile)
          : _LoginPanel(controller: controller);

      final weekBoardData = controller.toppers.value?.week;
      final todayBoardData = controller.toppers.value?.today;
      final totalBoardData = controller.toppers.value?.total;
      final weekHasEntries = (weekBoardData?.top10 ?? const []).isNotEmpty;
      final todayHasEntries = (todayBoardData?.top10 ?? const []).isNotEmpty;
      final totalHasEntries = (totalBoardData?.top10 ?? const []).isNotEmpty;
      final hasCompetition =
          (controller.session.value?.competitionId ??
              controller.loginPreview.value?.competitionId) !=
          null;
      // Login: total leaderboard only. After login: all boards when relevant.
      final showTotal =
          loggedIn ||
          totalHasEntries ||
          (hasCompetition && controller.isLoadingToppers.value) ||
          (hasCompetition && totalBoardData?.me != null);
      final showWeek = loggedIn && (weekHasEntries || loggedIn);
      final showToday = loggedIn && (todayHasEntries || loggedIn);

      Widget toppersBoard({
        required String title,
        required String subtitle,
        required ParticipantVideoToppersBoard? board,
      }) {
        return _ToppersBoard(
          title: title,
          subtitle: subtitle,
          board: board,
          isLoading: controller.isLoadingToppers.value,
          error: controller.toppersError.value,
          hasCompetition: hasCompetition,
          currentRegistrationNo:
              (controller.session.value?.registrationNo ??
                      controller.loginPreview.value?.registrationNo ??
                      controller.registrationNoController.text)
                  .trim(),
        );
      }

      final totalBoard = toppersBoard(
        title: 'Total Toppers',
        subtitle: 'Top 3 overall count',
        board: totalBoardData,
      );
      final weekBoard = toppersBoard(
        title: 'Weekly Toppers',
        subtitle: 'Mon–Sun count total',
        board: weekBoardData,
      );
      final todayBoard = toppersBoard(
        title: 'Today Toppers',
        subtitle: 'Highest count today',
        board: todayBoardData,
      );

      if (isMobile) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTotal) ...[
              totalBoard,
              const SizedBox(height: 16),
            ],
            if (showToday) ...[
              todayBoard,
              const SizedBox(height: 16),
            ],
            center,
            if (showWeek) ...[
              const SizedBox(height: 16),
              weekBoard,
            ],
          ],
        );
      }

      if (!showWeek && !showToday && !showTotal) {
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: center,
          ),
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTotal) ...[
            Expanded(flex: 5, child: totalBoard),
            const SizedBox(width: 16),
          ],
          Expanded(flex: 6, child: center),
          if (showToday) ...[
            const SizedBox(width: 16),
            Expanded(flex: 5, child: todayBoard),
          ],
          if (showWeek) ...[
            const SizedBox(width: 16),
            Expanded(flex: 5, child: weekBoard),
          ],
        ],
      );
    });
  }
}

class _LoginPanel extends StatelessWidget {
  final ParticipantVideoController controller;

  const _LoginPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _GamingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() {
            final fromQr = controller.loginFromQr.value;
            final preview = controller.loginPreview.value;
            final loadingPreview = controller.isLoadingLoginPreview.value;
            final previewError = controller.loginPreviewError.value;
            final name = (preview?.participantName ?? '').trim();
            final participantNo =
                (preview?.registrationNo ??
                        controller.registrationNoController.text)
                    .trim();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stackVertically = constraints.maxWidth < 420;
                    final title = Text(
                      'Online Participant login',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.2,
                          ),
                    );
                    final identity = fromQr
                        ? Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: stackVertically
                                ? WrapAlignment.start
                                : WrapAlignment.end,
                            children: [
                              if (loadingPreview)
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              else ...[
                                if (name.isNotEmpty)
                                  _GamingChip(
                                    icon: Icons.person_outline,
                                    label: name,
                                  ),
                                if (participantNo.isNotEmpty)
                                  _GamingChip(
                                    icon: Icons.badge_outlined,
                                    label: participantNo,
                                  ),
                              ],
                            ],
                          )
                        : const SizedBox.shrink();

                    if (stackVertically) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          title,
                          if (fromQr) ...[
                            const SizedBox(height: 10),
                            identity,
                          ],
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: title),
                        if (fromQr) ...[
                          const SizedBox(width: 12),
                          Flexible(child: identity),
                        ],
                      ],
                    );
                  },
                ),
                if (fromQr && previewError.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    previewError,
                    style: const TextStyle(
                      color: Color(0xFFFCA5A5),
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  fromQr
                      ? 'Confirm your date of birth to continue. '
                            'Only participants registered in an Online category can continue.'
                      : 'Sign in with your Participant number and date of birth. '
                            'Only participants registered in an Online category can continue.',
                  style: const TextStyle(
                    color: _ArenaTheme.muted,
                    height: 1.4,
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 24),
          Obx(() {
            if (controller.loginFromQr.value) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _GamingFormLabel(label: 'Participant number'),
                TextFormField(
                  controller: controller.registrationNoController,
                  style: const TextStyle(color: _ArenaTheme.text),
                  textInputAction: TextInputAction.next,
                  decoration: _gamingInputDecoration('e.g. CGA001'),
                  onChanged: (_) {
                    controller.loginPreview.value = null;
                    controller.loginPreviewError.value = '';
                    controller.toppers.value = null;
                    controller.toppersError.value = '';
                  },
                  onFieldSubmitted: (value) {
                    controller.loadLoginPreview(value);
                  },
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
          const _GamingFormLabel(label: 'Date of birth'),
          Obx(() {
            final dob = controller.dateOfBirth.value;
            return InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: dob ?? DateTime.now(),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  await controller.setDateOfBirth(picked);
                }
              },
              child: InputDecorator(
                decoration: _gamingInputDecoration('Select date of birth'),
                child: Text(
                  dob == null
                      ? 'Select date of birth'
                      : DateFormat('dd MMM yyyy').format(dob),
                  style: TextStyle(
                    color: dob == null
                        ? _ArenaTheme.muted
                        : _ArenaTheme.text,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          Obx(
            () => PrimaryButton(
              text: 'Continue',
              isLoading: controller.isLoading.value,
              onPressedAsync: controller.isLoading.value
                  ? null
                  : () async {
                      if (!controller.loginFromQr.value) {
                        await controller.loadLoginPreview(
                          controller.registrationNoController.text,
                        );
                      }
                      await controller.login();
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadPanel extends StatelessWidget {
  final ParticipantVideoController controller;
  final bool isMobile;

  const _UploadPanel({required this.controller, required this.isMobile});

  Future<void> _switchParticipant(BuildContext context) async {
    await controller.switchParticipant();
    if (!context.mounted) return;
    context.go(AppRoutes.participantVideoUpload);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final session = controller.session.value;
      if (session == null) return const SizedBox.shrink();
      final started = controller.hasStarted;
      final mode = controller.activeMode;

      final actionStyle = TextButton.styleFrom(
        foregroundColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GamingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stackHeader =
                        isMobile || constraints.maxWidth < 420;
                    final title = Text(
                      started ? 'Daily log' : 'Start your daily log',
                      maxLines: stackHeader ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    );
                    final actions = Wrap(
                      spacing: 4,
                      runSpacing: 0,
                      alignment: stackHeader
                          ? WrapAlignment.end
                          : WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => _switchParticipant(context),
                          style: actionStyle,
                          child: const Text('Switch participant'),
                        ),
                        TextButton.icon(
                          onPressed: controller.isOpeningFeedback.value
                              ? null
                              : controller.openFeedbackDialog,
                          style: actionStyle,
                          icon: controller.isOpeningFeedback.value
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              : const Icon(
                                  Icons.rate_review_outlined,
                                  size: 18,
                                ),
                          label: const Text('Feedback'),
                        ),
                      ],
                    );
                    if (stackHeader) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          title,
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: actions,
                          ),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: title),
                        Flexible(child: actions),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((session.participantName ?? '').trim().isNotEmpty)
                      _GamingChip(
                        icon: Icons.person_outline,
                        label: session.participantName!,
                      ),
                    if ((session.registrationNo ?? '').trim().isNotEmpty)
                      _GamingChip(
                        icon: Icons.badge_outlined,
                        label: session.registrationNo!,
                      ),
                    if ((session.categoryName ?? '').trim().isNotEmpty)
                      _GamingChip(
                        icon: Icons.category_outlined,
                        label: session.categoryName!,
                      ),
                  ],
                ),
                if ((session.competitionName ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    session.competitionName!,
                    style: const TextStyle(
                      color: _ArenaTheme.muted,
                      height: 1.4,
                    ),
                  ),
                ],
                if (controller.canDownloadCertificate ||
                    controller.certificatePendingMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  if (controller.canDownloadCertificate)
                    PrimaryButton(
                      text: 'Download e-certificate',
                      icon: Icons.workspace_premium_outlined,
                      isLoading: controller.isDownloadingCertificate.value,
                      onPressed: controller.isDownloadingCertificate.value
                          ? null
                          : controller.downloadECertificate,
                    )
                  else
                    Text(
                      controller.certificatePendingMessage,
                      style: const TextStyle(
                        color: _ArenaTheme.muted,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (controller.successMessage.value.isNotEmpty)
            _Banner(
              color: const Color(0xFF14532D),
              border: AppTheme.primaryColor.withValues(alpha: 0.55),
              icon: Icons.check_circle_outline,
              iconColor: AppTheme.primaryColor,
              text: controller.successMessage.value,
              textColor: _ArenaTheme.text,
            ),
          if (controller.errorMessage.value.isNotEmpty) ...[
            if (controller.successMessage.value.isNotEmpty)
              const SizedBox(height: 10),
            _Banner(
              color: const Color(0xFF450A0A),
              border: const Color(0xFFF87171),
              icon: Icons.error_outline,
              iconColor: const Color(0xFFFCA5A5),
              text: controller.errorMessage.value,
              textColor: const Color(0xFFFECACA),
            ),
          ],
          const SizedBox(height: 16),
          if (!started)
            _GamingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tap Start to open your calendar.',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: _ArenaTheme.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'The calendar begins on the day you tap Start.',
                    style: TextStyle(color: _ArenaTheme.muted, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: 'Start',
                    icon: Icons.play_arrow_rounded,
                    isLoading: controller.isStarting.value,
                    onPressed: controller.isStarting.value
                        ? null
                        : () async {
                            final ok = await controller.startDailyLog();
                            if (!ok || !context.mounted) return;
                            final today = controller.today;
                            if (controller.isSelectableDate(today) &&
                                !controller.isDurationExpiredDate(today)) {
                              await _openDateLogDialog(
                                context,
                                controller: controller,
                                date: today,
                                isMobile: isMobile,
                              );
                            }
                          },
                  ),
                ],
              ),
            )
          else ...[
            _GamingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Calendar starts ${DateFormat('dd MMM yyyy').format(controller.startedOn!)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _ArenaTheme.text,
                    ),
                  ),
                  if (mode == ParticipantVideoController.modeCount) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _CountHighlightChip(
                          label: 'Day count',
                          value: controller.dayCountHighlight.value
                                  ?.toString() ??
                              '—',
                        ),
                        _CountHighlightChip(
                          label: 'Days entered',
                          value: controller.configuredDurationDays != null
                              ? '${controller.enteredCountDayHighlight.value}/${controller.configuredDurationDays}'
                              : '${controller.enteredCountDayHighlight.value}',
                        ),
                        _CountHighlightChip(
                          label: 'Total count',
                          value: '${controller.totalCountHighlight.value}',
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  _DailyCalendar(controller: controller, isMobile: isMobile),
                  const SizedBox(height: 8),
                  const Text(
                    'Highlighted dates are saved. Count dates show the number; video or URL dates show an icon.',
                    style: TextStyle(
                      color: _ArenaTheme.muted,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  if (controller.canDownloadCertificate) ...[
                    const SizedBox(height: 16),
                    PrimaryButton(
                      text: 'Download e-certificate',
                      icon: Icons.workspace_premium_outlined,
                      isLoading: controller.isDownloadingCertificate.value,
                      onPressed: controller.isDownloadingCertificate.value
                          ? null
                          : controller.downloadECertificate,
                    ),
                  ] else if (controller
                      .certificatePendingMessage
                      .isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      controller.certificatePendingMessage,
                      style: const TextStyle(
                        color: _ArenaTheme.muted,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _CountOrVideoChoice extends StatelessWidget {
  final ParticipantVideoController controller;

  const _CountOrVideoChoice({required this.controller});

  @override
  Widget build(BuildContext context) {
    final date = controller.selectedDate.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          date == null
              ? 'Choose Count or Video'
              : 'Choose for the start date (${DateFormat('dd MMM yyyy').format(date)})',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: _ArenaTheme.text,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'This choice will be used for all later dates.',
          style: TextStyle(color: _ArenaTheme.muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ChoiceButton(
                icon: Icons.numbers,
                label: 'Count',
                onTap: controller.chooseCount,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ChoiceButton(
                icon: Icons.videocam_outlined,
                label: 'Video',
                onTap: controller.chooseVideo,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primaryColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountForm extends StatelessWidget {
  final ParticipantVideoController controller;
  final DateTime selectedDate;

  const _CountForm({required this.controller, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Count for ${DateFormat('dd MMM yyyy').format(selectedDate)}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: _ArenaTheme.text,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter the count for this date.',
          style: TextStyle(color: _ArenaTheme.muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        const _GamingFormLabel(label: 'Count'),
        TextFormField(
          controller: controller.countController,
          style: const TextStyle(color: _ArenaTheme.text),
          keyboardType: TextInputType.number,
          decoration: _gamingInputDecoration('e.g. 12'),
        ),
        const SizedBox(height: 14),
        Obx(
          () => PrimaryButton(
            text: controller.selectedEntry?.isCount == true
                ? 'Update count'
                : 'Save count',
            icon: Icons.save_outlined,
            isLoading: controller.isSavingCount.value,
            onPressed: controller.isSavingCount.value
                ? null
                : () async {
                    final saved = await controller.saveCount();
                    if (saved && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
          ),
        ),
      ],
    );
  }
}

class _DailyCalendar extends StatelessWidget {
  final ParticipantVideoController controller;
  final bool isMobile;

  const _DailyCalendar({required this.controller, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final month = controller.visibleCalendarMonth;
      final selected = controller.selectedDate.value;
      final canPrev = controller.canGoToPreviousMonth;
      final canNext = controller.canGoToNextMonth;
      final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;
      final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
      final rowCount = ((firstWeekday + daysInMonth + 6) ~/ 7);
      const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

      return Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: canPrev ? () => controller.changeMonth(-1) : null,
                color: _ArenaTheme.text,
                disabledColor: _ArenaTheme.muted.withValues(alpha: 0.4),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: _ArenaTheme.text,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: canNext ? () => controller.changeMonth(1) : null,
                color: _ArenaTheme.text,
                disabledColor: _ArenaTheme.muted.withValues(alpha: 0.4),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                controller.goToToday();
                final today = controller.selectedDate.value ?? controller.today;
                if (controller.isSelectableDate(today) &&
                    !controller.isDurationExpiredDate(today)) {
                  _openDateLogDialog(
                    context,
                    controller: controller,
                    date: today,
                    isMobile: isMobile,
                  );
                }
              },
              icon: Icon(
                Icons.today_outlined,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              label: Text(
                'Today',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final label in labels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _ArenaTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (var row = 0; row < rowCount; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: _CalendarDayCell(
                        controller: controller,
                        date: _cellDate(
                          year: month.year,
                          month: month.month,
                          firstWeekday: firstWeekday,
                          daysInMonth: daysInMonth,
                          row: row,
                          col: col,
                        ),
                        selected: selected,
                        isMobile: isMobile,
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
    });
  }

  DateTime? _cellDate({
    required int year,
    required int month,
    required int firstWeekday,
    required int daysInMonth,
    required int row,
    required int col,
  }) {
    final day = row * 7 + col - firstWeekday + 1;
    if (day < 1 || day > daysInMonth) return null;
    return DateTime(year, month, day);
  }
}

class _CalendarDayCell extends StatelessWidget {
  final ParticipantVideoController controller;
  final DateTime? date;
  final DateTime? selected;
  final bool isMobile;

  const _CalendarDayCell({
    required this.controller,
    required this.date,
    required this.selected,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final day = date;
    if (day == null) {
      return const SizedBox(height: 52);
    }
    final selectable = controller.isSelectableDate(day);
    final expired = controller.isDurationExpiredDate(day);
    final entry = controller.session.value?.entryFor(day);
    final submitted = entry?.hasSubmission == true;
    final isSelected =
        selected != null &&
        selected!.year == day.year &&
        selected!.month == day.month &&
        selected!.day == day.day;
    final isToday =
        controller.today.year == day.year &&
        controller.today.month == day.month &&
        controller.today.day == day.day;

    Color? background;
    Color border = Colors.transparent;
    Color textColor = selectable
        ? _ArenaTheme.text
        : _ArenaTheme.muted.withValues(alpha: 0.45);
    if (submitted && !expired) {
      background = AppTheme.primaryColor.withValues(alpha: 0.22);
      textColor = AppTheme.primaryColor;
    }
    if (isSelected) {
      border = AppTheme.primaryColor;
      background ??= AppTheme.primaryColor.withValues(alpha: 0.14);
    } else if (isToday && selectable) {
      border = AppTheme.primaryColor.withValues(alpha: 0.7);
      background ??= AppTheme.primaryColor.withValues(alpha: 0.12);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: background ?? const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: selectable
              ? () {
                  if (expired) {
                    AppDialog.show(
                      context,
                      title: 'Continue your challenge',
                      message:
                          'You\'ve completed the days set for this challenge.\n\n'
                          'Renew to keep going and log your count for more days.',
                      confirmText: 'Got it',
                    );
                    return;
                  }
                  _openDateLogDialog(
                    context,
                    controller: controller,
                    date: day,
                    isMobile: isMobile,
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: border,
                width: isSelected || (isToday && selectable) ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                if (entry?.isCount == true)
                  Text(
                    '${entry!.countValue ?? 0}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  )
                else if (entry?.hasUrl == true || entry?.hasFile == true)
                  Icon(
                    entry?.hasUrl == true ? Icons.link : Icons.videocam,
                    size: 12,
                    color: AppTheme.primaryColor,
                  )
                else
                  const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openDateLogDialog(
  BuildContext context, {
  required ParticipantVideoController controller,
  required DateTime date,
  required bool isMobile,
}) async {
  controller.selectDate(date);
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) =>
        _DateLogDialog(controller: controller, isMobile: isMobile),
  );
  controller.clearSelectedDate();
}

class _DateLogDialog extends StatelessWidget {
  final ParticipantVideoController controller;
  final bool isMobile;

  const _DateLogDialog({required this.controller, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _ArenaTheme.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.primaryColor.withValues(alpha: 0.4),
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Obx(() {
          final selectedDate = controller.selectedDate.value;
          final selectedEntry = controller.selectedEntry;
          final mode = controller.activeMode;
          final hasUrl = selectedEntry?.hasUrl == true;
          final showFile = controller.useFileUpload.value;
          final error = controller.errorMessage.value;
          final success = controller.successMessage.value;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedDate == null
                            ? 'Daily log'
                            : DateFormat('dd MMM yyyy').format(selectedDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: _ArenaTheme.text,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      color: _ArenaTheme.muted,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (success.isNotEmpty) ...[
                        _Banner(
                          color: const Color(0xFF14532D),
                          border: AppTheme.primaryColor.withValues(alpha: 0.55),
                          icon: Icons.check_circle_outline,
                          iconColor: AppTheme.primaryColor,
                          text: success,
                          textColor: _ArenaTheme.text,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (error.isNotEmpty) ...[
                        _Banner(
                          color: const Color(0xFF450A0A),
                          border: const Color(0xFFF87171),
                          icon: Icons.error_outline,
                          iconColor: const Color(0xFFFCA5A5),
                          text: error,
                          textColor: const Color(0xFFFECACA),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (controller.canChangeMode && mode != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: controller.resetChosenMode,
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                            ),
                            child: const Text('Change Count / Video'),
                          ),
                        ),
                      if (controller.showSavedEntryBanner &&
                          selectedEntry != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _Banner(
                            color: const Color(0xFF0F172A),
                            border: AppTheme.primaryColor.withValues(alpha: 0.45),
                            icon: selectedEntry.isCount
                                ? Icons.numbers
                                : Icons.videocam_outlined,
                            iconColor: AppTheme.primaryColor,
                            text: selectedEntry.isCount
                                ? 'Saved count: ${selectedEntry.countValue ?? 0}'
                                : hasUrl
                                ? 'Saved URL: ${selectedEntry.videoUrl ?? ''}'
                                : 'Uploaded file: ${selectedEntry.originalFileName ?? 'video'}'
                                      '${selectedEntry.resolution != null ? ' (${selectedEntry.resolution})' : ''}',
                            textColor: _ArenaTheme.text,
                          ),
                        ),
                      if (mode == null && controller.isStartDateSelected)
                        _CountOrVideoChoice(controller: controller)
                      else if (mode == null)
                        Text(
                          'Choose Count or Video on ${DateFormat('dd MMM yyyy').format(controller.startedOn!)} first.',
                          style: const TextStyle(
                            color: _ArenaTheme.muted,
                            height: 1.4,
                          ),
                        )
                      else if (mode == ParticipantVideoController.modeCount &&
                          selectedDate != null)
                        _CountForm(
                          controller: controller,
                          selectedDate: selectedDate,
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              selectedDate == null
                                  ? 'Video'
                                  : 'Video for ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: _ArenaTheme.text,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _ModeToggle(
                              useFileUpload: showFile,
                              isMobile: isMobile,
                              onSelectUrl: controller.showUrlOption,
                              onSelectFile: controller.showFileOption,
                            ),
                            const SizedBox(height: 20),
                            if (showFile)
                              _FileForm(controller: controller)
                            else
                              _UrlForm(
                                controller: controller,
                                hasSavedUrl: hasUrl,
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool useFileUpload;
  final bool isMobile;
  final VoidCallback onSelectUrl;
  final VoidCallback onSelectFile;

  const _ModeToggle({
    required this.useFileUpload,
    required this.isMobile,
    required this.onSelectUrl,
    required this.onSelectFile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ArenaTheme.panelEdge),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              selected: !useFileUpload,
              icon: Icons.link,
              label: isMobile ? 'Video URL' : 'Paste video URL',
              onTap: onSelectUrl,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ModeButton(
              selected: useFileUpload,
              icon: Icons.upload_file_rounded,
              label: isMobile ? 'Upload file' : 'Upload MP4 file',
              onTap: onSelectFile,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ModeButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppTheme.primaryColor.withValues(alpha: 0.18)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppTheme.primaryColor : _ArenaTheme.muted,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppTheme.primaryColor
                        : _ArenaTheme.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UrlForm extends StatelessWidget {
  final ParticipantVideoController controller;
  final bool hasSavedUrl;

  const _UrlForm({required this.controller, required this.hasSavedUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Paste a video link',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: _ArenaTheme.text,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'YouTube, Google Drive, Vimeo, or any public video URL.',
          style: TextStyle(color: _ArenaTheme.muted, height: 1.4),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.videoUrlController,
          style: const TextStyle(color: _ArenaTheme.text),
          decoration: _gamingInputDecoration('https://...'),
        ),
        const SizedBox(height: 14),
        Obx(
          () => PrimaryButton(
            text: hasSavedUrl ? 'Update URL' : 'Save URL',
            icon: Icons.link,
            isLoading: controller.isSavingUrl.value,
            onPressed: controller.isSavingUrl.value
                ? null
                : () async {
                    final saved = await controller.saveUrl();
                    if (saved && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
          ),
        ),
      ],
    );
  }
}

class _FileForm extends StatelessWidget {
  final ParticipantVideoController controller;

  const _FileForm({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final blockedReason = controller.uploadBlockedReason;
      final canUpload = blockedReason.isEmpty;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Upload an MP4 file',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: _ArenaTheme.text,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '720p or 1080p MP4 only. Maximum 500 MB.',
            style: TextStyle(color: _ArenaTheme.muted, height: 1.4),
          ),
          if (!canUpload) ...[
            const SizedBox(height: 16),
            _Banner(
              color: const Color(0xFF422006),
              border: const Color(0xFFFBBF24),
              icon: Icons.info_outline,
              iconColor: const Color(0xFFFBBF24),
              text: blockedReason,
              textColor: const Color(0xFFFDE68A),
            ),
          ],
          const SizedBox(height: 16),
          Opacity(
            opacity: canUpload ? 1 : 0.55,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (controller.isUploading.value || !canUpload)
                    ? null
                    : () {
                        controller.pickVideo();
                      },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 36,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        controller.isUploading.value
                            ? 'Uploading video...'
                            : controller.pickedFileBytes.value != null
                            ? 'Tap to choose a different MP4'
                            : 'Tap to choose MP4 file',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      if (controller.pickedFileName.value.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          controller.pickedFileName.value,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _ArenaTheme.muted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (controller.pickedFileBytes.value != null) ...[
            const SizedBox(height: 14),
            PrimaryButton(
              text: 'Upload Video',
              icon: Icons.cloud_upload_rounded,
              isLoading: false,
              onPressed: controller.isUploading.value
                  ? null
                  : () async {
                      final saved = await controller.uploadSelectedVideo();
                      if (saved && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
            ),
          ],
          if (controller.isUploading.value) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    controller.isSavingToDrive.value
                        ? 'Saving to Google Drive...'
                        : 'Uploading video...',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${(controller.uploadProgress.value * 100).round()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: controller.uploadProgress.value,
                minHeight: 10,
                backgroundColor: const Color(0xFF1E293B),
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.isSavingToDrive.value
                  ? 'Upload complete. Please wait while Google Drive confirms the file.'
                  : 'Do not close this page while the video is uploading.',
              style: const TextStyle(
                color: _ArenaTheme.muted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _CountHighlightChip extends StatelessWidget {
  final String label;
  final String value;

  const _CountHighlightChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor.withValues(alpha: 0.85),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final Color border;
  final IconData icon;
  final Color iconColor;
  final String text;
  final Color textColor;

  const _Banner({
    required this.color,
    required this.border,
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: textColor, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _GamingCard extends StatelessWidget {
  final Widget child;

  const _GamingCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ArenaTheme.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.45),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.18),
            blurRadius: 28,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GamingChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GamingChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ArenaTheme.panelEdge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _ArenaTheme.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _GamingFormLabel extends StatelessWidget {
  final String label;

  const _GamingFormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: _ArenaTheme.muted,
        ),
      ),
    );
  }
}

class _ToppersBoard extends StatelessWidget {
  final String title;
  final String subtitle;
  final ParticipantVideoToppersBoard? board;
  final bool isLoading;
  final String error;
  final bool hasCompetition;
  final String currentRegistrationNo;

  const _ToppersBoard({
    required this.title,
    required this.subtitle,
    required this.board,
    required this.isLoading,
    required this.error,
    required this.hasCompetition,
    required this.currentRegistrationNo,
  });

  @override
  Widget build(BuildContext context) {
    final me = board?.me;
    final top10 = board?.top10 ?? const <ParticipantVideoTopperEntry>[];
    final total = board?.totalParticipants ?? 0;
    final currentUpper = currentRegistrationNo.toUpperCase();
    final meInTop10 = me != null &&
        top10.any(
          (e) =>
              (e.registrationNo ?? '').trim().toUpperCase() ==
              (me.registrationNo ?? '').trim().toUpperCase(),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: _ArenaTheme.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ArenaTheme.panelEdge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_outlined, color: _ArenaTheme.gold, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _ArenaTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: _ArenaTheme.panelEdge),
          const SizedBox(height: 10),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (!hasCompetition)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Enter participant number to load toppers.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _ArenaTheme.muted, height: 1.35),
              ),
            )
          else if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFFCA5A5), height: 1.35),
              ),
            )
          else if (top10.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No count submissions yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _ArenaTheme.muted, height: 1.35),
              ),
            )
          else
            ...top10.map((entry) {
              final isYou = currentUpper.isNotEmpty &&
                  (entry.registrationNo ?? '').trim().toUpperCase() ==
                      currentUpper;
              return _TopperRow(entry: entry, isYou: isYou);
            }),
          if (!isLoading &&
              hasCompetition &&
              error.isEmpty &&
              me != null &&
              !meInTop10) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: _ArenaTheme.youHighlight.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                'Your rank: #${me.rank} of $total · ${me.score}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ArenaTheme.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopperRow extends StatelessWidget {
  final ParticipantVideoTopperEntry entry;
  final bool isYou;

  const _TopperRow({required this.entry, required this.isYou});

  @override
  Widget build(BuildContext context) {
    final name = (entry.participantName ?? '').trim();
    final regNo = (entry.registrationNo ?? '').trim();
    final label = name.isNotEmpty ? name : (regNo.isNotEmpty ? regNo : '—');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isYou
            ? _ArenaTheme.youHighlight.withValues(alpha: 0.65)
            : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isYou
              ? AppTheme.primaryColor.withValues(alpha: 0.55)
              : _ArenaTheme.panelEdge,
        ),
      ),
      child: Row(
        children: [
          _RankBadge(rank: entry.rank),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isYou ? '$label (You)' : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ArenaTheme.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (name.isNotEmpty && regNo.isNotEmpty)
                  Text(
                    regNo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ArenaTheme.muted,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              '${entry.score}',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gaming medal / rank pill for leaderboard rows.
class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  bool get _isPodium => rank >= 1 && rank <= 3;

  List<Color> get _gradientColors {
    switch (rank) {
      case 1:
        return const [Color(0xFFFFF1A8), Color(0xFFEAB308), Color(0xFFB45309)];
      case 2:
        return const [Color(0xFFF1F5F9), Color(0xFF94A3B8), Color(0xFF64748B)];
      case 3:
        return const [Color(0xFFFED7AA), Color(0xFFD97706), Color(0xFF9A3412)];
      default:
        return const [Color(0xFF334155), Color(0xFF1E293B)];
    }
  }

  Color get _glowColor {
    switch (rank) {
      case 1:
        return _ArenaTheme.gold;
      case 2:
        return _ArenaTheme.silver;
      case 3:
        return _ArenaTheme.bronze;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData? get _podiumIcon {
    switch (rank) {
      case 1:
        return Icons.workspace_premium_rounded;
      case 2:
        return Icons.military_tech_rounded;
      case 3:
        return Icons.emoji_events_rounded;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _podiumIcon;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: _isPodium ? 0.55 : 0.18),
          width: _isPodium ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _glowColor.withValues(alpha: _isPodium ? 0.55 : 0.22),
            blurRadius: _isPodium ? 12 : 6,
            spreadRadius: _isPodium ? 0.5 : 0,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (icon != null)
            Positioned(
              top: 3,
              child: Icon(
                icon,
                size: 11,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: icon != null ? 8 : 0),
            child: Text(
              '$rank',
              style: TextStyle(
                color: _isPodium
                    ? const Color(0xFF111827)
                    : _ArenaTheme.text,
                fontWeight: FontWeight.w900,
                fontSize: _isPodium ? 14 : 13,
                height: 1,
                shadows: _isPodium
                    ? [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.35),
                          offset: const Offset(0, 1),
                          blurRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _gamingInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _ArenaTheme.muted),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _ArenaTheme.panelEdge),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    filled: true,
    fillColor: const Color(0xFF0F172A),
  );
}
