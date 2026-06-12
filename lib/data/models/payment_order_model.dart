class PaymentOrderModel {
  final String orderId;
  final int amount;
  final String currency;
  final String key;
  final int? transactionId;
  final bool mockMode;

  const PaymentOrderModel({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.key,
    this.transactionId,
    this.mockMode = false,
  });

  factory PaymentOrderModel.fromJson(Map<String, dynamic> json) {
    final orderId =
        json['orderId']?.toString() ?? json['order_id']?.toString() ?? '';
    final amountRaw = json['amount'];
    final amount = amountRaw is int
        ? amountRaw
        : int.tryParse(amountRaw?.toString() ?? '') ?? 0;
    final txRaw = json['transactionId'];
    return PaymentOrderModel(
      orderId: orderId,
      amount: amount,
      currency: json['currency']?.toString() ?? 'INR',
      key: json['key']?.toString() ?? '',
      transactionId: txRaw is int
          ? txRaw
          : int.tryParse(txRaw?.toString() ?? ''),
      mockMode: json['mockMode'] == true,
    );
  }
}
