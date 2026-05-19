class DistrictModel {
  final int id;
  final String districtName;
  final int stateId;
  final String? stateName;

  DistrictModel({
    required this.id,
    required this.districtName,
    required this.stateId,
    this.stateName,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      id: json['id'] as int,
      districtName: json['districtName']?.toString() ?? '',
      stateId: json['stateId'] as int,
      stateName: json['stateName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'districtName': districtName,
      'stateId': stateId,
      if (stateName != null) 'stateName': stateName,
    };
  }
}
