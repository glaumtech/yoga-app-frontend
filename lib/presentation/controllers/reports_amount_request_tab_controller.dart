import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/utils/snackbar_helper.dart';
import '../../data/repositories/reports_repository.dart';
import 'amount_request_notification_controller.dart';
import 'reports_controller.dart';

class ReportsAmountRequestTabController extends GetxController {
  late final ReportsController reportsController;
  final ReportsRepository _repository = ReportsRepository();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString error = ''.obs;
  final Rxn<Map<String, dynamic>> data = Rxn<Map<String, dynamic>>();

  Worker? _competitionWatcher;

  @override
  void onInit() {
    super.onInit();
    reportsController = Get.find<ReportsController>();
    _competitionWatcher = ever<String?>(
      reportsController.selectedCompetitionId,
      (_) {
        Future.microtask(load);
      },
    );
  }

  @override
  void onReady() {
    super.onReady();
    Future.microtask(load);
  }

  @override
  void onClose() {
    _competitionWatcher?.dispose();
    super.onClose();
  }

  int? get competitionId =>
      int.tryParse(reportsController.selectedCompetitionId.value ?? '');

  Future<void> load() async {
    final id = competitionId;
    if (id == null) {
      data.value = null;
      error.value = '';
      return;
    }
    isLoading.value = true;
    error.value = '';
    try {
      final resp = await _repository.getOrganizerAmountRequests(id);
      if (resp.success && resp.data != null) {
        data.value = resp.data;
      } else {
        data.value = null;
        error.value = resp.message ?? 'Failed to load amount requests';
      }
    } catch (e) {
      data.value = null;
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveAmountRequest({
    int? requestId,
    required String fromParty,
    required String toParty,
    required double totalAmount,
    required double requestAmount,
    DateTime? requestDate,
  }) async {
    final id = competitionId;
    if (id == null) {
      SnackbarHelper.showErrorMessage('Select a competition first');
      return false;
    }
    if (isSaving.value) return false;
    isSaving.value = true;
    try {
      final dateStr = requestDate != null
          ? DateFormat('yyyy-MM-dd').format(requestDate)
          : null;
      final resp = requestId == null
          ? await _repository.createAmountRequest(
              competitionId: id,
              fromParty: fromParty,
              toParty: toParty,
              totalAmount: totalAmount,
              requestAmount: requestAmount,
              requestDate: dateStr,
            )
          : await _repository.updateAmountRequest(
              competitionId: id,
              requestId: requestId,
              fromParty: fromParty,
              toParty: toParty,
              totalAmount: totalAmount,
              requestAmount: requestAmount,
              requestDate: dateStr,
            );
      if (!resp.success) {
        SnackbarHelper.showErrorMessage(
          resp.message ?? 'Failed to save amount request',
        );
        return false;
      }
      await load();
      SnackbarHelper.showSuccessMessage(
        requestId == null ? 'Amount request saved' : 'Amount request updated',
      );
      if (Get.isRegistered<AmountRequestNotificationController>()) {
        Get.find<AmountRequestNotificationController>().load();
      }
      return true;
    } catch (e) {
      SnackbarHelper.showErrorMessage(e.toString());
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteAmountRequest(int requestId) async {
    final id = competitionId;
    if (id == null) return false;
    isSaving.value = true;
    try {
      final resp = await _repository.deleteAmountRequest(
        competitionId: id,
        requestId: requestId,
      );
      if (!resp.success) {
        SnackbarHelper.showErrorMessage(
          resp.message ?? 'Failed to delete amount request',
        );
        return false;
      }
      await load();
      SnackbarHelper.showSuccessMessage('Amount request deleted');
      if (Get.isRegistered<AmountRequestNotificationController>()) {
        Get.find<AmountRequestNotificationController>().load();
      }
      return true;
    } catch (e) {
      SnackbarHelper.showErrorMessage(e.toString());
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
