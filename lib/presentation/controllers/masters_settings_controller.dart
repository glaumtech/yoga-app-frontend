import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/navigation/root_scaffold_messenger_key.dart';
import '../../data/models/master_record_model.dart';
import '../../data/repositories/masters_repository.dart';

class MastersSettingsController extends GetxController {
  final MastersRepository _repo = MastersRepository();

  final RxBool isLoadingCategories = false.obs;
  final RxBool isLoadingStages = false.obs;
  final RxBool isLoadingPrizes = false.obs;

  final RxList<MasterRecordModel> categories = <MasterRecordModel>[].obs;
  final RxList<MasterRecordModel> stages = <MasterRecordModel>[].obs;
  final RxList<MasterRecordModel> prizes = <MasterRecordModel>[].obs;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final RxnInt editingCategoryId = RxnInt();
  final RxnInt editingStageId = RxnInt();
  final RxnInt editingPrizeId = RxnInt();

  bool get _anyLoading =>
      isLoadingCategories.value ||
      isLoadingStages.value ||
      isLoadingPrizes.value;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
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

  void _toastSuccess(String message) {
    final m = message.trim();
    if (m.isEmpty) return;
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  Future<void> loadAll() async {
    if (_anyLoading) return;
    await Future.wait([
      loadCategories(),
      loadStages(),
      loadPrizes(),
    ]);
  }

  Future<void> loadCategories() async {
    try {
      isLoadingCategories.value = true;
      final res = await _repo.list(MasterTableType.categories);
      if (!res.success || res.data == null) {
        _toastError(res.message ?? 'Failed to load categories');
        return;
      }
      categories.assignAll(res.data!);
    } catch (e) {
      _toastError(e.toString());
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<void> loadStages() async {
    try {
      isLoadingStages.value = true;
      final res = await _repo.list(MasterTableType.stages);
      if (!res.success || res.data == null) {
        _toastError(res.message ?? 'Failed to load stages');
        return;
      }
      stages.assignAll(res.data!);
    } catch (e) {
      _toastError(e.toString());
    } finally {
      isLoadingStages.value = false;
    }
  }

  Future<void> loadPrizes() async {
    try {
      isLoadingPrizes.value = true;
      final res = await _repo.list(MasterTableType.prizes);
      if (!res.success || res.data == null) {
        _toastError(res.message ?? 'Failed to load prizes');
        return;
      }
      prizes.assignAll(res.data!);
    } catch (e) {
      _toastError(e.toString());
    } finally {
      isLoadingPrizes.value = false;
    }
  }

  void clearForm(MasterTableType type) {
    switch (type) {
      case MasterTableType.categories:
        editingCategoryId.value = null;
      case MasterTableType.stages:
        editingStageId.value = null;
      case MasterTableType.prizes:
        editingPrizeId.value = null;
    }
    nameController.text = '';
    descriptionController.text = '';
  }

  void startCreate(MasterTableType type) => clearForm(type);

  void startEdit(MasterTableType type, MasterRecordModel record) {
    switch (type) {
      case MasterTableType.categories:
        editingCategoryId.value = record.id;
      case MasterTableType.stages:
        editingStageId.value = record.id;
      case MasterTableType.prizes:
        editingPrizeId.value = record.id;
    }
    nameController.text = record.name;
    descriptionController.text = record.description ?? '';
  }

  int? _editingId(MasterTableType type) {
    switch (type) {
      case MasterTableType.categories:
        return editingCategoryId.value;
      case MasterTableType.stages:
        return editingStageId.value;
      case MasterTableType.prizes:
        return editingPrizeId.value;
    }
  }

  Future<void> save(MasterTableType type) async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      _toastError('Name is required');
      return;
    }

    final description = descriptionController.text.trim();
    final editingId = _editingId(type);

    final res = editingId == null
        ? await _repo.create(
            type: type,
            name: name,
            description: description.isEmpty ? null : description,
          )
        : await _repo.update(
            type: type,
            id: editingId,
            name: name,
            description: description.isEmpty ? null : description,
          );

    if (!res.success) {
      _toastError(res.message ?? 'Failed to save');
      return;
    }

    _toastSuccess(editingId == null ? 'Created successfully' : 'Updated successfully');
    await _reload(type);
    clearForm(type);
  }

  Future<void> delete(MasterTableType type, MasterRecordModel record) async {
    final res = await _repo.delete(type: type, id: record.id);
    if (!res.success) {
      _toastError(res.message ?? 'Failed to delete');
      return;
    }
    _toastSuccess('Deleted successfully');
    if (_editingId(type) == record.id) {
      clearForm(type);
    }
    await _reload(type);
  }

  Future<void> reload(MasterTableType type) => _reload(type);

  Future<void> _reload(MasterTableType type) async {
    switch (type) {
      case MasterTableType.categories:
        await loadCategories();
      case MasterTableType.stages:
        await loadStages();
      case MasterTableType.prizes:
        await loadPrizes();
    }
  }

  RxList<MasterRecordModel> listFor(MasterTableType type) {
    switch (type) {
      case MasterTableType.categories:
        return categories;
      case MasterTableType.stages:
        return stages;
      case MasterTableType.prizes:
        return prizes;
    }
  }

  RxBool loadingFor(MasterTableType type) {
    switch (type) {
      case MasterTableType.categories:
        return isLoadingCategories;
      case MasterTableType.stages:
        return isLoadingStages;
      case MasterTableType.prizes:
        return isLoadingPrizes;
    }
  }

  bool isEditing(MasterTableType type) => _editingId(type) != null;
}
