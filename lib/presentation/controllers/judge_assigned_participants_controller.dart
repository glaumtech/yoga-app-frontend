import 'package:get/get.dart';
import '../../data/repositories/team_repository.dart';
import '../../data/models/participant_model.dart';
import '../../data/models/assignment_group_model.dart';
import '../controllers/judge_controller.dart';

class JudgeAssignedParticipantsController extends GetxController {
  final TeamRepository _teamRepository = TeamRepository();
  final JudgeController _judgeController = Get.find<JudgeController>();

  // State
  final RxString eventId = ''.obs;
  final RxList<AssignmentGroupModel> assignmentGroups =
      <AssignmentGroupModel>[].obs;
  final RxList<ParticipantModel> assignedParticipants =
      <ParticipantModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  @override
  void onInit() {
    super.onInit();
  }

  /// Load assigned participants for the current judge
  Future<void> loadAssignedParticipants(String eventId) async {
    try {
      this.eventId.value = eventId;
      isLoading.value = true;
      errorMessage.value = '';
      assignmentGroups.clear();
      assignedParticipants.clear();

      // Always reload current judge to ensure we have the latest data for current user
      await _judgeController.loadCurrentJudge();
      final judgeData = _judgeController.currentJudge.value;
      if (judgeData == null) {
        errorMessage.value = 'Judge not found';
        isLoading.value = false;
        return;
      }

      // Call assignedParticipantsByJudgeId API
      final response = await _teamRepository.getAssignedParticipantsByJudgeId(
        eventId,
        judgeData.id.toString(),
        page: 0,
        size: 100,
      );

      if (response.success && response.data != null) {
        assignmentGroups.value = response.data!;

        // Also extract all participants for backward compatibility
        final allParticipants = <ParticipantModel>[];
        final participantIds = <String>{};

        for (final assignmentGroup in response.data!) {
          for (final participant in assignmentGroup.participants) {
            // Avoid duplicates
            if (participant.id != null &&
                !participantIds.contains(participant.id)) {
              participantIds.add(participant.id!);
              allParticipants.add(participant);
            }
          }
        }

        assignedParticipants.value = allParticipants;
      } else {
        errorMessage.value =
            response.message ?? 'Failed to load assigned participants';
      }
    } catch (e) {
      errorMessage.value =
          'Error loading assigned participants: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  void reset() {
    eventId.value = '';
    assignmentGroups.clear();
    assignedParticipants.clear();
    isLoading.value = false;
    errorMessage.value = '';
  }
}
