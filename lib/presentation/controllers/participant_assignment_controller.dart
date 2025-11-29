import 'package:get/get.dart';
import '../../data/repositories/team_repository.dart';
import '../../data/repositories/participant_repository.dart';
import '../../data/models/team_model.dart';
import '../../data/models/participant_model.dart';
import '../../data/models/assignment_group_model.dart';
import 'judge_controller.dart';

class ParticipantAssignmentController extends GetxController {
  final TeamRepository _teamRepository = TeamRepository();
  final ParticipantRepository _participantRepository = ParticipantRepository();

  // State
  final RxString eventId = ''.obs;
  final RxString selectedTeamId = ''.obs;
  final Rx<TeamModel?> selectedTeam = Rx<TeamModel?>(null);
  final RxList<TeamModel> teams = <TeamModel>[].obs;
  final RxList<ParticipantModel> participants = <ParticipantModel>[].obs;
  final RxList<ParticipantModel> assignedParticipants =
      <ParticipantModel>[].obs;
  final RxList<AssignmentGroupModel> assignmentGroups =
      <AssignmentGroupModel>[].obs;
  final RxSet<String> selectedParticipantIds = <String>{}.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingParticipants = false.obs;
  final RxBool isLoadingAssigned = false.obs;
  final RxString errorMessage = ''.obs;

  // Filter state
  final Rx<ParticipantFilterRequest> currentFilter =
      Rx<ParticipantFilterRequest>(ParticipantFilterRequest());
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 0.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasMorePages = false.obs;

  // Section filter (standard/group)
  final RxString selectedSection = ''.obs;

  @override
  void onInit() {
    super.onInit();
    selectedSection.value = '';
  }

  /// Load teams for an event
  Future<void> loadTeams(String eventId) async {
    try {
      this.eventId.value = eventId;
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _teamRepository.getTeamsByEventId(eventId);

      if (response.success && response.data != null) {
        teams.value = response.data!;

        // If a team was previously selected and still exists, load assigned participants
        if (selectedTeamId.value.isNotEmpty) {
          final teamExists = teams.any((t) => t.id == selectedTeamId.value);
          if (teamExists) {
            // Reload assigned participants for the selected team
            loadAssignedParticipants(eventId);
          } else {
            // Clear selection if team no longer exists
            selectedTeamId.value = '';
            selectedTeam.value = null;
          }
        }
      } else {
        errorMessage.value = response.message ?? 'Failed to load teams';
      }
    } catch (e) {
      errorMessage.value = 'Error loading teams: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  /// Select a team
  void selectTeam(String teamId) {
    selectedTeamId.value = teamId;
    selectedTeam.value = teams.firstWhereOrNull((t) => t.id == teamId);
    selectedParticipantIds.clear();
    // Load assigned participants for the selected team
    if (teamId.isNotEmpty) {
      // Reload participants list with event filter and team category when team is selected
      if (eventId.value.isNotEmpty) {
        final team = selectedTeam.value;
        final category = team?.category.toLowerCase();
        loadParticipants(
          eventId.value,
          resetPage: true,
          category: category,
          assignedStatus: 'Not Assigned',
        );
        // Load assigned participants for the selected team
        loadAssignedParticipants(eventId.value);
      }
    }
  }

  /// Load participants for an event with filters
  Future<void> loadParticipants(
    String eventId, {
    bool resetPage = true,
    String? participantName,
    String? status,
    String? section,
    String? category,
    String? assignedStatus,
  }) async {
    try {
      isLoadingParticipants.value = true;
      errorMessage.value = '';

      if (resetPage) {
        currentPage.value = 1;
      }

      final filter = ParticipantFilterRequest(
        participant: participantName?.isEmpty ?? true ? null : participantName,
        status: status,
        group: section?.isEmpty ?? true ? null : section,
        category: category?.isEmpty ?? true ? null : category,
        assignmentStatus: assignedStatus?.isEmpty ?? true
            ? null
            : assignedStatus,
        page: currentPage.value - 1,
        size: 50,
      );

      final response = await _participantRepository.getParticipantsByEventId(
        eventId: eventId,
        filter: filter,
      );

      if (response.success && response.data != null) {
        final filterData = response.data!;

        // Apply section filter if provided
        List<ParticipantModel> filteredParticipants = filterData.participants;
        if (section != null && section.isNotEmpty) {
          filteredParticipants = filteredParticipants
              .where((p) => p.standard == section)
              .toList();
        }

        if (resetPage) {
          participants.value = filteredParticipants;
        } else {
          participants.addAll(filteredParticipants);
        }

        currentPage.value = filterData.currentPage + 1;
        totalPages.value = filterData.totalPages;
        totalItems.value = filterData.totalItems;
        hasMorePages.value = currentPage.value < totalPages.value;
      } else {
        errorMessage.value = response.message ?? 'Failed to load participants';
      }
    } catch (e) {
      errorMessage.value = 'Error loading participants: ${e.toString()}';
    } finally {
      isLoadingParticipants.value = false;
    }
  }

  /// Toggle participant selection
  void toggleParticipantSelection(String participantId) {
    if (selectedParticipantIds.contains(participantId)) {
      selectedParticipantIds.remove(participantId);
    } else {
      selectedParticipantIds.add(participantId);
    }
  }

  /// Check if participant is selected
  bool isParticipantSelected(String participantId) {
    return selectedParticipantIds.contains(participantId);
  }

  /// Check if participant is already assigned
  bool isParticipantAssigned(String participantId) {
    return assignedParticipants.any((p) => p.id == participantId);
  }

  /// Load assigned participants for an event
  Future<void> loadAssignedParticipants(String eventId) async {
    try {
      isLoadingAssigned.value = true;
      errorMessage.value = '';

      // Filter by selected team if one is selected
      final teamId = selectedTeamId.value.isNotEmpty
          ? selectedTeamId.value
          : null;

      final response = await _teamRepository.getAssignedParticipants(
        eventId,
        page: 0,
        size: 100,
        teamId: teamId,
      );

      if (response.success && response.data != null) {
        assignmentGroups.value = response.data!;
        // Also populate assignedParticipants for backward compatibility
        assignedParticipants.value = response.data!
            .expand((group) => group.participants)
            .toList();
        print('Loaded ${assignmentGroups.length} assignment groups');
      } else {
        errorMessage.value =
            response.message ?? 'Failed to load assigned participants';
        print('Failed to load assigned participants: ${errorMessage.value}');
      }
    } catch (e) {
      errorMessage.value =
          'Error loading assigned participants: ${e.toString()}';
      print('Error loading assigned participants: $e');
    } finally {
      isLoadingAssigned.value = false;
    }
  }

  /// Assign selected participants to the selected team
  Future<bool> assignParticipants() async {
    try {
      if (selectedTeamId.value.isEmpty) {
        Get.snackbar('Error', 'Please select a team');
        return false;
      }

      if (selectedParticipantIds.isEmpty) {
        Get.snackbar('Error', 'Please select at least one participant');
        return false;
      }

      if (selectedTeam.value == null) {
        Get.snackbar('Error', 'Team information not available');
        return false;
      }

      if (eventId.value.isEmpty) {
        Get.snackbar('Error', 'Event ID not available');
        return false;
      }

      isLoading.value = true;
      errorMessage.value = '';

      final team = selectedTeam.value!;

      // Convert eventId to int
      final eventIdInt = int.tryParse(eventId.value) ?? 0;

      // Build juryDtos array with id and name
      List<Map<String, dynamic>> juryDtos = [];

      // Use juryList from team if available (already has id and name)
      if (team.juryList != null && team.juryList!.isNotEmpty) {
        juryDtos = team.juryList!.map((jury) {
          // Ensure id is int if possible
          final juryId = jury['id'];
          final juryIdInt = juryId is int
              ? juryId
              : (int.tryParse(juryId.toString()) ?? 0);

          return {'id': juryIdInt, 'name': jury['name']?.toString() ?? ''};
        }).toList();
      } else {
        // Fallback: Get judge names from JudgeController
        if (Get.isRegistered<JudgeController>()) {
          final judgeController = Get.find<JudgeController>();
          juryDtos = team.juryIds.map((juryId) {
            final judge = judgeController.judges.firstWhereOrNull(
              (j) => j.id?.toString() == juryId.toString(),
            );

            final juryIdInt = int.tryParse(juryId) ?? 0;
            return {'id': juryIdInt, 'name': judge?.name ?? 'Unknown Judge'};
          }).toList();
        } else {
          // Last resort: Use juryIds with placeholder names
          juryDtos = team.juryIds.map((juryId) {
            final juryIdInt = int.tryParse(juryId) ?? 0;
            return {'id': juryIdInt, 'name': 'Judge $juryId'};
          }).toList();
        }
      }

      // Build participants array with id and name
      final participantsList = selectedParticipantIds.map((participantId) {
        final participant = this.participants.firstWhereOrNull(
          (p) => p.id?.toString() == participantId.toString(),
        );

        final participantIdInt = int.tryParse(participantId) ?? 0;
        return {
          'id': participantIdInt,
          'name': participant?.participantName ?? 'Unknown Participant',
        };
      }).toList();

      // Get category and convert to lowercase
      final category = team.category.toLowerCase();

      // Get teamId
      final teamId = selectedTeamId.value;

      final response = await _teamRepository.assignParticipants(
        eventId: eventIdInt,
        teamId: teamId,
        juryDtos: juryDtos,
        participants: participantsList,
        category: category,
      );

      if (response.success) {
        // Clear selection FIRST before reloading
        selectedParticipantIds.clear();

        // Reload assigned participants for the selected team
        await loadAssignedParticipants(eventId.value);

        isLoading.value = false;
        Get.snackbar('Success', 'Participants assigned successfully');
        return true;
      } else {
        errorMessage.value =
            response.message ?? 'Failed to assign participants';
        Get.snackbar('Error', errorMessage.value);
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error assigning participants: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
      isLoading.value = false;
      return false;
    }
  }

  /// Get available sections (standards) from participants
  List<String> getAvailableSections() {
    final sections = participants
        .map((p) => p.standard)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    sections.sort();
    return sections;
  }

  /// Reset filters
  void resetFilters() {
    currentFilter.value = ParticipantFilterRequest();
    selectedSection.value = '';
    currentPage.value = 1;
  }

  void reset() {
    eventId.value = '';
    selectedTeamId.value = '';
    selectedTeam.value = null;
    teams.clear();
    participants.clear();
    assignedParticipants.clear();
    assignmentGroups.clear();
    selectedParticipantIds.clear();
    isLoading.value = false;
    isLoadingParticipants.value = false;
    isLoadingAssigned.value = false;
    errorMessage.value = '';
    currentFilter.value = ParticipantFilterRequest();
    currentPage.value = 1;
    totalPages.value = 0;
    totalItems.value = 0;
    hasMorePages.value = false;
    selectedSection.value = '';
  }

  @override
  void onClose() {
    selectedParticipantIds.clear();
    super.onClose();
  }
}
