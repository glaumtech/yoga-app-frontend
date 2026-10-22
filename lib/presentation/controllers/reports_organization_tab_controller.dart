import 'package:get/get.dart';

import '../../core/utils/snackbar_helper.dart';
import '../../data/repositories/reports_repository.dart';
import 'reports_controller.dart';
import 'reports_participants_tab_logic.dart';

class ReportsOrganizationTabController extends GetxController {
  late final ReportsController reportsController;
  final ReportsRepository _repository = ReportsRepository();

  final RxBool isLoading = false.obs;
  final RxBool isDownloading = false.obs;
  final RxString error = ''.obs;
  final Rxn<Map<String, dynamic>> report = Rxn<Map<String, dynamic>>();

  Worker? _organizationWatcher;

  @override
  void onInit() {
    super.onInit();
    reportsController = Get.find<ReportsController>();
    _organizationWatcher = ever<String?>(
      reportsController.selectedOrganizationId,
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
    _organizationWatcher?.dispose();
    super.onClose();
  }

  int? get organizationId =>
      int.tryParse(reportsController.selectedOrganizationId.value ?? '');

  Future<void> load() async {
    final id = organizationId;
    if (id == null) {
      report.value = null;
      error.value = '';
      return;
    }
    isLoading.value = true;
    error.value = '';
    try {
      final resp = await _repository.getOrganizationReport(id);
      if (resp.success && resp.data != null) {
        report.value = resp.data;
      } else {
        report.value = null;
        error.value = resp.message ?? 'Failed to load organization report';
      }
    } catch (e) {
      report.value = null;
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> downloadExcel() async {
    final id = organizationId;
    if (id == null || isDownloading.value) return;

    isDownloading.value = true;
    try {
      final resp = await _repository.getOrganizationReportExcel(id);
      if (!resp.success || resp.data == null || resp.data!.isEmpty) {
        SnackbarHelper.showErrorMessage(
          resp.message ?? 'Failed to download organization Excel',
        );
        return;
      }

      final org =
          (report.value?['organization'] as Map?)?.cast<String, dynamic>();
      final rawName = (org?['organizationCode'] ??
              org?['organizationName'] ??
              id)
          .toString()
          .trim();
      final safe = rawName
          .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      final filename =
          'organization_report_${safe.isEmpty ? id : safe}.xlsx';

      await ReportsParticipantsTabLogic.downloadFileBytes(
        resp.data!,
        filename,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      SnackbarHelper.showSuccessMessage('Excel download started');
    } catch (e) {
      SnackbarHelper.showErrorMessage(
        'Failed to download organization Excel: $e',
      );
    } finally {
      isDownloading.value = false;
    }
  }
}
