import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'pinned_scroll_views.dart';

/// Horizontal scroll wrapper with a scrollbar pinned to the visible viewport
/// when height is bounded (so it stays visible without scrolling to the bottom).
class HorizontalScrollTable extends StatefulWidget {
  final Widget child;
  final double minWidth;
  final EdgeInsetsGeometry padding;
  final bool enableVerticalScroll;

  const HorizontalScrollTable({
    super.key,
    required this.child,
    required this.minWidth,
    this.padding = EdgeInsets.zero,
    this.enableVerticalScroll = true,
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

  Widget _buildHorizontalBody(double contentWidth) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        primary: false,
        child: Padding(
          padding: widget.padding,
          child: SizedBox(
            width: contentWidth,
            child: widget.child,
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedHorizontalBar({
    required double viewportWidth,
    required bool visible,
  }) {
    if (!visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: kPinnedScrollbarAreaGap),
      child: PinnedHorizontalScrollBar(
        controller: _horizontalScrollController,
        viewportWidth: viewportWidth,
        visible: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var availableWidth = constraints.maxWidth;
        if (!availableWidth.isFinite || availableWidth <= 0) {
          availableWidth = MediaQuery.sizeOf(context).width;
        }
        // Guard against absurd/unbounded widths that blow Expanded table rows.
        final screenW = MediaQuery.sizeOf(context).width;
        if (availableWidth > screenW * 2 || availableWidth > 4000) {
          availableWidth = screenW;
        }

        final contentWidth = math.max(widget.minWidth, availableWidth);
        final needsHorizontalScroll = contentWidth > availableWidth + 1;

        final hasBoundedHeight = constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight > 0;

        final horizontalBody = _buildHorizontalBody(contentWidth);

        // Bounded height: keep the horizontal bar pinned to the viewport bottom
        // so users do not need to scroll vertically to find it.
        if (hasBoundedHeight && widget.enableVerticalScroll) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: PinnedVerticalScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: horizontalBody,
                ),
              ),
              _buildPinnedHorizontalBar(
                viewportWidth: availableWidth,
                visible: needsHorizontalScroll,
              ),
            ],
          );
        }

        // Unbounded height (e.g. nested in another scroller): bar follows content.
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            horizontalBody,
            _buildPinnedHorizontalBar(
              viewportWidth: availableWidth,
              visible: needsHorizontalScroll,
            ),
          ],
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

  /// Wraps [table] so [RefreshIndicator] can pull-to-refresh and the table
  /// receives a bounded height (needed to pin the horizontal scrollbar).
  static Widget refreshable({
    required Future<void> Function() onRefresh,
    required Widget table,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: SizedBox(
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            child: table,
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
