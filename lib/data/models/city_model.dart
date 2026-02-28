class CityModel {
  final int id;
  final String cityName;
  final String district;
  final String pincode;
  final int stateId;
  final String stateName;
  final String? description;

  CityModel({
    required this.id,
    required this.cityName,
    required this.district,
    required this.pincode,
    required this.stateId,
    required this.stateName,
    this.description,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as int,
      cityName: json['cityName'] as String,
      district: json['district'] as String,
      pincode: json['pincode'] as String,
      stateId: json['stateId'] as int,
      stateName: json['stateName'] as String,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cityName': cityName,
      'district': district,
      'pincode': pincode,
      'stateId': stateId,
      'stateName': stateName,
      'description': description,
    };
  }
}
