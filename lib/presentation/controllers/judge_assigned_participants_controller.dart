import 'package:get/get.dart';
import '../../data/repositories/team_repository.dart';
import '../../data/models/participant_model.dart';
import '../../data/models/assignment_group_model.dart';
import '../controllers/auth_controller.dart';

class JudgeAssignedParticipantsController extends GetxController {
  final TeamRepository _teamRepository = TeamRepository();
  final AuthController _authController = Get.find<AuthController>();

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

      // Get current judge ID
      final currentUser = _authController.currentUser.value;
      if (currentUser == null) {
        errorMessage.value = 'User not logged in';
        isLoading.value = false;
        return;
      }

      final judgeId = currentUser.id.toString();

      // Call assignedParticipantsByJudgeId API
      final response = await _teamRepository.getAssignedParticipantsByJudgeId(
        eventId,
        judgeId,
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
}
