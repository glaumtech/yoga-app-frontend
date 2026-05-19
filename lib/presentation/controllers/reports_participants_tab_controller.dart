import 'dart:async' show Timer, unawaited;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/api_response.dart';
import '../../data/models/district_model.dart';
import '../../data/models/school_model.dart';
import '../../data/models/state_model.dart';
import '../../data/repositories/competition_repository.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/reports_repository.dart';
import '../../data/repositories/school_repository.dart';
import 'reports_controller.dart';

class ReportsParticipantsTabController extends GetxController {
  final ReportsRepository _reportsRepository = ReportsRepository();
  final CompetitionRepository _competitionRepository = CompetitionRepository();
  final LocationRepository _locationRepository = LocationRepository();
  final SchoolRepository _schoolRepository = SchoolRepository();

  late final ReportsController reportsController;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  /// Paginated participant rows (no jury breakdown).
  final RxList<Map<String, dynamic>> tableItems = <Map<String, dynamic>>[].obs;
  final RxInt tablePage = 0.obs;
  static const int tablePageSize = 20;
  final RxInt tableTotalElements = 0.obs;
  final RxInt tableTotalPages = 0.obs;
  final RxString tableCompetitionName = ''.obs;

  final RxBool isDetailsLoading = false.obs;

  Timer? _searchDebounce;

  /// Empty lists mean "all" for that dimension.
  final RxList<int> selectedStageIds = <int>[].obs;
  final RxList<int> selectedCategoryIds = <int>[].obs;
  final RxList<int> selectedGroupIds = <int>[].obs;
  final RxList<String> selectedGenders = <String>[].obs;

  final RxnInt selectedStateId = RxnInt();
  final RxnInt selectedInstitutionId = RxnInt();
  final RxnInt selectedDistrictFilter = RxnInt();

  // Search is sent to the paginated table API (server-side).
  final RxString participantSearchQuery = ''.obs;
  final TextEditingController participantSearchFieldController =
      TextEditingController();

  /// Stage / category options from API (competition-scoped)
  final RxList<Map<String, dynamic>> stageOptions =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> categoryOptions =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> groupOptions =
      <Map<String, dynamic>>[].obs;

  /// Populated when opening filters (location / institution pickers).
  final RxList<StateModel> filterStateOptions = <StateModel>[].obs;
  final RxList<DistrictModel> filterDistrictOptions = <DistrictModel>[].obs;
  final RxList<SchoolModel> filterInstitutionOptions = <SchoolModel>[].obs;

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
          tableItems.clear();
          tableTotalElements.value = 0;
          tableTotalPages.value = 0;
          tableCompetitionName.value = '';
          participantSearchQuery.value = '';
          participantSearchFieldController.clear();
          stageOptions.clear();
          categoryOptions.clear();
          groupOptions.clear();
          selectedStageIds.clear();
          selectedCategoryIds.clear();
          selectedGroupIds.clear();
          selectedGenders.clear();
          selectedStateId.value = null;
          selectedInstitutionId.value = null;
          selectedDistrictFilter.value = null;
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
  Future<void> refresh() async {
    final id = int.tryParse(
      reportsController.selectedCompetitionId.value ?? '',
    );
    if (id != null) {
      await load(id);
    }
  }

  void clearFilters() {
    selectedStageIds.clear();
    selectedCategoryIds.clear();
    selectedGroupIds.clear();
    selectedGenders.clear();
    selectedStateId.value = null;
    selectedInstitutionId.value = null;
    selectedDistrictFilter.value = null;
    participantSearchQuery.value = '';
    if (participantSearchFieldController.text.isNotEmpty) {
      participantSearchFieldController.clear();
    }
    tablePage.value = 0;
  }

  int get activeFilterCount {
    int n = 0;
    if (selectedStageIds.isNotEmpty) n++;
    if (selectedCategoryIds.isNotEmpty) n++;
    if (selectedGroupIds.isNotEmpty) n++;
    if (selectedStateId.value != null) n++;
    if (selectedDistrictFilter.value != null &&
        selectedDistrictFilter.value! > 0) {
      n++;
    }
    if (selectedInstitutionId.value != null) n++;
    if (selectedGenders.isNotEmpty) n++;
    return n;
  }

  int? _districtQueryParam() {
    final d = selectedDistrictFilter.value;
    if (d == null || d <= 0) return null;
    return d;
  }

  Future<void> ensureFilterStatesLoaded() async {
    if (filterStateOptions.isNotEmpty) return;
    final r = await _locationRepository.getAllStates();
    if (r.success && r.data != null) {
      final list = List<StateModel>.from(r.data!)
        ..sort((a, b) => a.stateName.compareTo(b.stateName));
      filterStateOptions.assignAll(list);
    }
  }

  /// Loads districts for autocomplete; clears when [stateId] is null. Call only after a state is chosen.
  Future<void> reloadFilterDistrictsForState(int? stateId) async {
    filterInstitutionOptions.clear();
    filterDistrictOptions.clear();
    if (stateId == null || stateId <= 0) return;
    final d = await _locationRepository.getDistrictsByStateId(stateId);
    if (d.success && d.data != null) {
      final list = List<DistrictModel>.from(d.data!)
        ..sort((a, b) => a.districtName.toLowerCase().compareTo(
              b.districtName.toLowerCase(),
            ));
      filterDistrictOptions.assignAll(list);
    }
  }

  Future<void> reloadFilterInstitutions({int? stateId, int? cityId}) async {
    filterInstitutionOptions.clear();
    final r = await _schoolRepository.getInstitutionsList(
      stateId: (stateId != null && stateId > 0) ? stateId : null,
      cityId: (cityId != null && cityId > 0) ? cityId : null,
      page: 0,
      limit: 500,
      sortBy: 'institutionName',
      order: 'asc',
    );
    if (r.success && r.data != null) {
      filterInstitutionOptions.assignAll(
        _dedupeInstitutionsForFilter(r.data!.institutions),
      );
    }
  }

  /// Removes duplicate API rows (same id) and near-duplicate names (case/spacing).
  static List<SchoolModel> _dedupeInstitutionsForFilter(List<SchoolModel> raw) {
    final byId = <int, SchoolModel>{};
    for (final s in raw) {
      final id = int.tryParse(s.id ?? '');
      if (id == null) continue;
      byId.putIfAbsent(id, () => s);
    }
    var list = byId.values.toList();
    list.sort((a, b) {
      final an = a.institutionName.toLowerCase();
      final bn = b.institutionName.toLowerCase();
      final c = an.compareTo(bn);
      if (c != 0) return c;
      return (int.tryParse(a.id ?? '0') ?? 0)
          .compareTo(int.tryParse(b.id ?? '0') ?? 0);
    });
    final seenNorm = <String>{};
    final out = <SchoolModel>[];
    for (final s in list) {
      final norm = _normalizedInstitutionNameKey(s.institutionName);
      if (norm.isEmpty) continue;
      if (seenNorm.contains(norm)) continue;
      seenNorm.add(norm);
      out.add(s);
    }
    return out;
  }

  static String _normalizedInstitutionNameKey(String? name) {
    if (name == null || name.isEmpty) return '';
    return name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> prefetchFilterListsForDialog() async {
    await ensureFilterStatesLoaded();
    final sid = selectedStateId.value;
    if (sid != null && sid > 0) {
      await reloadFilterDistrictsForState(sid);
      await reloadFilterInstitutions(stateId: sid, cityId: null);
    }
  }

  /// Resolves typed district name against loaded [known] list.
  int? resolveParticipantReportDistrictId(
    List<DistrictModel> known,
    String typed,
  ) {
    final t = typed.trim();
    if (t.isEmpty) return null;
    for (final d in known) {
      if (d.districtName.toLowerCase() == t.toLowerCase()) return d.id;
    }
    final subs = known
        .where((d) => d.districtName.toLowerCase().contains(t.toLowerCase()))
        .toList();
    if (subs.length == 1) return subs.first.id;
    return null;
  }

  void applyFilters({
    required List<int> stageIds,
    required List<int> categoryIds,
    required List<int> groupIds,
    required List<String> genders,
    int? stateId,
    int? institutionId,
    int? districtId,
  }) {
    selectedStageIds
      ..clear()
      ..addAll(stageIds.toSet());
    selectedCategoryIds
      ..clear()
      ..addAll(categoryIds.toSet());
    selectedGroupIds
      ..clear()
      ..addAll(groupIds.toSet());
    selectedGenders
      ..clear()
      ..addAll(genders.toSet());
    selectedStateId.value = stateId;
    selectedInstitutionId.value = institutionId;
    selectedDistrictFilter.value =
        (districtId != null && districtId > 0) ? districtId : null;
    tablePage.value = 0;
    _reloadWithFilters();
  }

  void setParticipantSearchQuery(String value) {
    participantSearchQuery.value = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      tablePage.value = 0;
      final id = int.tryParse(
        reportsController.selectedCompetitionId.value ?? '',
      );
      if (id != null) {
        unawaited(load(id));
      }
    });
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    _competitionWatcher?.dispose();
    participantSearchFieldController.dispose();
    super.onClose();
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

    final groupsResp = await _competitionRepository.getAllGroups();
    if (groupsResp.success && groupsResp.data != null) {
      groupOptions.value = groupsResp.data!
          .map((g) => <String, dynamic>{'id': g.id, 'name': g.name})
          .toList()
        ..sort(
          (a, b) =>
              (a['name'] as String).compareTo(b['name'] as String),
        );
    } else {
      groupOptions.clear();
    }
  }

  Future<void> load(int competitionId, {bool refreshOptions = false}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (refreshOptions) {
        await loadStageAndCategoryOptions(competitionId);
      }

      final resp = await _reportsRepository.getCompetitionParticipantScoresTable(
        competitionId,
        page: tablePage.value,
        size: tablePageSize,
        search: participantSearchQuery.value.trim().isEmpty
            ? null
            : participantSearchQuery.value.trim(),
        stageIds:
            selectedStageIds.isEmpty ? null : List<int>.from(selectedStageIds),
        categoryIds: selectedCategoryIds.isEmpty
            ? null
            : List<int>.from(selectedCategoryIds),
        groupIds:
            selectedGroupIds.isEmpty ? null : List<int>.from(selectedGroupIds),
        stateId: selectedStateId.value,
        cityId: null,
        institutionId: selectedInstitutionId.value,
        districtId: _districtQueryParam(),
        genders: selectedGenders.isEmpty
            ? null
            : List<String>.from(selectedGenders),
      );

      if (!resp.success || resp.data == null) {
        errorMessage.value =
            resp.message ?? 'Failed to load participant scores';
        tableItems.clear();
        tableTotalElements.value = 0;
        tableTotalPages.value = 0;
        return;
      }

      final d = Map<String, dynamic>.from(resp.data!);
      final rawItems = (d['items'] as List?) ?? const [];
      tableItems.assignAll(
        rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );
      tableTotalElements.value = (d['totalElements'] as num?)?.toInt() ?? 0;
      tableTotalPages.value = (d['totalPages'] as num?)?.toInt() ?? 0;
      tablePage.value = (d['page'] as num?)?.toInt() ?? 0;
      tableCompetitionName.value =
          (d['competitionName'] ?? '').toString();
    } catch (e) {
      errorMessage.value = 'Error loading participant scores: ${e.toString()}';
      tableItems.clear();
      tableTotalElements.value = 0;
      tableTotalPages.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> goToTablePage(int page) async {
    if (page < 0) return;
    if (tableTotalPages.value > 0 && page >= tableTotalPages.value) {
      return;
    }
    tablePage.value = page;
    final id = int.tryParse(
      reportsController.selectedCompetitionId.value ?? '',
    );
    if (id != null) {
      await load(id);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> fetchScoreDetails(
    Map<String, dynamic> row,
  ) async {
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
    final pid = (row['participantRegistrationId'] as num?)?.toInt();
    final rowStageId = (row['stageId'] as num?)?.toInt();
    final rowCategoryId = (row['categoryId'] as num?)?.toInt();
    final rowGroupId = row['groupId'] != null
        ? (row['groupId'] as num?)?.toInt()
        : null;
    if (pid == null || rowStageId == null || rowCategoryId == null) {
      return ApiResponse(
        success: false,
        message: 'Invalid row data',
        statusCode: 0,
      );
    }

    isDetailsLoading.value = true;
    try {
      return await _reportsRepository.getParticipantScoreDetails(
        competitionId,
        participantRegistrationId: pid,
        rowStageId: rowStageId,
        rowCategoryId: rowCategoryId,
        rowGroupId: rowGroupId,
        stageIds:
            selectedStageIds.isEmpty ? null : List<int>.from(selectedStageIds),
        categoryIds: selectedCategoryIds.isEmpty
            ? null
            : List<int>.from(selectedCategoryIds),
        groupIds:
            selectedGroupIds.isEmpty ? null : List<int>.from(selectedGroupIds),
        stateId: selectedStateId.value,
        cityId: null,
        institutionId: selectedInstitutionId.value,
        districtId: _districtQueryParam(),
        genders: selectedGenders.isEmpty
            ? null
            : List<String>.from(selectedGenders),
      );
    } finally {
      isDetailsLoading.value = false;
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

    if (selectedStageIds.length != 1) {
      return ApiResponse(
        success: false,
        message:
            'Select exactly one stage to download Excel (use report filters).',
        statusCode: 0,
      );
    }

    return _reportsRepository.getCompetitionParticipantsExcel(
      competitionId,
      stageIds: List<int>.from(selectedStageIds),
      categoryIds: selectedCategoryIds.isEmpty
          ? null
          : List<int>.from(selectedCategoryIds),
      groupIds: selectedGroupIds.isEmpty
          ? null
          : List<int>.from(selectedGroupIds),
      stateId: selectedStateId.value,
      cityId: null,
      institutionId: selectedInstitutionId.value,
      districtId: _districtQueryParam(),
      genders:
          selectedGenders.isEmpty ? null : List<String>.from(selectedGenders),
    );
  }
}
