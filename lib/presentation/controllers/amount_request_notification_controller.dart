import 'package:get/get.dart';

import 'package:intl/intl.dart';



import '../../core/utils/permission_store.dart';

import '../../data/repositories/reports_repository.dart';



class AmountRequestNotificationController extends GetxController {

  final ReportsRepository _repository = ReportsRepository();



  final isLoading = false.obs;

  final errorMessage = ''.obs;

  final requests = <Map<String, dynamic>>[].obs;



  bool get canShow {

    final store = Get.isRegistered<PermissionStore>()

        ? Get.find<PermissionStore>()

        : Get.put(PermissionStore());

    return store.has('SHOW_AMOUNT_REQUEST_NOTIFICATIONS');

  }



  int get count => requests.length;



  @override

  void onReady() {

    super.onReady();

    if (canShow) {

      load();

    }

  }



  Future<void> load() async {

    if (!canShow) {

      requests.clear();

      return;

    }

    try {

      isLoading.value = true;

      errorMessage.value = '';

      final resp = await _repository.getPendingAmountRequests();

      if (!resp.success) {

        errorMessage.value = resp.message ?? 'Failed to load amount requests';

        requests.clear();

        return;

      }

      requests.assignAll(resp.data ?? const []);

    } catch (e) {

      errorMessage.value = e.toString();

      requests.clear();

    } finally {

      isLoading.value = false;

    }

  }



  Future<bool> markViewed({

    required int competitionId,

    required int requestId,

  }) async {

    try {

      final resp = await _repository.markAmountRequestViewed(

        competitionId: competitionId,

        requestId: requestId,

      );

      if (!resp.success) {

        errorMessage.value =

            resp.message ?? 'Failed to mark amount request as viewed';

        return false;

      }

      requests.removeWhere((item) {

        final id = item['id'];

        final rid = id is int ? id : int.tryParse(id?.toString() ?? '');

        return rid == requestId;

      });

      return true;

    } catch (e) {

      errorMessage.value = e.toString();

      return false;

    }

  }



  String formatMoney(dynamic value) {

    final amount = value is num

        ? value.toDouble()

        : double.tryParse(value?.toString() ?? '') ?? 0;

    return NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(amount);

  }

}


