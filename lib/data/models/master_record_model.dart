class MasterRecordModel {
  final int id;
  final String name;
  final String? description;

  const MasterRecordModel({
    required this.id,
    required this.name,
    this.description,
  });

  String get subtitle {
    if (description != null && description!.trim().isNotEmpty) {
      return description!.trim();
    }
    return '';
  }

  factory MasterRecordModel.fromJson(Map<String, dynamic> json) {
    return MasterRecordModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ??
          json['categoryName']?.toString() ??
          json['stageName']?.toString() ??
          json['prizeName']?.toString() ??
          '',
      description: json['description']?.toString(),
    );
  }
}
