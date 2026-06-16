import '../../data/models/competition_grade_model.dart';

class CompetitionGradeResolver {
  static List<CompetitionGradeModel> parseGrades(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => CompetitionGradeModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((grade) => grade.gradeName.trim().isNotEmpty)
        .toList();
  }

  static String? resolveGradeName(
    List<CompetitionGradeModel> grades,
    double score,
  ) {
    if (grades.isEmpty) return null;
    final value = double.parse(score.toStringAsFixed(2));
    for (final grade in grades) {
      if (value >= grade.markRangeMin && value <= grade.markRangeMax) {
        return grade.gradeName;
      }
    }
    return null;
  }

  static void applyGradeToRow(
    Map<String, dynamic> row,
    List<CompetitionGradeModel> grades,
  ) {
    if (grades.isEmpty) return;
    final existing = (row['gradeName'] ?? '').toString().trim();
    if (existing.isNotEmpty) return;

    final score = double.tryParse(
      (row['totalGrandTotal'] ?? row['avgGrandTotal'] ?? row['totalScore'] ?? 0)
          .toString(),
    );
    if (score == null) return;

    final resolved = resolveGradeName(grades, score);
    if (resolved != null && resolved.trim().isNotEmpty) {
      row['gradeName'] = resolved;
    }
  }
}
