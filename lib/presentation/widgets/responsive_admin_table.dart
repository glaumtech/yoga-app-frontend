import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'pinned_scroll_views.dart';

/// Horizontal scroll wrapper with a visible scrollbar when content overflows.
class HorizontalScrollTable extends StatefulWidget {
  final Widget child;
  final double minWidth;
  final EdgeInsetsGeometry padding;

  const HorizontalScrollTable({
    super.key,
    required this.child,
    required this.minWidth,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<HorizontalScrollTable> createState() => _HorizontalScrollTableState();
}

class _HorizontalScrollTableState extends State<HorizontalScrollTable> {
  late final ScrollController _horizontalScrollController;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var availableWidth = constraints.maxWidth;
        if (!availableWidth.isFinite || availableWidth <= 0) {
          availableWidth = MediaQuery.sizeOf(context).width;
        }

        final contentWidth = math.max(widget.minWidth, availableWidth);
        final needsHorizontalScroll = contentWidth > availableWidth + 1;

        return Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: needsHorizontalScroll,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: widget.padding,
              child: SizedBox(
                width: contentWidth,
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

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
        flexTotal += width.value;
      }
    }

    return fixedTotal + (flexTotal * minFlexColumnWidth) + columnWidths.length;
  }

  /// Wraps [table] so [RefreshIndicator] can pull-to-refresh without nesting
  /// vertical and horizontal scroll views inside the table widget.
  static Widget refreshable({
    required Future<void> Function() onRefresh,
    required Widget table,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: PinnedVerticalScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: table,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final minRequired = computeMinTableWidth(
      columnWidths,
      minFlexColumnWidth: minFlexColumnWidth,
    );

    return HorizontalScrollTable(
      minWidth: minRequired,
      padding: padding,
      child: Table(
        border: border ?? TableBorder.all(color: Colors.grey[300]!, width: 1),
        columnWidths: columnWidths,
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: rows,
      ),
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
