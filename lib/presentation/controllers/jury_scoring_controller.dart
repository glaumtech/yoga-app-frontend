import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/participant_model.dart';
import '../../data/models/jury_assignment_model.dart';
import '../../data/repositories/user_management_repository.dart';
import '../../data/repositories/participant_repository.dart';
import 'user_management_controller.dart';

class JuryScoringController extends GetxController {
  final UserManagementRepository _repository = UserManagementRepository();
  final ParticipantRepository _participantRepository = ParticipantRepository();

  // Selection dropdowns (single selection, not checkboxes)
  final RxString selectedStage = ''.obs;
  final RxString selectedCategory = ''.obs;
  final RxString selectedGroup = ''.obs;

  // Selection panel expand/collapse state
  final RxBool isSelectionExpanded = false.obs;

  // Current participants (A, B, C)
  final RxList<ParticipantModel> currentParticipants = <ParticipantModel>[].obs;
  final RxMap<String, bool> selectedParticipantCheckboxes =
      <String, bool>{}.obs; // Map of participantId to checkbox state

  // Number of asanas to score (default: 5)
  static const int numberOfAsanas = 5;

  // Score controllers for each participant and asana
  // Format: Map<participantId, Map<asanaNumber, TextEditingController>>
  final Map<String, Map<int, TextEditingController>> scoreControllers = {};

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

  // Get minimum and maximum marks from assignment
  int get minimumMarks => juryAssignment.value?.minimumMarks ?? 0;
  int get maximumMarks => juryAssignment.value?.maximumMarks ?? 100;

  @override
  void onInit() {
    super.onInit();
    // Don't load data automatically - wait for explicit call
    // This prevents loading with stale user data
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

    // Clear checkboxes
    selectedParticipantCheckboxes.clear();

    // Clear assignments
    juryAssignment.value = null;
    availableStages.clear();
    availableCategories.clear();
    availableGroups.clear();

    // Clear error messages
    errorMessage.value = '';
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

    // Don't call API - wait for search button click
  }

  // Set selected category
  void setSelectedCategory(String category) {
    selectedCategory.value = category;
    // Don't call API - wait for search button click
  }

  // Set selected group
  void setSelectedGroup(String group) {
    selectedGroup.value = group;
    // Don't call API - wait for search button click
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
  Future<void> loadParticipantsForSelection() async {
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

    // At least stage must be selected to load participants
    if (selectedStage.value.isEmpty) {
      currentParticipants.clear();
      return;
    }

    isLoading.value = true;
    try {
      // Map stage/category/group names to IDs
      int? stageId;
      int? categoryId;
      int? groupId;

      // Get stage ID (required)
      final stageAssignment = availableStages.firstWhereOrNull(
        (s) => s.stageName == selectedStage.value,
      );
      stageId = stageAssignment?.id;

      if (stageId == null) {
        currentParticipants.clear();
        isLoading.value = false;
        return;
      }

      // Get category ID (optional)
      if (selectedCategory.value.isNotEmpty) {
        final categoryAssignment = availableCategories.firstWhereOrNull(
          (c) => c.categoryName == selectedCategory.value,
        );
        categoryId = categoryAssignment?.id;
      }

      // Get group ID
      if (selectedGroup.value.isNotEmpty) {
        final groupAssignment = availableGroups.firstWhereOrNull(
          (g) => g.groupName == selectedGroup.value,
        );
        groupId = groupAssignment?.id;
      } else {
        groupId = null;
      }

      // Get unselected participant IDs (those with unchecked checkboxes)
      final List<int> unselectedParticipantIds = [];
      for (final participant in currentParticipants) {
        if (participant.id != null) {
          final isSelected =
              selectedParticipantCheckboxes[participant.id!] ?? false;
          if (!isSelected) {
            final participantId = int.tryParse(participant.id!);
            if (participantId != null) {
              unselectedParticipantIds.add(participantId);
            }
          }
        }
      }

      // Call API to get participants for scoring
      final response = await _participantRepository.getParticipantsForScoring(
        competitionId: competitionId,
        juryId: juryId,
        stageId: stageId,
        categoryId: categoryId,
        groupId: groupId,
        replaceParticipantIds: unselectedParticipantIds.isNotEmpty
            ? unselectedParticipantIds
            : null,
      );

      if (response.success && response.data != null) {
        // Take first 3 participants (A, B, C)
        currentParticipants.value = response.data!.take(3).toList();

        // Initialize score controllers for new participants (5 asanas each)
        for (final participant in currentParticipants) {
          if (participant.id != null) {
            if (!scoreControllers.containsKey(participant.id)) {
              scoreControllers[participant.id!] = {};
            }
            // Initialize controllers for all 5 asanas
            for (int asanaNum = 1; asanaNum <= numberOfAsanas; asanaNum++) {
              if (!scoreControllers[participant.id!]!.containsKey(asanaNum)) {
                scoreControllers[participant.id!]![asanaNum] =
                    TextEditingController();
              }
            }
            // Initialize checkbox state - select all by default
            selectedParticipantCheckboxes[participant.id!] = true;
          }
        }
      } else {
        currentParticipants.clear();
        errorMessage.value = response.message ?? 'Failed to load participants';
      }
    } catch (e, stackTrace) {
      print('Error in loadParticipantsForSelection: $e');
      print('Stack trace: $stackTrace');
      errorMessage.value = 'Error loading participants: ${e.toString()}';
      currentParticipants.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle participant checkbox
  void toggleParticipantCheckbox(String participantId) {
    final currentValue = selectedParticipantCheckboxes[participantId] ?? false;
    selectedParticipantCheckboxes[participantId] = !currentValue;
  }

  // Refresh and reallocate from queue based on selected checkboxes
  Future<void> refreshAndReallocate() async {
    try {
      // Prevent multiple simultaneous calls
      if (isLoading.value) {
        return;
      }

    // Don't reload assignments - just reload participants with unselected IDs
    // Reload participants based on current filters and unselected participant IDs
    await loadParticipantsForSelection();

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
    // Prevent multiple simultaneous submissions
    if (isLoading.value) {
      return;
    }

    // Validate that all required fields are filled
    if (selectedStage.value.isEmpty ||
        selectedCategory.value.isEmpty ||
        selectedGroup.value.isEmpty) {
      _showSnackbar(
        title: 'Validation Error',
        message: 'Please select Stage, Category, and Group',
        backgroundColor: Colors.red,
      );
      return;
    }

    if (currentParticipants.isEmpty) {
      _showSnackbar(
        title: 'Validation Error',
        message: 'No participants to score',
        backgroundColor: Colors.red,
      );
      return;
    }

    // Validate that all participants have scores for all 5 asanas
    bool allScoresFilled = true;
    String? missingScoreInfo;
    for (final participant in currentParticipants) {
      if (participant.id != null) {
        final participantControllers = scoreControllers[participant.id!];
        if (participantControllers == null) {
          allScoresFilled = false;
          missingScoreInfo =
              'Missing controllers for ${participant.participantName}';
          break;
        }
        // Check all 5 asanas
        for (int asanaNum = 1; asanaNum <= numberOfAsanas; asanaNum++) {
          final controller = participantControllers[asanaNum];
          if (controller == null || controller.text.trim().isEmpty) {
            allScoresFilled = false;
            missingScoreInfo =
                'Missing score for ${participant.participantName} - ASANA $asanaNum';
            break;
          }
          // Validate that the score is a valid number
          final scoreText = controller.text.trim();
          final score = double.tryParse(scoreText);
          if (score == null) {
            allScoresFilled = false;
            missingScoreInfo =
                'Invalid score for ${participant.participantName} - ASANA $asanaNum (must be a number)';
            break;
          }
        }
        if (!allScoresFilled) break;
      }
    }

    if (!allScoresFilled) {
      _showSnackbar(
        title: 'Validation Error',
        message: missingScoreInfo ??
            'Please enter scores for all participants and all asanas',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // Get competition and jury info
    if (juryAssignment.value == null) {
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
      _showSnackbar(
        title: 'Error',
        message: 'Invalid competition or jury ID',
        backgroundColor: Colors.red,
      );
      return;
    }

    // Get stage, category, and group IDs
    final stageAssignment = availableStages.firstWhereOrNull(
      (s) => s.stageName == selectedStage.value,
    );
    final categoryAssignment = availableCategories.firstWhereOrNull(
      (c) => c.categoryName == selectedCategory.value,
    );
    final groupAssignment = availableGroups.firstWhereOrNull(
      (g) => g.groupName == selectedGroup.value,
    );

    if (stageAssignment == null ||
        categoryAssignment == null ||
        groupAssignment == null) {
      _showSnackbar(
        title: 'Error',
        message: 'Invalid stage, category, or group selection',
        backgroundColor: Colors.red,
      );
      return;
    }

    final stageId = stageAssignment.id;
    final categoryId = categoryAssignment.id;
    final groupId = groupAssignment.id;

    isLoading.value = true;
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
          print('Warning: Participant ${participant.participantName} has no ID, skipping');
          continue;
        }

        final participantControllers = scoreControllers[participant.id!];
        if (participantControllers == null) {
          print('Warning: No controllers found for participant ${participant.id}, skipping');
          continue;
        }

        // Parse participant registration ID
        final participantRegistrationId = int.tryParse(participant.id!);
        if (participantRegistrationId == null) {
          print('Warning: Invalid participant ID format: ${participant.id}, skipping');
          continue;
        }

        // Build asana scores array for all 5 asanas
        // Since validation passed, all scores should be present and valid
        final List<Map<String, dynamic>> asanaScores = [];
        for (int asanaNum = 1; asanaNum <= numberOfAsanas; asanaNum++) {
          final controller = participantControllers[asanaNum];
          if (controller == null || controller.text.trim().isEmpty) {
            print('Error: Missing score for participant ${participant.id} - ASANA $asanaNum');
            isLoading.value = false;
            _showSnackbar(
              title: 'Error',
              message: 'Missing score for ${participant.participantName} - ASANA $asanaNum',
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            );
            return;
          }

          final scoreText = controller.text.trim();
          final score = double.tryParse(scoreText);
          if (score == null) {
            print('Error: Invalid score format for participant ${participant.id} - ASANA $asanaNum: $scoreText');
            isLoading.value = false;
            _showSnackbar(
              title: 'Error',
              message: 'Invalid score for ${participant.participantName} - ASANA $asanaNum: $scoreText',
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            );
            return;
          }

          asanaScores.add({'asanaName': 'ASANA $asanaNum', 'score': score});
        }

        // Add participant score entry
        participantScoresList.add({
          'participantRegistrationId': participantRegistrationId,
          'asanaScores': asanaScores,
        });
        print('Added scores for participant $participantRegistrationId with ${asanaScores.length} asanas');
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
      print('Calling submitBulkScores API...');
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

        // Clear current scores for all participants and asanas
        for (final participantControllers in scoreControllers.values) {
          for (final controller in participantControllers.values) {
            controller.clear();
          }
        }

        // Reload participants list based on current filters
        try {
        await loadParticipantsForSelection();
        } catch (e) {
          // Log error but don't fail the submission
          print('Error reloading participants after submission: $e');
        }

        _showSnackbar(
          title: 'Success',
          message: response.message ?? 'Scores submitted successfully',
          backgroundColor: Colors.green,
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
      print('EXCEPTION in submitScores: $e');
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

  // Helper method to safely show snackbars
  void _showSnackbar({
    required String title,
    required String message,
    Color backgroundColor = Colors.red,
    Duration duration = const Duration(seconds: 4),
  }) {
    try {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: backgroundColor,
        duration: duration,
      );
    } catch (e) {
      // If GetX context is not available, just print the error
      print('Error showing snackbar: $e');
      print('Title: $title, Message: $message');
    }
  }

  @override
  void onClose() {
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
