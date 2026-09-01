import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/layout/home_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/online_participant_login_url.dart';
import '../../../routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/participant_video_controller.dart';
import '../../controllers/user_management_controller.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/custom_loader.dart';
import '../../widgets/footer_section.dart';
import '../../widgets/form_label_with_hint.dart';
import '../../widgets/pinned_scroll_views.dart';
import '../../widgets/primary_button.dart';
import '../home/home_landing_sections.dart';

class ParticipantVideoUploadScreen extends StatefulWidget {
  final String? registrationNo;

  const ParticipantVideoUploadScreen({super.key, this.registrationNo});

  @override
  State<ParticipantVideoUploadScreen> createState() =>
      _ParticipantVideoUploadScreenState();
}

class _ParticipantVideoUploadScreenState
    extends State<ParticipantVideoUploadScreen> {
  @override
  void initState() {
    super.initState();
    final controller = Get.put(ParticipantVideoController());
    final regNo = _resolveRegistrationNo();
    if (regNo != null && regNo.isNotEmpty) {
      controller.applyQrRegistrationNo(regNo);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyResolvedRegistrationNo();
  }

  @override
  void didUpdateWidget(covariant ParticipantVideoUploadScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyResolvedRegistrationNo();
  }

  void _applyResolvedRegistrationNo() {
    if (!Get.isRegistered<ParticipantVideoController>()) return;
    Get.find<ParticipantVideoController>().applyQrRegistrationNo(
      _resolveRegistrationNo(),
    );
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
    final controller = Get.put(ParticipantVideoController());
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
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(padH, 24, padH, 32),
                    child: controller.isLoggedIn
                        ? _UploadPanel(
                            controller: controller,
                            isMobile: isMobile,
                          )
                        : _LoginPanel(controller: controller),
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

class _LoginPanel extends StatelessWidget {
  final ParticipantVideoController controller;

  const _LoginPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Online Participant login',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            if (controller.loginFromQr.value) {
              return Text(
                'Confirm your date of birth to continue. '
                'Only participants registered in an Online category can continue.',
                style: TextStyle(color: AppColors.textMuted, height: 1.4),
              );
            }
            return Text(
              'Sign in with your Participant ID (registration number) and date of birth. '
              'Only participants registered in an Online category can continue.',
              style: TextStyle(color: AppColors.textMuted, height: 1.4),
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
                const FormLabelWithHint(label: 'Participant ID'),
                TextFormField(
                  controller: controller.registrationNoController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('e.g. CGA001'),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
          const FormLabelWithHint(label: 'Date of birth'),
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
                  controller.dateOfBirth.value = picked;
                }
              },
              child: InputDecorator(
                decoration: _inputDecoration('Select date of birth'),
                child: Text(
                  dob == null
                      ? 'Select date of birth'
                      : DateFormat('dd MMM yyyy').format(dob),
                  style: TextStyle(
                    color: dob == null
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final session = controller.session.value;
      if (session == null) return const SizedBox.shrink();
      final started = controller.hasStarted;
      final selectedDate = controller.selectedDate.value;
      final selectedEntry = controller.selectedEntry;
      final mode = controller.activeMode;
      final hasUrl = selectedEntry?.hasUrl == true;
      final showFile = controller.useFileUpload.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isMobile) ...[
                  Text(
                    started ? 'Daily log' : 'Start your daily log',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 0,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton(
                          onPressed: controller.logout,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Switch participant'),
                        ),
                        TextButton.icon(
                          onPressed: controller.isOpeningFeedback.value
                              ? null
                              : controller.openFeedbackDialog,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: controller.isOpeningFeedback.value
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.rate_review_outlined,
                                  size: 18,
                                ),
                          label: const Text('Feedback'),
                        ),
                      ],
                    ),
                  ),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          started
                              ? 'Daily log'
                              : 'Start your daily log',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                              ),
                        ),
                      ),
                      TextButton(
                        onPressed: controller.logout,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Switch participant'),
                      ),
                      TextButton.icon(
                        onPressed: controller.isOpeningFeedback.value
                            ? null
                            : controller.openFeedbackDialog,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: controller.isOpeningFeedback.value
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.rate_review_outlined,
                                size: 18,
                              ),
                        label: const Text('Feedback'),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((session.participantName ?? '').trim().isNotEmpty)
                      _InfoChip(
                        icon: Icons.person_outline,
                        label: session.participantName!,
                      ),
                    if ((session.registrationNo ?? '').trim().isNotEmpty)
                      _InfoChip(
                        icon: Icons.badge_outlined,
                        label: session.registrationNo!,
                      ),
                    if ((session.categoryName ?? '').trim().isNotEmpty)
                      _InfoChip(
                        icon: Icons.category_outlined,
                        label: session.categoryName!,
                      ),
                  ],
                ),
                if ((session.competitionName ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    session.competitionName!,
                    style: TextStyle(color: AppColors.textMuted, height: 1.4),
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
                      style: TextStyle(
                        color: AppColors.textMuted,
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
              color: const Color(0xFFECFDF3),
              border: const Color(0xFF86EFAC),
              icon: Icons.check_circle_outline,
              iconColor: const Color(0xFF15803D),
              text: controller.successMessage.value,
              textColor: const Color(0xFF166534),
            ),
          if (controller.errorMessage.value.isNotEmpty) ...[
            if (controller.successMessage.value.isNotEmpty)
              const SizedBox(height: 10),
            _Banner(
              color: const Color(0xFFFEF2F2),
              border: const Color(0xFFFECACA),
              icon: Icons.error_outline,
              iconColor: const Color(0xFFDC2626),
              text: controller.errorMessage.value,
              textColor: const Color(0xFFB91C1C),
            ),
          ],
          const SizedBox(height: 16),
          if (!started)
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tap Start to open your calendar.',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'The calendar begins on the day you tap Start. Then choose Count or Video for the first date; later dates use the same option.',
                    style: TextStyle(color: AppColors.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: 'Start',
                    icon: Icons.play_arrow_rounded,
                    isLoading: controller.isStarting.value,
                    onPressed: controller.isStarting.value
                        ? null
                        : () {
                            controller.startDailyLog();
                          },
                  ),
                ],
              ),
            )
          else ...[
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Calendar starts ${DateFormat('dd MMM yyyy').format(controller.startedOn!)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mode == ParticipantVideoController.modeCount
                        ? 'Count is selected for all dates.'
                        : mode == ParticipantVideoController.modeVideo
                        ? 'Video is selected for all dates.'
                        : controller.session.value?.hasConfiguredType == true
                        ? 'This category is already set to Count or Video.'
                        : 'Choose Count or Video on the start date. Later dates use the same option.',
                    style: TextStyle(color: AppColors.textMuted, height: 1.4),
                  ),
                  if (controller.configuredDurationDays != null &&
                      controller.durationEndsOn != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      controller.configuredDurationDays == 1
                          ? 'You can log count for 1 day only (${DateFormat('dd MMM yyyy').format(controller.durationEndsOn!)}).'
                          : 'You can log count for ${controller.configuredDurationDays} days, until ${DateFormat('dd MMM yyyy').format(controller.durationEndsOn!)}.',
                      style: TextStyle(color: AppColors.textMuted, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _DailyCalendar(controller: controller),
                  const SizedBox(height: 8),
                  Text(
                    'Highlighted dates are saved. Count dates show the number; video or URL dates show an icon.',
                    style: TextStyle(
                      color: AppColors.textMuted,
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
                  ] else if (controller.certificatePendingMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      controller.certificatePendingMessage,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selectedDate != null) ...[
              const SizedBox(height: 16),
              if (controller.canChangeMode && mode != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: controller.resetChosenMode,
                    child: const Text('Change Count / Video'),
                  ),
                ),
              if (controller.showSavedEntryBanner && selectedEntry != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _Banner(
                    color: const Color(0xFFEFF6FF),
                    border: const Color(0xFFBFDBFE),
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
                    textColor: AppColors.textSecondary,
                  ),
                ),
              if (mode == null && controller.isStartDateSelected)
                _Card(
                  child: _CountOrVideoChoice(controller: controller),
                )
              else if (mode == null)
                _Card(
                  child: Text(
                    'Choose Count or Video on ${DateFormat('dd MMM yyyy').format(controller.startedOn!)} first.',
                    style: TextStyle(color: AppColors.textMuted, height: 1.4),
                  ),
                )
              else if (mode == ParticipantVideoController.modeCount)
                _Card(
                  child: _CountForm(
                    controller: controller,
                    selectedDate: selectedDate,
                  ),
                )
              else
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Video for ${DateFormat('dd MMM yyyy').format(selectedDate)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
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
                ),
            ],
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
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          'This choice will be used for all later dates.',
          style: TextStyle(color: AppColors.textMuted, height: 1.4),
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
      color: AppTheme.primaryColor.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
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

  const _CountForm({
    required this.controller,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Count for ${DateFormat('dd MMM yyyy').format(selectedDate)}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter the count for this date.',
          style: TextStyle(color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: 16),
        const FormLabelWithHint(label: 'Count'),
        TextFormField(
          controller: controller.countController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('e.g. 12'),
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
                : () {
                    controller.saveCount();
                  },
          ),
        ),
      ],
    );
  }
}

class _DailyCalendar extends StatelessWidget {
  final ParticipantVideoController controller;

  const _DailyCalendar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final month = controller.calendarMonth.value ??
        DateTime(controller.today.year, controller.today.month, 1);
    final start = controller.startedOn!;
    final today = controller.today;
    final selected = controller.selectedDate.value;
    final canPrev = DateTime(month.year, month.month, 1)
        .isAfter(DateTime(start.year, start.month, 1));
    final canNext = DateTime(month.year, month.month, 1)
        .isBefore(DateTime(today.year, today.month, 1));
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final rowCount = ((firstWeekday + daysInMonth + 6) ~/ 7);
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: canPrev ? () => controller.changeMonth(-1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                DateFormat('MMMM yyyy').format(month),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(
              onPressed: canNext ? () => controller.changeMonth(1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final label in labels)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
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
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
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

  const _CalendarDayCell({
    required this.controller,
    required this.date,
    required this.selected,
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
    final isSelected = selected != null &&
        selected!.year == day.year &&
        selected!.month == day.month &&
        selected!.day == day.day;
    final isToday = controller.today.year == day.year &&
        controller.today.month == day.month &&
        controller.today.day == day.day;

    Color? background;
    Color border = Colors.transparent;
    Color textColor = selectable ? AppColors.textPrimary : AppColors.textDisabled;
    if (submitted && !expired) {
      background = AppTheme.primaryColor.withValues(alpha: 0.16);
      textColor = AppTheme.primaryColor;
    }
    if (isSelected) {
      border = AppTheme.primaryColor;
      background ??= AppTheme.primaryColor.withValues(alpha: 0.08);
    } else if (isToday && selectable) {
      border = AppTheme.primaryColor.withValues(alpha: 0.45);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: background ?? Colors.transparent,
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
                  controller.selectDate(day);
                }
              : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border, width: isSelected ? 2 : 1),
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
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
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
      color: selected ? Colors.white : Colors.transparent,
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
                color: selected ? AppTheme.primaryColor : AppColors.textMuted,
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
                        : AppColors.textMuted,
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

  const _UrlForm({
    required this.controller,
    required this.hasSavedUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Paste a video link',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          'YouTube, Google Drive, Vimeo, or any public video URL.',
          style: TextStyle(color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: controller.videoUrlController,
          decoration: _inputDecoration('https://...'),
        ),
        const SizedBox(height: 14),
        Obx(
          () => PrimaryButton(
            text: hasSavedUrl ? 'Update URL' : 'Save URL',
            icon: Icons.link,
            isLoading: controller.isSavingUrl.value,
            onPressed: controller.isSavingUrl.value
                ? null
                : () {
                    controller.saveUrl();
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
    final blockedReason = controller.uploadBlockedReason;
    final canUpload = blockedReason.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Upload an MP4 file',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          '720p or 1080p MP4 only. Maximum 500 MB.',
          style: TextStyle(color: AppColors.textMuted, height: 1.4),
        ),
        if (!canUpload) ...[
          const SizedBox(height: 16),
          _Banner(
            color: const Color(0xFFFFFBEB),
            border: const Color(0xFFFDE68A),
            icon: Icons.info_outline,
            iconColor: const Color(0xFFB45309),
            text: blockedReason,
            textColor: const Color(0xFF92400E),
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
                  color: AppTheme.primaryColor.withValues(alpha: 0.04),
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
                        style: TextStyle(color: AppColors.textMuted),
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
                : () {
                    controller.uploadSelectedVideo();
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
              backgroundColor: const Color(0xFFE5E7EB),
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.isSavingToDrive.value
                ? 'Upload complete. Please wait while Google Drive confirms the file.'
                : 'Do not close this page while the video is uploading.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
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
            child: Text(
              text,
              style: TextStyle(color: textColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    filled: true,
    fillColor: Colors.white,
  );
}
