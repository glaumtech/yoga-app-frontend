import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/utils/snackbar_helper.dart';
import '../../data/repositories/reports_repository.dart';
import 'amount_request_notification_controller.dart';
import 'reports_controller.dart';

class ReportsFinancialTabController extends GetxController {
  late final ReportsController reportsController;
  final ReportsRepository _repository = ReportsRepository();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isPrinting = false.obs;
  final RxString error = ''.obs;
  final Rxn<Map<String, dynamic>> report = Rxn<Map<String, dynamic>>();
  final RxnInt highlightedTransferId = RxnInt();
  final RxInt highlightScrollTick = 0.obs;
  final Map<int, GlobalKey> _transferRowKeys = {};
  int _appliedHighlightTick = 0;

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

  void highlightTransfer(int? transferId) {
    highlightedTransferId.value = transferId;
    if (transferId == null) return;
    highlightScrollTick.value++;
    Future.delayed(const Duration(seconds: 5), () {
      if (highlightedTransferId.value == transferId) {
        highlightedTransferId.value = null;
      }
    });
  }

  GlobalKey transferRowKey(int id) =>
      _transferRowKeys.putIfAbsent(id, GlobalKey.new);

  /// Scrolls the highlighted transfer row into view. Call from the table
  /// build so the row key is already in the tree.
  void revealHighlightedTransfer() {
    final tick = highlightScrollTick.value;
    final id = highlightedTransferId.value;
    if (id == null || tick == 0 || tick == _appliedHighlightTick) return;
    _appliedHighlightTick = tick;
    _scrollToTransferRow(id);
  }

  void _ensureVerticallyVisible(BuildContext context) {
    RenderObject? targetRenderObject;
    ScrollableState? scrollable = Scrollable.maybeOf(context);
    while (scrollable != null) {
      if (scrollable.position.axis == Axis.vertical) {
        scrollable.position.ensureVisible(
          context.findRenderObject()!,
          alignment: 0.22,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          targetRenderObject: targetRenderObject,
        );
      }
      targetRenderObject ??= context.findRenderObject();
      context = scrollable.context;
      scrollable = Scrollable.maybeOf(context);
    }
  }

  void _scrollToTransferRow(int id, {int attempt = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _transferRowKeys[id]?.currentContext;
      if (target == null || !target.mounted) {
        if (attempt < 3) _scrollToTransferRow(id, attempt: attempt + 1);
        return;
      }
      _ensureVerticallyVisible(target);
    });
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
    int? amountRequestId,
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
              amountRequestId: amountRequestId,
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
      if (amountRequestId != null &&
          Get.isRegistered<AmountRequestNotificationController>()) {
        Get.find<AmountRequestNotificationController>().load();
      }
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
