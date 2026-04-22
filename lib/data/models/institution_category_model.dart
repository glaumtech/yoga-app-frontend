class InstitutionCategoryModel {
  final int id;
  final String categoryName;
  final String displayName;
  final int institutionTypeId;
  final int displayOrder;

  InstitutionCategoryModel({
    required this.id,
    required this.categoryName,
    required this.displayName,
    required this.institutionTypeId,
    required this.displayOrder,
  });

  factory InstitutionCategoryModel.fromJson(Map<String, dynamic> json) {
    return InstitutionCategoryModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      categoryName: json['categoryName']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      institutionTypeId: json['institutionTypeId'] is int
          ? json['institutionTypeId'] as int
          : int.tryParse(json['institutionTypeId'].toString()) ?? 0,
      displayOrder: json['displayOrder'] is int
          ? json['displayOrder'] as int
          : int.tryParse(json['displayOrder']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryName': categoryName,
      'displayName': displayName,
      'institutionTypeId': institutionTypeId,
      'displayOrder': displayOrder,
    };
  }
}

