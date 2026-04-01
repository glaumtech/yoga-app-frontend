import 'package:get/get.dart';

import 'competition_controller.dart';

class CompetitionsListController extends GetxController {
  late final CompetitionController competitionController;
  bool _didInit = false;

  @override
  void onInit() {
    super.onInit();
    competitionController = Get.put(CompetitionController());
  }

  @override
  void onReady() {
    super.onReady();
    if (_didInit) return;
    _didInit = true;

    if (competitionController.competitions.isEmpty &&
        !competitionController.isLoading.value) {
      competitionController.loadCompetitions();
    }
  }
}
