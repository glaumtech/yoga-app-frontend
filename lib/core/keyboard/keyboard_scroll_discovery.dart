import 'package:flutter/widgets.dart';

import 'keyboard_scroll_registry.dart';

/// Walks the subtree after layout and registers every vertical [Scrollable]
/// so arrow-key scrolling works without wrapping each screen manually.
class KeyboardScrollDiscovery extends StatefulWidget {
  const KeyboardScrollDiscovery({super.key, required this.child});

  final Widget child;

  @override
  State<KeyboardScrollDiscovery> createState() => _KeyboardScrollDiscoveryState();
}

class _KeyboardScrollDiscoveryState extends State<KeyboardScrollDiscovery> {
  bool _discoverScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleDiscover();
  }

  @override
  void didUpdateWidget(KeyboardScrollDiscovery oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleDiscover();
  }

  void _scheduleDiscover() {
    if (_discoverScheduled) return;
    _discoverScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _discoverScheduled = false;
      if (!mounted) return;
      _discoverScrollables();
    });
  }

  void _discoverScrollables() {
    KeyboardScrollRegistry.clearAutoDiscovered();

    void visit(Element element) {
      if (element is StatefulElement) {
        final State<StatefulWidget> state = element.state;
        if (state is ScrollableState) {
          final AxisDirection axis = state.axisDirection;
          if (axis == AxisDirection.down || axis == AxisDirection.up) {
            final ScrollPosition position = state.position;
            if (position.hasPixels) {
              KeyboardScrollRegistry.registerDiscovered(
                position: position,
                scopeContext: element,
              );
            }
          }
        }
      }
      element.visitChildren(visit);
    }

    final Element root = context as Element;
    root.visitChildren(visit);
  }

  @override
  Widget build(BuildContext context) {
    _scheduleDiscover();
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        _scheduleDiscover();
        return false;
      },
      child: widget.child,
    );
  }
}
