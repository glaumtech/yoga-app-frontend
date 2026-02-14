class SchoolModel {
  final String? id;
  final String institutionName;
  final String address;
  final String district;
  final String state;
  final String pincode;
  final String institutionType; // 'Private School', 'Govt / Govt Aided School', 'Private College', 'Govt / Govt Aided College'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SchoolModel({
    this.id,
    required this.institutionName,
    required this.address,
    required this.district,
    required this.state,
    required this.pincode,
    required this.institutionType,
    this.createdAt,
    this.updatedAt,
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      institutionName: json['institutionName']?.toString() ??
          json['institution_name']?.toString() ??
          '',
      address: json['address']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      institutionType: json['institutionType']?.toString() ??
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
      'district': district,
      'state': state,
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
      district: district ?? this.district,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      institutionType: institutionType ?? this.institutionType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

