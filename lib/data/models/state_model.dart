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
    return StateModel(
      id: json['id'] as int,
      stateName: json['stateName'] as String,
      stateCode: json['stateCode'] as String,
      description: json['description'] as String?,
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
