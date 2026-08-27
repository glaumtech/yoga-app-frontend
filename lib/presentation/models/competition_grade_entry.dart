import 'package:flutter/material.dart';

import '../../data/models/competition_grade_model.dart';

class CompetitionGradeEntry {
  CompetitionGradeEntry({
    String gradeName = '',
    String markRangeMin = '',
    String markRangeMax = '',
    String? rowId,
  })  : rowId = rowId ?? 'grade-${DateTime.now().microsecondsSinceEpoch}-${_nextRowId++}',
        nameController = TextEditingController(text: gradeName),
        minMarkController = TextEditingController(text: markRangeMin),
        maxMarkController = TextEditingController(text: markRangeMax);

  static int _nextRowId = 0;

  final String rowId;
  final TextEditingController nameController;
  final TextEditingController minMarkController;
  final TextEditingController maxMarkController;

  bool get hasAnyInput =>
      nameController.text.trim().isNotEmpty ||
      minMarkController.text.trim().isNotEmpty ||
      maxMarkController.text.trim().isNotEmpty;

  bool get isComplete =>
      nameController.text.trim().isNotEmpty &&
      minMarkController.text.trim().isNotEmpty &&
      maxMarkController.text.trim().isNotEmpty;

  CompetitionGradeModel? toModel() {
    if (!isComplete) return null;
    final min = int.tryParse(minMarkController.text.trim());
    final max = int.tryParse(maxMarkController.text.trim());
    if (min == null || max == null) return null;
    return CompetitionGradeModel(
      gradeName: nameController.text.trim(),
      markRangeMin: min,
      markRangeMax: max,
    );
  }

  factory CompetitionGradeEntry.fromModel(CompetitionGradeModel model) {
    return CompetitionGradeEntry(
      gradeName: model.gradeName,
      markRangeMin: model.markRangeMin.toString(),
      markRangeMax: model.markRangeMax.toString(),
    );
  }

  void dispose() {
    nameController.dispose();
    minMarkController.dispose();
    maxMarkController.dispose();
  }
}
