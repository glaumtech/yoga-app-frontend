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
    _ensureCompetitionsAndUsersLoaded();
  }

  Future<void> _ensureCompetitionsAndUsersLoaded() async {
    // Load competitions if empty
    if (competitionController.competitions.isEmpty &&
        !competitionController.isLoading.value) {
      await competitionController.loadCompetitions();
    }

    // Set first competition as default if none is selected
    if (competitionController.competitions.isNotEmpty &&
        userController.selectedEventId.value.isEmpty) {
      final firstCompetition = competitionController.competitions.firstWhere(
        (c) => c.id != null,
        orElse: () => competitionController.competitions.first,
      );
      if (firstCompetition.id != null) {
        final competitionId = int.tryParse(firstCompetition.id!);
        if (competitionId != null) {
          userController.selectedEventId.value = firstCompetition.id!;
          await userController.loadUsers(eventId: competitionId);
        }
      }
    }

    // Load users if a competition is selected and list is empty
    if (userController.users.isEmpty &&
        !userController.isLoading.value &&
        userController.selectedEventId.value.isNotEmpty) {
      final eventId = int.tryParse(userController.selectedEventId.value);
      await userController.loadUsers(eventId: eventId);
    }
  }
}

