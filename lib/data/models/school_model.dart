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
  final int? districtId;
  final String? districtName;
  final String? village;
  final String? state; // Legacy field for backward compatibility
  final String pincode;
  final String? email;
  final String? website;
  final String? landLine;
  final String? mobile;
  final String? contributorName;
  final String? contributorMobileNo;
  final String
  institutionType; // 'PRIVATE_SCHOOL', 'GOVT_AIDED_SCHOOL', etc. or UI format
  final String? institutionTypeDisplayName;
  final String? institutionCategoryDisplayName;
  final List<int> institutionCategoryIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

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
    this.districtId,
    this.districtName,
    this.village,
    this.state,
    required this.pincode,
    this.email,
    this.website,
    this.landLine,
    this.mobile,
    this.contributorName,
    this.contributorMobileNo,
    required this.institutionType,
    this.institutionTypeDisplayName,
    this.institutionCategoryDisplayName,
    this.institutionCategoryIds = const [],
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    final rawCategoryIds =
        json['institutionCategoryIds'] ?? json['institution_category_ids'];
    final parsedCategoryIds = <int>[];
    if (rawCategoryIds is List) {
      for (final v in rawCategoryIds) {
        if (v is int) {
          parsedCategoryIds.add(v);
        } else if (v is String) {
          final n = int.tryParse(v);
          if (n != null) parsedCategoryIds.add(n);
        }
      }
    }
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
      districtId: json['districtId'] is int
          ? json['districtId'] as int
          : json['districtId'] is String
          ? int.tryParse(json['districtId'])
          : null,
      districtName: json['districtName']?.toString(),
      village: json['village']?.toString(),
      state: json['stateName']?.toString() ?? json['state']?.toString(),
      pincode: json['pincode']?.toString() ?? '',
      email: json['email']?.toString() ?? json['emailId']?.toString(),
      website: json['website']?.toString() ?? json['websiteUrl']?.toString(),
      landLine:
          json['landLine']?.toString() ??
          json['landline']?.toString() ??
          json['landLineNo']?.toString(),
      mobile:
          json['mobile']?.toString() ??
          json['mobileNo']?.toString() ??
          json['institutionMobile']?.toString(),
      contributorName: json['contributorName']?.toString(),
      contributorMobileNo:
          json['contributorMobileNo']?.toString() ??
          json['contributorMobile']?.toString(),
      institutionType:
          json['institutionType']?.toString() ??
          json['institution_type']?.toString() ??
          '',
      institutionTypeDisplayName: json['institutionTypeDisplayName']
          ?.toString(),
      institutionCategoryDisplayName: json['institutionCategoryDisplayName']
          ?.toString(),
      institutionCategoryIds: parsedCategoryIds,
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
      createdBy: json['createdBy']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson({bool includeMetadata = false}) {
    return {
      if (id != null && includeMetadata) 'id': id,
      'institutionName': institutionName,
      'institutionShortName': institutionShortName,
      'address': address,
      if (stateId != null) 'stateId': stateId,
      if (districtId != null) 'districtId': districtId,
      if (cityId != null) 'cityId': cityId,
      'pincode': pincode,
      if (email != null) 'email': email,
      if (website != null) 'website': website,
      if (landLine != null) 'landLine': landLine,
      if (mobile != null) 'mobile': mobile,
      if (contributorName != null) 'contributorName': contributorName,
      if (contributorMobileNo != null)
        'contributorMobileNo': contributorMobileNo,
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
    int? districtId,
    String? districtName,
    String? village,
    String? state,
    String? pincode,
    String? email,
    String? website,
    String? landLine,
    String? mobile,
    String? contributorName,
    String? contributorMobileNo,
    String? institutionType,
    String? institutionTypeDisplayName,
    String? institutionCategoryDisplayName,
    List<int>? institutionCategoryIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
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
      districtId: districtId ?? this.districtId,
      districtName: districtName ?? this.districtName,
      village: village ?? this.village,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      email: email ?? this.email,
      website: website ?? this.website,
      landLine: landLine ?? this.landLine,
      mobile: mobile ?? this.mobile,
      contributorName: contributorName ?? this.contributorName,
      contributorMobileNo: contributorMobileNo ?? this.contributorMobileNo,
      institutionType: institutionType ?? this.institutionType,
      institutionTypeDisplayName:
          institutionTypeDisplayName ?? this.institutionTypeDisplayName,
      institutionCategoryDisplayName:
          institutionCategoryDisplayName ?? this.institutionCategoryDisplayName,
      institutionCategoryIds:
          institutionCategoryIds ?? this.institutionCategoryIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
