class SubscriptionModeModel {
  final int id;
  final String name;
  final String modeKey;
  final bool active;

  const SubscriptionModeModel({
    required this.id,
    required this.name,
    required this.modeKey,
    this.active = true,
  });

  factory SubscriptionModeModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return SubscriptionModeModel(
      id: parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      modeKey: json['modeKey']?.toString() ?? '',
      active: json['active'] == true || json['active'] == 1,
    );
  }
}
