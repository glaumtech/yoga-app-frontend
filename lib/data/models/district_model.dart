class DistrictModel {
  final int id;
  final String districtName;
  final int stateId;
  final String? stateName;
  final String? description;

  DistrictModel({
    required this.id,
    required this.districtName,
    required this.stateId,
    this.stateName,
    this.description,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int
        ? rawId
        : rawId is String
            ? int.tryParse(rawId) ?? 0
            : (rawId as num?)?.toInt() ?? 0;
    final rawStateId = json['stateId'];
    final stateId = rawStateId is int
        ? rawStateId
        : rawStateId is String
            ? int.tryParse(rawStateId) ?? 0
            : (rawStateId as num?)?.toInt() ?? 0;
    return DistrictModel(
      id: id,
      districtName: json['districtName']?.toString() ?? '',
      stateId: stateId,
      stateName: json['stateName']?.toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'districtName': districtName,
      'stateId': stateId,
      if (stateName != null) 'stateName': stateName,
      if (description != null) 'description': description,
    };
  }
}
