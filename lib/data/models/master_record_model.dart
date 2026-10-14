class MasterRecordModel {
  final int id;
  final String name;
  final String? description;
  final double amount;
  final double spotAmount;

  const MasterRecordModel({
    required this.id,
    required this.name,
    this.description,
    this.amount = 0,
    this.spotAmount = 0,
  });

  String get subtitle {
    if (description != null && description!.trim().isNotEmpty) {
      return description!.trim();
    }
    return '';
  }

  String get amountLabel {
    String fmt(double value) => value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    final online = amount;
    final spot = spotAmount > 0 ? spotAmount : amount;
    if ((spot - online).abs() < 0.001) {
      return '₹${fmt(online)}';
    }
    return 'Online ₹${fmt(online)} · Spot ₹${fmt(spot)}';
  }

  factory MasterRecordModel.fromJson(Map<String, dynamic> json) {
    final amount = _parseAmount(json['amount']);
    final spot = _parseAmount(json['spotAmount'] ?? json['spot_amount']);
    return MasterRecordModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ??
          json['categoryName']?.toString() ??
          json['stageName']?.toString() ??
          json['prizeName']?.toString() ??
          '',
      description: json['description']?.toString(),
      amount: amount,
      spotAmount: spot > 0 ? spot : amount,
    );
  }

  static double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
