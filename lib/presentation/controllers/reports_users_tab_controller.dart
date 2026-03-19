import 'package:get/get.dart';

import '../../data/models/user_management_model.dart';
import 'reports_controller.dart';
import 'user_management_controller.dart';

class ReportsUsersTabController extends GetxController {
  late final ReportsController reportsController;
  late final UserManagementController userController;

  final RxString typeFilter = 'ALL'.obs;
  final RxInt page = 0.obs;
  final int limit = 25;

  Worker? _competitionWatcher;

  @override
  void onInit() {
    super.onInit();
    reportsController = Get.find<ReportsController>();
    userController = Get.isRegistered<UserManagementController>()
        ? Get.find<UserManagementController>()
        : Get.put(UserManagementController(), permanent: false);

    // Watch competition changes but don't trigger loads synchronously during build.
    _competitionWatcher = ever<String?>(
      reportsController.selectedCompetitionId,
      (competitionId) {
        final id = int.tryParse(competitionId ?? '');
        userController.selectedEventId.value = competitionId ?? '';
        if (id != null) {
          Future.microtask(() async {
            page.value = 0;
            await loadUsers();
          });
        } else {
          userController.users.clear();
        }
      },
    );
  }

  @override
  void onReady() {
    super.onReady();
    // Initial load after first frame to avoid "markNeedsBuild during build".
    final initialId =
        int.tryParse(reportsController.selectedCompetitionId.value ?? '');
    if (initialId != null) {
      userController.selectedEventId.value =
          reportsController.selectedCompetitionId.value ?? '';
      page.value = 0;
      loadUsers();
    }
  }

  @override
  void onClose() {
    _competitionWatcher?.dispose();
    super.onClose();
  }

  Future<void> loadUsers() async {
    final compId =
        int.tryParse(reportsController.selectedCompetitionId.value ?? '');
    if (compId == null) return;

    final roleType = typeFilter.value == 'ALL' ? null : typeFilter.value;
    await userController.loadUsers(
      eventId: compId,
      roleType: roleType,
      page: page.value,
      limit: limit,
    );
  }

  Future<void> refresh() async {
    page.value = 0;
    await loadUsers();
  }

  Future<void> setTypeFilter(String label) async {
    typeFilter.value = label;
    page.value = 0;
    await loadUsers();
  }

  List<UserManagementModel> get users => userController.users.toList();

  String normalizeRoleLabel(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return 'OTHERS';

    // Prefer friendly labels
    final upper = v.toUpperCase();
    if (upper == 'SUB_ADMIN' || upper == 'SUB ADMIN') return 'SUB ADMIN';
    if (upper == 'SPOT_REG_ADMIN' ||
        upper == 'SPOT REG ADMIN' ||
        upper == 'SPOT REG ADMIN(S)') {
      return 'SPOT REG ADMIN(S)';
    }
    if (upper == 'JURY' || upper == 'JURY(S)') return 'JURY(S)';
    if (upper == 'VOLUNTEER' || upper == 'VOLUNTEERS') return 'VOLUNTEERS';

    return v;
  }

  String displayRole(UserManagementModel u) {
    // userTypeName comes from backend as SUB_ADMIN / JURY / etc. which isn't our UI label.
    return normalizeRoleLabel(u.userTypeName ?? u.type);
  }

  Map<String, List<UserManagementModel>> groupByType(
    List<UserManagementModel> users,
  ) {
    final Map<String, List<UserManagementModel>> grouped = {
      'SUB ADMIN': [],
      'SPOT REG ADMIN(S)': [],
      'JURY(S)': [],
      'VOLUNTEERS': [],
      'OTHERS': [],
    };

    for (final u in users) {
      final label = displayRole(u);
      final key = label.toUpperCase();
      if (grouped.containsKey(key)) {
        grouped[key]!.add(u);
      } else {
        grouped['OTHERS']!.add(u);
      }
    }

    for (final entry in grouped.entries) {
      entry.value.sort((a, b) {
        final ad = a.createdAt;
        final bd = b.createdAt;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });
    }

    return grouped;
  }

  String paginationText() {
    final total = userController.usersTotal.value;
    final p = userController.usersPage.value;
    final totalPages = userController.usersTotalPages.value;
    final lim = userController.usersLimit.value;
    final loadedCount = userController.users.length;

    if (totalPages <= 0) return '';
    final start = (p * lim) + (loadedCount > 0 ? 1 : 0);
    final end = (p * lim) + loadedCount;
    return 'Page ${p + 1}/$totalPages\n$start-$end of $total';
  }
}

