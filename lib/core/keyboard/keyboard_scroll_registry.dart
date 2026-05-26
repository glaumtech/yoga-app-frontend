import 'package:flutter/widgets.dart';

/// Tracks vertical scroll views for global ↑/↓ / Page Up/Down handling.
class KeyboardScrollRegistry {
  KeyboardScrollRegistry._();

  static final List<_ControllerRegistration> _manualControllers =
      <_ControllerRegistration>[];
  static final List<_PositionRegistration> _autoPositions =
      <_PositionRegistration>[];

  static void register({
    required Object token,
    required ScrollController controller,
    required BuildContext scopeContext,
  }) {
    unregister(token);
    _manualControllers.add(
      _ControllerRegistration(
        token: token,
        controller: controller,
        scopeContext: scopeContext,
      ),
    );
  }

  static void unregister(Object token) {
    _manualControllers.removeWhere((r) => r.token == token);
  }

  static void clearAutoDiscovered() {
    _autoPositions.clear();
  }

  static void registerDiscovered({
    required ScrollPosition position,
    required BuildContext scopeContext,
  }) {
    final int id = identityHashCode(position);
    _autoPositions.removeWhere((r) => r.id == id);
    _autoPositions.add(
      _PositionRegistration(
        id: id,
        position: position,
        scopeContext: scopeContext,
      ),
    );
  }

  /// Best vertical [ScrollPosition] for the current focus / visible UI.
  static ScrollPosition? activePosition() {
    final BuildContext? focusContext = primaryFocus?.context;

    if (focusContext != null) {
      final ScrollPosition? fromFocus = _positionUnderFocus(focusContext);
      if (fromFocus != null) {
        return fromFocus;
      }
    }

    for (final _PositionRegistration entry in _autoPositions.reversed) {
      if (_isUsablePosition(entry.position, entry.scopeContext)) {
        return entry.position;
      }
    }

    for (final _ControllerRegistration entry in _manualControllers.reversed) {
      if (!entry.scopeContext.mounted) continue;
      if (entry.controller.hasClients &&
          _canScrollVertically(entry.controller.position)) {
        return entry.controller.position;
      }
    }

    if (focusContext != null) {
      final ScrollableState? scrollable = Scrollable.maybeOf(focusContext);
      if (scrollable != null &&
          scrollable.position.hasPixels &&
          _isVertical(scrollable.axisDirection) &&
          _canScrollVertically(scrollable.position)) {
        return scrollable.position;
      }
    }

    return null;
  }

  static ScrollPosition? _positionUnderFocus(BuildContext focusContext) {
    for (final _ControllerRegistration entry in _manualControllers.reversed) {
      if (!entry.scopeContext.mounted) continue;
      if (!_contains(entry.scopeContext, focusContext)) continue;
      if (entry.controller.hasClients &&
          _canScrollVertically(entry.controller.position)) {
        return entry.controller.position;
      }
    }

    for (final _PositionRegistration entry in _autoPositions.reversed) {
      if (!entry.scopeContext.mounted) continue;
      if (!_contains(entry.scopeContext, focusContext)) continue;
      if (_isUsablePosition(entry.position, entry.scopeContext)) {
        return entry.position;
      }
    }

    return null;
  }

  static bool _isUsablePosition(
    ScrollPosition position,
    BuildContext scopeContext,
  ) {
    if (!scopeContext.mounted || !position.hasPixels) return false;
    if (!_isVertical(position.axisDirection)) return false;
    return _canScrollVertically(position);
  }

  static bool _isVertical(AxisDirection direction) {
    return direction == AxisDirection.down || direction == AxisDirection.up;
  }

  static bool _canScrollVertically(ScrollPosition position) {
    return position.maxScrollExtent > 0;
  }

  static bool _contains(BuildContext ancestor, BuildContext descendant) {
    if (descendant == ancestor) return true;
    var found = false;
    descendant.visitAncestorElements((element) {
      if (element == ancestor) {
        found = true;
        return false;
      }
      return true;
    });
    return found;
  }
}

class _ControllerRegistration {
  _ControllerRegistration({
    required this.token,
    required this.controller,
    required this.scopeContext,
  });

  final Object token;
  final ScrollController controller;
  final BuildContext scopeContext;
}

class _PositionRegistration {
  _PositionRegistration({
    required this.id,
    required this.position,
    required this.scopeContext,
  });

  final int id;
  final ScrollPosition position;
  final BuildContext scopeContext;
}
