import 'dart:typed_data';

import 'package:get/get.dart';

import '../../data/models/api_response.dart';
import '../../data/repositories/reports_repository.dart';
import 'reports_controller.dart';

class ReportsParticipantsTabController extends GetxController {
  final ReportsRepository _reportsRepository = ReportsRepository();

  late final ReportsController reportsController;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<Map<String, dynamic>> data = Rxn<Map<String, dynamic>>();

  // Cached full (unfiltered) blocks used to derive filters/options
  final RxList<Map<String, dynamic>> allBlocksCache =
      <Map<String, dynamic>>[].obs;

  // Filter selections
  final RxnInt selectedStageId = RxnInt();
  final RxnInt selectedCategoryId = RxnInt();
  final RxnInt selectedGroupId = RxnInt();

  // UI-only search (filters current blocks in the Participants tab)
  final RxString participantSearchQuery = ''.obs;

  // Options derived from blocks
  final RxList<Map<String, dynamic>> stageOptions =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> categoryOptions =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> groupOptions =
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
          allBlocksCache.clear();
          stageOptions.clear();
          categoryOptions.clear();
          groupOptions.clear();
          selectedStageId.value = null;
          selectedCategoryId.value = null;
          selectedGroupId.value = null;
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
    selectedGroupId.value = null;
  }

  void setParticipantSearchQuery(String value) {
    participantSearchQuery.value = value;
  }

  void setStage(int? id) {
    selectedStageId.value = id;
    // Reset dependent selections
    selectedGroupId.value = null;
    // Category can stay independent, but options should update based on stage
    _deriveOptionsFromCache();
    _reloadWithFilters();
  }

  void setCategory(int? id) {
    selectedCategoryId.value = id;
    _deriveOptionsFromCache();
    _reloadWithFilters();
  }

  void setGroup(int? id) {
    selectedGroupId.value = id;
    _reloadWithFilters();
  }

  Future<void> _reloadWithFilters() async {
    final compId = int.tryParse(
      reportsController.selectedCompetitionId.value ?? '',
    );
    if (compId == null) return;
    await load(compId);
  }

  void _deriveOptionsFromCache() {
    final stages = <int, String>{};
    final categories = <int, String>{};
    final groups = <int, String>{};

    final stageFilter = selectedStageId.value;
    final categoryFilter = selectedCategoryId.value;

    for (final b in allBlocksCache) {
      final sId = (b['stageId'] as num?)?.toInt();
      final cId = (b['categoryId'] as num?)?.toInt();
      final gId = (b['groupId'] as num?)?.toInt();
      final sName = (b['stageName'] ?? '').toString();
      final cName = (b['categoryName'] ?? '').toString();
      final gName = (b['groupName'] ?? '').toString();

      if (sId != null && sId > 0 && sName.isNotEmpty) {
        stages[sId] = sName;
      }

      // Category options can be derived independent; but if stage is selected,
      // show only categories present for that stage.
      final stageOk = stageFilter == null || stageFilter == sId;
      if (stageOk && cId != null && cId > 0 && cName.isNotEmpty) {
        categories[cId] = cName;
      }

      // Group options are stage-wise and also can be narrowed by category selection.
      final categoryOk = categoryFilter == null || categoryFilter == cId;
      if (stageOk && categoryOk && gId != null && gId > 0 && gName.isNotEmpty) {
        groups[gId] = gName;
      }
    }

    stageOptions.value =
        stages.entries.map((e) => {'id': e.key, 'name': e.value}).toList()
          ..sort(
            (a, b) => (a['name'] as String).compareTo(b['name'] as String),
          );

    categoryOptions.value =
        categories.entries.map((e) => {'id': e.key, 'name': e.value}).toList()
          ..sort(
            (a, b) => (a['name'] as String).compareTo(b['name'] as String),
          );

    groupOptions.value =
        groups.entries.map((e) => {'id': e.key, 'name': e.value}).toList()
          ..sort(
            (a, b) => (a['name'] as String).compareTo(b['name'] as String),
          );
  }

  Future<void> load(int competitionId, {bool refreshOptions = false}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final resp = await _reportsRepository.getCompetitionParticipantScores(
        competitionId,
        stageId: selectedStageId.value,
        categoryId: selectedCategoryId.value,
        groupId: selectedGroupId.value,
      );

      if (!resp.success || resp.data == null) {
        errorMessage.value =
            resp.message ?? 'Failed to load participant scores';
        data.value = null;
        return;
      }

      data.value = Map<String, dynamic>.from(resp.data!);

      // Refresh cache/options when requested or when filters are cleared
      if (refreshOptions ||
          (selectedStageId.value == null &&
              selectedCategoryId.value == null &&
              selectedGroupId.value == null)) {
        final blocks = (data.value?['blocks'] as List?)?.cast() ?? const [];
        allBlocksCache.value = blocks
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
        _deriveOptionsFromCache();
      }
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

    return _reportsRepository.getCompetitionParticipantsExcel(
      competitionId,
      stageId: selectedStageId.value,
      categoryId: selectedCategoryId.value,
      groupId: selectedGroupId.value,
    );
  }
}
