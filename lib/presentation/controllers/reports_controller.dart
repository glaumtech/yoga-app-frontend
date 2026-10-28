import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../data/models/competition_model.dart';
import '../../data/repositories/competition_repository.dart';
import '../../data/repositories/organization_repository.dart';
import '../../data/repositories/reports_repository.dart';
import 'reports_participants_list_preset.dart';
import 'reports_registered_participants_tab_controller.dart';

class ReportsController extends GetxController {
  final CompetitionRepository _competitionRepository = CompetitionRepository();
  final OrganizationRepository _organizationRepository = OrganizationRepository();
  final ReportsRepository _reportsRepository = ReportsRepository();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<CompetitionModel> competitions = <CompetitionModel>[].obs;
  final RxnString selectedCompetitionId = RxnString();

  final RxList<OrganizationListItem> organizations = <OrganizationListItem>[].obs;
  final RxnString selectedOrganizationId = RxnString();
  final RxBool isLoadingOrganizations = false.obs;
  final RxString organizationsError = ''.obs;

  /// Competitions for the organization selected on the financial report.
  final RxList<Map<String, String>> organizationCompetitions =
      <Map<String, String>>[].obs;
  final RxnString organizationCompetitionsOrgId = RxnString();
  final RxBool isLoadingOrganizationCompetitions = false.obs;
  final RxString organizationCompetitionsError = ''.obs;
  int _organizationCompetitionRequest = 0;

  /// Raw report payload returned by backend:
  /// {
  ///   totals: {...},
  ///   categoryCounts: {...},
  ///   prefixAgeCounts: { COMMON: { CBA: { age: count } }, ... },
  ///   institutions: {...},
  ///   prizeWinners: [...]
  /// }
  final Rxn<Map<String, dynamic>> report = Rxn<Map<String, dynamic>>();

  /// Reports tab id to open (e.g. [registeredParticipantsReportTabId]).
  final RxnString navigateToReportTabId = RxnString();

  /// Prefill amount for Add transfer dialog opened from amount-request inbox.
  final RxnDouble pendingTransferPrefillAmount = RxnDouble();

  /// Amount request id to link when creating transfer from inbox / shortcut.
  final RxnInt pendingTransferAmountRequestId = RxnInt();

  /// Transfer row to highlight after navigating from amount request.
  final RxnInt pendingHighlightTransferId = RxnInt();

  /// Applied when opening the registered participants tab from dashboard counts.
  final Rxn<ReportsParticipantsListPreset> pendingParticipantsPreset =
      Rxn<ReportsParticipantsListPreset>();

  static const String registeredParticipantsReportTabId =
      'registered_participants';

  void openParticipantsReport(ReportsParticipantsListPreset preset) {
    pendingParticipantsPreset.value = preset;
    navigateToReportTabId.value = registeredParticipantsReportTabId;
    _scheduleApplyPendingPreset();
  }

  /// Applies dashboard preset after the registered tab controller is created.
  void _scheduleApplyPendingPreset([int attempt = 0]) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final pending = pendingParticipantsPreset.value;
      if (pending == null) return;

      if (Get.isRegistered<ReportsRegisteredParticipantsTabController>()) {
        Get.find<ReportsRegisteredParticipantsTabController>()
            .applyDashboardPreset(pending);
        pendingParticipantsPreset.value = null;
        return;
      }

      if (attempt < 10) {
        _scheduleApplyPendingPreset(attempt + 1);
      }
    });
  }

  @override
  void onInit() {
    super.onInit();
    // Data load is triggered from [ReportsScreen] on every visit so
    // competition list + summary APIs run each time the Reports menu opens.
  }

  Future<void> loadCompetitionsAndMaybeReport() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final resp = await _competitionRepository.getAllCompetitions(
        page: 0,
        limit: 100,
        sortBy: 'createdAt',
        order: 'desc',
      );

      if (!resp.success || resp.data == null) {
        errorMessage.value = resp.message ?? 'Failed to load competitions';
        competitions.clear();
        report.value = null;
        return;
      }

      competitions.value = resp.data!.competitions;

      // Default selection. A blank id is unset, same as null.
      if ((selectedCompetitionId.value ?? '').trim().isEmpty &&
          competitions.isNotEmpty) {
        selectedCompetitionId.value = competitions.first.id;
      }

      if (selectedCompetitionId.value != null &&
          selectedCompetitionId.value!.isNotEmpty) {
        await loadReport(selectedCompetitionId.value!);
      } else {
        report.value = null;
      }
    } catch (e) {
      errorMessage.value = 'Error loading competitions: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadReport(String competitionId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final id = int.tryParse(competitionId);
      if (id == null) {
        errorMessage.value = 'Invalid competition id: $competitionId';
        report.value = null;
        return;
      }

      final resp = await _reportsRepository.getCompetitionReportSummary(
        id,
      );

      if (!resp.success || resp.data == null) {
        errorMessage.value = resp.message ?? 'Failed to load report';
        report.value = null;
        return;
      }

      report.value = Map<String, dynamic>.from(resp.data!);
    } catch (e) {
      errorMessage.value = 'Error loading report: ${e.toString()}';
      report.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setSelectedCompetition(String? competitionId) async {
    if (competitionId == null) return;
    if (competitionId == selectedCompetitionId.value) return;

    selectedCompetitionId.value = competitionId;
    await loadReport(competitionId);
  }

  Future<void> loadOrganizations() async {
    try {
      isLoadingOrganizations.value = true;
      organizationsError.value = '';

      final resp = await _organizationRepository.listOrganizations();
      if (!resp.success || resp.data == null) {
        organizationsError.value =
            resp.message ?? 'Failed to load organizations';
        organizations.clear();
        return;
      }

      organizations.value = resp.data!;

      if (selectedOrganizationId.value == null && organizations.isNotEmpty) {
        selectedOrganizationId.value = organizations.first.id.toString();
      }
    } catch (e) {
      organizationsError.value =
          'Error loading organizations: ${e.toString()}';
      organizations.clear();
    } finally {
      isLoadingOrganizations.value = false;
    }
  }

  void setSelectedOrganization(String? organizationId) {
    if (organizationId == null || organizationId.isEmpty) return;
    if (organizationId == selectedOrganizationId.value) return;
    selectedOrganizationId.value = organizationId;
    // Competition belongs to one organization. Clear it so the financial
    // report does not keep showing another organization's competition.
    organizationCompetitions.clear();
    organizationCompetitionsOrgId.value = null;
    organizationCompetitionsError.value = '';
    if ((selectedCompetitionId.value ?? '').isNotEmpty) {
      selectedCompetitionId.value = '';
    }
  }

  /// Loads competition names for [organizationId]. Keeps the current
  /// competition when it still belongs to that organization. An empty
  /// selection ("All competitions") is kept only when [preserveEmptySelection]
  /// is true. Otherwise the first competition is selected.
  Future<void> loadCompetitionsForOrganization(
    String? organizationId, {
    bool preserveEmptySelection = false,
  }) async {
    final requestId = ++_organizationCompetitionRequest;
    final normalized = (organizationId ?? '').trim();
    organizationCompetitionsOrgId.value =
        normalized.isEmpty ? null : normalized;
    if (normalized.isEmpty) {
      organizationCompetitions.clear();
      organizationCompetitionsError.value = '';
      if ((selectedCompetitionId.value ?? '').isNotEmpty) {
        selectedCompetitionId.value = '';
      }
      return;
    }

    final id = int.tryParse(normalized);
    if (id == null) {
      organizationCompetitions.clear();
      organizationCompetitionsError.value = 'Invalid organization';
      return;
    }

    isLoadingOrganizationCompetitions.value = true;
    organizationCompetitionsError.value = '';
    try {
      final resp = await _competitionRepository.listCompetitionOptions(id);
      if (requestId != _organizationCompetitionRequest) return;
      if (!resp.success || resp.data == null) {
        organizationCompetitions.clear();
        organizationCompetitionsError.value =
            resp.message ?? 'Failed to load competitions';
        return;
      }

      final items = List<Map<String, String>>.from(resp.data!);
      organizationCompetitions.assignAll(items);
      final ids = items.map((item) => item['id']).whereType<String>().toSet();
      final previous = selectedCompetitionId.value;
      if (preserveEmptySelection && (previous == null || previous.isEmpty)) {
        if (selectedCompetitionId.value != '') {
          selectedCompetitionId.value = '';
        }
        return;
      }
      if (previous != null && previous.isNotEmpty && ids.contains(previous)) {
        return;
      }
      if (items.isNotEmpty) {
        final first = items.first['id'] ?? '';
        if (first.isNotEmpty && selectedCompetitionId.value != first) {
          selectedCompetitionId.value = first;
        }
      } else if ((selectedCompetitionId.value ?? '').isNotEmpty) {
        selectedCompetitionId.value = '';
      }
    } catch (e) {
      if (requestId != _organizationCompetitionRequest) return;
      organizationCompetitions.clear();
      organizationCompetitionsError.value =
          'Error loading competitions: ${e.toString()}';
    } finally {
      if (requestId == _organizationCompetitionRequest) {
        isLoadingOrganizationCompetitions.value = false;
      }
    }
  }

  /// Opens Financial report tab for [competitionId] (amount-request inbox).
  Future<void> openFinancialReport(
    String competitionId, {
    double? transferPrefillAmount,
    int? amountRequestId,
    int? highlightTransferId,
  }) async {
    selectedCompetitionId.value = competitionId;
    pendingTransferPrefillAmount.value = transferPrefillAmount;
    pendingTransferAmountRequestId.value = amountRequestId;
    pendingHighlightTransferId.value = highlightTransferId;
    navigateToReportTabId.value = 'financial';
    await loadReport(competitionId);
  }

  void resetSession() {
    isLoading.value = false;
    errorMessage.value = '';
    competitions.clear();
    selectedCompetitionId.value = null;
    organizations.clear();
    selectedOrganizationId.value = null;
    isLoadingOrganizations.value = false;
    organizationsError.value = '';
    organizationCompetitions.clear();
    organizationCompetitionsOrgId.value = null;
    isLoadingOrganizationCompetitions.value = false;
    organizationCompetitionsError.value = '';
    _organizationCompetitionRequest++;
    report.value = null;
    navigateToReportTabId.value = null;
    pendingTransferPrefillAmount.value = null;
    pendingTransferAmountRequestId.value = null;
    pendingHighlightTransferId.value = null;
    pendingParticipantsPreset.value = null;
  }
}

