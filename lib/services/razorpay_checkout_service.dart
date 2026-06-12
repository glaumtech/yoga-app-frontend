import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'razorpay_checkout_web_stub.dart'
    if (dart.library.html) 'razorpay_checkout_web.dart' as web_checkout;

/// Opens Razorpay checkout on web (Checkout.js) and mobile (razorpay_flutter).
class RazorpayCheckoutService {
  Razorpay? _razorpay;
  Completer<Map<String, String>>? _completer;

  Future<Map<String, String>> openCheckout({
    required String keyId,
    required String orderId,
    required int amountPaise,
    required String description,
    String? contact,
    String? email,
    bool mockMode = false,
  }) async {
    if (mockMode) {
      return {
        'razorpay_order_id': orderId,
        'razorpay_payment_id':
            'pay_mock_${DateTime.now().millisecondsSinceEpoch}',
        'razorpay_signature': 'mock_signature',
      };
    }

    if (kIsWeb) {
      return web_checkout.openRazorpayWebCheckout(
        keyId: keyId,
        orderId: orderId,
        amountPaise: amountPaise,
        description: description,
      );
    }

    _completer = Completer<Map<String, String>>();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    final options = {
      'key': keyId,
      'amount': amountPaise,
      'name': 'Yoga Competition',
      'order_id': orderId,
      'description': description,
      'prefill': {
        if (contact != null) 'contact': contact,
        if (email != null) 'email': email,
      },
    };

    _razorpay!.open(options);
    return _completer!.future;
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  void _onSuccess(PaymentSuccessResponse response) {
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete({
        'razorpay_order_id': response.orderId ?? '',
        'razorpay_payment_id': response.paymentId ?? '',
        'razorpay_signature': response.signature ?? '',
      });
    }
  }

  void _onError(PaymentFailureResponse response) {
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.completeError(
        Exception(response.message ?? 'Payment failed'),
      );
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    // No-op
  }
}
