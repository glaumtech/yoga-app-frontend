import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'keyboard_scroll_registry.dart';

/// Scrolls using [controller], or the nearest [Scrollable] above [primaryFocus].
class KeyboardScrollAction extends Action<ScrollIntent> {
  KeyboardScrollAction({this.controller});

  final ScrollController? controller;

  @override
  bool isEnabled(ScrollIntent intent, [BuildContext? context]) {
    return _resolvePosition(context) != null;
  }

  ScrollPosition? _resolvePosition([BuildContext? context]) {
    if (controller != null && controller!.hasClients) {
      return controller!.position;
    }

    final ScrollPosition? registered = KeyboardScrollRegistry.activePosition();
    if (registered != null && registered.hasPixels) {
      return registered;
    }

    final BuildContext? focusContext = primaryFocus?.context ?? context;
    if (focusContext != null) {
      final ScrollableState? scrollable = Scrollable.maybeOf(focusContext);
      if (scrollable != null && scrollable.position.hasPixels) {
        return scrollable.position;
      }
    }

    if (context != null) {
      final ScrollController? primary = PrimaryScrollController.maybeOf(context);
      if (primary != null && primary.hasClients) {
        return primary.position;
      }
    }

    return null;
  }

  @override
  Object? invoke(ScrollIntent intent, [BuildContext? context]) {
    final ScrollPosition? position = _resolvePosition(context);
    if (position == null) {
      return null;
    }
    applyScrollIntent(position, intent);
    return null;
  }

  /// Returns true if the scroll position changed (or an animation started).
  static bool applyScrollIntent(ScrollPosition position, ScrollIntent intent) {
    if (!position.hasPixels) {
      return false;
    }

    final ScrollPhysics physics = position.physics;
    if (!physics.shouldAcceptUserOffset(position)) {
      return false;
    }

    final double increment = switch (intent.type) {
      ScrollIncrementType.line => 50.0,
      ScrollIncrementType.page => 0.8 * position.viewportDimension,
    };

    final bool scrollDown =
        intent.direction == AxisDirection.down ||
        intent.direction == AxisDirection.right;
    final double target = (position.pixels + (scrollDown ? increment : -increment))
        .clamp(position.minScrollExtent, position.maxScrollExtent);

    if (target == position.pixels) {
      return false;
    }

    void applyScroll() {
      position.moveTo(
        target,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
      );
    }

    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      applyScroll();
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) => applyScroll());
    }
    return true;
  }

  /// Handles a physical key press (used on web where text fields block shortcuts).
  static bool handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }

    final ScrollIntent? intent = _intentForKey(event.logicalKey);
    if (intent == null) {
      return false;
    }

    final ScrollPosition? position = KeyboardScrollRegistry.activePosition();
    if (position == null) {
      return false;
    }

    return applyScrollIntent(position, intent);
  }

  static ScrollIntent? _intentForKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp) {
      return const ScrollIntent(direction: AxisDirection.up);
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      return const ScrollIntent(direction: AxisDirection.down);
    }
    if (key == LogicalKeyboardKey.pageUp) {
      return const ScrollIntent(
        direction: AxisDirection.up,
        type: ScrollIncrementType.page,
      );
    }
    if (key == LogicalKeyboardKey.pageDown) {
      return const ScrollIntent(
        direction: AxisDirection.down,
        type: ScrollIncrementType.page,
      );
    }
    return null;
  }
}
