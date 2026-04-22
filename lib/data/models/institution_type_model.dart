class InstitutionTypeModel {
  final int id;
  final String typeName;
  final String displayName;
  final int displayOrder;

  InstitutionTypeModel({
    required this.id,
    required this.typeName,
    required this.displayName,
    required this.displayOrder,
  });

  factory InstitutionTypeModel.fromJson(Map<String, dynamic> json) {
    return InstitutionTypeModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      typeName: json['typeName']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      displayOrder: json['displayOrder'] is int
          ? json['displayOrder'] as int
          : int.tryParse(json['displayOrder']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'typeName': typeName,
      'displayName': displayName,
      'displayOrder': displayOrder,
    };
  }
}

