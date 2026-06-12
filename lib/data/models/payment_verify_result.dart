class PaymentVerifyResult {
  final String orderId;
  final String paymentId;
  final int? transactionId;

  const PaymentVerifyResult({
    required this.orderId,
    required this.paymentId,
    this.transactionId,
  });

  factory PaymentVerifyResult.fromJson(Map<String, dynamic> json) {
    return PaymentVerifyResult(
      orderId:
          json['orderId']?.toString() ?? json['order_id']?.toString() ?? '',
      paymentId: json['paymentId']?.toString() ??
          json['payment_id']?.toString() ??
          '',
      transactionId: json['transactionId'] is int
          ? json['transactionId'] as int
          : int.tryParse(json['transactionId']?.toString() ?? ''),
    );
  }
}
