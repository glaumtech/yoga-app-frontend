class CompetitionOptionModel {
  final int id;
  final String name;

  CompetitionOptionModel({required this.id, required this.name});

  factory CompetitionOptionModel.fromJson(Map<String, dynamic> json) {
    return CompetitionOptionModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ??
            json['stageName']?.toString() ??
            json['categoryName']?.toString() ??
            json['groupName']?.toString() ??
            '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
