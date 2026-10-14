class StateModel {
  final int id;
  final String stateName;
  final String stateCode;
  final String? description;

  StateModel({
    required this.id,
    required this.stateName,
    required this.stateCode,
    this.description,
  });

  factory StateModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int
        ? rawId
        : rawId is String
            ? int.tryParse(rawId) ?? 0
            : (rawId as num?)?.toInt() ?? 0;
    return StateModel(
      id: id,
      stateName: json['stateName']?.toString() ?? '',
      stateCode: json['stateCode']?.toString() ?? '',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stateName': stateName,
      'stateCode': stateCode,
      'description': description,
    };
  }
}
