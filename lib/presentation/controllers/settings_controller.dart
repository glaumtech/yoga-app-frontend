import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/role_theme_controller.dart';
import '../../core/utils/storage_service.dart';
import '../../data/models/app_permission_record_model.dart';
import '../../data/repositories/permission_repository.dart';
import '../../data/models/user_management_model.dart';
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
  final RxInt formResetTrigger = 0.obs;

  final themeColorInput = '#4CAF50'.obs;
  final selectedThemeUserTypeId = RxnInt();
  final isSavingTheme = false.obs;
  final themeErrorMessage = ''.obs;
  final themeFormKey = GlobalKey<FormState>();

  static const Set<String> themeableRoleKeys = {
    'BRANCH_ADMIN',
    'ORG_ADMIN',
    'SUB_ADMIN',
    'JURY',
    'SPOT_REG_ADMIN',
    'VOLUNTEER',
  };

  static const Map<String, String> roleDefaultThemeColors = {
    'BRANCH_ADMIN': '#4CAF50',
    'ORG_ADMIN': '#1565C0',
    'SUB_ADMIN': '#5E35B1',
    'JURY': '#7B1FA2',
    'SPOT_REG_ADMIN': '#EF6C00',
    'VOLUNTEER': '#00897B',
  };

  static const List<String> themePresetColors = [
    '#4CAF50',
    '#1565C0',
    '#5E35B1',
    '#7B1FA2',
    '#EF6C00',
    '#00897B',
    '#C62828',
    '#A11D45',
    '#AD1457',
    '#6A1B9A',
    '#283593',
    '#0277BD',
    '#00695C',
    '#B87333',
  ];

  @override
  void onReady() {
    super.onReady();
    loadPermissions();
    loadUserTypes().then((_) => initThemeTab());
  }

  UserManagementModel? get _currentUser =>
      Get.isRegistered<UserManagementController>()
      ? Get.find<UserManagementController>().currentUser.value
      : null;

  bool get canManageAllRoleThemes {
    final role = _currentUser?.userTypeName?.trim().toUpperCase() ?? '';
    return role == 'BRANCH_ADMIN' || role == 'ORG_ADMIN';
  }

  List<UserTypeModel> get themeableUserTypes {
    final currentRole = _currentUser?.userTypeName?.trim().toUpperCase() ?? '';
    final filtered = userTypes.where((t) {
      final key = t.typeName.trim().toUpperCase();
      if (!themeableRoleKeys.contains(key)) return false;
      if (key == 'ORG_ADMIN' && currentRole != 'ORG_ADMIN') return false;
      return true;
    }).toList();
    if (canManageAllRoleThemes) return filtered;

    final ownId = _currentUser?.userTypeId;
    if (ownId == null) return filtered;
    return filtered.where((t) => t.id == ownId).toList();
  }

  UserTypeModel? get selectedThemeUserType {
    final id = selectedThemeUserTypeId.value;
    if (id == null) return null;
    return userTypes.firstWhereOrNull((t) => t.id == id);
  }

  void initThemeTab() {
    final user = _currentUser;
    if (user?.userTypeId == null) return;

    final available = themeableUserTypes;
    final preferredId = user!.userTypeId!;
    final hasPreferred = available.any((t) => t.id == preferredId);
    selectedThemeUserTypeId.value = hasPreferred
        ? preferredId
        : (available.isNotEmpty ? available.first.id : preferredId);
    _loadColorForSelectedUserType();
  }

  void selectThemeUserType(int id) {
    selectedThemeUserTypeId.value = id;
    themeErrorMessage.value = '';
    _loadColorForSelectedUserType();
  }

  void _loadColorForSelectedUserType() {
    final selected = selectedThemeUserType;
    if (selected == null) return;

    final saved = selected.themeColor?.trim();
    if (saved != null && saved.isNotEmpty) {
      themeColorInput.value = _normalizeHex(saved);
    } else {
      final roleKey = selected.typeName.trim().toUpperCase();
      themeColorInput.value = roleDefaultThemeColors[roleKey] ?? '#4CAF50';
    }
    _applyLiveThemeIfEditingOwnRole();
  }

  bool get _isEditingOwnRoleTheme {
    final userTypeId = _currentUser?.userTypeId;
    final selectedId = selectedThemeUserTypeId.value;
    return userTypeId != null && selectedId != null && userTypeId == selectedId;
  }

  void _applyLiveThemeIfEditingOwnRole() {
    if (_isEditingOwnRoleTheme) {
      _previewThemeColor(themeColorInput.value);
    }
  }

  String _normalizeHex(String value) {
    var hex = value.trim().toUpperCase();
    if (!hex.startsWith('#')) hex = '#$hex';
    return hex;
  }

  Color? get selectedThemePreviewColor =>
      AppTheme.parseHexColor(themeColorInput.value);

  void selectThemeColor(String hex) {
    themeColorInput.value = _normalizeHex(hex);
    themeErrorMessage.value = '';
    _applyLiveThemeIfEditingOwnRole();
  }

  void previewThemeFromInput(String value) {
    themeColorInput.value = value;
    final parsed = AppTheme.parseHexColor(_normalizeHex(value));
    if (parsed != null) {
      _applyLiveThemeIfEditingOwnRole();
    }
  }

  void _previewThemeColor(String hex) {
    if (Get.isRegistered<RoleThemeController>()) {
      Get.find<RoleThemeController>().applyThemeColor(hex);
    }
  }

  Future<void> saveThemeColor() async {
    final userTypeId = selectedThemeUserTypeId.value;
    if (userTypeId == null) {
      themeErrorMessage.value = 'Select a role type';
      return;
    }

    if (themeFormKey.currentState?.validate() != true) return;

    final hex = _normalizeHex(themeColorInput.value);
    isSavingTheme.value = true;
    themeErrorMessage.value = '';

    try {
      final res = await _userManagementRepository.updateUserTypeThemeColor(
        userTypeId: userTypeId,
        themeColor: hex,
      );

      if (res.success && res.data != null) {
        final idx = userTypes.indexWhere((t) => t.id == userTypeId);
        if (idx >= 0) {
          userTypes[idx] = res.data!;
        }
        if (_isEditingOwnRoleTheme) {
          await _persistThemeColorForCurrentUser(hex);
        }
        Get.snackbar(
          'Success',
          res.message ?? 'Theme colour saved',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        themeErrorMessage.value = res.message ?? 'Failed to save theme colour';
        _loadColorForSelectedUserType();
        Get.snackbar(
          'Error',
          themeErrorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isSavingTheme.value = false;
    }
  }

  Future<void> resetThemeToDefault() async {
    final roleKey = selectedThemeUserType?.typeName.trim().toUpperCase() ?? '';
    final defaultHex = roleDefaultThemeColors[roleKey] ?? '#4CAF50';
    selectThemeColor(defaultHex);
    await saveThemeColor();
  }

  Future<void> _persistThemeColorForCurrentUser(String hex) async {
    if (!Get.isRegistered<UserManagementController>()) return;
    final userController = Get.find<UserManagementController>();
    final user = userController.currentUser.value;
    if (user == null) return;

    final updated = user.copyWith(themeColor: hex);
    userController.currentUser.value = updated;

    final userJson = StorageService.getString(AppConstants.userKey);
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        map['themeColor'] = hex;
        await StorageService.setString(AppConstants.userKey, jsonEncode(map));
      } catch (_) {
        // ignore malformed cache
      }
    }

    _previewThemeColor(hex);
  }

  String? validateThemeHex(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Colour is required';
    }
    final hex = _normalizeHex(value);
    if (!RegExp(r'^#[0-9A-F]{6}$').hasMatch(hex)) {
      return 'Use format #RRGGBB';
    }
    return null;
  }

  @override
  void onClose() {
    // Do not dispose TextEditingControllers here — logout can delete this
    // controller while Settings screens are still unmounting, which triggers
    // "TextEditingController was used after being disposed" on TextFormFields.
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
    // Reset form state now and also next frame so any lingering validation
    // errors and TextFormField internal state are cleared.
    formKey.currentState?.reset();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      formKey.currentState?.reset();
    });

    // Force the permission form subtree to rebuild (clears any cached field state).
    formResetTrigger.value = formResetTrigger.value + 1;
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
