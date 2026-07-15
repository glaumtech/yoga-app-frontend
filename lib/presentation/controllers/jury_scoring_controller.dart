import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../data/models/participant_model.dart';
import '../../data/models/jury_assignment_model.dart';
import '../../data/repositories/user_management_repository.dart';
import '../../data/repositories/participant_repository.dart';
import '../../data/repositories/school_repository.dart';
import '../../data/models/school_model.dart';
import '../../routes/app_routes.dart';
import 'user_management_controller.dart';

class JuryScoringController extends GetxController {
  final UserManagementRepository _repository = UserManagementRepository();
  final ParticipantRepository _participantRepository = ParticipantRepository();
  final SchoolRepository _schoolRepository = SchoolRepository();

  // Selection dropdowns (single selection, not checkboxes)
  final RxString selectedStage = ''.obs;
  final RxString selectedCategory = ''.obs;
  final RxString selectedGroup = ''.obs;

  // Institution search (optional)
  final TextEditingController institutionSearchController =
      TextEditingController();
  final RxString institutionSearchText = ''.obs;
  final RxList<SchoolModel> institutionSuggestions = <SchoolModel>[].obs;
  final RxBool isLoadingInstitutions = false.obs;
  final RxnString selectedInstitutionId = RxnString();

  // Selection panel expand/collapse state
  /// SELECT filter section starts expanded so Stage/Category/Group are visible on load.
  final RxBool isSelectionExpanded = true.obs;

  // Current participants (A, B, C)
  final RxList<ParticipantModel> currentParticipants = <ParticipantModel>[].obs;
  final RxMap<String, bool> selectedParticipantCheckboxes =
      <String, bool>{}.obs; // Map of participantId to checkbox state

  // Number of asanas to score (default: 5)
  static const int numberOfAsanas = 5;

  // Score controllers for each participant and asana
  // Format: Map<participantId, Map<asanaNumber, TextEditingController>>
  final Map<String, Map<int, TextEditingController>> scoreControllers = {};

  // Score values for each participant and asana (whole number and decimal)
  // Format: Map<participantId, Map<asanaNumber, Map<String, int>>>
  // where inner map has 'whole' and 'decimal' keys
  // Using regular Map with RxInt trigger for reactivity
  final Map<String, Map<int, Map<String, int>>> scoreValues = {};
  final RxInt scoreUpdateTrigger = 0.obs; // Trigger for reactivity

  // Derived flags for UI enable/disable states
  final RxBool hasScoresEntered = false.obs;
  final RxBool canSubmitScores = false.obs;

  // Current asana being scored (1-5)
  final RxInt currentAsana = 1.obs;

  // Asana numbers (1-5) for which user has clicked Submit this round; API is called only when all 5 are submitted
  final RxList<int> submittedAsanas = <int>[].obs;

  // Jury submission status
  final RxMap<String, bool> jurySubmissionStatus =
      <String, bool>{}.obs; // Map of juryId to submission status

  // Loading states
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Jury assignments data
  final Rx<JuryAssignmentModel?> juryAssignment = Rx<JuryAssignmentModel?>(
    null,
  );

  // Available options from assignments
  final RxList<StageAssignment> availableStages = <StageAssignment>[].obs;
  final RxList<CategoryAssignment> availableCategories =
      <CategoryAssignment>[].obs;
  final RxList<GroupAssignment> availableGroups = <GroupAssignment>[].obs;

  /// Whole-number range from jury assignments API; falls back to 3–10 if missing/invalid.
  int get effectiveMinimumMarks {
    final j = juryAssignment.value;
    if (j == null) return 3;
    final min = j.minimumMarks;
    final max = j.maximumMarks;
    if (min > 0 && max > 0 && min <= max) return min;
    return 3;
  }

  int get effectiveMaximumMarks {
    final j = juryAssignment.value;
    if (j == null) return 10;
    final min = j.minimumMarks;
    final max = j.maximumMarks;
    if (min > 0 && max > 0 && min <= max) return max;
    return 10;
  }

  /// Mark used when jury marks an asana as skipped (from competition config).
  int get effectiveSkippedAsanaMarks {
    final j = juryAssignment.value;
    if (j == null) return 0;
    final skipped = j.skippedAsanaMarks;
    if (skipped < 0) return 0;
    return skipped;
  }

  /// Hide stage/group only for Champions jury on FROM_FIRST_PLACE_WINNERS competitions.
  bool get hideStageAndGroupSelection {
    final j = juryAssignment.value;
    if (j == null ||
        !j.isWinnerBasedChampionship ||
        !j.hasChampionsCategoryAssignment) {
      return false;
    }
    // Jury allotted only to Champions — always hide stage/group.
    if (j.categories.length == 1 && j.categories.first.isChampions) {
      return true;
    }
    // Multiple categories — hide only while Champions is selected.
    return selectedCategory.value.trim().toUpperCase() == 'CHAMPIONS';
  }

  /// Integer buttons for the whole part of the score (inclusive).
  List<int> get wholeScoreValueOptions {
    final min = effectiveMinimumMarks;
    final max = effectiveMaximumMarks;
    if (min > max) {
      return List.generate(8, (i) => 3 + i);
    }
    return List.generate(max - min + 1, (i) => min + i);
  }

  bool _isWholeScoreValid(int whole) {
    return whole >= effectiveMinimumMarks && whole <= effectiveMaximumMarks;
  }

  bool isAsanaSkipped(String participantId, int asanaNum) {
    final score = scoreValues[participantId]?[asanaNum];
    return (score?['skipped'] ?? 0) == 1;
  }

  bool _isAsanaScoreComplete(int whole, bool skipped) {
    return skipped || _isWholeScoreValid(whole);
  }

  @override
  void onInit() {
    super.onInit();
    // Don't load data in onInit - wait for onReady so widget is built
  }

  @override
  void onReady() {
    super.onReady();
    resetAndLoadData();
  }

  // Method to initialize/reset controller data
  Future<void> resetAndLoadData() async {
    // Clear all existing data first
    clearAllData();

    // Then load fresh data
    await loadInitialData();
  }

  // Clear all controller data
  void clearAllData() {
    // Clear participants
    currentParticipants.clear();

    // Clear score controllers
    for (final participantControllers in scoreControllers.values) {
      for (final controller in participantControllers.values) {
        controller.dispose();
      }
    }
    scoreControllers.clear();

    // Clear selections
    selectedStage.value = '';
    selectedCategory.value = '';
    selectedGroup.value = '';
    institutionSearchController.text = '';
    institutionSearchText.value = '';
    institutionSuggestions.clear();
    selectedInstitutionId.value = null;

    // Clear checkboxes
    selectedParticipantCheckboxes.clear();

    // Clear assignments
    juryAssignment.value = null;
    availableStages.clear();
    availableCategories.clear();
    availableGroups.clear();

    // Clear error messages
    errorMessage.value = '';

    // Reset derived flags
    hasScoresEntered.value = false;
    canSubmitScores.value = false;
    submittedAsanas.clear();
  }

  Future<void> searchInstitutions(String query) async {
    if (query.trim().length < 2) {
      institutionSuggestions.clear();
      return;
    }
    try {
      isLoadingInstitutions.value = true;
      final res = await _schoolRepository.searchInstitutions(
        query: query.trim(),
      );
      if (res.success && res.data != null) {
        institutionSuggestions.assignAll(res.data!.institutions);
      } else {
        institutionSuggestions.clear();
      }
    } finally {
      isLoadingInstitutions.value = false;
    }
  }

  void selectInstitution(SchoolModel inst) {
    institutionSearchController.text = inst.institutionName;
    institutionSearchText.value = inst.institutionName;
    selectedInstitutionId.value = inst.id;
    institutionSuggestions.clear();
    _checkAndCallApiIfAllSelected();
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    try {
      // Load jury assignments first
      await loadJuryAssignments();
    } catch (e) {
      errorMessage.value = 'Error loading data: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Load jury assignments from API
  Future<void> loadJuryAssignments() async {
    try {
      // Get current user ID
      final userController = Get.find<UserManagementController>();
      final currentUser = userController.currentUser.value;

      if (currentUser?.id == null) {
        errorMessage.value = 'User not logged in';
        return;
      }

      final response = await _repository.getJuryAssignments(currentUser!.id!);

      if (response.success && response.data != null) {
        juryAssignment.value = response.data!;

        // Populate available stages and categories
        availableStages.value = response.data!.stages;
        availableCategories.value = response.data!.categories;

        // Clear groups initially - will be populated when stage is selected
        availableGroups.clear();
      } else {
        errorMessage.value =
            response.message ?? 'Failed to load jury assignments';
      }
    } catch (e) {
      errorMessage.value = 'Error loading jury assignments: ${e.toString()}';
    }
  }

  // Remaining participants count
  final RxInt remainingCount = 0.obs;

  // Helper method to check if all dropdowns are selected and call API
  void _checkAndCallApiIfAllSelected() {
    final ready = hideStageAndGroupSelection
        ? selectedCategory.value.isNotEmpty
        : selectedStage.value.isNotEmpty &&
              selectedCategory.value.isNotEmpty &&
              selectedGroup.value.isNotEmpty;

    if (ready) {
      print(
        hideStageAndGroupSelection
            ? 'Category selected (${selectedCategory.value}) - Calling for-scoring API (Champions from 1st-place winners)'
            : 'All dropdowns selected - Stage: ${selectedStage.value}, Category: ${selectedCategory.value}, Group: ${selectedGroup.value} - Calling for-scoring API',
      );
      loadParticipantsForSelection();
    } else {
      currentParticipants.clear();
      remainingCount.value = 0;
      print(
        hideStageAndGroupSelection
            ? 'Category not selected - Skipping API call'
            : 'Not all dropdowns selected - Stage: ${selectedStage.value}, Category: ${selectedCategory.value}, Group: ${selectedGroup.value} - Skipping API call',
      );
    }
  }

  // Set selected stage
  void setSelectedStage(String stage) {
    selectedStage.value = stage;

    // Update available groups based on selected stage
    if (stage.isNotEmpty && juryAssignment.value != null) {
      final stageAssignment = availableStages.firstWhereOrNull(
        (s) => s.stageName == stage,
      );
      if (stageAssignment != null) {
        availableGroups.value = stageAssignment.groups;
      } else {
        availableGroups.clear();
      }
    } else {
      availableGroups.clear();
    }

    // Clear group selection if stage changes
    if (selectedGroup.value.isNotEmpty) {
      selectedGroup.value = '';
    }

    // Clear participants if stage is cleared
    if (stage.isEmpty) {
      currentParticipants.clear();
      remainingCount.value = 0;
      return;
    }

    // Check if all dropdowns are selected, then call API
    _checkAndCallApiIfAllSelected();
  }

  // Set selected category
  void setSelectedCategory(String category) {
    selectedCategory.value = category;

    // Clear participants if category is cleared
    if (category.isEmpty) {
      currentParticipants.clear();
      remainingCount.value = 0;
      return;
    }

    // Switching away from Champions on winner-based competitions — clear stage/group
    // so the jury must pick them again for Common/Special scoring.
    final j = juryAssignment.value;
    if (j != null &&
        j.isWinnerBasedChampionship &&
        j.hasChampionsCategoryAssignment &&
        category.trim().toUpperCase() != 'CHAMPIONS') {
      selectedStage.value = '';
      selectedGroup.value = '';
      availableGroups.clear();
    }

    // Check if all dropdowns are selected, then call API
    _checkAndCallApiIfAllSelected();
  }

  // Set selected group
  void setSelectedGroup(String group) {
    selectedGroup.value = group;

    // Clear participants if group is cleared
    if (group.isEmpty) {
      currentParticipants.clear();
      remainingCount.value = 0;
      return;
    }

    // Check if all dropdowns are selected, then call API
    _checkAndCallApiIfAllSelected();
  }

  // Search participants based on current filter selections
  Future<void> searchParticipants() async {
    await loadParticipantsForSelection();
  }

  // Toggle selection panel expanded state
  void toggleSelectionExpanded() {
    isSelectionExpanded.value = !isSelectionExpanded.value;
  }

  // Load participants based on current selections
  // `replaceParticipantIdsOverride` is only used for refresh/reallocate flows.
  Future<void> loadParticipantsForSelection({
    List<int>? replaceParticipantIdsOverride,
  }) async {
    // Get competition and jury info
    if (juryAssignment.value == null) {
      currentParticipants.clear();
      return;
    }

    final competitionId = juryAssignment.value!.competitionId;
    final juryId = juryAssignment.value!.juryId;

    if (competitionId == 0 || juryId == 0) {
      currentParticipants.clear();
      return;
    }

    if (!hideStageAndGroupSelection && selectedStage.value.isEmpty) {
      currentParticipants.clear();
      return;
    }

    if (selectedCategory.value.isEmpty) {
      currentParticipants.clear();
      return;
    }

    isLoading.value = true;
    errorMessage.value = ''; // Clear previous errors
    try {
      // Map stage/category/group names to IDs
      int? stageId;
      int? categoryId;
      int? groupId;

      print(
        'Loading participants - Stage: ${selectedStage.value}, Category: ${selectedCategory.value}, Group: ${selectedGroup.value}',
      );

      if (!hideStageAndGroupSelection) {
        final stageAssignment = availableStages.firstWhereOrNull(
          (s) => s.stageName == selectedStage.value,
        );
        stageId = stageAssignment?.id;

        if (stageId == null) {
          currentParticipants.clear();
          isLoading.value = false;
          return;
        }
      }

      print(
        'Available categories: ${availableCategories.map((c) => c.categoryName).toList()}',
      );
      print('Selected category: ${selectedCategory.value}');
      final categoryAssignment = availableCategories.firstWhereOrNull(
        (c) => c.categoryName == selectedCategory.value,
      );
      categoryId = categoryAssignment?.id;
      print('Category ID found: $categoryId');

      if (categoryId == null) {
        currentParticipants.clear();
        isLoading.value = false;
        return;
      }

      if (!hideStageAndGroupSelection && selectedGroup.value.isNotEmpty) {
        print(
          'Available groups: ${availableGroups.map((g) => g.groupName).toList()}',
        );
        print('Selected group: ${selectedGroup.value}');
        final groupAssignment = availableGroups.firstWhereOrNull(
          (g) => g.groupName == selectedGroup.value,
        );
        groupId = groupAssignment?.id;
        print('Group ID found: $groupId');
      } else {
        groupId = null;
      }

      // Only refresh flow should send replace IDs.
      // Normal auto-load (on stage/category/group change) should NOT send replace IDs.
      final List<int>? replaceParticipantIds = replaceParticipantIdsOverride;

      // Call API to get participants for scoring
      final assignment = juryAssignment.value!;
      print(
        'Calling API with - CompetitionId: $competitionId, JuryId: $juryId, StageId: $stageId, CategoryId: $categoryId, GroupId: $groupId, male: ${assignment.male}, female: ${assignment.female}',
      );
      final response = await _participantRepository.getParticipantsForScoring(
        competitionId: competitionId,
        juryId: juryId,
        stageId: stageId,
        categoryId: categoryId,
        groupId: groupId,
        institutionId: selectedInstitutionId.value,
        male: assignment.male,
        female: assignment.female,
        replaceParticipantIds:
            replaceParticipantIds != null && replaceParticipantIds.isNotEmpty
            ? replaceParticipantIds
            : null,
      );

      print(
        'API Response - Success: ${response.success}, Participants count: ${response.data?.participants.length ?? 0}',
      );

      if (response.success && response.data != null) {
        // Extract participants and remaining count
        final participants = response.data!.participants;
        print('Loaded ${participants.length} participants');
        // Take first 3 participants (A, B, C)
        currentParticipants.value = participants.take(3).toList();

        // Update remaining count if available
        if (response.data!.remainingCount != null) {
          remainingCount.value = response.data!.remainingCount!;
        } else {
          remainingCount.value = 0;
        }

        // Initialize score controllers and values for new participants (5 asanas each)
        for (final participant in currentParticipants) {
          if (participant.id != null) {
            if (!scoreControllers.containsKey(participant.id)) {
              scoreControllers[participant.id!] = {};
            }
            if (!scoreValues.containsKey(participant.id)) {
              scoreValues[participant.id!] = {};
            }
            // Initialize controllers and score values for all 5 asanas
            for (int asanaNum = 1; asanaNum <= numberOfAsanas; asanaNum++) {
              if (!scoreControllers[participant.id!]!.containsKey(asanaNum)) {
                scoreControllers[participant.id!]![asanaNum] =
                    TextEditingController();
              }
              if (!scoreValues[participant.id!]!.containsKey(asanaNum)) {
                scoreValues[participant.id!]![asanaNum] = {
                  'whole': 0,
                  'decimal': 0,
                  'skipped': 0,
                };
              }
            }
            // Initialize checkbox state - UNSELECTED by default
            selectedParticipantCheckboxes[participant.id!] = false;
          }
        }
        // Reset to first asana when new participants are loaded
        currentAsana.value = 1;
        submittedAsanas.clear();

        // Reset derived flags for the new queue
        hasScoresEntered.value = false;
        canSubmitScores.value = false;
      } else {
        currentParticipants.clear();
        errorMessage.value = response.message ?? 'Failed to load participants';
        hasScoresEntered.value = false;
        canSubmitScores.value = false;
      }
    } catch (e, stackTrace) {
      print('Error in loadParticipantsForSelection: $e');
      print('Stack trace: $stackTrace');
      errorMessage.value = 'Error loading participants: ${e.toString()}';
      currentParticipants.clear();
      hasScoresEntered.value = false;
      canSubmitScores.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle participant checkbox
  void toggleParticipantCheckbox(String participantId) {
    final currentValue = selectedParticipantCheckboxes[participantId] ?? false;
    selectedParticipantCheckboxes[participantId] = !currentValue;
  }

  void setAsanaSkipped(String participantId, int asanaNum, bool skipped) {
    if (!scoreValues.containsKey(participantId)) {
      scoreValues[participantId] = {};
    }
    if (!scoreValues[participantId]!.containsKey(asanaNum)) {
      scoreValues[participantId]![asanaNum] = {
        'whole': 0,
        'decimal': 0,
        'skipped': 0,
      };
    }
    scoreValues[participantId]![asanaNum]!['skipped'] = skipped ? 1 : 0;
    if (skipped) {
      final skippedMark = effectiveSkippedAsanaMarks;
      scoreValues[participantId]![asanaNum]!['whole'] = skippedMark;
      scoreValues[participantId]![asanaNum]!['decimal'] = 0;
      final controller = scoreControllers[participantId]?[asanaNum];
      controller?.text = skippedMark.toString();
    }
    scoreUpdateTrigger.value = scoreUpdateTrigger.value + 1;
    _recomputeScoreFlags();
  }

  // Set score for a participant's asana using whole number and decimal
  void setAsanaScore(
    String participantId,
    int asanaNum,
    int whole,
    int decimal,
  ) {
    if (!scoreValues.containsKey(participantId)) {
      scoreValues[participantId] = {};
    }
    if (!scoreValues[participantId]!.containsKey(asanaNum)) {
      scoreValues[participantId]![asanaNum] = {
        'whole': 0,
        'decimal': 0,
        'skipped': 0,
      };
    }
    scoreValues[participantId]![asanaNum]!['skipped'] = 0;
    scoreValues[participantId]![asanaNum]!['whole'] = whole;
    scoreValues[participantId]![asanaNum]!['decimal'] = decimal;
    // Trigger reactivity by updating the trigger
    scoreUpdateTrigger.value = scoreUpdateTrigger.value + 1;

    // Update derived flags for UI
    _recomputeScoreFlags();

    // Next asana loads only after user clicks Submit (no auto-advance)

    // Update text controller with formatted score
    // Decimal values: 25 = 0.25, 50 = 0.5, 75 = 0.75
    final score = whole + (decimal / 100);
    final controller = scoreControllers[participantId]?[asanaNum];
    if (controller != null) {
      // Format to show 1-2 decimal places (e.g., 6.5 or 6.75)
      if (decimal == 0) {
        controller.text = whole.toString();
      } else if (decimal == 50) {
        controller.text = score.toStringAsFixed(1); // 6.5
      } else {
        controller.text = score.toStringAsFixed(2); // 6.25 or 6.75
      }
    }
  }

  void _recomputeScoreFlags() {
    bool any = false;
    // Submit enabled only when all participants have valid score for *current* asana
    bool currentAsanaComplete = currentParticipants.isNotEmpty;
    final asanaNum = currentAsana.value;

    for (final participant in currentParticipants) {
      final pid = participant.id;
      if (pid == null) continue;

      final participantScores = scoreValues[pid];
      if (participantScores == null) {
        currentAsanaComplete = false;
      } else {
        final score = participantScores[asanaNum];
        final whole = score?['whole'] ?? 0;
        final skipped = (score?['skipped'] ?? 0) == 1;
        if (!_isAsanaScoreComplete(whole, skipped)) {
          currentAsanaComplete = false;
        }
      }

      for (int a = 1; a <= numberOfAsanas; a++) {
        final score = participantScores?[a];
        final whole = score?['whole'] ?? 0;
        final skipped = (score?['skipped'] ?? 0) == 1;
        if (_isAsanaScoreComplete(whole, skipped)) {
          any = true;
          break;
        }
      }
    }

    hasScoresEntered.value = any;
    canSubmitScores.value = currentAsanaComplete;
  }

  // Get score for a participant's asana
  Map<String, int>? getAsanaScore(String participantId, int asanaNum) {
    return scoreValues[participantId]?[asanaNum];
  }

  // Get formatted score string (e.g., "6.5", "6.25", "6.75")
  String getFormattedScore(String participantId, int asanaNum) {
    final score = getAsanaScore(participantId, asanaNum);
    if (score != null && (score['skipped'] ?? 0) == 1) {
      return 'Skipped (${effectiveSkippedAsanaMarks})';
    }
    if (score == null || (score['whole'] == 0 && score['decimal'] == 0)) {
      return '';
    }
    final whole = score['whole'] ?? 0;
    final decimal = score['decimal'] ?? 0;
    // Decimal values: 25 = 0.25, 50 = 0.5, 75 = 0.75
    final totalScore = whole + (decimal / 100);
    // Format to show 1-2 decimal places (e.g., 6.5 or 6.75)
    if (decimal == 0) {
      return whole.toString();
    } else if (decimal == 50) {
      return totalScore.toStringAsFixed(1); // 6.5
    } else {
      return totalScore.toStringAsFixed(2); // 6.25 or 6.75
    }
  }

  // Move to next asana
  void nextAsana() {
    if (currentAsana.value < numberOfAsanas) {
      currentAsana.value++;
    }
  }

  // Move to previous asana
  void previousAsana() {
    if (currentAsana.value > 1) {
      currentAsana.value--;
    }
  }

  // Check if current asana has a score
  bool hasCurrentAsanaScore() {
    for (final participant in currentParticipants) {
      if (participant.id != null) {
        final score = getAsanaScore(participant.id!, currentAsana.value);
        final skipped = (score?['skipped'] ?? 0) == 1;
        if (score == null ||
            (!skipped && (score['whole'] == 0 && score['decimal'] == 0))) {
          return false;
        }
      }
    }
    return true;
  }

  // Check if all participants have scores for all 5 asanas
  bool hasAllAsanasScored() {
    // Force reactivity for UI (scoreValues is a plain Map)
    scoreUpdateTrigger.value;
    if (currentParticipants.isEmpty) return false;

    for (final participant in currentParticipants) {
      if (participant.id != null) {
        final participantScores = scoreValues[participant.id!];
        if (participantScores == null) return false;

        // Check all 5 asanas
        for (int asanaNum = 1; asanaNum <= numberOfAsanas; asanaNum++) {
          final score = participantScores[asanaNum];
          if (score == null) return false;

          final whole = score['whole'] ?? 0;
          final skipped = (score['skipped'] ?? 0) == 1;
          if (!_isAsanaScoreComplete(whole, skipped)) return false;
        }
      }
    }
    return true;
  }

  // Check if any participant has any score entered (to disable filters)
  bool hasAnyScoresEntered() {
    // Force reactivity for UI (scoreValues is a plain Map)
    scoreUpdateTrigger.value;
    if (currentParticipants.isEmpty) return false;

    for (final participant in currentParticipants) {
      if (participant.id != null) {
        final participantScores = scoreValues[participant.id!];
        if (participantScores != null) {
          for (int asanaNum = 1; asanaNum <= numberOfAsanas; asanaNum++) {
            final score = participantScores[asanaNum];
            if (score != null) {
              final whole = score['whole'] ?? 0;
              final skipped = (score['skipped'] ?? 0) == 1;
              if (_isAsanaScoreComplete(whole, skipped)) {
                return true;
              }
            }
          }
        }
      }
    }
    return false;
  }

  // Refresh and reallocate from queue based on selected checkboxes
  Future<void> refreshAndReallocate() async {
    try {
      // Prevent multiple simultaneous calls
      if (isLoading.value) {
        return;
      }

      // Only selected participant IDs should be passed for replacement
      final List<int> selectedParticipantIds = [];
      for (final participant in currentParticipants) {
        if (participant.id == null) continue;
        final isSelected =
            selectedParticipantCheckboxes[participant.id!] ?? false;
        if (isSelected) {
          final idInt = int.tryParse(participant.id!);
          if (idInt != null) {
            selectedParticipantIds.add(idInt);
          }
        }
      }

      // Reload participants based on current filters and selected participant IDs
      await loadParticipantsForSelection(
        replaceParticipantIdsOverride: selectedParticipantIds,
      );

      _showSnackbar(
        title: 'Success',
        message: 'Participants refreshed successfully',
        backgroundColor: Colors.green,
      );
    } catch (e, stackTrace) {
      print('Error in refreshAndReallocate: $e');
      print('Stack trace: $stackTrace');
      _showSnackbar(
        title: 'Error',
        message: 'Failed to refresh participants: ${e.toString()}',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // Submit scores
  Future<void> submitScores() async {
    print('=== submitScores() called ===');
    // Prevent multiple simultaneous submissions
    if (isLoading.value) {
      print('Already loading, returning early');
      return;
    }

    print('Setting isLoading to true');
    isLoading.value = true;

    try {
      // Validate that all required fields are filled
      print('Checking stage/category/group selection...');
      print('  Stage: ${selectedStage.value}');
      print('  Category: ${selectedCategory.value}');
      print('  Group: ${selectedGroup.value}');

      if (hideStageAndGroupSelection) {
        if (selectedCategory.value.isEmpty) {
          print('Validation failed: Missing category');
          isLoading.value = false;
          _showSnackbar(
            title: 'Validation Error',
            message: 'Please select Category',
            backgroundColor: Colors.red,
          );
          return;
        }
      } else if (selectedStage.value.isEmpty ||
          selectedCategory.value.isEmpty ||
          selectedGroup.value.isEmpty) {
        print('Validation failed: Missing stage/category/group');
        isLoading.value = false;
        _showSnackbar(
          title: 'Validation Error',
          message: 'Please select Stage, Category, and Group',
          backgroundColor: Colors.red,
        );
        return;
      }

      print('Checking participants...');
      print('  Participants count: ${currentParticipants.length}');

      if (currentParticipants.isEmpty) {
        print('Validation failed: No participants');
        isLoading.value = false;
        _showSnackbar(
          title: 'Validation Error',
          message: 'No participants to score',
          backgroundColor: Colors.red,
        );
        return;
      }

      // Validate that all participants have scores for *current* asana only
      final asanaNum = currentAsana.value;
      bool currentAsanaFilled = true;
      String? missingScoreInfo;
      print('=== Validating current ASANA $asanaNum ===');

      for (final participant in currentParticipants) {
        if (participant.id == null) continue;
        final participantScores = scoreValues[participant.id!];
        if (participantScores == null) {
          currentAsanaFilled = false;
          missingScoreInfo =
              'Missing scores for ${participant.participantName}';
          break;
        }
        final score = participantScores[asanaNum];
        if (score == null) {
          currentAsanaFilled = false;
          missingScoreInfo =
              'Missing score for ${participant.participantName} - ASANA $asanaNum';
          break;
        }
        final whole = score['whole'] ?? 0;
        final skipped = (score['skipped'] ?? 0) == 1;
        if (!_isAsanaScoreComplete(whole, skipped)) {
          currentAsanaFilled = false;
          missingScoreInfo =
              'Invalid score for ${participant.participantName} - ASANA $asanaNum (enter a score ${effectiveMinimumMarks}-${effectiveMaximumMarks} or mark as skipped)';
          break;
        }
      }

      if (!currentAsanaFilled) {
        _showSnackbar(
          title: 'Validation Error',
          message:
              missingScoreInfo ??
              'Please enter scores for all participants for this asana',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        );
        isLoading.value = false;
        return;
      }

      // Record this asana as submitted; next asana loads only after Submit
      if (!submittedAsanas.contains(asanaNum)) {
        submittedAsanas.add(asanaNum);
      }

      // If not all 5 asanas submitted yet, advance to next asana and return (no API call)
      if (submittedAsanas.length < numberOfAsanas) {
        if (currentAsana.value < numberOfAsanas) {
          currentAsana.value++;
        }
        _recomputeScoreFlags();
        _showSnackbar(
          title: 'Asana $asanaNum submitted',
          message: 'Enter scores for ASANA ${currentAsana.value}',
          backgroundColor: Colors.green,
        );
        isLoading.value = false;
        return;
      }

      // All 5 asanas submitted — validate all asanas for API payload
      bool allScoresFilled = true;
      for (final participant in currentParticipants) {
        if (participant.id == null) continue;
        final participantScores = scoreValues[participant.id!];
        if (participantScores == null) {
          allScoresFilled = false;
          break;
        }
        for (int a = 1; a <= numberOfAsanas; a++) {
          final score = participantScores[a];
          final whole = score?['whole'] ?? 0;
          final skipped = (score?['skipped'] ?? 0) == 1;
          if (score == null || !_isAsanaScoreComplete(whole, skipped)) {
            allScoresFilled = false;
            break;
          }
        }
        if (!allScoresFilled) break;
      }
      if (!allScoresFilled) {
        _showSnackbar(
          title: 'Error',
          message: 'All asanas must be scored before saving',
          backgroundColor: Colors.red,
        );
        isLoading.value = false;
        return;
      }

      print('Validation passed! Proceeding to API call...');

      // Get competition and jury info
      if (juryAssignment.value == null) {
        isLoading.value = false;
        _showSnackbar(
          title: 'Error',
          message: 'Jury assignments not loaded',
          backgroundColor: Colors.red,
        );
        return;
      }

      final competitionId = juryAssignment.value!.competitionId;
      final juryId = juryAssignment.value!.juryId;

      if (competitionId == 0 || juryId == 0) {
        isLoading.value = false;
        _showSnackbar(
          title: 'Error',
          message: 'Invalid competition or jury ID',
          backgroundColor: Colors.red,
        );
        return;
      }

      final categoryAssignment = availableCategories.firstWhereOrNull(
        (c) => c.categoryName == selectedCategory.value,
      );

      if (categoryAssignment == null) {
        isLoading.value = false;
        _showSnackbar(
          title: 'Error',
          message: 'Invalid category selection',
          backgroundColor: Colors.red,
        );
        return;
      }

      final categoryId = categoryAssignment.id;
      int? stageId;
      int? groupId;

      if (hideStageAndGroupSelection) {
        stageId = null;
        groupId = null;
      } else {
        final stageAssignment = availableStages.firstWhereOrNull(
          (s) => s.stageName == selectedStage.value,
        );
        final groupAssignment = availableGroups.firstWhereOrNull(
          (g) => g.groupName == selectedGroup.value,
        );

        if (stageAssignment == null || groupAssignment == null) {
          isLoading.value = false;
          _showSnackbar(
            title: 'Error',
            message: 'Invalid stage or group selection',
            backgroundColor: Colors.red,
          );
          return;
        }

        stageId = stageAssignment.id;
        groupId = groupAssignment.id;
      }

      // isLoading.value is already set at the beginning of the method
      errorMessage.value = '';

      try {
        print('=== Starting Score Submission ===');
        print('Competition ID: $competitionId');
        print('Jury ID: $juryId');
        print('Stage ID: $stageId');
        print('Category ID: $categoryId');
        print('Group ID: $groupId');
        print('Number of participants: ${currentParticipants.length}');

        // Build participant scores array in the new format
        final List<Map<String, dynamic>> participantScoresList = [];

        for (final participant in currentParticipants) {
          if (participant.id == null) {
            print(
              'Warning: Participant ${participant.participantName} has no ID, skipping',
            );
            continue;
          }

          final participantScores = scoreValues[participant.id!];
          if (participantScores == null) {
            print(
              'Warning: No scores found for participant ${participant.id}, skipping',
            );
            continue;
          }

          // Parse participant registration ID
          final participantRegistrationId = int.tryParse(participant.id!);
          if (participantRegistrationId == null) {
            print(
              'Warning: Invalid participant ID format: ${participant.id}, skipping',
            );
            continue;
          }

          // Build asana scores array for all 5 asanas
          // Since validation passed, all scores should be present and valid
          final List<Map<String, dynamic>> asanaScores = [];
          for (int asanaNum = 1; asanaNum <= numberOfAsanas; asanaNum++) {
            final score = participantScores[asanaNum];
            if (score == null) {
              print(
                'Error: Missing score for participant ${participant.id} - ASANA $asanaNum',
              );
              isLoading.value = false;
              _showSnackbar(
                title: 'Error',
                message:
                    'Missing score for ${participant.participantName} - ASANA $asanaNum',
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              );
              return;
            }

            final whole = score['whole'] ?? 0;
            final decimal = score['decimal'] ?? 0;
            final skipped = (score['skipped'] ?? 0) == 1;

            if (!_isAsanaScoreComplete(whole, skipped)) {
              print(
                'Error: Invalid score for participant ${participant.id} - ASANA $asanaNum (whole: $whole)',
              );
              isLoading.value = false;
              _showSnackbar(
                title: 'Error',
                message:
                    'Invalid score for ${participant.participantName} - ASANA $asanaNum (enter a score ${effectiveMinimumMarks}-${effectiveMaximumMarks} or mark as skipped)',
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              );
              return;
            }

            // Decimal values: 25 = 0.25, 50 = 0.5, 75 = 0.75
            final totalScore = skipped
                ? effectiveSkippedAsanaMarks.toDouble()
                : whole + (decimal / 100);

            asanaScores.add({
              'asanaName': 'ASANA $asanaNum',
              'score': totalScore,
              'isSkipped': skipped,
            });
          }

          // Add participant score entry
          participantScoresList.add({
            'participantRegistrationId': participantRegistrationId,
            'asanaScores': asanaScores,
          });
          print(
            'Added scores for participant $participantRegistrationId with ${asanaScores.length} asanas',
          );
        }

        if (participantScoresList.isEmpty) {
          isLoading.value = false;
          print('Error: No valid scores to submit after processing');
          _showSnackbar(
            title: 'Error',
            message: 'No valid scores to submit',
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          );
          return;
        }

        print('Total participants to submit: ${participantScoresList.length}');
        print('Request payload: ${jsonEncode(participantScoresList)}');

        // Call API to submit all scores in bulk
        print('=== CALLING submitBulkScores API ===');
        print('CompetitionId: $competitionId, JuryId: $juryId');
        print('StageId: $stageId, CategoryId: $categoryId, GroupId: $groupId');

        final response = await _participantRepository.submitBulkScores(
          competitionId: competitionId,
          juryId: juryId,
          stageId: stageId,
          categoryId: categoryId,
          groupId: groupId,
          participantScores: participantScoresList,
        );

        print('API Response - Success: ${response.success}');
        print('API Response - Message: ${response.message}');
        print('API Response - Status Code: ${response.statusCode}');

        if (response.success) {
          print('Submission successful!');
          // Mark current jury as submitted
          try {
            final userController = Get.find<UserManagementController>();
            final currentUser = userController.currentUser.value;
            if (currentUser?.id != null) {
              final currentUserId = currentUser!.id.toString();
              jurySubmissionStatus[currentUserId] = true;
            }
          } catch (e) {
            // Continue even if we can't mark submission status
          }

          // Clear submitted-asana tracking and current asana
          submittedAsanas.clear();
          currentAsana.value = 1;

          // Clear current scores for all participants and asanas
          for (final participantControllers in scoreControllers.values) {
            for (final controller in participantControllers.values) {
              controller.clear();
            }
          }
          // Clear score values map to re-enable filters
          scoreValues.clear();
          scoreUpdateTrigger.value = 0;
          hasScoresEntered.value = false;
          canSubmitScores.value = false;

          // Reload participants list based on current filters
          try {
            await loadParticipantsForSelection();
          } catch (e) {
            // Log error but don't fail the submission
            print('Error reloading participants after submission: $e');
          }

          final successMsg = response.message?.trim();
          _showSnackbar(
            title: 'Success',
            message: (successMsg != null && successMsg.isNotEmpty)
                ? successMsg
                : 'Scores saved successfully.',
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          );
        } else {
          print('Submission failed!');
          print('Error message: ${response.message}');
          print('Status code: ${response.statusCode}');
          errorMessage.value = response.message ?? 'Failed to submit scores';
          _showSnackbar(
            title: 'Error',
            message: errorMessage.value,
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          );
        }
      } catch (e, stackTrace) {
        print('EXCEPTION in API call: $e');
        print('Stack trace: $stackTrace');
        errorMessage.value = 'Error submitting scores: ${e.toString()}';
        _showSnackbar(
          title: 'Error',
          message: errorMessage.value,
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e, stackTrace) {
      print('EXCEPTION in submitScores (outer catch): $e');
      print('Stack trace: $stackTrace');
      errorMessage.value = 'Error submitting scores: ${e.toString()}';
      _showSnackbar(
        title: 'Error',
        message: errorMessage.value,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
      print('=== Score Submission Complete ===');
    }
  }

  // Get available stages
  List<String> getAvailableStages() {
    return availableStages.map((stage) => stage.stageName).toList();
  }

  // Get available categories
  List<String> getAvailableCategories() {
    return availableCategories
        .map((category) => category.categoryName)
        .toList();
  }

  // Get available groups (filtered by selected stage)
  List<String> getAvailableGroups() {
    return availableGroups.map((group) => group.groupName).toList();
  }

  // Get pending juries (juries that haven't submitted)
  List<String> getPendingJuries() {
    return jurySubmissionStatus.entries
        .where((entry) => entry.value == false)
        .map((entry) => entry.key)
        .toList();
  }

  /// Handle logout: show dialog, then logout and navigate to login.
  Future<void> handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    try {
      if (Get.isRegistered<UserManagementController>()) {
        final userController = Get.find<UserManagementController>();
        await userController.logout();
      }
      if (context.mounted) {
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to safely show snackbars.
  // Deferred to next frame so we never call during a build/layout pass (e.g. after
  // [loadParticipantsForSelection] updates Rx values and triggers Obx rebuilds).
  void _showSnackbar({
    required String title,
    required String message,
    Color backgroundColor = Colors.red,
    Duration duration = const Duration(seconds: 4),
  }) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      SnackbarHelper.show(
        title: title,
        message: message,
        backgroundColor: backgroundColor,
        duration: duration,
      );
    });
  }

  @override
  void onClose() {
    institutionSearchController.dispose();

    // Dispose all score controllers for all participants and asanas
    for (final participantControllers in scoreControllers.values) {
      for (final controller in participantControllers.values) {
        controller.dispose();
      }
    }
    scoreControllers.clear();
    super.onClose();
  }
}
