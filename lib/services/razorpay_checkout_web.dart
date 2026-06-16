import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Handle to a Razorpay Checkout.js instance (`rzp.open()`).
extension type RazorpayCheckout._(JSObject _) implements JSObject {
  external void open();
}

bool _isRazorpaySdkLoaded() {
  final ctor = globalContext.getProperty('Razorpay'.toJS);
  return ctor != null && !ctor.isUndefinedOrNull && ctor.isA<JSFunction>();
}

Future<void> _ensureRazorpaySdkLoaded() async {
  if (_isRazorpaySdkLoaded()) {
    return;
  }

  final completer = Completer<void>();
  final document = globalContext.getProperty('document'.toJS) as JSObject;
  final script = document.callMethod('createElement'.toJS, 'script'.toJS) as JSObject;
  script.setProperty(
    'src'.toJS,
    'https://checkout.razorpay.com/v1/checkout.js'.toJS,
  );
  script.setProperty('async'.toJS, false.toJS);
  script.setProperty(
    'onload'.toJS,
    (() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }).toJS,
  );
  script.setProperty(
    'onerror'.toJS,
    (() {
      if (!completer.isCompleted) {
        completer.completeError(
          Exception(
            'Failed to load Razorpay checkout. Check your network or antivirus settings.',
          ),
        );
      }
    }).toJS,
  );

  final head = document.getProperty('head'.toJS) as JSObject;
  head.callMethod('appendChild'.toJS, script);

  await completer.future.timeout(
    const Duration(seconds: 20),
    onTimeout: () => throw Exception(
      'Timed out loading Razorpay checkout. Refresh the page and try again.',
    ),
  );

  if (!_isRazorpaySdkLoaded()) {
    throw Exception(
      'Razorpay checkout is unavailable. Refresh the page and try again.',
    );
  }
}

RazorpayCheckout _createRazorpayCheckout(JSObject options) {
  final ctor = globalContext.getProperty('Razorpay'.toJS) as JSFunction;
  return ctor.callAsConstructor(options) as RazorpayCheckout;
}

Future<Map<String, String>> openRazorpayWebCheckout({
  required String keyId,
  required String orderId,
  required int amountPaise,
  required String description,
}) async {
  await _ensureRazorpaySdkLoaded();

  final completer = Completer<Map<String, String>>();

  void completeSuccess(JSAny response) {
    if (completer.isCompleted) return;
    final dynamic dart = response.dartify();
    if (dart is Map) {
      completer.complete({
        'razorpay_order_id':
            dart['razorpay_order_id']?.toString() ?? orderId,
        'razorpay_payment_id': dart['razorpay_payment_id']?.toString() ?? '',
        'razorpay_signature': dart['razorpay_signature']?.toString() ?? '',
      });
      return;
    }
    completer.completeError(Exception('Invalid Razorpay payment response'));
  }

  void onDismiss() {
    if (!completer.isCompleted) {
      completer.completeError(Exception('Payment cancelled'));
    }
  }

  final options = <String, Object?>{
    'key': keyId,
    'amount': amountPaise,
    'currency': 'INR',
    'order_id': orderId,
    'name': 'Yoga Competition',
    'description': description,
    'handler': completeSuccess.toJS,
    'modal': <String, Object?>{'ondismiss': onDismiss.toJS},
  }.jsify() as JSObject;

  final checkout = _createRazorpayCheckout(options);
  checkout.open();
  return completer.future;
}
