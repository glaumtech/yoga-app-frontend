import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_constants.dart';
import '../../core/navigation/root_navigator_key.dart';
import '../../core/utils/storage_service.dart';
import '../../core/utils/video_blob_url.dart';
import '../../data/models/participant_feedback_model.dart';
import '../../data/models/participant_video_model.dart';
import '../../data/repositories/participant_feedback_repository.dart';
import '../../data/repositories/participant_video_repository.dart';
import '../../data/repositories/reports_repository.dart';
import '../widgets/app_dialog.dart';
import '../widgets/participant_feedback_dialog.dart';
import 'reports_participants_tab_logic.dart';

class ParticipantVideoController extends GetxController {
  static const int maxVideoBytes = 500 * 1024 * 1024;
  static const String modeCount = 'COUNT';
  static const String modeVideo = 'VIDEO';

  final ParticipantVideoRepository _repository = ParticipantVideoRepository();
  final ParticipantFeedbackRepository _feedbackRepository =
      ParticipantFeedbackRepository();

  final registrationNoController = TextEditingController();
  final videoUrlController = TextEditingController();
  final countController = TextEditingController();
  final Rxn<DateTime> dateOfBirth = Rxn<DateTime>();
  final RxBool loginFromQr = false.obs;
  /// After "Switch participant", keep the full login form even if a QR URL
  /// is still in the browser address (hash routing can lag behind go()).
  final RxBool preferFullLoginForm = false.obs;
  final Rxn<ParticipantVideoLoginPreview> loginPreview =
      Rxn<ParticipantVideoLoginPreview>();
  final RxBool isLoadingLoginPreview = false.obs;
  final RxString loginPreviewError = ''.obs;
  final Rxn<ParticipantVideoToppers> toppers = Rxn<ParticipantVideoToppers>();
  final RxBool isLoadingToppers = false.obs;
  final RxString toppersError = ''.obs;

  final RxBool isLoading = false.obs;

  /// Full-page loader only while restoring a saved video session.
  final RxBool isRestoringSession = false.obs;
  final RxBool isStarting = false.obs;
  final RxBool isSavingUrl = false.obs;
  final RxBool isSavingCount = false.obs;
  final RxBool isUploading = false.obs;
  final RxBool isDownloadingCertificate = false.obs;
  final RxBool isOpeningFeedback = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;
  final Rxn<ParticipantVideoSession> session = Rxn<ParticipantVideoSession>();
  final RxString pickedFileName = ''.obs;
  final Rxn<Uint8List> pickedFileBytes = Rxn<Uint8List>();
  final RxDouble uploadProgress = 0.0.obs;
  final RxBool isSavingToDrive = false.obs;

  /// false = URL form (default), true = MP4 upload form.
  final RxBool useFileUpload = false.obs;
  final Rxn<DateTime> calendarMonth = Rxn<DateTime>();
  final Rxn<DateTime> selectedDate = Rxn<DateTime>();
  final RxnString chosenMode = RxnString();
  final RxBool isChangingMode = false.obs;

  bool get isLoggedIn => session.value != null;

  bool get hasStarted => session.value?.hasStarted == true;

  bool get canUploadFile => session.value?.driveUploadEnabled == true;

  DateTime get today {
    final serverToday = session.value?.today;
    if (serverToday != null) return _dateOnly(serverToday);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime? get startedOn {
    final value = session.value?.startedOn;
    return value == null ? null : _dateOnly(value);
  }

  int? get configuredDurationDays {
    final days = session.value?.durationDays;
    if (days == null || days < 1) return null;
    return days;
  }

  DateTime? get durationEndsOn {
    final days = configuredDurationDays;
    final start = startedOn;
    if (days == null || start == null) return null;
    return DateTime(start.year, start.month, start.day + (days - 1));
  }

  /// Calendar day number from start date through today (inclusive).
  /// Example: start = 1 Sep, today = 14 Sep → Day count = 14.
  /// Uses an explicit Rx so header chips rebuild immediately after save.
  final RxnInt dayCountHighlight = RxnInt();
  final RxInt enteredCountDayHighlight = 0.obs;
  final RxInt totalCountHighlight = 0.obs;

  int? get dayCountValue => dayCountHighlight.value;

  int get enteredCountDayCount => enteredCountDayHighlight.value;

  int get totalCountValue => totalCountHighlight.value;

  void _refreshCountHighlights() {
    final current = session.value;
    final start = startedOn;
    final end = today;
    if (start == null) {
      dayCountHighlight.value = null;
      enteredCountDayHighlight.value = 0;
      totalCountHighlight.value = 0;
      return;
    }
    final clampedEnd = end.isBefore(start) ? start : end;
    dayCountHighlight.value = clampedEnd.difference(start).inDays + 1;
    final countEntries = (current?.entries ?? const [])
        .where((entry) => entry.isCount)
        .toList();
    enteredCountDayHighlight.value = countEntries.length;
    totalCountHighlight.value = countEntries.fold<int>(
      0,
      (sum, entry) => sum + (entry.countValue ?? 0),
    );
  }

  String? get activeMode {
    final configured = session.value?.configuredType?.trim().toUpperCase();
    if (configured == modeCount || configured == modeVideo) return configured;
    if (isChangingMode.value && isStartDateSelected) {
      final chosen = chosenMode.value?.trim().toUpperCase();
      if (chosen == modeCount || chosen == modeVideo) return chosen;
      return null;
    }
    final locked = session.value?.lockedMode?.trim().toUpperCase();
    if (locked == modeCount || locked == modeVideo) return locked;
    final chosen = chosenMode.value?.trim().toUpperCase();
    if (chosen == modeCount || chosen == modeVideo) return chosen;
    return null;
  }

  ParticipantVideoModel? get selectedEntry {
    final date = selectedDate.value;
    if (date == null) return null;
    return session.value?.entryFor(date);
  }

  bool get canDownloadCertificate {
    final current = session.value;
    if (current == null) return false;
    if (!current.certificateAvailable) return false;
    if (current.competitionId == null || current.registrationId == null) {
      return false;
    }
    if (current.isCountType) return true;
    return current.optForECertificate;
  }

  String get certificatePendingMessage {
    final current = session.value;
    if (current == null || current.certificateAvailable) {
      return '';
    }
    if (current.isCountType) {
      final date = current.certificateAvailableOn;
      if (date != null) {
        return 'E-certificate download opens on ${DateFormat('dd MMM yyyy').format(date)}.';
      }
      return 'E-certificate download opens after you save count on the last duration day.';
    }
    if (!current.optForECertificate) return '';
    return 'E-certificate download opens after results are published.';
  }

  /// Server-supplied explanation shown before the participant wastes an upload.
  String get uploadBlockedReason {
    if (canUploadFile) return '';
    final reason = session.value?.driveUploadDisabledReason?.trim() ?? '';
    return reason.isNotEmpty
        ? reason
        : 'File upload is not available for this competition right now. '
              'Paste a video URL instead.';
  }

  void showUrlOption() {
    useFileUpload.value = false;
    errorMessage.value = '';
  }

  void showFileOption() {
    useFileUpload.value = true;
    errorMessage.value = '';
  }

  void chooseCount() {
    if (session.value?.hasConfiguredType == true) return;
    if (!isStartDateSelected && activeMode != null) return;
    chosenMode.value = modeCount;
    errorMessage.value = '';
    successMessage.value = '';
  }

  void chooseVideo() {
    if (session.value?.hasConfiguredType == true) return;
    if (!isStartDateSelected && activeMode != null) return;
    chosenMode.value = modeVideo;
    errorMessage.value = '';
    successMessage.value = '';
  }

  void resetChosenMode() {
    if (!canChangeMode) return;
    isChangingMode.value = true;
    chosenMode.value = null;
    errorMessage.value = '';
    successMessage.value = '';
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get isStartDateSelected {
    final selected = selectedDate.value;
    final start = startedOn;
    if (selected == null || start == null) return false;
    return isSameDay(selected, start);
  }

  bool get canChangeMode =>
      isStartDateSelected && session.value?.hasConfiguredType != true;

  bool get showSavedEntryBanner {
    final entry = selectedEntry;
    if (entry == null || !entry.hasSubmission) return false;
    final mode = activeMode;
    if (isChangingMode.value && isStartDateSelected) {
      if (mode == modeVideo && entry.isCount) return false;
      if (mode == modeCount && (entry.hasUrl || entry.hasFile)) return false;
      if (mode == null) return false;
    }
    return true;
  }

  bool isSelectableDate(DateTime date) {
    final start = startedOn;
    if (start == null) return false;
    final day = _dateOnly(date);
    if (day.isBefore(start)) return false;
    if (day.isAfter(today)) return false;
    return true;
  }

  bool isWithinConfiguredDuration(DateTime date) {
    final end = durationEndsOn;
    if (end == null) return true;
    return !_dateOnly(date).isAfter(end);
  }

  bool isDurationExpiredDate(DateTime date) {
    return isSelectableDate(date) && !isWithinConfiguredDuration(date);
  }

  DateTime get visibleCalendarMonth {
    final stored = calendarMonth.value;
    if (stored != null) return DateTime(stored.year, stored.month, 1);
    final start = startedOn;
    if (start != null) return DateTime(start.year, start.month, 1);
    return DateTime(today.year, today.month, 1);
  }

  DateTime get calendarMinMonth {
    final start = startedOn ?? today;
    return DateTime(start.year, start.month, 1);
  }

  DateTime get calendarMaxMonth {
    final end = durationEndsOn;
    var last = today;
    if (end != null && end.isAfter(last)) last = end;
    return DateTime(last.year, last.month, 1);
  }

  bool get canGoToPreviousMonth =>
      visibleCalendarMonth.isAfter(calendarMinMonth);

  bool get canGoToNextMonth => visibleCalendarMonth.isBefore(calendarMaxMonth);

  void selectDate(DateTime date) {
    if (!isSelectableDate(date) || isDurationExpiredDate(date)) return;
    final day = _dateOnly(date);
    final current = selectedDate.value;
    if (current != null && isSameDay(current, day)) {
      _hydrateSelectedDate();
      return;
    }
    isChangingMode.value = false;
    selectedDate.value = day;
    errorMessage.value = '';
    successMessage.value = '';
    pickedFileName.value = '';
    pickedFileBytes.value = null;
    uploadProgress.value = 0;
    _hydrateSelectedDate();
  }

  void clearSelectedDate() {
    selectedDate.value = null;
    isChangingMode.value = false;
    pickedFileName.value = '';
    pickedFileBytes.value = null;
  }

  void changeMonth(int delta) {
    final current = visibleCalendarMonth;
    final next = DateTime(current.year, current.month + delta, 1);
    if (next.isBefore(calendarMinMonth) || next.isAfter(calendarMaxMonth)) {
      return;
    }
    calendarMonth.value = next;
  }

  /// Show today's month and select today when it is within the active range.
  void goToToday() {
    if (!hasStarted) return;
    final now = today;
    calendarMonth.value = DateTime(now.year, now.month, 1);
    if (isSelectableDate(now) && !isDurationExpiredDate(now)) {
      selectDate(now);
    }
  }

  void applyQrRegistrationNo(String? registrationNo) {
    final value = registrationNo?.trim() ?? '';
    if (value.isEmpty) {
      final wasQr = loginFromQr.value;
      if (!wasQr && loginPreview.value == null) return;
      loginFromQr.value = false;
      loginPreview.value = null;
      loginPreviewError.value = '';
      if (wasQr) {
        // Keep the draft Participant ID / DOB when leaving a QR deep-link.
        restoreLoginDraft();
      }
      return;
    }
    final alreadyApplied =
        loginFromQr.value &&
        registrationNoController.text.trim().toUpperCase() ==
            value.toUpperCase() &&
        ((loginPreview.value?.registrationNo ?? '').trim().toUpperCase() ==
                value.toUpperCase() ||
            isLoadingLoginPreview.value);
    if (registrationNoController.text.trim() != value) {
      registrationNoController.text = value;
    }
    if (!loginFromQr.value) {
      loginFromQr.value = true;
    }
    persistLoginDraft();
    if (!alreadyApplied) {
      loadLoginPreview(value);
    }
    final currentReg = session.value?.registrationNo?.trim() ?? '';
    if (currentReg.isNotEmpty &&
        currentReg.toUpperCase() != value.toUpperCase()) {
      logout();
    }
  }

  Future<void> loadLoginPreview(String? registrationNo) async {
    final value = (registrationNo ?? registrationNoController.text).trim();
    if (value.isEmpty) {
      loginPreview.value = null;
      loginPreviewError.value = '';
      toppers.value = null;
      toppersError.value = '';
      return;
    }
    final current = loginPreview.value;
    if (current != null &&
        (current.registrationNo ?? '').trim().toUpperCase() ==
            value.toUpperCase() &&
        (current.participantName ?? '').trim().isNotEmpty) {
      await loadToppers(
        competitionId: current.competitionId,
        registrationNo: current.registrationNo ?? value,
      );
      return;
    }
    if (isLoadingLoginPreview.value &&
        registrationNoController.text.trim().toUpperCase() ==
            value.toUpperCase()) {
      return;
    }
    isLoadingLoginPreview.value = true;
    loginPreviewError.value = '';
    try {
      final response = await _repository.loginPreview(registrationNo: value);
      if (response.success && response.data != null) {
        loginPreview.value = response.data;
        final resolvedNo = response.data!.registrationNo?.trim();
        if (resolvedNo != null &&
            resolvedNo.isNotEmpty &&
            registrationNoController.text.trim().toUpperCase() !=
                resolvedNo.toUpperCase()) {
          registrationNoController.text = resolvedNo;
        }
        await loadToppers(
          competitionId: response.data!.competitionId,
          registrationNo: resolvedNo ?? value,
        );
      } else {
        loginPreview.value = null;
        toppers.value = null;
        loginPreviewError.value =
            response.message ?? 'Could not load participant details.';
      }
    } catch (_) {
      loginPreview.value = null;
      toppers.value = null;
      loginPreviewError.value = 'Could not load participant details.';
    } finally {
      isLoadingLoginPreview.value = false;
    }
  }

  Future<void> loadToppers({
    int? competitionId,
    String? registrationNo,
  }) async {
    final competition =
        competitionId ??
        session.value?.competitionId ??
        loginPreview.value?.competitionId;
    if (competition == null) {
      toppers.value = null;
      toppersError.value = '';
      return;
    }
    final regNo =
        (registrationNo ??
                session.value?.registrationNo ??
                loginPreview.value?.registrationNo ??
                registrationNoController.text)
            .trim();
    isLoadingToppers.value = true;
    toppersError.value = '';
    try {
      final response = await _repository.toppers(
        competitionId: competition,
        registrationNo: regNo.isEmpty ? null : regNo,
      );
      if (response.success && response.data != null) {
        toppers.value = response.data;
      } else {
        toppers.value = null;
        toppersError.value = response.message ?? 'Could not load toppers.';
      }
    } catch (_) {
      toppers.value = null;
      toppersError.value = 'Could not load toppers.';
    } finally {
      isLoadingToppers.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    restoreLoginDraft();
    registrationNoController.addListener(_onRegistrationNoChanged);
    _restoreSession();
  }

  void _onRegistrationNoChanged() {
    final regNo = registrationNoController.text.trim();
    if (regNo.isEmpty) return;
    StorageService.setString(AppConstants.participantVideoLoginRegNoKey, regNo);
  }

  /// Reloads DOB / Participant ID from local storage (safe to call on every visit).
  void restoreLoginDraft() {
    if (dateOfBirth.value == null) {
      final savedDob = StorageService.getString(
        AppConstants.participantVideoLoginDobKey,
      );
      if (savedDob != null && savedDob.isNotEmpty) {
        final parsed = _parseStoredDate(savedDob);
        if (parsed != null) {
          dateOfBirth.value = parsed;
        }
      }
    }
    if (loginFromQr.value) return;
    final savedReg = StorageService.getString(
      AppConstants.participantVideoLoginRegNoKey,
    );
    if (savedReg != null &&
        savedReg.isNotEmpty &&
        registrationNoController.text.trim().isEmpty) {
      registrationNoController.text = savedReg;
    }
  }

  Future<void> persistLoginDraft() async {
    final dob = dateOfBirth.value;
    if (dob != null) {
      await StorageService.setString(
        AppConstants.participantVideoLoginDobKey,
        DateFormat('yyyy-MM-dd').format(dob),
      );
    }
    final regNo = registrationNoController.text.trim();
    if (regNo.isNotEmpty) {
      await StorageService.setString(
        AppConstants.participantVideoLoginRegNoKey,
        regNo,
      );
    }
  }

  Future<void> setDateOfBirth(DateTime value) async {
    final day = DateTime(value.year, value.month, value.day);
    dateOfBirth.value = day;
    await persistLoginDraft();
  }

  static DateTime? _parseStoredDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split('-');
    if (parts.length >= 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }
    try {
      final parsed = DateTime.parse(trimmed);
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }

  @override
  void onClose() {
    registrationNoController.removeListener(_onRegistrationNoChanged);
    registrationNoController.dispose();
    videoUrlController.dispose();
    countController.dispose();
    super.onClose();
  }

  Future<void> _restoreSession() async {
    final token = StorageService.getString(
      AppConstants.participantVideoTokenKey,
    );
    if (token == null || token.isEmpty) return;
    isRestoringSession.value = true;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _repository.me();
      if (response.success && response.data != null) {
        if (loginFromQr.value) {
          final expected = registrationNoController.text.trim().toUpperCase();
          final actual = (response.data!.registrationNo ?? '')
              .trim()
              .toUpperCase();
          if (expected.isNotEmpty && actual != expected) {
            await StorageService.remove(AppConstants.participantVideoTokenKey);
            return;
          }
        }
        _applySession(response.data!);
        await loadToppers(
          competitionId: response.data!.competitionId,
          registrationNo: response.data!.registrationNo,
        );
      } else {
        await StorageService.remove(AppConstants.participantVideoTokenKey);
      }
    } catch (_) {
      await StorageService.remove(AppConstants.participantVideoTokenKey);
    } finally {
      isLoading.value = false;
      isRestoringSession.value = false;
    }
  }

  Future<bool> login() async {
    final registrationNo = registrationNoController.text.trim();
    final dob = dateOfBirth.value;
    if (registrationNo.isEmpty || dob == null) {
      await _showLoginErrorDialog(
        loginFromQr.value
            ? 'Select your date of birth to continue.'
            : 'Enter Participant number and date of birth.',
      );
      return false;
    }
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _repository.login(
        registrationNo: registrationNo,
        dateOfBirth: DateFormat('yyyy-MM-dd').format(dob),
      );
      if (response.success && response.data != null) {
        final token = response.data!.token?.trim();
        if (token != null && token.isNotEmpty) {
          await StorageService.setString(
            AppConstants.participantVideoTokenKey,
            token,
          );
        }
        selectedDate.value = null;
        chosenMode.value = null;
        isChangingMode.value = false;
        preferFullLoginForm.value = false;
        _applySession(response.data!);
        await loadToppers(
          competitionId: response.data!.competitionId,
          registrationNo: response.data!.registrationNo,
        );
        return true;
      }
      final message = (response.message ?? '').trim().isEmpty
          ? 'Login failed. Check Participant ID and date of birth.'
          : response.message!.trim();
      errorMessage.value = message;
      await _showLoginErrorDialog(message);
      return false;
    } catch (_) {
      const message = 'Login failed. Please try again.';
      errorMessage.value = message;
      await _showLoginErrorDialog(message);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _showLoginErrorDialog(String message) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    await AppDialog.show(
      context,
      title: 'Unable to sign in',
      message: message,
      confirmText: 'OK',
    );
  }

  Future<void> openFeedbackDialog() async {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !isLoggedIn || isOpeningFeedback.value) return;

    isOpeningFeedback.value = true;
    errorMessage.value = '';
    try {
      final response = await _feedbackRepository.getMine();
      ParticipantFeedbackModel? existing;
      if (response.success) {
        existing = response.data;
      }
      if (!ctx.mounted) return;
      final saved = await showParticipantFeedbackDialog(
        ctx,
        existing: existing,
      );
      if (saved == true) {
        successMessage.value = 'Feedback saved successfully.';
        errorMessage.value = '';
      }
    } catch (e) {
      errorMessage.value = 'Unable to open feedback: $e';
    } finally {
      isOpeningFeedback.value = false;
    }
  }

  Future<void> logout() async {
    await StorageService.remove(AppConstants.participantVideoTokenKey);
    session.value = null;
    dayCountHighlight.value = null;
    enteredCountDayHighlight.value = 0;
    totalCountHighlight.value = 0;
    loginPreview.value = null;
    loginPreviewError.value = '';
    toppers.value = null;
    toppersError.value = '';
    videoUrlController.clear();
    countController.clear();
    pickedFileName.value = '';
    pickedFileBytes.value = null;
    uploadProgress.value = 0;
    isSavingToDrive.value = false;
    errorMessage.value = '';
    successMessage.value = '';
    useFileUpload.value = false;
    selectedDate.value = null;
    calendarMonth.value = null;
    chosenMode.value = null;
    isChangingMode.value = false;
    if (loginFromQr.value) {
      await loadLoginPreview(registrationNoController.text);
    }
  }

  /// Leave the current session and return to the full login form
  /// (Participant number + date of birth), including after a QR deep-link.
  Future<void> switchParticipant() async {
    final sessionReg = session.value?.registrationNo?.trim() ?? '';
    if (sessionReg.isNotEmpty) {
      registrationNoController.text = sessionReg;
    }
    await persistLoginDraft();
    preferFullLoginForm.value = true;
    loginFromQr.value = false;
    await logout();
    restoreLoginDraft();
  }

  Future<void> downloadECertificate() async {
    final current = session.value;
    if (current == null || !canDownloadCertificate) return;
    final competitionId = current.competitionId;
    final registrationId = current.registrationId;
    if (competitionId == null || registrationId == null) return;

    isDownloadingCertificate.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    try {
      final resp = await ReportsRepository().getParticipantECertificatePdf(
        competitionId,
        participantRegistrationId: registrationId,
        stageId: current.stageId,
        categoryId: current.categoryId,
        groupId: current.groupId,
      );
      if (!resp.success || resp.data == null) {
        errorMessage.value =
            resp.message ?? 'Failed to download e-certificate.';
        return;
      }
      await ReportsParticipantsTabLogic.downloadReportPdfBytes(
        resp.data!,
        'e_certificate_${competitionId}_$registrationId.pdf',
      );
      successMessage.value = 'E-certificate download started.';
    } catch (e) {
      errorMessage.value = 'Failed to download e-certificate: $e';
    } finally {
      isDownloadingCertificate.value = false;
    }
  }

  Future<bool> startDailyLog() async {
    isStarting.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    try {
      final response = await _repository.start();
      if (response.success && response.data != null) {
        _applySession(response.data!);
        successMessage.value = 'Daily log started. Select a date to continue.';
        return true;
      }
      errorMessage.value = response.message ?? 'Could not start the daily log.';
      return false;
    } catch (_) {
      errorMessage.value = 'Could not start the daily log.';
      return false;
    } finally {
      isStarting.value = false;
    }
  }

  Future<bool> saveCount() async {
    final date = selectedDate.value;
    if (date == null) {
      errorMessage.value = 'Select a date on the calendar.';
      return false;
    }
    if (isDurationExpiredDate(date)) {
      errorMessage.value =
          'Your challenge duration has ended. Renew to continue this challenge.';
      return false;
    }
    final parsed = int.tryParse(countController.text.trim());
    if (parsed == null) {
      errorMessage.value = 'Enter a valid count.';
      return false;
    }
    isSavingCount.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    try {
      final response = await _repository.saveCount(
        entryDate: DateFormat('yyyy-MM-dd').format(date),
        count: parsed,
      );
      if (response.success && response.data != null) {
        isChangingMode.value = false;
        chosenMode.value = modeCount;
        _applySession(response.data!);
        // Ensure header chips reflect this save even if the response omits
        // the entry (e.g. flush timing) or Obx misses a nested list change.
        final applied = session.value;
        final savedEntry = applied?.entryFor(date);
        if (savedEntry?.isCount != true || savedEntry?.countValue != parsed) {
          if (applied != null) {
            session.value = applied.withCountEntry(date: date, count: parsed);
          }
        }
        _refreshCountHighlights();
        successMessage.value = 'Count saved.';
        await loadToppers(
          competitionId: session.value?.competitionId,
          registrationNo: session.value?.registrationNo,
        );
        return true;
      }
      errorMessage.value = response.message ?? 'Could not save the count.';
      return false;
    } catch (_) {
      errorMessage.value = 'Could not save the count.';
      return false;
    } finally {
      isSavingCount.value = false;
    }
  }

  Future<bool> saveUrl() async {
    final date = selectedDate.value;
    if (date == null) {
      errorMessage.value = 'Select a date on the calendar.';
      return false;
    }
    if (isDurationExpiredDate(date)) {
      errorMessage.value =
          'Your challenge duration has ended. Renew to continue this challenge.';
      return false;
    }
    isSavingUrl.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    try {
      final response = await _repository.saveUrl(
        entryDate: DateFormat('yyyy-MM-dd').format(date),
        videoUrl: videoUrlController.text.trim(),
      );
      if (response.success && response.data != null) {
        isChangingMode.value = false;
        chosenMode.value = modeVideo;
        _applySession(response.data!);
        successMessage.value = 'Video URL saved.';
        useFileUpload.value = false;
        return true;
      }
      errorMessage.value = response.message ?? 'Could not save the video URL.';
      return false;
    } catch (_) {
      errorMessage.value = 'Could not save the video URL.';
      return false;
    } finally {
      isSavingUrl.value = false;
    }
  }

  Future<bool> pickVideo() async {
    errorMessage.value = '';
    successMessage.value = '';
    uploadProgress.value = 0;
    isSavingToDrive.value = false;
    if (!canUploadFile) {
      errorMessage.value = uploadBlockedReason;
      return false;
    }
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mp4'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return false;
      }
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        errorMessage.value = 'Could not read the selected video file.';
        return false;
      }
      if (bytes.length > maxVideoBytes) {
        errorMessage.value = 'Video must be 500 MB or smaller.';
        return false;
      }
      if (!file.name.toLowerCase().endsWith('.mp4')) {
        errorMessage.value = 'Only MP4 video files are allowed.';
        return false;
      }
      final resolutionError = await _validateResolution(bytes, file.path);
      if (resolutionError != null) {
        errorMessage.value = resolutionError;
        return false;
      }
      pickedFileName.value = file.name;
      pickedFileBytes.value = bytes;
      return true;
    } catch (e) {
      errorMessage.value = 'Could not read the selected video file: $e';
      return false;
    }
  }

  Future<bool> uploadSelectedVideo() async {
    final date = selectedDate.value;
    if (date == null) {
      errorMessage.value = 'Select a date on the calendar.';
      return false;
    }
    if (isDurationExpiredDate(date)) {
      errorMessage.value =
          'Your challenge duration has ended. Renew to continue this challenge.';
      return false;
    }
    final bytes = pickedFileBytes.value;
    final filename = pickedFileName.value.trim();
    if (bytes == null || bytes.isEmpty || filename.isEmpty) {
      errorMessage.value = 'Choose an MP4 video before uploading.';
      return false;
    }
    if (!canUploadFile) {
      errorMessage.value = uploadBlockedReason;
      return false;
    }

    errorMessage.value = '';
    successMessage.value = '';
    uploadProgress.value = 0;
    isSavingToDrive.value = false;
    isUploading.value = true;
    try {
      final response = await _repository.uploadVideo(
        entryDate: DateFormat('yyyy-MM-dd').format(date),
        bytes: bytes,
        filename: filename,
        onProgress: (progress) {
          uploadProgress.value = progress;
          if (progress >= 1) {
            isSavingToDrive.value = true;
          }
        },
      );
      if (response.success && response.data != null) {
        isChangingMode.value = false;
        chosenMode.value = modeVideo;
        _applySession(response.data!);
        successMessage.value = 'Video uploaded successfully.';
        useFileUpload.value = true;
        pickedFileBytes.value = null;
        return true;
      }
      errorMessage.value = response.message ?? 'Video upload failed.';
      return false;
    } catch (e) {
      errorMessage.value = 'Video upload failed: $e';
      return false;
    } finally {
      isUploading.value = false;
      isSavingToDrive.value = false;
    }
  }

  void _applySession(ParticipantVideoSession next) {
    final previousToken = session.value?.token?.trim();
    final incomingToken = next.token?.trim();
    // save/start responses often omit token — keep the logged-in one.
    final merged = (incomingToken == null || incomingToken.isEmpty) &&
            previousToken != null &&
            previousToken.isNotEmpty
        ? next.copyWith(token: previousToken)
        : next;
    session.value = merged;
    final configured = merged.configuredType?.trim().toUpperCase();
    if (configured == modeCount || configured == modeVideo) {
      chosenMode.value = configured;
      isChangingMode.value = false;
    } else if (!isChangingMode.value) {
      final locked = merged.lockedMode?.trim().toUpperCase();
      if (locked == modeCount || locked == modeVideo) {
        chosenMode.value = locked;
      }
    }
    if (merged.hasStarted) {
      final selected = selectedDate.value;
      if (selected != null) {
        calendarMonth.value = DateTime(selected.year, selected.month, 1);
      } else {
        goToToday();
      }
    }
    _refreshCountHighlights();
    _hydrateSelectedDate();
  }

  void _hydrateSelectedDate() {
    final date = selectedDate.value;
    if (date == null) return;
    final entry = session.value?.entryFor(date);
    if (entry?.isCount == true) {
      countController.text = '${entry!.countValue ?? ''}';
    } else {
      countController.clear();
    }
    videoUrlController.text = entry?.videoUrl ?? '';
    if (entry?.hasFile == true) {
      useFileUpload.value = true;
    } else if (entry?.hasUrl == true) {
      useFileUpload.value = false;
    }
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<String?> _validateResolution(Uint8List bytes, String? path) async {
    VideoPlayerController? player;
    String? blobUrl;
    try {
      if (kIsWeb) {
        blobUrl = createVideoBlobUrl(bytes);
        if (blobUrl == null) {
          return null;
        }
        player = VideoPlayerController.networkUrl(Uri.parse(blobUrl));
      } else if (path != null && path.isNotEmpty) {
        player = VideoPlayerController.file(File(path));
      } else {
        return null;
      }
      await player.initialize();
      final size = player.value.size;
      final width = size.width.round();
      final height = size.height.round();
      final is720 =
          (width == 1280 && height == 720) || (width == 720 && height == 1280);
      final is1080 =
          (width == 1920 && height == 1080) ||
          (width == 1080 && height == 1920);
      if (width > 0 && height > 0 && !is720 && !is1080) {
        return 'Video must be 720p (1280x720) or 1080p (1920x1080) MP4. Found ${width}x$height.';
      }
      return null;
    } catch (_) {
      // The browser could not decode it here; the server validates resolution too.
      return null;
    } finally {
      await player?.dispose();
      if (blobUrl != null) {
        revokeVideoBlobUrl(blobUrl);
      }
    }
  }
}
