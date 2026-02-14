import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/participant_model.dart';
import 'auth_controller.dart';
import 'event_controller.dart';
import 'participant_controller.dart';

class JuryScoringController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final EventController _eventController = Get.find<EventController>();
  final ParticipantController _participantController =
      Get.find<ParticipantController>();

  // Selection dropdowns (single selection, not checkboxes)
  final RxString selectedStage = ''.obs;
  final RxString selectedCategory = ''.obs;
  final RxString selectedGroup = ''.obs;

  // Current selections display
  final RxString currentStageDisplay = ''.obs;
  final RxString currentCategoryDisplay = ''.obs;
  final RxString currentGroupDisplay = ''.obs;

  // Selection panel expand/collapse state
  final RxBool isSelectionExpanded = false.obs;

  // Queue status
  final RxInt queueCount = 0.obs;

  // Current participants (A, B, C)
  final RxList<ParticipantModel> currentParticipants = <ParticipantModel>[].obs;
  final RxMap<String, bool> selectedParticipantCheckboxes =
      <String, bool>{}.obs; // Map of participantId to checkbox state

  // Current Asana number
  final RxInt currentAsanaNumber = 1.obs;

  // Score controllers for each participant (A, B, C)
  final Map<String, TextEditingController> scoreControllers = {};

  // Jury submission status
  final RxMap<String, bool> jurySubmissionStatus =
      <String, bool>{}.obs; // Map of juryId to submission status

  // Loading states
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    try {
      // Load events if needed
      if (_eventController.events.isEmpty) {
        await _eventController.loadEvents();
      }
      // Load participants for queue
      await loadQueueParticipants();
    } catch (e) {
      errorMessage.value = 'Error loading data: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Load participants in queue
  Future<void> loadQueueParticipants() async {
    try {
      // TODO: Implement API call to get queue participants
      // For now, using dummy data
      queueCount.value = 555; // Dummy queue count
    } catch (e) {
      errorMessage.value = 'Error loading queue: ${e.toString()}';
    }
  }

  // Set selected stage
  void setSelectedStage(String stage) {
    selectedStage.value = stage;
    currentStageDisplay.value = stage.isNotEmpty ? 'STAGE $stage' : '';
    // Load participants for this stage
    loadParticipantsForSelection();
  }

  // Set selected category
  void setSelectedCategory(String category) {
    selectedCategory.value = category;
    currentCategoryDisplay.value = category.isNotEmpty ? category : '';
    // Load participants for this category
    loadParticipantsForSelection();
  }

  // Set selected group
  void setSelectedGroup(String group) {
    selectedGroup.value = group;
    currentGroupDisplay.value = group.isNotEmpty ? group : '';
    // Load participants for this group
    loadParticipantsForSelection();
  }

  // Toggle selection panel expanded state
  void toggleSelectionExpanded() {
    isSelectionExpanded.value = !isSelectionExpanded.value;
  }

  // Load participants based on current selections
  Future<void> loadParticipantsForSelection() async {
    if (selectedStage.value.isEmpty ||
        selectedCategory.value.isEmpty ||
        selectedGroup.value.isEmpty) {
      currentParticipants.clear();
      return;
    }

    isLoading.value = true;
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 500));

      // TODO: Implement API call to get participants based on stage/category/group
      // For now, using dummy data
      currentParticipants.value = [
        ParticipantModel(
          id: '1',
          participantName: 'John Doe',
          participantCode: 'CBA001',
          dateOfBirth: DateTime(2010, 1, 1),
          age: 14,
          gender: 'Male',
          category: selectedCategory.value,
          standard: selectedGroup.value,
          schoolName: 'ABC School',
          address: '123 Main St',
          yogaMasterName: 'Master Yogi',
          yogaMasterContact: '1234567890',
        ),
        ParticipantModel(
          id: '2',
          participantName: 'Jane Smith',
          participantCode: 'CBA002',
          dateOfBirth: DateTime(2011, 2, 15),
          age: 13,
          gender: 'Female',
          category: selectedCategory.value,
          standard: selectedGroup.value,
          schoolName: 'XYZ School',
          address: '456 Oak Ave',
          yogaMasterName: 'Master Zen',
          yogaMasterContact: '0987654321',
        ),
        ParticipantModel(
          id: '3',
          participantName: 'Bob Johnson',
          participantCode: 'CBA003',
          dateOfBirth: DateTime(2010, 5, 20),
          age: 14,
          gender: 'Male',
          category: selectedCategory.value,
          standard: selectedGroup.value,
          schoolName: 'DEF School',
          address: '789 Pine Rd',
          yogaMasterName: 'Master Peace',
          yogaMasterContact: '1122334455',
        ),
      ];

      // Initialize score controllers for new participants
      for (final participant in currentParticipants) {
        if (participant.id != null && !scoreControllers.containsKey(participant.id)) {
          scoreControllers[participant.id!] = TextEditingController();
        }
        // Initialize checkbox state
        if (participant.id != null) {
          selectedParticipantCheckboxes[participant.id!] = false;
        }
      }
    } catch (e) {
      errorMessage.value = 'Error loading participants: ${e.toString()}';
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
    final selectedIds = selectedParticipantCheckboxes.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    if (selectedIds.isEmpty) {
      Get.snackbar(
        'No Selection',
        'Please select at least one participant to reallocate',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
      );
      return;
    }

    isLoading.value = true;
    try {
      // TODO: Implement API call to reallocate participants
      // Remove selected participants from current list
      currentParticipants.removeWhere(
        (p) => selectedIds.contains(p.id),
      );

      // Clear score controllers for removed participants
      for (final id in selectedIds) {
        scoreControllers[id]?.dispose();
        scoreControllers.remove(id);
        selectedParticipantCheckboxes.remove(id);
      }

      // Load next participants from queue
      await loadNextParticipantsFromQueue(selectedIds.length);

      Get.snackbar(
        'Success',
        'Participants reallocated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
      );
    } catch (e) {
      errorMessage.value = 'Error reallocating: ${e.toString()}';
      Get.snackbar(
        'Error',
        'Failed to reallocate participants',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load next participants from queue
  Future<void> loadNextParticipantsFromQueue(int count) async {
    try {
      // TODO: Implement API call to get next participants from queue
      // For now, this is a placeholder
      queueCount.value = (queueCount.value - count).clamp(0, double.infinity).toInt();
    } catch (e) {
      errorMessage.value = 'Error loading next participants: ${e.toString()}';
    }
  }

  // Submit scores
  Future<void> submitScores() async {
    // Validate that all required fields are filled
    if (selectedStage.value.isEmpty ||
        selectedCategory.value.isEmpty ||
        selectedGroup.value.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please select Stage, Category, and Group',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
      return;
    }

    if (currentParticipants.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'No participants to score',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
      return;
    }

    // Validate that all participants have scores
    bool allScoresFilled = true;
    for (final participant in currentParticipants) {
      if (participant.id != null) {
        final controller = scoreControllers[participant.id!];
        if (controller == null || controller.text.trim().isEmpty) {
          allScoresFilled = false;
          break;
        }
      }
    }

    if (!allScoresFilled) {
      Get.snackbar(
        'Validation Error',
        'Please enter scores for all participants',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
      return;
    }

    isLoading.value = true;
    try {
      // Build score data
      final scoreData = <Map<String, dynamic>>[];

      for (final participant in currentParticipants) {
        if (participant.id != null) {
          final controller = scoreControllers[participant.id!];
          if (controller != null && controller.text.trim().isNotEmpty) {
            final score = double.tryParse(controller.text.trim());
            if (score != null) {
              scoreData.add({
                'participantId': participant.id,
                'asanaNumber': currentAsanaNumber.value,
                'asanaName': 'ASANA ${currentAsanaNumber.value}',
                'score': score,
                'stage': selectedStage.value,
                'category': selectedCategory.value,
                'group': selectedGroup.value,
              });
            }
          }
        }
      }

      // TODO: Implement API call to save scores
      // await _participantController.saveScores(...);

      // Mark current jury as submitted
      final currentUser = _authController.currentUser.value;
      if (currentUser?.id != null) {
        final currentUserId = currentUser!.id.toString();
        jurySubmissionStatus[currentUserId] = true;
      }

      // Increment Asana number
      currentAsanaNumber.value++;

      // Clear current scores
      for (final controller in scoreControllers.values) {
        controller.clear();
      }

      // Check if all juries have submitted
      await checkAllJuriesSubmitted();

      Get.snackbar(
        'Success',
        'Scores submitted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
      );
    } catch (e) {
      errorMessage.value = 'Error submitting scores: ${e.toString()}';
      Get.snackbar(
        'Error',
        'Failed to submit scores',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Check if all juries have submitted
  Future<void> checkAllJuriesSubmitted() async {
    // TODO: Implement API call to check jury submission status
    // If all juries have submitted, auto-populate next set of participants
    final allSubmitted = true; // Placeholder - replace with actual check

    if (allSubmitted) {
      // Auto-populate next participants
      await loadNextParticipantsFromQueue(3); // Load next 3 participants
    }
  }

  // Get available stages
  List<String> getAvailableStages() {
    // TODO: Get from API or competition data
    return ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
  }

  // Get available categories
  List<String> getAvailableCategories() {
    // TODO: Get from API or competition data
    return ['COMMON', 'SPECIAL', 'CHAMPIONS'];
  }

  // Get available groups
  List<String> getAvailableGroups() {
    // TODO: Get from API or competition data
    return ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];
  }

  // Get pending juries (juries that haven't submitted)
  List<String> getPendingJuries() {
    // TODO: Get from API
    return jurySubmissionStatus.entries
        .where((entry) => entry.value == false)
        .map((entry) => entry.key)
        .toList();
  }

  // Check if participant controller is used (for linting)
  ParticipantController get participantController => _participantController;

  @override
  void onClose() {
    // Dispose score controllers
    for (final controller in scoreControllers.values) {
      controller.dispose();
    }
    scoreControllers.clear();
    super.onClose();
  }
}

