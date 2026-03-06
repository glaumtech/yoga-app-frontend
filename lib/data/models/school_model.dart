class SchoolModel {
  final String? id;
  final String institutionName;
  final String? institutionShortName;
  final String address;
  final int? stateId;
  final String? stateName;
  final String? stateCode;
  final int? cityId;
  final String? cityName;
  final String? district;
  final String? state; // Legacy field for backward compatibility
  final String pincode;
  final String? email;
  final String
  institutionType; // 'PRIVATE_SCHOOL', 'GOVT_AIDED_SCHOOL', etc. or UI format
  final String? institutionTypeDisplayName;
  final String? institutionCategoryDisplayName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? createdBy;
  final int? updatedBy;

  SchoolModel({
    this.id,
    required this.institutionName,
    this.institutionShortName,
    required this.address,
    this.stateId,
    this.stateName,
    this.stateCode,
    this.cityId,
    this.cityName,
    this.district,
    this.state,
    required this.pincode,
    this.email,
    required this.institutionType,
    this.institutionTypeDisplayName,
    this.institutionCategoryDisplayName,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      institutionName:
          json['institutionName']?.toString() ??
          json['institution_name']?.toString() ??
          '',
      institutionShortName: json['institutionShortName']?.toString() ?? '',
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
      email: json['email']?.toString() ?? json['emailId']?.toString(),
      institutionType:
          json['institutionType']?.toString() ??
          json['institution_type']?.toString() ??
          '',
      institutionTypeDisplayName: json['institutionTypeDisplayName']
          ?.toString(),
      institutionCategoryDisplayName: json['institutionCategoryDisplayName']
          ?.toString(),
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
      createdBy: json['createdBy'] is int
          ? json['createdBy'] as int
          : json['createdBy'] is String
          ? int.tryParse(json['createdBy'])
          : null,
      updatedBy: json['updatedBy'] is int
          ? json['updatedBy'] as int
          : json['updatedBy'] is String
          ? int.tryParse(json['updatedBy'])
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeMetadata = false}) {
    return {
      if (id != null && includeMetadata) 'id': id,
      'institutionName': institutionName,
      'institutionShortName': institutionShortName,
      'address': address,
      if (stateId != null) 'stateId': stateId,
      if (cityId != null) 'cityId': cityId,
      'pincode': pincode,
      if (email != null) 'email': email,
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
    String? institutionShortName,
    String? address,
    int? stateId,
    String? stateName,
    String? stateCode,
    int? cityId,
    String? cityName,
    String? district,
    String? state,
    String? pincode,
    String? email,
    String? institutionType,
    String? institutionTypeDisplayName,
    String? institutionCategoryDisplayName,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
    int? updatedBy,
  }) {
    return SchoolModel(
      id: id ?? this.id,
      institutionName: institutionName ?? this.institutionName,
      institutionShortName: institutionShortName ?? this.institutionShortName,
      address: address ?? this.address,
      stateId: stateId ?? this.stateId,
      stateName: stateName ?? this.stateName,
      stateCode: stateCode ?? this.stateCode,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      district: district ?? this.district,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      email: email ?? this.email,
      institutionType: institutionType ?? this.institutionType,
      institutionTypeDisplayName:
          institutionTypeDisplayName ?? this.institutionTypeDisplayName,
      institutionCategoryDisplayName:
          institutionCategoryDisplayName ?? this.institutionCategoryDisplayName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
