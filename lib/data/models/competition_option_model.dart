class CompetitionOptionModel {
  final int id;
  final String name;
  final double amount;
  final double spotAmount;

  CompetitionOptionModel({
    required this.id,
    required this.name,
    this.amount = 0,
    this.spotAmount = 0,
  });

  factory CompetitionOptionModel.fromJson(Map<String, dynamic> json) {
    final amount = _parseAmount(json['amount']);
    final spot = _parseAmount(json['spotAmount'] ?? json['spot_amount']);
    return CompetitionOptionModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ??
            json['stageName']?.toString() ??
            json['categoryName']?.toString() ??
            json['groupName']?.toString() ??
            '',
      amount: amount,
      spotAmount: spot > 0 ? spot : amount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'spotAmount': spotAmount,
    };
  }

  static double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
