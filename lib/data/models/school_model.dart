class SchoolModel {
  final String? id;
  final String institutionName;
  final String address;
  final int? stateId;
  final String? stateName;
  final String? stateCode;
  final int? cityId;
  final String? cityName;
  final String? district;
  final String? state; // Legacy field for backward compatibility
  final String pincode;
  final String
  institutionType; // 'PRIVATE_SCHOOL', 'GOVT_AIDED_SCHOOL', etc. or UI format
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SchoolModel({
    this.id,
    required this.institutionName,
    required this.address,
    this.stateId,
    this.stateName,
    this.stateCode,
    this.cityId,
    this.cityName,
    this.district,
    this.state,
    required this.pincode,
    required this.institutionType,
    this.createdAt,
    this.updatedAt,
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      institutionName:
          json['institutionName']?.toString() ??
          json['institution_name']?.toString() ??
          '',
      address: json['address']?.toString() ?? '',
      stateId: json['stateId'] is int
          ? json['stateId'] as int
          : json['stateId'] is String
          ? int.tryParse(json['stateId'])
          : null,
      stateName: json['stateName']?.toString(),
      stateCode: json['stateCode']?.toString(),
      cityId: json['cityId'] is int
          ? json['cityId'] as int
          : json['cityId'] is String
          ? int.tryParse(json['cityId'])
          : null,
      cityName: json['cityName']?.toString(),
      district: json['district']?.toString() ?? json['cityName']?.toString(),
      state: json['stateName']?.toString() ?? json['state']?.toString(),
      pincode: json['pincode']?.toString() ?? '',
      institutionType:
          json['institutionType']?.toString() ??
          json['institution_type']?.toString() ??
          '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String
                ? DateTime.parse(json['createdAt'])
                : json['createdAt'] is int
                ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
                : null)
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is String
                ? DateTime.parse(json['updatedAt'])
                : json['updatedAt'] is int
                ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
                : null)
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeMetadata = false}) {
    return {
      if (id != null && includeMetadata) 'id': id,
      'institutionName': institutionName,
      'address': address,
      if (stateId != null) 'stateId': stateId,
      if (cityId != null) 'cityId': cityId,
      'pincode': pincode,
      'institutionType': institutionType,
      if (includeMetadata && createdAt != null)
        'createdAt': createdAt!.toIso8601String(),
      if (includeMetadata && updatedAt != null)
        'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  SchoolModel copyWith({
    String? id,
    String? institutionName,
    String? address,
    int? stateId,
    String? stateName,
    String? stateCode,
    int? cityId,
    String? cityName,
    String? district,
    String? state,
    String? pincode,
    String? institutionType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolModel(
      id: id ?? this.id,
      institutionName: institutionName ?? this.institutionName,
      address: address ?? this.address,
      stateId: stateId ?? this.stateId,
      stateName: stateName ?? this.stateName,
      stateCode: stateCode ?? this.stateCode,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      district: district ?? this.district,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      institutionType: institutionType ?? this.institutionType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
