class CompetitionGradeModel {
  const CompetitionGradeModel({
    required this.gradeName,
    required this.markRangeMin,
    required this.markRangeMax,
  });

  final String gradeName;
  final int markRangeMin;
  final int markRangeMax;

  String get markRangeLabel => '$markRangeMin - $markRangeMax';

  factory CompetitionGradeModel.fromJson(Map<String, dynamic> json) {
    return CompetitionGradeModel(
      gradeName: json['gradeName']?.toString() ?? '',
      markRangeMin: _parseInt(json['markRangeMin']) ?? 0,
      markRangeMax: _parseInt(json['markRangeMax']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gradeName': gradeName,
      'markRangeMin': markRangeMin,
      'markRangeMax': markRangeMax,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
