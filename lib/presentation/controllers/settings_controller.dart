import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/app_permission_record_model.dart';
import '../../data/repositories/permission_repository.dart';
import '../../data/models/user_type_model.dart';
import '../../data/repositories/user_management_repository.dart';
import 'user_management_controller.dart';

class SettingsController extends GetxController {
  final PermissionRepository _permissionRepository = PermissionRepository();
  final UserManagementRepository _userManagementRepository =
      UserManagementRepository();

  final permissions = <AppPermissionRecord>[].obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;

  final isEditMode = false.obs;
  int? _editingPermissionId;

  final userTypes = <UserTypeModel>[].obs;
  final isLoadingUserTypes = false.obs;
  final selectedUserTypeId = RxnInt();
  final assignedPermissionIds = <int>{}.obs;
  final isAssignSaving = false.obs;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final permissionKeyController = TextEditingController();
  final typeController = TextEditingController();
  final menuController = TextEditingController();
  final subMenuController = TextEditingController();
  final tabController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void onReady() {
    super.onReady();
    loadPermissions();
    loadUserTypes();
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    permissionKeyController.dispose();
    typeController.dispose();
    menuController.dispose();
    subMenuController.dispose();
    tabController.dispose();
    super.onClose();
  }

  Future<void> loadPermissions() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final res = await _permissionRepository.getAllPermissions();
      if (res.success && res.data != null) {
        permissions.assignAll(res.data!);
      } else {
        errorMessage.value = res.message ?? 'Could not load permissions';
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUserTypes() async {
    isLoadingUserTypes.value = true;
    try {
      final res = await _userManagementRepository.getUserTypes(
        includeAdminTypes: true,
      );
      if (res.success && res.data != null) {
        userTypes.assignAll(res.data!);
      }
    } finally {
      isLoadingUserTypes.value = false;
    }
  }

  void selectUserType(int id) {
    selectedUserTypeId.value = id;
    final ut = userTypes.firstWhereOrNull((e) => e.id == id);
    final ids = <int>{};
    if (ut != null) {
      for (final p in ut.permissions) {
        ids.add(p.id);
      }
    }
    assignedPermissionIds
      ..clear()
      ..addAll(ids);
  }

  Map<String, List<AppPermissionRecord>> get groupedPermissionsByMenu {
    final map = <String, List<AppPermissionRecord>>{};
    for (final p in permissions) {
      final key = (p.menu ?? '').trim();
      map.putIfAbsent(key, () => <AppPermissionRecord>[]).add(p);
    }
    return map;
  }

  void toggleAssigned(int permissionId, bool isOn) {
    if (isOn) {
      assignedPermissionIds.add(permissionId);
    } else {
      assignedPermissionIds.remove(permissionId);
    }
  }

  void setAssignedForPermissions(Iterable<int> permissionIds, bool isOn) {
    if (isOn) {
      assignedPermissionIds.addAll(permissionIds);
    } else {
      assignedPermissionIds.removeAll(permissionIds);
    }
  }

  Future<void> saveAssignedPermissions() async {
    final userTypeId = selectedUserTypeId.value;
    if (userTypeId == null) return;

    isAssignSaving.value = true;
    try {
      final branchId = Get.isRegistered<UserManagementController>()
          ? Get.find<UserManagementController>().currentUser.value?.branchId
          : null;
      final res = await _userManagementRepository.updateUserTypePermissions(
        userTypeId: userTypeId,
        branchId: branchId,
        permissionIds: assignedPermissionIds.toList(),
      );
      if (res.success && res.data != null) {
        // update local list
        final idx = userTypes.indexWhere((e) => e.id == userTypeId);
        if (idx >= 0) {
          userTypes[idx] = res.data!;
        }
        Get.snackbar(
          'Success',
          res.message ?? 'Permissions updated',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          res.message ?? 'Failed to update permissions',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isAssignSaving.value = false;
    }
  }

  void startEdit(AppPermissionRecord p) {
    isEditMode.value = true;
    _editingPermissionId = p.id;

    nameController.text = p.permissionName;
    descriptionController.text = p.description ?? '';
    permissionKeyController.text = p.permissionKey ?? '';
    typeController.text = p.type ?? '';
    menuController.text = p.menu ?? '';
    subMenuController.text = p.subMenu ?? '';
    tabController.text = p.tab ?? '';

    errorMessage.value = '';
    // Don't call `FormState.reset()` here: it can clear controller-backed fields.
  }

  void resetForm() {
    isEditMode.value = false;
    _editingPermissionId = null;

    nameController.clear();
    descriptionController.clear();
    permissionKeyController.clear();
    typeController.clear();
    menuController.clear();
    subMenuController.clear();
    tabController.clear();

    errorMessage.value = '';
    formKey.currentState?.reset();
  }

  Future<void> submitCreatePermission() async {
    if (formKey.currentState?.validate() != true) return;

    isSaving.value = true;
    errorMessage.value = '';
    try {
      final res = await _permissionRepository.createPermission(
        permissionName: nameController.text,
        description: descriptionController.text,
        permissionKey: permissionKeyController.text,
        type: typeController.text,
        menu: menuController.text,
        subMenu: subMenuController.text,
        tab: tabController.text,
      );
      if (res.success && res.data != null) {
        errorMessage.value = '';
        resetForm();
        await loadPermissions();
        Get.snackbar(
          'Success',
          res.message ?? 'Permission created',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        errorMessage.value = res.message ?? 'Could not create permission';
      }
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> submitUpdatePermission() async {
    if (_editingPermissionId == null) return;
    if (formKey.currentState?.validate() != true) return;

    isSaving.value = true;
    errorMessage.value = '';

    try {
      final res = await _permissionRepository.updatePermission(
        id: _editingPermissionId!,
        permissionName: nameController.text,
        description: descriptionController.text,
        permissionKey: permissionKeyController.text,
        type: typeController.text,
        menu: menuController.text,
        subMenu: subMenuController.text,
        tab: tabController.text,
      );

      if (res.success && res.data != null) {
        errorMessage.value = '';
        resetForm();
        await loadPermissions();
        Get.snackbar(
          'Success',
          res.message ?? 'Permission updated',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        errorMessage.value = res.message ?? 'Could not update permission';
      }
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> confirmDeletePermission(AppPermissionRecord p) async {
    final id = p.id;
    if (id == null) return;

    Get.defaultDialog(
      title: 'Delete permission',
      middleText: 'This permission may be used by related tables. Continue?',
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red[700],
      onConfirm: () async {
        Get.back();
        await deletePermission(id);
      },
    );
  }

  Future<void> deletePermission(int id) async {
    isSaving.value = true;
    errorMessage.value = '';

    try {
      final res = await _permissionRepository.deletePermission(id: id);
      if (res.success) {
        if (isEditMode.value && _editingPermissionId == id) {
          resetForm();
        }
        await loadPermissions();
        Get.snackbar(
          'Deleted',
          res.message ?? 'Permission deleted',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        errorMessage.value = res.message ?? 'Could not delete permission';
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isSaving.value = false;
    }
  }
}
