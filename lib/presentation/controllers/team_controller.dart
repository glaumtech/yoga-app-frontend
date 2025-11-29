import 'package:get/get.dart';
import '../../data/models/team_model.dart';
import '../../data/repositories/team_repository.dart';
import '../../core/constants/app_constants.dart';
import 'judge_controller.dart';

class TeamController extends GetxController {
  final TeamRepository _teamRepository = TeamRepository();

  final RxList<TeamModel> teams = <TeamModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Form fields for creating/editing a team
  final RxString teamName = ''.obs;
  final RxList<String> selectedJuryIds = <String>[].obs;
  final RxString selectedCategory = ''.obs;
  final Rx<TeamModel?> teamToEdit = Rx<TeamModel?>(null);

  Future<void> loadTeamsByEventId(String eventId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _teamRepository.getTeamsByEventId(eventId);

      if (response.success && response.data != null) {
        teams.value = response.data!;
      } else {
        errorMessage.value = response.message ?? 'Failed to load teams';
        Get.snackbar('Error', errorMessage.value);
      }
    } catch (e) {
      errorMessage.value = 'Failed to load teams: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateTeam(String teamId, String eventId) async {
    try {
      // Validation
      if (teamName.value.trim().isEmpty) {
        Get.snackbar('Error', 'Team name is required');
        return false;
      }

      if (selectedJuryIds.isEmpty) {
        Get.snackbar('Error', 'Please select at least one jury member');
        return false;
      }

      if (selectedCategory.value.isEmpty) {
        Get.snackbar('Error', 'Please select a category');
        return false;
      }

      isLoading.value = true;
      errorMessage.value = '';

      // Build juryList with id and name from JudgeController
      List<Map<String, dynamic>> juryList = [];
      try {
        final judgeController = Get.find<JudgeController>();
        for (String juryId in selectedJuryIds) {
          final judge = judgeController.judges.firstWhereOrNull(
            (j) => j.id == juryId,
          );
          if (judge != null) {
            // Try to parse as int, fallback to string if not possible
            final idValue = int.tryParse(juryId);
            juryList.add({'id': idValue ?? juryId, 'name': judge.name});
          }
        }
      } catch (e) {
        Get.snackbar('Error', 'Failed to get judge details: ${e.toString()}');
        isLoading.value = false;
        return false;
      }

      final team = TeamModel(
        id: teamId,
        teamName: teamName.value.trim(),
        eventId: eventId,
        juryIds: selectedJuryIds.toList(),
        category: selectedCategory.value,
      );

      final response = await _teamRepository.updateTeam(
        teamId,
        team,
        juryList: juryList,
      );

      if (response.success && response.data != null) {
        // Update team in teams list
        final index = teams.indexWhere((t) => t.id == teamId);
        if (index != -1) {
          teams[index] = response.data!;
        }
        // Reset form
        resetForm();
        isLoading.value = false;
        Get.snackbar('Success', 'Team updated successfully');
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to update team';
        Get.snackbar('Error', errorMessage.value);
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error updating team: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
      isLoading.value = false;
      return false;
    }
  }

  Future<bool> createTeam(String eventId) async {
    try {
      // Validation
      if (teamName.value.trim().isEmpty) {
        Get.snackbar('Error', 'Team name is required');
        return false;
      }

      if (selectedJuryIds.isEmpty) {
        Get.snackbar('Error', 'Please select at least one jury member');
        return false;
      }

      if (selectedCategory.value.isEmpty) {
        Get.snackbar('Error', 'Please select a category');
        return false;
      }

      isLoading.value = true;
      errorMessage.value = '';

      // Build juryList with id and name from JudgeController
      List<Map<String, dynamic>> juryList = [];
      try {
        final judgeController = Get.find<JudgeController>();
        for (String juryId in selectedJuryIds) {
          final judge = judgeController.judges.firstWhereOrNull(
            (j) => j.id == juryId,
          );
          if (judge != null) {
            // Try to parse as int, fallback to string if not possible
            final idValue = int.tryParse(juryId);
            juryList.add({'id': idValue ?? juryId, 'name': judge.name});
          }
        }
      } catch (e) {
        Get.snackbar('Error', 'Failed to get judge details: ${e.toString()}');
        isLoading.value = false;
        return false;
      }

      final team = TeamModel(
        teamName: teamName.value.trim(),
        eventId: eventId,
        juryIds: selectedJuryIds.toList(),
        category: selectedCategory.value,
      );

      final response = await _teamRepository.createTeam(
        team,
        juryList: juryList,
      );

      if (response.success && response.data != null) {
        // Add to teams list
        teams.add(response.data!);
        // Reset form
        resetForm();
        isLoading.value = false;
        Get.snackbar('Success', 'Team created successfully');
        return true;
      } else {
        errorMessage.value = response.message ?? 'Failed to create team';
        Get.snackbar('Error', errorMessage.value);
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error creating team: ${e.toString()}';
      Get.snackbar('Error', errorMessage.value);
      isLoading.value = false;
      return false;
    }
  }

  void resetForm() {
    teamName.value = '';
    selectedJuryIds.clear();
    selectedCategory.value = '';
    errorMessage.value = '';
    teamToEdit.value = null;
  }

  void initializeFormForEdit(TeamModel team) {
    teamToEdit.value = team;
    teamName.value = team.teamName;
    selectedCategory.value = team.category;
    selectedJuryIds.value = team.juryIds.toList();
    errorMessage.value = '';
  }

  bool get isEditMode => teamToEdit.value != null;

  void toggleJurySelection(String juryId) {
    if (selectedJuryIds.contains(juryId)) {
      selectedJuryIds.remove(juryId);
    } else {
      selectedJuryIds.add(juryId);
    }
  }

  bool isJurySelected(String juryId) {
    return selectedJuryIds.contains(juryId);
  }

  List<String> get categories => [
    AppConstants.categoryCommon,
    AppConstants.categorySpecial,
  ];

  void reset() {
    teams.clear();
    isLoading.value = false;
    errorMessage.value = '';
    teamName.value = '';
    selectedJuryIds.clear();
    selectedCategory.value = '';
    teamToEdit.value = null;
  }
}
