class SubscriptionPackageModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int credits;
  final String paymentModel;

  SubscriptionPackageModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.credits,
    required this.paymentModel,
  });

  factory SubscriptionPackageModel.fromJson(Map<String, dynamic> json) {
    double parsePrice(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }

    int parseInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return SubscriptionPackageModel(
      id: parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: parsePrice(json['price']),
      credits: parseInt(json['credits']),
      paymentModel: json['paymentModel']?.toString() ?? 'ORG_SUBSCRIPTION',
    );
  }

  String get displayLabel => '$name — ₹${price.toStringAsFixed(0)} ($credits credits)';

  String get paymentModelLabel {
    switch (paymentModel) {
      case 'USER_PACK_SUBSCRIPTION':
        return 'User pack subscription';
      case 'PAY_PER_PARTICIPANT':
        return 'Pay per participant';
      case 'ORG_SUBSCRIPTION':
      default:
        return 'Organization subscription';
    }
  }

  bool get requiresSubscriptionPayment =>
      paymentModel == 'ORG_SUBSCRIPTION' ||
      paymentModel == 'USER_PACK_SUBSCRIPTION';
}
