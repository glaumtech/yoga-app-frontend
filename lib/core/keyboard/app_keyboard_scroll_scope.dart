import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'keyboard_scroll_action.dart';
import 'keyboard_scroll_discovery.dart';

/// App-wide keyboard scrolling: arrow keys and Page Up/Down scroll vertical
/// content on every screen (via [KeyboardScrollDiscovery] + registry).
///
/// A [HardwareKeyboard] handler is used because web text fields (and some
/// desktop shortcuts) consume arrow keys before [Shortcuts] run.
class AppKeyboardScrollScope extends StatefulWidget {
  const AppKeyboardScrollScope({super.key, required this.child});

  final Widget? child;

  /// Shortcuts merged into [MaterialApp.shortcuts]: plain ↑/↓ scroll instead
  /// of focus traversal on desktop.
  static Map<ShortcutActivator, Intent> mergeAppShortcuts(
    Map<ShortcutActivator, Intent> base,
  ) {
    final merged = Map<ShortcutActivator, Intent>.from(base);
    const scrollUp = ScrollIntent(direction: AxisDirection.up);
    const scrollDown = ScrollIntent(direction: AxisDirection.down);
    const scrollLeft = ScrollIntent(direction: AxisDirection.left);
    const scrollRight = ScrollIntent(direction: AxisDirection.right);
    const pageUp = ScrollIntent(
      direction: AxisDirection.up,
      type: ScrollIncrementType.page,
    );
    const pageDown = ScrollIntent(
      direction: AxisDirection.down,
      type: ScrollIncrementType.page,
    );

    merged[const SingleActivator(LogicalKeyboardKey.arrowUp)] = scrollUp;
    merged[const SingleActivator(LogicalKeyboardKey.arrowDown)] = scrollDown;
    merged[const SingleActivator(LogicalKeyboardKey.pageUp)] = pageUp;
    merged[const SingleActivator(LogicalKeyboardKey.pageDown)] = pageDown;

    if (!kIsWeb) {
      merged[const SingleActivator(LogicalKeyboardKey.arrowLeft)] = scrollLeft;
      merged[const SingleActivator(LogicalKeyboardKey.arrowRight)] = scrollRight;
    }

    return merged;
  }

  @override
  State<AppKeyboardScrollScope> createState() => _AppKeyboardScrollScopeState();
}

class _AppKeyboardScrollScopeState extends State<AppKeyboardScrollScope> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    return KeyboardScrollAction.handleKeyEvent(event);
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        ScrollIntent: KeyboardScrollAction(),
      },
      child: KeyboardScrollDiscovery(
        child: widget.child ?? const SizedBox.shrink(),
      ),
    );
  }
}
