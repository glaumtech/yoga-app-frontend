import 'package:get/get.dart';

import '../../core/utils/snackbar_helper.dart';
import '../../data/repositories/reports_repository.dart';
import 'reports_controller.dart';
import 'reports_participants_tab_logic.dart';
import 'user_management_controller.dart';

class ReportsFeedbackTabController extends GetxController {
  final ReportsRepository _repository = ReportsRepository();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isDownloading = false.obs;
  final RxString error = ''.obs;
  final Rxn<Map<String, dynamic>> data = Rxn<Map<String, dynamic>>();
  final RxString typeFilter = ''.obs;
  final RxString competitionFilter = ''.obs;

  /// Organization id whose feedback payload is currently in [data].
  final RxnString loadedOrganizationId = RxnString();

  /// Competition id whose feedback payload is currently in [data].
  final RxnString loadedCompetitionId = RxnString();

  Worker? _competitionWatcher;
  Worker? _organizationWatcher;
  Worker? _organizationsLoadingWatcher;
  Worker? _competitionsLoadingWatcher;
  ReportsController? _boundReports;
  int _loadRequest = 0;

  static const List<Map<String, String>> fallbackTypes = [
    {'value': 'WEBSITE', 'label': 'Website'},
    {'value': 'APPLICATION', 'label': 'Application'},
    {'value': 'REGISTRATION', 'label': 'Registration'},
    {'value': 'PAYMENT', 'label': 'Payment'},
    {'value': 'SCORING', 'label': 'Scoring'},
    {'value': 'OTHER', 'label': 'Other'},
  ];

  ReportsController get reportsController {
    final current = Get.find<ReportsController>();
    if (!identical(current, _boundReports)) {
      _bindReportsController(current);
    }
    return current;
  }

  void _bindReportsController(ReportsController current) {
    _competitionWatcher?.dispose();
    _organizationWatcher?.dispose();
    _organizationsLoadingWatcher?.dispose();
    _competitionsLoadingWatcher?.dispose();
    _boundReports = current;
    _competitionWatcher = ever<String?>(
      current.selectedCompetitionId,
      (_) {
        if (isApplicationAdmin) return;
        Future.microtask(load);
      },
    );
    _organizationWatcher = ever<String?>(
      current.selectedOrganizationId,
      (_) {
        if (!isApplicationAdmin) return;
        competitionFilter.value = '';
        Future.microtask(load);
      },
    );
    _organizationsLoadingWatcher = ever<bool>(
      current.isLoadingOrganizations,
      (loading) {
        if (loading || !isApplicationAdmin) return;
        Future.microtask(load);
      },
    );
    _competitionsLoadingWatcher = ever<bool>(
      current.isLoading,
      (loading) {
        if (loading || isApplicationAdmin) return;
        Future.microtask(load);
      },
    );
  }

  @override
  void onInit() {
    super.onInit();
    _bindReportsController(Get.find<ReportsController>());
  }

  @override
  void onReady() {
    super.onReady();
    Future.microtask(load);
  }

  @override
  void onClose() {
    _competitionWatcher?.dispose();
    _organizationWatcher?.dispose();
    _organizationsLoadingWatcher?.dispose();
    _competitionsLoadingWatcher?.dispose();
    super.onClose();
  }

  String get currentRole {
    final userController = Get.isRegistered<UserManagementController>()
        ? Get.find<UserManagementController>()
        : null;
    return (userController?.currentUser.value?.userTypeName ??
            userController?.currentUser.value?.type ??
            '')
        .trim()
        .toUpperCase();
  }

  bool get isApplicationAdmin => currentRole == 'APPLICATION_ADMIN';

  int? get competitionId =>
      int.tryParse(reportsController.selectedCompetitionId.value ?? '');

  bool get canManage {
    final value = data.value?['canManage'];
    if (value is bool) return value;
    return !isApplicationAdmin;
  }

  List<Map<String, String>> get types {
    final raw = data.value?['types'];
    if (raw is List && raw.isNotEmpty) {
      return raw.whereType<Map>().map((item) {
        final map = Map<String, dynamic>.from(item);
        return {
          'value': (map['value'] ?? '').toString(),
          'label': (map['label'] ?? map['value'] ?? '').toString(),
        };
      }).where((item) => item['value']!.isNotEmpty).toList();
    }
    return fallbackTypes;
  }

  List<Map<String, dynamic>> get feedbacks {
    final raw = data.value?['feedbacks'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, String>> get competitionOptions {
    final raw = data.value?['competitions'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      final id = (map['id'] ?? '').toString();
      final name = (map['name'] ?? '').toString();
      return {'id': id, 'name': name};
    }).where((item) => item['id']!.isNotEmpty).toList();
  }

  List<Map<String, dynamic>> get visibleFeedbacks {
    final type = typeFilter.value;
    return feedbacks.where((row) {
      if (type.isNotEmpty && (row['type'] ?? '').toString() != type) {
        return false;
      }
      return true;
    }).toList();
  }

  void selectCompetition(String competitionId) {
    if (competitionFilter.value == competitionId) return;
    competitionFilter.value = competitionId;
    load();
  }

  Future<void> load() async {
    final requestId = ++_loadRequest;
    int? id;
    int? organizationId;
    if (isApplicationAdmin) {
      final rawOrg = (reportsController.selectedOrganizationId.value ?? '')
          .trim();
      organizationId = int.tryParse(rawOrg);
      if (organizationId == null) {
        if (requestId != _loadRequest) return;
        // Organizations are still arriving. Keep the previous payload and
        // load again when the selection is ready.
        if (reportsController.isLoadingOrganizations.value ||
            reportsController.organizations.isEmpty) {
          return;
        }
        loadedOrganizationId.value = null;
        data.value = {
          'feedbacks': <dynamic>[],
          'canManage': false,
          'competitions': <dynamic>[],
          'types': fallbackTypes,
        };
        error.value = '';
        return;
      }
      loadedOrganizationId.value = rawOrg;
      id = int.tryParse(competitionFilter.value);
    } else {
      final rawCompetition =
          (reportsController.selectedCompetitionId.value ?? '').trim();
      id = int.tryParse(rawCompetition);
      if (id == null) {
        if (requestId != _loadRequest) return;
        if (reportsController.isLoading.value) return;
        loadedCompetitionId.value = null;
        data.value = null;
        error.value = '';
        return;
      }
      loadedCompetitionId.value = rawCompetition;
    }
    isLoading.value = true;
    error.value = '';
    try {
      final resp = await _repository.getFeedbacks(
        competitionId: id,
        organizationId: organizationId,
      );
      if (requestId != _loadRequest) return;
      if (resp.success && resp.data != null) {
        data.value = resp.data;
      } else {
        data.value = null;
        error.value = resp.message ?? 'Failed to load feedback';
      }
    } catch (e) {
      if (requestId != _loadRequest) return;
      data.value = null;
      error.value = e.toString();
    } finally {
      if (requestId == _loadRequest) {
        isLoading.value = false;
      }
    }
  }

  Future<void> downloadExcel() async {
    if (isDownloading.value) return;

    int? id;
    int? organizationId;
    if (isApplicationAdmin) {
      organizationId = int.tryParse(
        (reportsController.selectedOrganizationId.value ?? '').trim(),
      );
      id = int.tryParse(competitionFilter.value);
    } else {
      id = competitionId;
    }

    isDownloading.value = true;
    try {
      final type = typeFilter.value.trim();
      final resp = await _repository.getFeedbacksExcel(
        competitionId: id,
        organizationId: organizationId,
        type: type.isEmpty ? null : type,
      );
      if (!resp.success || resp.data == null || resp.data!.isEmpty) {
        SnackbarHelper.showErrorMessage(
          resp.message ?? 'Failed to download feedback Excel',
        );
        return;
      }

      await ReportsParticipantsTabLogic.downloadFileBytes(
        resp.data!,
        'feedback_report.xlsx',
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      SnackbarHelper.showSuccessMessage('Excel download started');
    } catch (e) {
      SnackbarHelper.showErrorMessage('Failed to download feedback Excel: $e');
    } finally {
      isDownloading.value = false;
    }
  }

  Future<bool> saveFeedback({
    int? feedbackId,
    required int competitionId,
    required String type,
    required String message,
  }) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    try {
      final resp = feedbackId == null
          ? await _repository.createFeedback(
              competitionId: competitionId,
              type: type,
              message: message,
            )
          : await _repository.updateFeedback(
              feedbackId: feedbackId,
              competitionId: competitionId,
              type: type,
              message: message,
            );
      if (!resp.success) {
        SnackbarHelper.showErrorMessage(
          resp.message ?? 'Failed to save feedback',
        );
        return false;
      }
      final selected = reportsController.selectedCompetitionId.value;
      if (!isApplicationAdmin && selected != competitionId.toString()) {
        await reportsController.setSelectedCompetition(competitionId.toString());
      } else {
        await load();
      }
      SnackbarHelper.showSuccessMessage(
        feedbackId == null ? 'Feedback saved' : 'Feedback updated',
      );
      return true;
    } catch (e) {
      SnackbarHelper.showErrorMessage(e.toString());
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteFeedback(int feedbackId) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    try {
      final resp = await _repository.deleteFeedback(feedbackId);
      if (!resp.success) {
        SnackbarHelper.showErrorMessage(
          resp.message ?? 'Failed to delete feedback',
        );
        return false;
      }
      await load();
      SnackbarHelper.showSuccessMessage('Feedback deleted');
      return true;
    } catch (e) {
      SnackbarHelper.showErrorMessage(e.toString());
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
