import 'package:get/get.dart';

import 'reports_participants_list_preset.dart';
import 'reports_participants_tab_controller.dart';

/// Registered participants table (no jury scores) for Reports.
class ReportsRegisteredParticipantsTabController
    extends ReportsParticipantsTabController {
  final RxList<String> selectedCategoryTypes = <String>[].obs;
  final RxnBool spotRegistrationFilter = RxnBool();
  final RxnInt filterAge = RxnInt();
  final RxString registrationPrefix = ''.obs;
  final RxnString selectedInstitutionKind = RxnString();
  final RxnString selectedInstitutionDisplayName = RxnString();
  final RxBool requireInstitutionFilter = false.obs;

  Worker? _presetWatcher;

  /// Invalidates stale [Future.microtask] loads from the competition watcher.
  int _competitionLoadGeneration = 0;

  String? _lastCompetitionId;

  @override
  void onInit() {
    super.onInit();
    // Parent [ever] on competition clears filters on init — replace so dashboard presets stick.
    competitionWatcher?.dispose();
    competitionWatcher = ever<String?>(
      reportsController.selectedCompetitionId,
      (competitionId) {
        final id = int.tryParse(competitionId ?? '');
        if (id != null) {
          final competitionChanged = _lastCompetitionId != competitionId;
          _lastCompetitionId = competitionId;
          final generation = ++_competitionLoadGeneration;
          Future.microtask(() async {
            if (generation != _competitionLoadGeneration) return;

            final pending =
                reportsController.pendingParticipantsPreset.value;
            if (pending != null) {
              applyDashboardPreset(pending);
              reportsController.pendingParticipantsPreset.value = null;
              return;
            }
            if (!competitionChanged) return;

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
          selectedCategoryTypes.clear();
          spotRegistrationFilter.value = null;
          filterAge.value = null;
          registrationPrefix.value = '';
          selectedInstitutionKind.value = null;
          selectedInstitutionDisplayName.value = null;
          requireInstitutionFilter.value = false;
        }
      },
    );
    _presetWatcher = ever<ReportsParticipantsListPreset?>(
      reportsController.pendingParticipantsPreset,
      (preset) {
        if (preset == null) return;
        applyDashboardPreset(preset);
        reportsController.pendingParticipantsPreset.value = null;
      },
    );
  }

  @override
  void onReady() {
    final preset = reportsController.pendingParticipantsPreset.value;
    if (preset != null) {
      applyDashboardPreset(preset);
      reportsController.pendingParticipantsPreset.value = null;
      return;
    }
    super.onReady();
  }

  @override
  void onClose() {
    _presetWatcher?.dispose();
    super.onClose();
  }

  void applyDashboardPreset(ReportsParticipantsListPreset preset) {
    _competitionLoadGeneration++;
    clearFilters();
    if (preset.genders != null && preset.genders!.isNotEmpty) {
      selectedGenders.assignAll(preset.genders!);
    }
    if (preset.categoryTypes != null && preset.categoryTypes!.isNotEmpty) {
      selectedCategoryTypes.assignAll(
        preset.categoryTypes!.map((e) => e.toUpperCase()).toList(),
      );
    }
    if (preset.spotRegistration != null) {
      spotRegistrationFilter.value = preset.spotRegistration;
    }
    if (preset.hasInstitution == true) {
      requireInstitutionFilter.value = true;
    }
    if (preset.institutionKind != null &&
        preset.institutionKind!.trim().isNotEmpty) {
      selectedInstitutionKind.value =
          preset.institutionKind!.trim().toUpperCase();
    }
    if (preset.institutionId != null && preset.institutionId! > 0) {
      selectedInstitutionId.value = preset.institutionId;
      if (preset.label != null && preset.label!.trim().isNotEmpty) {
        selectedInstitutionDisplayName.value = preset.label!.trim();
      }
    }
    if (preset.registrationPrefix != null &&
        preset.registrationPrefix!.trim().isNotEmpty) {
      registrationPrefix.value = preset.registrationPrefix!.trim().toUpperCase();
    }
    if (preset.age != null) {
      filterAge.value = preset.age;
    }
    tablePage.value = 0;
    final id = int.tryParse(
      reportsController.selectedCompetitionId.value ?? '',
    );
    if (id != null) {
      load(id);
    }
  }

  @override
  void clearFilters() {
    super.clearFilters();
    selectedCategoryTypes.clear();
    spotRegistrationFilter.value = null;
    filterAge.value = null;
    registrationPrefix.value = '';
    selectedInstitutionKind.value = null;
    selectedInstitutionDisplayName.value = null;
    requireInstitutionFilter.value = false;
  }

  @override
  int get activeFilterCount {
    var n = super.activeFilterCount;
    if (selectedCategoryTypes.isNotEmpty) n++;
    if (spotRegistrationFilter.value != null) n++;
    if (filterAge.value != null) n++;
    if (registrationPrefix.value.trim().isNotEmpty) n++;
    if (selectedInstitutionKind.value != null &&
        selectedInstitutionKind.value!.isNotEmpty) {
      n++;
    }
    if (requireInstitutionFilter.value) n++;
    return n;
  }

  @override
  List<ReportsActiveFilterChip> buildActiveFilterChips() {
    final chips = super.buildActiveFilterChips();

    for (final ct in selectedCategoryTypes) {
      chips.add(ReportsActiveFilterChip(
        key: 'categoryType:$ct',
        label: 'Type: $ct',
      ));
    }

    final spot = spotRegistrationFilter.value;
    if (spot != null) {
      chips.add(ReportsActiveFilterChip(
        key: 'spotRegistration',
        label: spot ? 'Spot registration' : 'Online registration',
      ));
    }

    final age = filterAge.value;
    final prefix = registrationPrefix.value.trim();
    if (age != null && prefix.isNotEmpty) {
      chips.add(ReportsActiveFilterChip(
        key: 'agePrefix',
        label: 'Age $age ($prefix)',
      ));
    } else if (age != null) {
      chips.add(ReportsActiveFilterChip(
        key: 'age',
        label: 'Age: $age',
      ));
    } else if (prefix.isNotEmpty) {
      chips.add(ReportsActiveFilterChip(
        key: 'prefix',
        label: 'Prefix: $prefix',
      ));
    }

    if (requireInstitutionFilter.value) {
      chips.add(const ReportsActiveFilterChip(
        key: 'allInstitutions',
        label: 'All institutions',
      ));
    }

    final instKind = selectedInstitutionKind.value?.trim();
    if (instKind == 'SCHOOL') {
      chips.add(const ReportsActiveFilterChip(
        key: 'institutionKind:SCHOOL',
        label: 'Schools only',
      ));
    } else if (instKind == 'COLLEGE') {
      chips.add(const ReportsActiveFilterChip(
        key: 'institutionKind:COLLEGE',
        label: 'Colleges only',
      ));
    }

    final instId = selectedInstitutionId.value;
    if (instId != null && instId > 0) {
      final display = selectedInstitutionDisplayName.value?.trim();
      if (display != null && display.isNotEmpty) {
        chips.removeWhere((c) => c.key == 'institution');
        chips.add(ReportsActiveFilterChip(
          key: 'institution',
          label: 'Institution: $display',
        ));
      }
    }

    return chips;
  }

  @override
  Future<void> removeActiveFilter(String key) async {
    if (key.startsWith('categoryType:')) {
      selectedCategoryTypes.remove(key.substring('categoryType:'.length));
    } else if (key == 'spotRegistration') {
      spotRegistrationFilter.value = null;
    } else if (key == 'agePrefix') {
      filterAge.value = null;
      registrationPrefix.value = '';
    } else if (key == 'age') {
      filterAge.value = null;
    } else if (key == 'prefix') {
      registrationPrefix.value = '';
    } else if (key == 'allInstitutions') {
      requireInstitutionFilter.value = false;
    } else if (key.startsWith('institutionKind:')) {
      selectedInstitutionKind.value = null;
    } else if (key == 'institution') {
      selectedInstitutionId.value = null;
      selectedInstitutionDisplayName.value = null;
    } else {
      await super.removeActiveFilter(key);
      return;
    }

    tablePage.value = 0;
    await refresh();
  }

  @override
  Future<void> load(int competitionId, {bool refreshOptions = false}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (refreshOptions) {
        await loadStageAndCategoryOptions(competitionId);
      }

      final prefix = registrationPrefix.value.trim();
      final resp = await reportsRepository.getCompetitionParticipantsTable(
        competitionId,
        page: tablePage.value,
        size: ReportsParticipantsTabController.tablePageSize,
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
        districtId: districtQueryParam(),
        genders: selectedGenders.isEmpty
            ? null
            : List<String>.from(selectedGenders),
        categoryTypes: selectedCategoryTypes.isEmpty
            ? null
            : List<String>.from(selectedCategoryTypes),
        spotRegistration: spotRegistrationFilter.value,
        age: filterAge.value,
        registrationPrefix: prefix.isEmpty ? null : prefix,
        institutionKind: selectedInstitutionKind.value,
        hasInstitution:
            requireInstitutionFilter.value ? true : null,
      );

      if (!resp.success || resp.data == null) {
        errorMessage.value =
            resp.message ?? 'Failed to load registered participants';
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
      tableCompetitionName.value = (d['competitionName'] ?? '').toString();
    } catch (e) {
      errorMessage.value =
          'Error loading registered participants: ${e.toString()}';
      tableItems.clear();
      tableTotalElements.value = 0;
      tableTotalPages.value = 0;
    } finally {
      isLoading.value = false;
    }
  }
}
