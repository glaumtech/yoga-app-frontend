import 'package:flutter/material.dart';

import '../../data/models/category_config_model.dart';

class IncreaseCountRangeEntry {
  IncreaseCountRangeEntry({
    String from = '',
    String to = '',
    String count = '',
    String? rowId,
  })  : rowId = rowId ??
            'inc-${DateTime.now().microsecondsSinceEpoch}-${_nextRowId++}',
        fromController = TextEditingController(text: from),
        toController = TextEditingController(text: to),
        countController = TextEditingController(text: count);

  static int _nextRowId = 0;

  final String rowId;
  final TextEditingController fromController;
  final TextEditingController toController;
  final TextEditingController countController;

  bool get isComplete =>
      fromController.text.trim().isNotEmpty &&
      toController.text.trim().isNotEmpty &&
      countController.text.trim().isNotEmpty;

  IncreaseCountRangeModel? toModel() {
    if (!isComplete) return null;
    final from = int.tryParse(fromController.text.trim());
    final to = int.tryParse(toController.text.trim());
    final count = int.tryParse(countController.text.trim());
    if (from == null || to == null || count == null) return null;
    return IncreaseCountRangeModel(from: from, to: to, count: count);
  }

  factory IncreaseCountRangeEntry.fromModel(IncreaseCountRangeModel model) {
    return IncreaseCountRangeEntry(
      from: model.from.toString(),
      to: model.to.toString(),
      count: model.count.toString(),
    );
  }

  void dispose() {
    fromController.dispose();
    toController.dispose();
    countController.dispose();
  }
}
