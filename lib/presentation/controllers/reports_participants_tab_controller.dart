import 'dart:typed_data';

import 'package:get/get.dart';

import '../../data/models/api_response.dart';
import '../../data/repositories/competition_repository.dart';
import '../../data/repositories/reports_repository.dart';
import 'reports_controller.dart';

class ReportsParticipantsTabController extends GetxController {
  final ReportsRepository _reportsRepository = ReportsRepository();
  final CompetitionRepository _competitionRepository = CompetitionRepository();

  late final ReportsController reportsController;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<Map<String, dynamic>> data = Rxn<Map<String, dynamic>>();

  // Filter selections
  final RxnInt selectedStageId = RxnInt();
  final RxnInt selectedCategoryId = RxnInt();

  // UI-only search (filters current blocks in the Participants tab)
  final RxString participantSearchQuery = ''.obs;

  /// Stage / category options from API (competition-scoped)
  final RxList<Map<String, dynamic>> stageOptions =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> categoryOptions =
      <Map<String, dynamic>>[].obs;

  Worker? _competitionWatcher;

  @override
  void onInit() {
    super.onInit();
    reportsController = Get.find<ReportsController>();

    _competitionWatcher = ever<String?>(
      reportsController.selectedCompetitionId,
      (competitionId) {
        final id = int.tryParse(competitionId ?? '');
        if (id != null) {
          Future.microtask(() async {
            clearFilters();
            await load(id, refreshOptions: true);
          });
        } else {
          data.value = null;
          stageOptions.clear();
          categoryOptions.clear();
          selectedStageId.value = null;
          selectedCategoryId.value = null;
        }
      },
    );
  }

  @override
  void onReady() {
    super.onReady();
    final id = int.tryParse(
      reportsController.selectedCompetitionId.value ?? '',
    );
    if (id != null) {
      load(id, refreshOptions: true);
    }
  }

  @override
  void onClose() {
    _competitionWatcher?.dispose();
    super.onClose();
  }

  @override
  Future<void> refresh() async {
    final id = int.tryParse(
      reportsController.selectedCompetitionId.value ?? '',
    );
    if (id != null) {
      await load(id);
    }
  }

  void clearFilters() {
    selectedStageId.value = null;
    selectedCategoryId.value = null;
  }

  void setParticipantSearchQuery(String value) {
    participantSearchQuery.value = value;
  }

  void setStage(int? id) {
    selectedStageId.value = id;
    _reloadWithFilters();
  }

  void setCategory(int? id) {
    selectedCategoryId.value = id;
    _reloadWithFilters();
  }

  Future<void> _reloadWithFilters() async {
    final compId = int.tryParse(
      reportsController.selectedCompetitionId.value ?? '',
    );
    if (compId == null) return;
    await load(compId);
  }

  /// Loads stage & category dropdown options for the competition from API.
  Future<void> loadStageAndCategoryOptions(int competitionId) async {
    final stagesResp =
        await _competitionRepository.getStagesByCompetition(competitionId);
    final catsResp =
        await _competitionRepository.getCategoriesByCompetition(competitionId);

    if (stagesResp.success && stagesResp.data != null) {
      stageOptions.value = stagesResp.data!
          .map((s) => <String, dynamic>{'id': s.id, 'name': s.name})
          .toList()
        ..sort(
          (a, b) =>
              (a['name'] as String).compareTo(b['name'] as String),
        );
    } else {
      stageOptions.clear();
    }

    if (catsResp.success && catsResp.data != null) {
      categoryOptions.value = catsResp.data!
          .map((c) => <String, dynamic>{'id': c.id, 'name': c.name})
          .toList()
        ..sort(
          (a, b) =>
              (a['name'] as String).compareTo(b['name'] as String),
        );
    } else {
      categoryOptions.clear();
    }
  }

  Future<void> load(int competitionId, {bool refreshOptions = false}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (refreshOptions) {
        await loadStageAndCategoryOptions(competitionId);
      }

      final resp = await _reportsRepository.getCompetitionParticipantScores(
        competitionId,
        stageId: selectedStageId.value,
        categoryId: selectedCategoryId.value,
      );

      if (!resp.success || resp.data == null) {
        errorMessage.value =
            resp.message ?? 'Failed to load participant scores';
        data.value = null;
        return;
      }

      data.value = Map<String, dynamic>.from(resp.data!);
    } catch (e) {
      errorMessage.value = 'Error loading participant scores: ${e.toString()}';
      data.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<ApiResponse<Uint8List>> getParticipantsScoresExcel() async {
    final competitionId = int.tryParse(
      reportsController.selectedCompetitionId.value ?? '',
    );
    if (competitionId == null) {
      return ApiResponse(
        success: false,
        message: 'Select a competition first',
        statusCode: 0,
      );
    }

    if (selectedStageId.value == null) {
      return ApiResponse(
        success: false,
        message:
            'Select a stage before downloading Excel (All is not allowed).',
        statusCode: 0,
      );
    }

    return _reportsRepository.getCompetitionParticipantsExcel(
      competitionId,
      stageId: selectedStageId.value,
      categoryId: selectedCategoryId.value,
    );
  }
}
