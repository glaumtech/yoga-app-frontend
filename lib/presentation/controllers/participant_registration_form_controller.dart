import 'package:get/get.dart';

import 'competition_controller.dart';
import 'participant_controller.dart';

class ParticipantRegistrationFormController extends GetxController {
  final String? initialCompetitionId;

  ParticipantRegistrationFormController({this.initialCompetitionId});

  late final ParticipantController participantController;
  late final CompetitionController competitionController;

  bool _didInit = false;

  @override
  void onInit() {
    super.onInit();
    participantController = Get.find<ParticipantController>();
    competitionController = Get.put(CompetitionController());
  }

  @override
  void onReady() {
    super.onReady();
    if (_didInit) return;
    _didInit = true;

    // Preselect competition when coming from a competition-specific route
    if ((initialCompetitionId ?? '').isNotEmpty &&
        participantController.selectedEventId.value.isEmpty) {
      participantController.selectedEventId.value = initialCompetitionId!;
    }

    // Load competitions (full model needed for category/group/stage mapping)
    if (competitionController.competitions.isEmpty &&
        !competitionController.isLoading.value) {
      competitionController.loadCompetitions();
    }
  }
}
