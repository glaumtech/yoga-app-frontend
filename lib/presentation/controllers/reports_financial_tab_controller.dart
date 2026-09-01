import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/utils/snackbar_helper.dart';
import '../../data/repositories/reports_repository.dart';
import 'reports_controller.dart';

class ReportsFinancialTabController extends GetxController {
  late final ReportsController reportsController;
  final ReportsRepository _repository = ReportsRepository();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isPrinting = false.obs;
  final RxString error = ''.obs;
  final Rxn<Map<String, dynamic>> report = Rxn<Map<String, dynamic>>();

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
      report.value = null;
      error.value = '';
      return;
    }
    isLoading.value = true;
    error.value = '';
    try {
      final resp = await _repository.getCompetitionFinancialReport(id);
      if (resp.success && resp.data != null) {
        report.value = resp.data;
      } else {
        report.value = null;
        error.value = resp.message ?? 'Failed to load financial report';
      }
    } catch (e) {
      report.value = null;
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<Uint8List?> printPdf() async {
    final id = competitionId;
    if (id == null) {
      SnackbarHelper.showErrorMessage('Select a competition first');
      return null;
    }
    if (isPrinting.value) return null;
    isPrinting.value = true;
    try {
      final resp = await _repository.getCompetitionFinancialReportPrintPdf(id);
      if (!resp.success || resp.data == null) {
        SnackbarHelper.showErrorMessage(
          resp.message ?? 'Failed to generate Financial Report PDF',
        );
        return null;
      }
      return resp.data;
    } catch (e) {
      SnackbarHelper.showErrorMessage(e.toString());
      return null;
    } finally {
      isPrinting.value = false;
    }
  }

  Future<bool> saveTransfer({
    int? transferId,
    required double amount,
    String? referenceNumber,
    DateTime? transferDate,
    Uint8List? screenshotBytes,
    String? screenshotFilename,
    bool clearScreenshot = false,
  }) async {
    final id = competitionId;
    if (id == null) {
      SnackbarHelper.showErrorMessage('Select a competition first');
      return false;
    }
    if (isSaving.value) return false;
    isSaving.value = true;
    try {
      final dateStr = transferDate != null
          ? DateFormat('yyyy-MM-dd').format(transferDate)
          : null;
      final resp = transferId == null
          ? await _repository.createCysTransfer(
              competitionId: id,
              amount: amount,
              referenceNumber: referenceNumber,
              transferDate: dateStr,
              screenshotBytes: screenshotBytes,
              screenshotFilename: screenshotFilename,
            )
          : await _repository.updateCysTransfer(
              competitionId: id,
              transferId: transferId,
              amount: amount,
              referenceNumber: referenceNumber,
              transferDate: dateStr,
              clearScreenshot: clearScreenshot,
              screenshotBytes: screenshotBytes,
              screenshotFilename: screenshotFilename,
            );
      if (!resp.success) {
        SnackbarHelper.showErrorMessage(
          resp.message ?? 'Failed to save transfer',
        );
        return false;
      }
      await load();
      SnackbarHelper.showSuccessMessage(
        transferId == null ? 'Transfer saved' : 'Transfer updated',
      );
      return true;
    } catch (e) {
      SnackbarHelper.showErrorMessage(e.toString());
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteTransfer(int transferId) async {
    final id = competitionId;
    if (id == null) return false;
    isSaving.value = true;
    try {
      final resp = await _repository.deleteCysTransfer(
        competitionId: id,
        transferId: transferId,
      );
      if (!resp.success) {
        SnackbarHelper.showErrorMessage(
          resp.message ?? 'Failed to delete transfer',
        );
        return false;
      }
      await load();
      SnackbarHelper.showSuccessMessage('Transfer deleted');
      return true;
    } catch (e) {
      SnackbarHelper.showErrorMessage(e.toString());
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  String? screenshotUrlFor(Map<String, dynamic> transfer) {
    final id = competitionId;
    final transferId = transfer['id'];
    if (id == null || transferId == null) return null;
    final tid = transferId is int
        ? transferId
        : int.tryParse(transferId.toString());
    if (tid == null) return null;
    final path = transfer['screenshotUrl']?.toString();
    if (path == null || path.isEmpty) return null;
    final bust = transfer['updatedAt']?.toString() ??
        transfer['screenshotPath']?.toString() ??
        tid.toString();
    if (path.startsWith('http')) {
      final sep = path.contains('?') ? '&' : '?';
      return '$path${sep}v=${Uri.encodeQueryComponent(bust)}';
    }
    final base = _repository.cysTransferScreenshotUrl(id, tid);
    return '$base?v=${Uri.encodeQueryComponent(bust)}';
  }
}
