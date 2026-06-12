Future<Map<String, String>> openRazorpayWebCheckout({
  required String keyId,
  required String orderId,
  required int amountPaise,
  required String description,
}) {
  throw UnsupportedError('Razorpay web checkout is only available on web');
}
