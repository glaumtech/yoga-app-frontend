class CityModel {
  final int id;
  final String cityName;
  final int districtId;
  final String districtName;
  final String? village;
  final String pincode;
  final int stateId;
  final String stateName;
  final String? description;

  CityModel({
    required this.id,
    required this.cityName,
    required this.districtId,
    required this.districtName,
    this.village,
    required this.pincode,
    required this.stateId,
    required this.stateName,
    this.description,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as int,
      cityName: json['cityName'] as String? ?? '',
      districtId: json['districtId'] as int? ?? 0,
      districtName: json['districtName']?.toString() ?? '',
      village: json['village'] as String?,
      pincode: json['pincode']?.toString() ?? '',
      stateId: json['stateId'] as int,
      stateName: json['stateName'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cityName': cityName,
      'districtId': districtId,
      'districtName': districtName,
      'village': village,
      'pincode': pincode,
      'stateId': stateId,
      'stateName': stateName,
      'description': description,
    };
  }
}
