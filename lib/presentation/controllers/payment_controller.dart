import 'package:get/get.dart';

import '../../data/models/payment_order_model.dart';
import '../../data/repositories/payment_repository.dart';
import '../../services/razorpay_checkout_service.dart';

enum RegistrationPaymentUiStatus {
  notStarted,
  processing,
  paid,
  failed,
  cancelled,
}

class PaymentController extends GetxController {
  final PaymentRepository _paymentRepository = PaymentRepository();
  final RazorpayCheckoutService _checkout = RazorpayCheckoutService();

  final RxBool isPaymentInProgress = false.obs;
  final RxString paymentError = ''.obs;
  final Rx<RegistrationPaymentUiStatus> paymentStatus =
      RegistrationPaymentUiStatus.notStarted.obs;
  final RxnInt lastRegistrationId = RxnInt();

  void resetPaymentState() {
    isPaymentInProgress.value = false;
    paymentError.value = '';
    paymentStatus.value = RegistrationPaymentUiStatus.notStarted;
    lastRegistrationId.value = null;
  }

  /// Collect Razorpay payment before registration is saved (Model 3).
  Future<Map<String, String>?> collectRegistrationPayment({
    required int competitionId,
    required int categoryId,
    required String description,
  }) async {
    isPaymentInProgress.value = true;
    paymentError.value = '';
    paymentStatus.value = RegistrationPaymentUiStatus.processing;

    PaymentOrderModel? order;
    try {
      order = await _paymentRepository.createRegistrationCheckoutOrder(
        competitionId: competitionId,
        categoryId: categoryId,
      );

      if (order.orderId.isEmpty || order.amount < 100) {
        throw Exception('Invalid payment order details');
      }
      if (!order.mockMode && order.key.isEmpty) {
        throw Exception('Payment gateway is not configured. Contact support.');
      }

      final checkout = await _checkout.openCheckout(
        keyId: order.key,
        orderId: order.orderId,
        amountPaise: order.amount,
        description: description,
        mockMode: order.mockMode,
      );

      final orderId =
          checkout['razorpay_order_id']?.toString() ?? order.orderId;
      final paymentId = checkout['razorpay_payment_id']?.toString() ?? '';
      final signature = checkout['razorpay_signature']?.toString() ?? '';

      await _paymentRepository.verifyStandardPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );

      paymentStatus.value = RegistrationPaymentUiStatus.paid;
      return {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      };
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      final cancelled = message.toLowerCase().contains('cancelled');
      final orderId = order?.orderId;
      if (orderId != null && orderId.isNotEmpty) {
        await _paymentRepository.markPaymentFailed(
          orderId: orderId,
          reason: cancelled ? 'cancelled' : message,
        );
      }
      paymentError.value = cancelled ? 'Payment cancelled' : message;
      paymentStatus.value = cancelled
          ? RegistrationPaymentUiStatus.cancelled
          : RegistrationPaymentUiStatus.failed;
      return null;
    } finally {
      isPaymentInProgress.value = false;
      _checkout.dispose();
    }
  }

  Future<void> linkCollectedRegistrationPayment({
    required int registrationId,
    required Map<String, String> checkout,
  }) async {
    lastRegistrationId.value = registrationId;
    final orderId = checkout['razorpay_order_id'] ?? '';
    final paymentId = checkout['razorpay_payment_id'] ?? '';
    final signature = checkout['razorpay_signature'] ?? '';
    await _paymentRepository.linkRegistrationPayment(
      registrationId: registrationId,
      orderId: orderId,
      paymentId: paymentId,
      signature: signature,
    );
    paymentStatus.value = RegistrationPaymentUiStatus.paid;
  }

  @override
  void onClose() {
    _checkout.dispose();
    super.onClose();
  }
}
