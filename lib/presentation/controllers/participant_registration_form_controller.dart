import 'package:get/get.dart';

import 'competition_controller.dart';
import 'participant_controller.dart';

const String kParticipantRegistrationFormControllerTag =
    'participant_registration_form';

class ParticipantRegistrationFormController extends GetxController {
  final String? initialCompetitionId;

  ParticipantRegistrationFormController({this.initialCompetitionId});

  late final ParticipantController participantController;
  late final CompetitionController competitionController;

  bool _listenersBound = false;

  @override
  void onInit() {
    super.onInit();
    participantController = Get.isRegistered<ParticipantController>()
        ? Get.find<ParticipantController>()
        : Get.put(ParticipantController());
    competitionController = Get.isRegistered<CompetitionController>()
        ? Get.find<CompetitionController>()
        : Get.put(CompetitionController());
  }

  @override
  void onReady() {
    super.onReady();
    _bindListeners();
    _prepareRegistrationForm();
  }

  void _bindListeners() {
    if (_listenersBound) return;
    _listenersBound = true;

    ever(participantController.selectedEventId, (id) {
      _loadCompetitionForRegistration(id);
    });
    ever(competitionController.competitions, (_) {
      participantController.applySpotRegistrationRulesForSelectedEvent();
    });
  }

  Future<void> _prepareRegistrationForm() async {
    final id = (initialCompetitionId ?? '').isNotEmpty
        ? initialCompetitionId!
        : participantController.selectedEventId.value;
    if (id.isNotEmpty) {
      participantController.selectedEventId.value = id;
    }

    if (competitionController.homeCompetitions.isEmpty &&
        !competitionController.isLoadingHomeCompetitions.value) {
      await competitionController.loadCompetitionsForHome();
    }

    await _loadCompetitionForRegistration(participantController.selectedEventId.value);
  }

  Future<void> _loadCompetitionForRegistration(String competitionId) async {
    await competitionController.ensureCompetitionLoadedForRegistration(
      competitionId,
    );
    participantController.applySpotRegistrationRulesForSelectedEvent();
  }
}
