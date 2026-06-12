import 'package:get/get.dart';

import 'competition_controller.dart';
import 'user_management_controller.dart';

class UsersListController extends GetxController {
  late final UserManagementController userController;
  late final CompetitionController competitionController;

  bool _didInit = false;

  @override
  void onInit() {
    super.onInit();
    userController = Get.find<UserManagementController>();
    competitionController = Get.put(CompetitionController());
  }

  @override
  void onReady() {
    super.onReady();
    if (_didInit) return;
    _didInit = true;
    _ensureCompetitionsLoaded();
  }

  Future<void> _ensureCompetitionsLoaded() async {
    if (competitionController.competitions.isEmpty &&
        !competitionController.isLoading.value) {
      await competitionController.loadCompetitions();
    }

    // Load users only when a competition is already selected.
    final eventId = _selectedCompetitionId();
    if (eventId != null && !userController.isLoading.value) {
      await userController.loadUsers(eventId: eventId);
    }
  }

  int? _selectedCompetitionId() {
    if (userController.selectedEventId.value.isEmpty) return null;
    return int.tryParse(userController.selectedEventId.value);
  }
}
