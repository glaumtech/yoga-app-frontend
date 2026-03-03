class InstitutionTypeModel {
  final int id;
  final String typeName;
  final String displayName;

  InstitutionTypeModel({
    required this.id,
    required this.typeName,
    required this.displayName,
  });

  factory InstitutionTypeModel.fromJson(Map<String, dynamic> json) {
    return InstitutionTypeModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      typeName: json['typeName']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'typeName': typeName,
      'displayName': displayName,
    };
  }
}

