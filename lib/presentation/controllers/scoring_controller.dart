import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/participant_model.dart';
import '../../data/models/judge_model.dart';
import '../../data/models/score_response_model.dart';
import '../../core/constants/app_constants.dart';
import 'participant_controller.dart';
import 'judge_controller.dart';
import 'auth_controller.dart';

class ScoringController extends GetxController {
  final ParticipantController _participantController =
      Get.find<ParticipantController>();
  final JudgeController _judgeController = Get.find<JudgeController>();
  final AuthController _authController = Get.find<AuthController>();

  // Map to store jury position to judge mapping: {1: JudgeModel, 2: JudgeModel, ...}
  final RxMap<int, JudgeModel?> juryJudgeMap = <int, JudgeModel?>{}.obs;
  final Rx<ParticipantModel?> participant = Rx<ParticipantModel?>(null);
  final RxList<ParticipantModel> participants = <ParticipantModel>[].obs;
  final RxInt currentParticipantIndex = 0.obs;
  final RxString eventId = ''.obs;
  final RxDouble grandTotal = 0.0.obs;
  final Rx<JudgeModel?> currentJudge = Rx<JudgeModel?>(null);
  final RxInt assignedId = 0.obs; // Store assignedId for score saving
  final RxString category = ''.obs; // Store category for score saving

  // Score viewing
  final Rx<ScoreResponseModel?> scoreResponse = Rx<ScoreResponseModel?>(null);
  final RxBool isLoadingScores = false.obs;
  final RxString scoreErrorMessage = ''.obs;

  // Controllers for each jury position
  final Map<int, TextEditingController> juryScoreControllers = {};

  // Yoga poses support - each pose has a name and score controllers
  // Map to store yoga poses for each participant: {participantId: [YogaPoseScore]}
  final RxMap<String, List<YogaPoseScore>> participantYogaPoses =
      <String, List<YogaPoseScore>>{}.obs;

  bool get isAdmin => _authController.isAdmin;
  bool get isJudge =>
      _authController.currentUser.value?.roleName.toUpperCase().contains(
        'JUDGE',
      ) ??
      false;

  // Get current judge ID
  String? get currentJudgeId {
    final user = _authController.currentUser.value;
    return user?.id.toString();
  }

  @override
  void onInit() {
    super.onInit();
    // Initialize score controllers for all jury positions
    for (int i = 1; i <= AppConstants.juryCount; i++) {
      juryScoreControllers[i] = TextEditingController();
      juryScoreControllers[i]?.addListener(calculateGrandTotal);
    }

    // Participants are now loaded by event ID only
    // Load judges if not already loaded
    if (_judgeController.judges.isEmpty) {
      _judgeController.loadJudges();
    }

    // Load current judge if user is a judge
    if (isJudge) {
      _loadCurrentJudge();
    }
  }

  /// Load current judge details from JudgeController
  Future<void> _loadCurrentJudge() async {
    // Load from JudgeController if not already loaded
    if (_judgeController.currentJudge.value == null) {
      await _judgeController.loadCurrentJudge();
    }
    currentJudge.value = _judgeController.currentJudge.value;
  }

  void initializeWithParticipant(ParticipantModel? participantModel) {
    if (participantModel != null) {
      participant.value = participantModel;
      participants.value = [participantModel];
      currentParticipantIndex.value = 0;
      // Initialize with at least one yoga pose
      initializeYogaPosesForParticipant(participantModel.id ?? '');
      loadExistingScores();
    }
  }

  void initializeWithParticipants(
    List<ParticipantModel> participantsList, {
    String? eventId,
    int? assignedId,
    String? category,
  }) {
    if (participantsList.isNotEmpty) {
      participants.value = participantsList;
      currentParticipantIndex.value = 0;
      participant.value = participantsList[0];
      if (eventId != null) {
        this.eventId.value = eventId;
      }
      if (assignedId != null) {
        this.assignedId.value = assignedId;
      }
      if (category != null && category.isNotEmpty) {
        this.category.value = category;
      }
      // Initialize yoga poses for all participants
      for (final p in participantsList) {
        initializeYogaPosesForParticipant(p.id ?? '');
      }
      loadExistingScores();
    }
  }

  void initializeYogaPosesForParticipant(String participantId) {
    if (!participantYogaPoses.containsKey(participantId)) {
      participantYogaPoses[participantId] = [
        YogaPoseScore(
          poseName: 'Task 1',
          scoreController: TextEditingController(),
        ),
      ];
      participantYogaPoses[participantId]!.last.scoreController.addListener(
        calculateGrandTotal,
      );
    }
  }

  // Get current participant's yoga poses
  List<YogaPoseScore> get currentYogaPoses {
    final currentId = participant.value?.id ?? '';
    return participantYogaPoses[currentId] ?? [];
  }

  // Add a new yoga pose for current participant
  void addYogaPose() {
    if (participant.value == null) return;
    final participantId = participant.value!.id ?? '';
    final currentPoses = participantYogaPoses[participantId] ?? [];

    if (currentPoses.length >= 5) {
      return; // Maximum 5 tasks
    }

    final poseNumber = currentPoses.length + 1;
    final newPose = YogaPoseScore(
      poseName: 'Task $poseNumber',
      scoreController: TextEditingController(),
    );
    newPose.scoreController.addListener(calculateGrandTotal);

    participantYogaPoses[participantId] = [...currentPoses, newPose];
    participantYogaPoses.refresh();
  }

  // Remove a yoga pose for current participant
  void removeYogaPose(int index) {
    if (participant.value == null) return;
    final participantId = participant.value!.id ?? '';
    final currentPoses = participantYogaPoses[participantId] ?? [];

    if (currentPoses.length > 1 && index < currentPoses.length) {
      currentPoses[index].scoreController.dispose();
      currentPoses.removeAt(index);
      // Renumber remaining tasks
      for (int i = 0; i < currentPoses.length; i++) {
        currentPoses[i].poseName = 'Task ${i + 1}';
      }
      participantYogaPoses[participantId] = currentPoses;
      participantYogaPoses.refresh();
      calculateGrandTotal();
    }
  }

  // Switch to next participant
  void nextParticipant() {
    if (currentParticipantIndex.value < participants.length - 1) {
      currentParticipantIndex.value++;
      participant.value = participants[currentParticipantIndex.value];
      loadExistingScores();
    }
  }

  // Switch to previous participant
  void previousParticipant() {
    if (currentParticipantIndex.value > 0) {
      currentParticipantIndex.value--;
      participant.value = participants[currentParticipantIndex.value];
      loadExistingScores();
    }
  }

  bool get hasNextParticipant =>
      currentParticipantIndex.value < participants.length - 1;
  bool get hasPreviousParticipant => currentParticipantIndex.value > 0;

  void loadExistingScores() {
    if (participant.value?.juryScores != null) {
      if (isAdmin) {
        // Admin: Load all jury scores
        for (int i = 1; i <= AppConstants.juryCount; i++) {
          final juryKey = 'jury$i';
          final score = participant.value!.juryScores![juryKey];
          if (score != null) {
            juryScoreControllers[i]?.text = score.toString();
          }
        }
      } else if (isJudge) {
        // Judge: Only load their own score (jury1 by default)
        final score = participant.value!.juryScores!['jury1'];
        if (score != null) {
          juryScoreControllers[1]?.text = score.toString();
        }
      }
      calculateGrandTotal();
    }
  }

  void calculateGrandTotal() {
    double total = 0.0;

    // Calculate from yoga pose scores (tasks) for current participant
    final currentPoses = currentYogaPoses;
    for (final pose in currentPoses) {
      final value = double.tryParse(pose.scoreController.text);
      if (value != null && value > 0) {
        total += value;
      }
    }

    // Also include jury scores if any
    if (isAdmin) {
      // Admin: Calculate from all jury score inputs (can see all scores)
      for (var controller in juryScoreControllers.values) {
        final value = double.tryParse(controller.text);
        if (value != null && value > 0) {
          total += value;
        }
      }
      // Also include existing scores that aren't in the input fields yet
      if (participant.value?.juryScores != null) {
        for (int i = 1; i <= AppConstants.juryCount; i++) {
          final controller = juryScoreControllers[i];
          final existingScore = participant.value!.juryScores!['jury$i'];
          // If input is empty but existing score exists, use existing score
          if ((controller == null || controller.text.isEmpty) &&
              existingScore != null) {
            total += existingScore;
          }
        }
      }
    } else if (isJudge) {
      // Judge: Only calculate their own score (jury1)
      final controller = juryScoreControllers[1];
      if (controller != null) {
        final value = double.tryParse(controller.text);
        if (value != null && value > 0) {
          total += value;
        } else {
          // Use existing score if input is empty
          final existing = participant.value?.juryScores?['jury1'];
          if (existing != null) {
            total += existing;
          }
        }
      } else {
        // Use existing score if controller is null
        final existing = participant.value?.juryScores?['jury1'];
        if (existing != null) {
          total += existing;
        }
      }
    }

    grandTotal.value = total;
  }

  Future<void> saveScores(BuildContext context) async {
    // Only judges can add scores
    if (!isJudge && !isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only judges can add scores'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if eventId is available
    if (eventId.value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event ID is required to save scores'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get current judge from JudgeController
    if (_judgeController.currentJudge.value == null) {
      await _judgeController.loadCurrentJudge();
    }
    final judgeData = _judgeController.currentJudge.value;

    if (judgeData == null || judgeData.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judge ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final judgeId = int.tryParse(judgeData.id!) ?? 0;
    if (judgeId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid judge ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Build scoreOfParticipants array
    final scoreOfParticipants = <Map<String, dynamic>>[];

    for (final participant in participants) {
      final participantId = int.tryParse(participant.id ?? '') ?? 0;
      if (participantId == 0) continue;

      // Get yoga poses (asanas) for this participant
      final participantIdStr = participant.id ?? '';
      final poses = participantYogaPoses[participantIdStr] ?? [];

      final asanas = <Map<String, dynamic>>[];
      double grandTotal = 0.0;

      for (final pose in poses) {
        final scoreStr = pose.scoreController.text.trim();
        if (scoreStr.isNotEmpty) {
          final score = double.tryParse(scoreStr);
          if (score != null && score > 0) {
            asanas.add({
              'asanaName': pose.poseName,
              'score': scoreStr, // Keep as string as per API format
            });
            grandTotal += score;
          }
        }
      }

      // Only add participant if they have at least one asana with score
      if (asanas.isNotEmpty) {
        final participantScore = {
          'participantId': participantId,
          'grandTotal': grandTotal,
          'juryId': judgeId,
          'asanas': asanas,
        };

        // Add assignId if available
        if (assignedId.value > 0) {
          participantScore['assignId'] = assignedId.value;
        }

        // Add category if available
        if (category.value.isNotEmpty) {
          participantScore['category'] = category.value;
        }

        scoreOfParticipants.add(participantScore);
      }
    }

    // Validate that we have at least one participant with scores
    if (scoreOfParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one score for participants'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    _participantController.isLoading.value = true;

    try {
      final response = await _participantController.saveScores(
        eventId: eventId.value,
        scoreOfParticipants: scoreOfParticipants,
      );

      _participantController.isLoading.value = false;

      if (response.success) {
        // Reset all scoring data after successful save
        resetAllScoringData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All scores saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        if (context.mounted) {
          context.pop();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to save scores'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _participantController.isLoading.value = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving scores: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void selectParticipant(ParticipantModel participantModel) {
    participant.value = participantModel;
    loadExistingScores();
  }

  void clearParticipant() {
    participant.value = null;
  }

  /// Reset all scoring data (yoga poses, scores, grand total)
  void resetAllScoringData() {
    // Dispose all yoga pose controllers
    for (var poses in participantYogaPoses.values) {
      for (var pose in poses) {
        pose.scoreController.dispose();
      }
    }
    participantYogaPoses.clear();

    // Clear jury score controllers
    for (var controller in juryScoreControllers.values) {
      controller.clear();
    }

    // Reset grand total
    grandTotal.value = 0.0;

    // Reset participant index
    currentParticipantIndex.value = 0;

    // Reinitialize yoga poses for all participants (fresh start with one empty task)
    for (final p in participants) {
      initializeYogaPosesForParticipant(p.id ?? '');
    }

    // Reload existing scores if any
    if (participant.value != null) {
      loadExistingScores();
    }
  }

  void reset() {
    // Clear participants
    participant.value = null;
    participants.clear();
    currentParticipantIndex.value = 0;
    eventId.value = '';
    grandTotal.value = 0.0;
    currentJudge.value = null;
    assignedId.value = 0;
    category.value = '';
    juryJudgeMap.clear();

    // Clear jury score controllers
    for (var controller in juryScoreControllers.values) {
      controller.clear();
    }

    // Dispose and clear yoga pose controllers
    for (var poses in participantYogaPoses.values) {
      for (var pose in poses) {
        pose.scoreController.dispose();
      }
    }
    participantYogaPoses.clear();
  }

  /// Load scores by event ID for viewing
  Future<void> loadScoresByEventId(String eventId) async {
    this.eventId.value = eventId;
    isLoadingScores.value = true;
    scoreErrorMessage.value = '';

    try {
      final response = await _participantController
          .getParticipantScoresByEventId(eventId);

      isLoadingScores.value = false;

      if (response.success && response.data != null) {
        scoreResponse.value = response.data;
      } else {
        scoreErrorMessage.value = response.message ?? 'Failed to load scores';
        scoreResponse.value = null;
      }
    } catch (e) {
      isLoadingScores.value = false;
      scoreErrorMessage.value = 'Error loading scores: ${e.toString()}';
      scoreResponse.value = null;
    }
  }

  void resetScoreView() {
    scoreResponse.value = null;
    scoreErrorMessage.value = '';
  }

  @override
  void onClose() {
    for (var controller in juryScoreControllers.values) {
      controller.dispose();
    }
    // Dispose all yoga pose controllers for all participants
    for (var poses in participantYogaPoses.values) {
      for (var pose in poses) {
        pose.scoreController.dispose();
      }
    }
    super.onClose();
  }
}

// Model for yoga pose with score
class YogaPoseScore {
  String poseName;
  TextEditingController scoreController;

  YogaPoseScore({required this.poseName, required this.scoreController});
}
