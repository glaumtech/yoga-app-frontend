import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

const double kPinnedScrollbarThickness = 8;
const double kPinnedScrollbarRadius = 4;
const double kPinnedScrollbarThumbMinLength = 48;
const double kPinnedScrollbarAreaGap = 4;

bool _scrollMetricsReady(ScrollPosition position) {
  return position.hasViewportDimension && position.hasContentDimensions;
}

/// Visual style for pinned scrollbars. Use [PinnedScrollBarStyle.adaptive] for
/// light/dark app screens, or [PinnedScrollBarStyle.dark] for dark panels.
class PinnedScrollBarStyle {
  const PinnedScrollBarStyle({
    required this.trackColor,
    required this.thumbColor,
    required this.thumbActiveColor,
  });

  final Color trackColor;
  final Color thumbColor;
  final Color thumbActiveColor;

  static const PinnedScrollBarStyle dark = PinnedScrollBarStyle(
    trackColor: Color(0xFF3A5070),
    thumbColor: Color(0xFF5B8DEF),
    thumbActiveColor: Color(0xFF7BA8FF),
  );

  static PinnedScrollBarStyle adaptive(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      return dark;
    }
    return PinnedScrollBarStyle(
      trackColor: Colors.grey.shade300,
      thumbColor: Colors.grey.shade500,
      thumbActiveColor: Colors.grey.shade600,
    );
  }
}

/// Reports hover state for showing pinned scrollbars.
class PinnedScrollHoverRegion extends StatefulWidget {
  const PinnedScrollHoverRegion({super.key, required this.builder});

  final Widget Function(BuildContext context, bool isHovered) builder;

  @override
  State<PinnedScrollHoverRegion> createState() =>
      _PinnedScrollHoverRegionState();
}

class _PinnedScrollHoverRegionState extends State<PinnedScrollHoverRegion> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: widget.builder(context, _isHovered),
    );
  }
}

/// Vertical scrollbar with reliable click-and-drag on web.
class PinnedVerticalScrollBar extends StatefulWidget {
  const PinnedVerticalScrollBar({
    super.key,
    required this.controller,
    required this.viewportHeight,
    this.contentHeight,
    this.visible = true,
    this.style,
  });

  final ScrollController controller;
  final double viewportHeight;
  final double? contentHeight;
  final bool visible;
  final PinnedScrollBarStyle? style;

  @override
  State<PinnedVerticalScrollBar> createState() =>
      _PinnedVerticalScrollBarState();
}

class _PinnedVerticalScrollBarState extends State<PinnedVerticalScrollBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScrollChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant PinnedVerticalScrollBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScrollChanged);
      widget.controller.addListener(_onScrollChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScrollChanged);
    super.dispose();
  }

  void _onScrollChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? PinnedScrollBarStyle.adaptive(context);
    const trackWidth = kPinnedScrollbarThickness;
    const thumbMinHeight = kPinnedScrollbarThumbMinLength;

    double viewportDim = widget.viewportHeight;
    double maxScroll = 0;
    double pixels = 0;

    if (widget.controller.hasClients &&
        widget.controller.positions.length == 1) {
      final position = widget.controller.positions.first;
      if (_scrollMetricsReady(position)) {
        viewportDim = position.viewportDimension;
        maxScroll = position.maxScrollExtent;
        pixels = position.pixels;
      }
    } else if (widget.contentHeight != null &&
        widget.contentHeight! > widget.viewportHeight) {
      maxScroll = widget.contentHeight! - widget.viewportHeight;
    }

    final trackHeight = widget.viewportHeight;
    if (!widget.visible || maxScroll <= 0 || trackHeight <= 0) {
      return const SizedBox.shrink();
    }

    final contentHeight = viewportDim + maxScroll;
    final minThumb = math.min(thumbMinHeight, trackHeight);
    final thumbHeight = (trackHeight * viewportDim / contentHeight)
        .clamp(minThumb, trackHeight);
    final scrollableRange = math.max(0.0, trackHeight - thumbHeight);
    final thumbOffset = scrollableRange == 0
        ? 0.0
        : (pixels / maxScroll) * scrollableRange;

    void scrollToThumbCenter(double localY) {
      if (scrollableRange <= 0 || !widget.controller.hasClients) return;
      final target =
          ((localY - thumbHeight / 2) / scrollableRange).clamp(0.0, 1.0);
      widget.controller.jumpTo(target * maxScroll);
    }

    void scrollByDragDelta(double deltaDy) {
      if (scrollableRange <= 0 || !widget.controller.hasClients) return;
      final position = widget.controller.positions.first;
      final scrollDelta = deltaDy * maxScroll / scrollableRange;
      widget.controller.jumpTo(
        (position.pixels + scrollDelta).clamp(0.0, maxScroll),
      );
    }

    return SizedBox(
      width: trackWidth,
      height: trackHeight,
      child: Container(
        decoration: BoxDecoration(
          color: style.trackColor,
          borderRadius: BorderRadius.circular(kPinnedScrollbarRadius),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) =>
                    scrollToThumbCenter(details.localPosition.dy),
                onPanUpdate: (details) => scrollByDragDelta(details.delta.dy),
              ),
            ),
            Positioned(
              top: thumbOffset,
              height: thumbHeight,
              left: 0,
              right: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) => scrollByDragDelta(details.delta.dy),
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Container(
                    decoration: BoxDecoration(
                      color: style.thumbColor,
                      borderRadius:
                          BorderRadius.circular(kPinnedScrollbarRadius),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal scrollbar with reliable click-and-drag on web.
class PinnedHorizontalScrollBar extends StatefulWidget {
  const PinnedHorizontalScrollBar({
    super.key,
    required this.controller,
    required this.viewportWidth,
    this.contentWidth,
    this.visible = true,
    this.style,
  });

  final ScrollController controller;
  final double viewportWidth;
  final double? contentWidth;
  final bool visible;
  final PinnedScrollBarStyle? style;

  @override
  State<PinnedHorizontalScrollBar> createState() =>
      _PinnedHorizontalScrollBarState();
}

class _PinnedHorizontalScrollBarState extends State<PinnedHorizontalScrollBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScrollChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant PinnedHorizontalScrollBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScrollChanged);
      widget.controller.addListener(_onScrollChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScrollChanged);
    super.dispose();
  }

  void _onScrollChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? PinnedScrollBarStyle.adaptive(context);
    const trackHeight = kPinnedScrollbarThickness;
    const thumbMinWidth = kPinnedScrollbarThumbMinLength;

    double viewportDim = widget.viewportWidth;
    double maxScroll = 0;
    double pixels = 0;

    if (widget.controller.hasClients &&
        widget.controller.positions.length == 1) {
      final position = widget.controller.positions.first;
      if (_scrollMetricsReady(position)) {
        viewportDim = position.viewportDimension;
        maxScroll = position.maxScrollExtent;
        pixels = position.pixels;
      }
    } else if (widget.contentWidth != null &&
        widget.contentWidth! > widget.viewportWidth) {
      maxScroll = widget.contentWidth! - widget.viewportWidth;
    }

    final trackWidth = widget.viewportWidth;
    if (!widget.visible || maxScroll <= 0 || trackWidth <= 0) {
      return const SizedBox.shrink();
    }

    final contentWidth = viewportDim + maxScroll;
    final minThumb = math.min(thumbMinWidth, trackWidth);
    final thumbWidth = (trackWidth * viewportDim / contentWidth)
        .clamp(minThumb, trackWidth);
    final scrollableRange = math.max(0.0, trackWidth - thumbWidth);
    final thumbOffset = scrollableRange == 0
        ? 0.0
        : (pixels / maxScroll) * scrollableRange;

    void scrollToThumbCenter(double localX) {
      if (scrollableRange <= 0 || !widget.controller.hasClients) return;
      final target =
          ((localX - thumbWidth / 2) / scrollableRange).clamp(0.0, 1.0);
      widget.controller.jumpTo(target * maxScroll);
    }

    void scrollByDragDelta(double deltaDx) {
      if (scrollableRange <= 0 || !widget.controller.hasClients) return;
      final position = widget.controller.positions.first;
      final scrollDelta = deltaDx * maxScroll / scrollableRange;
      widget.controller.jumpTo(
        (position.pixels + scrollDelta).clamp(0.0, maxScroll),
      );
    }

    return SizedBox(
      height: trackHeight,
      child: Container(
        decoration: BoxDecoration(
          color: style.trackColor,
          borderRadius: BorderRadius.circular(kPinnedScrollbarRadius),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) =>
                    scrollToThumbCenter(details.localPosition.dx),
                onPanUpdate: (details) => scrollByDragDelta(details.delta.dx),
              ),
            ),
            Positioned(
              left: thumbOffset,
              width: thumbWidth,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) => scrollByDragDelta(details.delta.dx),
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Container(
                    decoration: BoxDecoration(
                      color: style.thumbColor,
                      borderRadius:
                          BorderRadius.circular(kPinnedScrollbarRadius),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Drop-in replacement for vertical [SingleChildScrollView] with a pinned
/// scrollbar that supports click and drag on web.
class PinnedVerticalScrollView extends StatefulWidget {
  const PinnedVerticalScrollView({
    super.key,
    required this.child,
    this.controller,
    this.padding,
    this.physics,
    this.primary,
    this.reverse = false,
    this.alwaysShowScrollbar = false,
    this.style,
    this.dragDevices,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool? primary;
  final bool reverse;
  final bool alwaysShowScrollbar;
  final PinnedScrollBarStyle? style;
  final Set<PointerDeviceKind>? dragDevices;

  @override
  State<PinnedVerticalScrollView> createState() =>
      _PinnedVerticalScrollViewState();
}

class _PinnedVerticalScrollViewState extends State<PinnedVerticalScrollView> {
  ScrollController? _ownedController;

  ScrollController get _controller => widget.controller ?? _ownedController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownedController = ScrollController();
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  Widget _buildScrollView() {
    Widget scrollView = SingleChildScrollView(
      controller: _controller,
      padding: widget.padding,
      physics: widget.physics,
      primary: widget.primary,
      reverse: widget.reverse,
      child: widget.child,
    );

    if (widget.dragDevices != null) {
      scrollView = ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: widget.dragDevices,
        ),
        child: scrollView,
      );
    }

    return scrollView;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight > 0;

        if (!hasBoundedHeight) {
          return _buildScrollView();
        }

        final viewportHeight = constraints.maxHeight;

        return PinnedScrollHoverRegion(
          builder: (context, isHovered) {
            final showBar = widget.alwaysShowScrollbar || isHovered;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                _buildScrollView(),
                Positioned(
                  right: 0,
                  top: 0,
                  height: viewportHeight,
                  child: PinnedVerticalScrollBar(
                    controller: _controller,
                    viewportHeight: viewportHeight,
                    visible: showBar,
                    style: widget.style,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Overlays a pinned vertical scrollbar on an existing vertical scrollable
/// (e.g. [ListView]) that uses [controller].
class PinnedVerticalScrollViewport extends StatelessWidget {
  const PinnedVerticalScrollViewport({
    super.key,
    required this.controller,
    required this.child,
    this.alwaysShowScrollbar = false,
    this.style,
  });

  final ScrollController controller;
  final Widget child;
  final bool alwaysShowScrollbar;
  final PinnedScrollBarStyle? style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight &&
            constraints.maxHeight.isFinite &&
            constraints.maxHeight > 0;

        if (!hasBoundedHeight) {
          return child;
        }

        final viewportHeight = constraints.maxHeight;

        return PinnedScrollHoverRegion(
          builder: (context, isHovered) {
            final showBar = alwaysShowScrollbar || isHovered;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                child,
                Positioned(
                  right: 0,
                  top: 0,
                  height: viewportHeight,
                  child: PinnedVerticalScrollBar(
                    controller: controller,
                    viewportHeight: viewportHeight,
                    visible: showBar,
                    style: style,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// [ListView.builder] with a pinned vertical scrollbar.
class PinnedListView extends StatefulWidget {
  const PinnedListView.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.controller,
    this.alwaysShowScrollbar = false,
    this.style,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final ScrollController? controller;
  final bool alwaysShowScrollbar;
  final PinnedScrollBarStyle? style;

  @override
  State<PinnedListView> createState() => _PinnedListViewState();
}

class _PinnedListViewState extends State<PinnedListView> {
  ScrollController? _ownedController;

  ScrollController get _controller => widget.controller ?? _ownedController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownedController = ScrollController();
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PinnedVerticalScrollViewport(
      controller: _controller,
      alwaysShowScrollbar: widget.alwaysShowScrollbar,
      style: widget.style,
      child: ListView.builder(
        controller: _controller,
        padding: widget.padding,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        itemCount: widget.itemCount,
        itemBuilder: widget.itemBuilder,
      ),
    );
  }
}
