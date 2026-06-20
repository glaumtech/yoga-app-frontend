import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Scrollable admin [Table] that never overflows on narrow viewports.
///
/// Uses a computed minimum width (fixed columns + flex minimums) and expands
/// to fill wider layouts so flex columns grow on large screens.
class ResponsiveAdminTable extends StatelessWidget {
  final Map<int, TableColumnWidth> columnWidths;
  final List<TableRow> rows;
  final double minFlexColumnWidth;
  final TableBorder? border;
  final EdgeInsetsGeometry padding;

  const ResponsiveAdminTable({
    super.key,
    required this.columnWidths,
    required this.rows,
    this.minFlexColumnWidth = 72,
    this.border,
    this.padding = const EdgeInsets.all(16),
  });

  static double computeMinTableWidth(
    Map<int, TableColumnWidth> columnWidths, {
    double minFlexColumnWidth = 72,
  }) {
    var fixedTotal = 0.0;
    var flexTotal = 0.0;

    for (final width in columnWidths.values) {
      if (width is FixedColumnWidth) {
        fixedTotal += width.value;
      } else if (width is FlexColumnWidth) {
        flexTotal += (width.flex as num?)?.toDouble() ?? 1.0;
      }
    }

    return fixedTotal + (flexTotal * minFlexColumnWidth) + columnWidths.length;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var availableWidth = constraints.maxWidth;
        if (!availableWidth.isFinite || availableWidth <= 0) {
          availableWidth = MediaQuery.sizeOf(context).width;
        }

        final minRequired = computeMinTableWidth(
          columnWidths,
          minFlexColumnWidth: minFlexColumnWidth,
        );
        final tableWidth = math.max(minRequired, availableWidth);

        return Scrollbar(
          thumbVisibility: tableWidth > availableWidth + 1,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Scrollbar(
              thumbVisibility: tableWidth > availableWidth + 1,
              notificationPredicate: (notification) =>
                  notification.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: padding,
                  child: SizedBox(
                    width: tableWidth,
                    child: Table(
                      border:
                          border ??
                          TableBorder.all(color: Colors.grey[300]!, width: 1),
                      columnWidths: columnWidths,
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: rows,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Keeps icon action rows inside their table cell on any width/DPR.
class AdminTableActionCell extends StatelessWidget {
  final List<Widget> actions;

  const AdminTableActionCell({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Align(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: actions,
          ),
        ),
      ),
    );
  }
}
