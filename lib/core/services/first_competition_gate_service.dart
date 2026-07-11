import 'dart:convert';

import 'package:get/get.dart';

import '../../data/models/user_management_model.dart';
import '../../data/repositories/competition_repository.dart';
import '../../routes/app_router.dart';
import '../constants/app_constants.dart';
import '../utils/organization_mandatory_checker.dart';
import '../utils/storage_service.dart';

/// Tracks whether a branch admin must create their first competition
/// (with payment when required) before accessing the rest of the app.
class FirstCompetitionGateService extends GetxService {
  final CompetitionRepository _competitionRepo = CompetitionRepository();

  final RxBool requiresFirstCompetition = false.obs;

  Future<void> initFromStorage() async {
    requiresFirstCompetition.value =
        StorageService.getBool(AppConstants.firstCompetitionRequiredKey) ??
        false;
  }

  Future<void> setRequired(bool required) async {
    requiresFirstCompetition.value = required;
    if (required) {
      await StorageService.setBool(
        AppConstants.firstCompetitionRequiredKey,
        true,
      );
    } else {
      await StorageService.remove(AppConstants.firstCompetitionRequiredKey);
    }
    AppRouter.refresh();
  }

  Future<void> clear() => setRequired(false);

  bool isCurrentUserBranchAdmin() {
    final user = _readStoredUser();
    if (user == null) return false;
    return isBranchAdminRole(user.userTypeName, fallbackType: user.type);
  }

  bool _isOrgMandatoryStillRequired() {
    return StorageService.getBool(AppConstants.orgMandatoryUpdateRequiredKey) ==
        true;
  }

  UserManagementModel? _readStoredUser() {
    final userJson = StorageService.getString(AppConstants.userKey);
    if (userJson == null || userJson.isEmpty) return null;
    try {
      return UserManagementModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetches competitions and updates the gate flag.
  /// Returns `true` when first competition creation is still required.
  Future<bool> evaluateForCurrentUser() async {
    if (!isCurrentUserBranchAdmin()) {
      await clear();
      return false;
    }

    if (_isOrgMandatoryStillRequired()) {
      await clear();
      return false;
    }

    final branchId = _readStoredUser()?.branchId;
    if (branchId == null || branchId <= 0) {
      await setRequired(true);
      return true;
    }

    try {
      final response = await _competitionRepo.getAllCompetitions(
        page: 0,
        limit: 1,
      );
      if (!response.success || response.data == null) {
        await setRequired(true);
        return true;
      }

      final pagination = response.data!.pagination;
      final rawTotal = pagination?['total'];
      final total = rawTotal is int
          ? rawTotal
          : int.tryParse(rawTotal?.toString() ?? '') ??
              response.data!.competitions.length;
      final needsFirstCompetition = total <= 0;
      await setRequired(needsFirstCompetition);
      return needsFirstCompetition;
    } catch (_) {
      await setRequired(true);
      return true;
    }
  }

  bool isGateActive() {
    return requiresFirstCompetition.value ||
        StorageService.getBool(AppConstants.firstCompetitionRequiredKey) == true;
  }

  /// Call after mandatory organization details are saved.
  Future<void> activateAfterMandatoryOrganizationSave() async {
    if (!isCurrentUserBranchAdmin() || _isOrgMandatoryStillRequired()) {
      return;
    }
    await setRequired(true);
  }
}
