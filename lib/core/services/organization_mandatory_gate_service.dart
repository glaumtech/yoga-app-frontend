import 'dart:convert';

import 'package:get/get.dart';

import '../../data/models/organization_setup_model.dart';
import '../../data/models/user_management_model.dart';
import '../../data/repositories/branch_repository.dart';
import '../../routes/app_router.dart';
import '../constants/app_constants.dart';
import '../utils/organization_mandatory_checker.dart';
import '../utils/storage_service.dart';

/// Tracks whether a super admin (branch admin) must complete organization
/// details before accessing the rest of the app.
class OrganizationMandatoryGateService extends GetxService {
  final BranchRepository _branchRepo = BranchRepository();

  final RxBool requiresMandatoryUpdate = false.obs;

  Future<void> initFromStorage() async {
    requiresMandatoryUpdate.value =
        StorageService.getBool(AppConstants.orgMandatoryUpdateRequiredKey) ??
        false;
  }

  Future<void> setRequired(bool required) async {
    requiresMandatoryUpdate.value = required;
    if (required) {
      await StorageService.setBool(
        AppConstants.orgMandatoryUpdateRequiredKey,
        true,
      );
    } else {
      await StorageService.remove(AppConstants.orgMandatoryUpdateRequiredKey);
    }
    AppRouter.refresh();
  }

  Future<void> clear() => setRequired(false);

  bool isCurrentUserBranchAdmin() {
    final user = _readStoredUser();
    if (user == null) return false;
    return isBranchAdminRole(user.userTypeName, fallbackType: user.type);
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

  /// Fetches the current branch and updates the gate flag.
  /// Returns `true` when mandatory organization update is still required.
  Future<bool> evaluateForCurrentUser() async {
    if (!isCurrentUserBranchAdmin()) {
      await clear();
      return false;
    }

    final user = _readStoredUser();
    final branchId = user?.branchId;
    if (branchId == null || branchId <= 0) {
      await clear();
      return false;
    }

    try {
      final response = await _branchRepo.getBranch(branchId);
      if (!response.success || response.data == null) {
        return requiresMandatoryUpdate.value;
      }
      final missing = hasMissingMandatoryOrganizationFields(response.data!);
      await setRequired(missing);
      return missing;
    } catch (_) {
      return requiresMandatoryUpdate.value;
    }
  }

  int? initialStepForBranch(BranchDtoModel branch) {
    if (hasOrganizationStepMissing(branch)) return 0;
    if (hasDocumentStepMissing(branch)) return 1;
    return 0;
  }
}
