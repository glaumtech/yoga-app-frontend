import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/navigation/root_scaffold_messenger_key.dart';
import '../../data/models/institution_category_model.dart';
import '../../data/models/institution_type_model.dart';
import '../../data/repositories/institution_config_repository.dart';
import 'participant_controller.dart';
import 'school_controller.dart';

class InstitutionConfigController extends GetxController {
  final InstitutionConfigRepository _repo = InstitutionConfigRepository();

  final RxBool isLoadingTypes = false.obs;
  final RxBool isLoadingCategories = false.obs;
  final RxString error = ''.obs;

  final RxList<InstitutionTypeModel> types = <InstitutionTypeModel>[].obs;
  final RxList<InstitutionCategoryModel> categories =
      <InstitutionCategoryModel>[].obs;

  final RxnInt selectedTypeId = RxnInt();

  // Forms
  final TextEditingController typeNameController = TextEditingController();
  final TextEditingController typeDisplayNameController =
      TextEditingController();
  final TextEditingController typeDescriptionController =
      TextEditingController();

  final TextEditingController categoryNameController = TextEditingController();
  final TextEditingController categoryDisplayNameController =
      TextEditingController();
  final TextEditingController categoryDescriptionController =
      TextEditingController();

  final RxnInt editingTypeId = RxnInt();
  final RxnInt editingCategoryId = RxnInt();

  @override
  void onInit() {
    super.onInit();
    loadTypes();
  }

  void _toastError(String message) {
    final m = message.trim();
    if (m.isEmpty) return;
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  Future<void> _reloadInstitutionConsumers() async {
    // School screens (create/list filters)
    if (Get.isRegistered<SchoolController>()) {
      await Get.find<SchoolController>().loadInstitutionTypes();
    }

    // Participant registration institution search filters cache
    if (Get.isRegistered<ParticipantController>()) {
      final p = Get.find<ParticipantController>();
      await p.refreshInstitutionSearchFilters();
    }
  }

  @override
  void onClose() {
    typeNameController.dispose();
    typeDisplayNameController.dispose();
    typeDescriptionController.dispose();
    categoryNameController.dispose();
    categoryDisplayNameController.dispose();
    categoryDescriptionController.dispose();
    super.onClose();
  }

  Future<void> loadTypes() async {
    if (isLoadingTypes.value) return;
    try {
      isLoadingTypes.value = true;
      error.value = '';
      final res = await _repo.getTypes();
      if (!res.success || res.data == null) {
        final msg = res.message ?? 'Failed to load institution types';
        error.value = msg;
        _toastError(msg);
        return;
      }
      final list = [...res.data!]
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      types.assignAll(list);
      selectedTypeId.value ??= list.isNotEmpty ? list.first.id : null;
      if (selectedTypeId.value != null) {
        await loadCategoriesForSelectedType();
      }
    } catch (e) {
      final msg = e.toString();
      error.value = msg;
      _toastError(msg);
    } finally {
      isLoadingTypes.value = false;
    }
  }

  Future<void> loadCategoriesForSelectedType() async {
    final typeId = selectedTypeId.value;
    if (typeId == null) {
      categories.clear();
      return;
    }
    if (isLoadingCategories.value) return;
    try {
      isLoadingCategories.value = true;
      error.value = '';
      final res = await _repo.getCategoriesByType(typeId);
      if (!res.success || res.data == null) {
        final msg = res.message ?? 'Failed to load categories';
        error.value = msg;
        _toastError(msg);
        return;
      }
      final list = [...res.data!]
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      categories.assignAll(list);
    } catch (e) {
      final msg = e.toString();
      error.value = msg;
      _toastError(msg);
    } finally {
      isLoadingCategories.value = false;
    }
  }

  void selectType(int? typeId) {
    if (typeId == null) return;
    selectedTypeId.value = typeId;
    loadCategoriesForSelectedType();
  }

  void startCreateType() {
    editingTypeId.value = null;
    typeNameController.text = '';
    typeDisplayNameController.text = '';
    typeDescriptionController.text = '';
  }

  void startEditType(InstitutionTypeModel t) {
    editingTypeId.value = t.id;
    typeNameController.text = t.typeName;
    typeDisplayNameController.text = t.displayName;
    typeDescriptionController.text = '';
  }

  Future<void> saveType() async {
    final name = typeNameController.text.trim();
    final display = typeDisplayNameController.text.trim();
    if (name.isEmpty || display.isEmpty) {
      const msg = 'Type name and display name are required';
      error.value = msg;
      _toastError(msg);
      return;
    }

    final id = editingTypeId.value;
    final res = id == null
        ? await _repo.createType(
            typeName: name,
            displayName: display,
            description: typeDescriptionController.text.trim(),
          )
        : await _repo.updateType(
            id: id,
            typeName: name,
            displayName: display,
            description: typeDescriptionController.text.trim(),
          );

    if (!res.success) {
      final msg = res.message ?? 'Failed to save type';
      error.value = msg;
      _toastError(msg);
      return;
    }

    await loadTypes();
    await _reloadInstitutionConsumers();
    startCreateType();
  }

  Future<void> deleteType(int id) async {
    final res = await _repo.deleteType(id);
    if (!res.success) {
      final msg = res.message ?? 'Failed to delete type';
      error.value = msg;
      _toastError(msg);
      return;
    }
    await loadTypes();
    await _reloadInstitutionConsumers();
  }

  Future<void> reorderTypes(int oldIndex, int newIndex) async {
    final list = types.toList();
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    types.assignAll(list);

    final res = await _repo.reorderTypes(list.map((e) => e.id).toList());
    if (!res.success) {
      final msg = res.message ?? 'Failed to reorder types';
      error.value = msg;
      _toastError(msg);
      await loadTypes();
    } else {
      await loadTypes();
    }
    await _reloadInstitutionConsumers();
  }

  void startCreateCategory() {
    editingCategoryId.value = null;
    categoryNameController.text = '';
    categoryDisplayNameController.text = '';
    categoryDescriptionController.text = '';
  }

  void startEditCategory(InstitutionCategoryModel c) {
    editingCategoryId.value = c.id;
    categoryNameController.text = c.categoryName;
    categoryDisplayNameController.text = c.displayName;
    categoryDescriptionController.text = '';
  }

  Future<void> saveCategory() async {
    final typeId = selectedTypeId.value;
    if (typeId == null) {
      const msg = 'Please select a type';
      error.value = msg;
      _toastError(msg);
      return;
    }

    final name = categoryNameController.text.trim();
    final display = categoryDisplayNameController.text.trim();
    if (name.isEmpty || display.isEmpty) {
      const msg = 'Category name and display name are required';
      error.value = msg;
      _toastError(msg);
      return;
    }

    final id = editingCategoryId.value;
    final res = id == null
        ? await _repo.createCategory(
            institutionTypeId: typeId,
            categoryName: name,
            displayName: display,
            description: categoryDescriptionController.text.trim(),
          )
        : await _repo.updateCategory(
            id: id,
            institutionTypeId: typeId,
            categoryName: name,
            displayName: display,
            description: categoryDescriptionController.text.trim(),
          );

    if (!res.success) {
      final msg = res.message ?? 'Failed to save category';
      error.value = msg;
      _toastError(msg);
      return;
    }

    await loadCategoriesForSelectedType();
    await _reloadInstitutionConsumers();
    startCreateCategory();
  }

  Future<void> deleteCategory(int id) async {
    final res = await _repo.deleteCategory(id);
    if (!res.success) {
      final msg = res.message ?? 'Failed to delete category';
      error.value = msg;
      _toastError(msg);
      return;
    }
    await loadCategoriesForSelectedType();
    await _reloadInstitutionConsumers();
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    final typeId = selectedTypeId.value;
    if (typeId == null) return;

    final list = categories.toList();
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    categories.assignAll(list);

    final res = await _repo.reorderCategories(
      institutionTypeId: typeId,
      orderedIds: list.map((e) => e.id).toList(),
    );
    if (!res.success) {
      final msg = res.message ?? 'Failed to reorder categories';
      error.value = msg;
      _toastError(msg);
      await loadCategoriesForSelectedType();
    } else {
      await loadCategoriesForSelectedType();
    }
    await _reloadInstitutionConsumers();
  }
}
