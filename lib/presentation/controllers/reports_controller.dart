import 'package:get/get.dart';

import '../../data/models/competition_model.dart';
import '../../data/repositories/competition_repository.dart';
import '../../data/repositories/reports_repository.dart';

class ReportsController extends GetxController {
  final CompetitionRepository _competitionRepository = CompetitionRepository();
  final ReportsRepository _reportsRepository = ReportsRepository();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<CompetitionModel> competitions = <CompetitionModel>[].obs;
  final RxnString selectedCompetitionId = RxnString();

  /// Raw report payload returned by backend:
  /// {
  ///   totals: {...},
  ///   categoryCounts: {...},
  ///   prefixAgeCounts: {...},
  ///   institutions: {...},
  ///   prizeWinners: [...]
  /// }
  final Rxn<Map<String, dynamic>> report = Rxn<Map<String, dynamic>>();

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

      // Default selection
      if (selectedCompetitionId.value == null && competitions.isNotEmpty) {
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
}

