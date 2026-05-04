import 'dart:typed_data';

import 'package:get/get.dart';

import '../../data/models/api_response.dart';
import '../../data/models/city_model.dart';
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
  final Rxn<Map<String, dynamic>> data = Rxn<Map<String, dynamic>>();

  /// Empty lists mean "all" for that dimension.
  final RxList<int> selectedStageIds = <int>[].obs;
  final RxList<int> selectedCategoryIds = <int>[].obs;
  final RxList<int> selectedGroupIds = <int>[].obs;
  final RxList<String> selectedGenders = <String>[].obs;

  final RxnInt selectedStateId = RxnInt();
  final RxnInt selectedCityId = RxnInt();
  final RxnInt selectedInstitutionId = RxnInt();

  // UI-only search (filters current blocks in the Participants tab)
  final RxString participantSearchQuery = ''.obs;

  /// Stage / category options from API (competition-scoped)
  final RxList<Map<String, dynamic>> stageOptions =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> categoryOptions =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> groupOptions =
      <Map<String, dynamic>>[].obs;

  /// Populated when opening filters (location / institution pickers).
  final RxList<StateModel> filterStateOptions = <StateModel>[].obs;
  final RxList<CityModel> filterCityOptions = <CityModel>[].obs;
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
          data.value = null;
          stageOptions.clear();
          categoryOptions.clear();
          groupOptions.clear();
          selectedStageIds.clear();
          selectedCategoryIds.clear();
          selectedGroupIds.clear();
          selectedGenders.clear();
          selectedStateId.value = null;
          selectedCityId.value = null;
          selectedInstitutionId.value = null;
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
    selectedStageIds.clear();
    selectedCategoryIds.clear();
    selectedGroupIds.clear();
    selectedGenders.clear();
    selectedStateId.value = null;
    selectedCityId.value = null;
    selectedInstitutionId.value = null;
    participantSearchQuery.value = '';
  }

  int get activeFilterCount {
    int n = 0;
    if (selectedStageIds.isNotEmpty) n++;
    if (selectedCategoryIds.isNotEmpty) n++;
    if (selectedGroupIds.isNotEmpty) n++;
    if (selectedStateId.value != null) n++;
    if (selectedCityId.value != null) n++;
    if (selectedInstitutionId.value != null) n++;
    if (selectedGenders.isNotEmpty) n++;
    return n;
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

  Future<void> reloadFilterCitiesForState(int? stateId) async {
    filterCityOptions.clear();
    filterInstitutionOptions.clear();
    if (stateId == null || stateId <= 0) return;
    final r = await _locationRepository.getCitiesByStateId(stateId);
    if (r.success && r.data != null) {
      final list = List<CityModel>.from(r.data!)
        ..sort((a, b) => a.cityName.compareTo(b.cityName));
      filterCityOptions.assignAll(list);
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
      await reloadFilterCitiesForState(sid);
      await reloadFilterInstitutions(
        stateId: sid,
        cityId: selectedCityId.value,
      );
    }
  }

  void applyFilters({
    required List<int> stageIds,
    required List<int> categoryIds,
    required List<int> groupIds,
    required List<String> genders,
    int? stateId,
    int? cityId,
    int? institutionId,
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
    selectedCityId.value = cityId;
    selectedInstitutionId.value = institutionId;
    _reloadWithFilters();
  }

  void setParticipantSearchQuery(String value) {
    participantSearchQuery.value = value;
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

      final resp = await _reportsRepository.getCompetitionParticipantScores(
        competitionId,
        stageIds:
            selectedStageIds.isEmpty ? null : List<int>.from(selectedStageIds),
        categoryIds: selectedCategoryIds.isEmpty
            ? null
            : List<int>.from(selectedCategoryIds),
        groupIds:
            selectedGroupIds.isEmpty ? null : List<int>.from(selectedGroupIds),
        stateId: selectedStateId.value,
        cityId: selectedCityId.value,
        institutionId: selectedInstitutionId.value,
        genders: selectedGenders.isEmpty
            ? null
            : List<String>.from(selectedGenders),
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
      cityId: selectedCityId.value,
      institutionId: selectedInstitutionId.value,
      genders:
          selectedGenders.isEmpty ? null : List<String>.from(selectedGenders),
    );
  }
}
