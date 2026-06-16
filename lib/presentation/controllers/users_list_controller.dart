import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/recent_competition_store.dart';
import 'competition_controller.dart';
import 'user_management_controller.dart';

class UsersListController extends GetxController {
  late final UserManagementController userController;
  late final CompetitionController competitionController;

  final RxList<RecentCompetitionEntry> recentCompetitions =
      <RecentCompetitionEntry>[].obs;

  bool _didInit = false;

  @override
  void onInit() {
    super.onInit();
    userController = Get.find<UserManagementController>();
    competitionController = Get.put(CompetitionController());
    _loadRecentCompetitions();
  }

  void _loadRecentCompetitions() {
    recentCompetitions.assignAll(
      RecentCompetitionStore.read(AppConstants.usersListRecentCompetitionsKey),
    );
  }

  Future<void> recordCompetitionSelection({
    required int competitionId,
    required String competitionName,
  }) async {
    await RecentCompetitionStore.add(
      storageKey: AppConstants.usersListRecentCompetitionsKey,
      id: competitionId.toString(),
      name: competitionName,
    );
    _loadRecentCompetitions();
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
    if (userController.usersListEventId.value.isEmpty) return null;
    return int.tryParse(userController.usersListEventId.value);
  }
}
