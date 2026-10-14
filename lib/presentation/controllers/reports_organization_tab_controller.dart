import 'package:get/get.dart';

import '../../data/repositories/reports_repository.dart';
import 'reports_controller.dart';

class ReportsOrganizationTabController extends GetxController {
  late final ReportsController reportsController;
  final ReportsRepository _repository = ReportsRepository();

  final RxBool isLoading = false.obs;
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
}
