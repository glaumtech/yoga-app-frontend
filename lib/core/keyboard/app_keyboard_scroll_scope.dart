import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App-wide keyboard scrolling: arrow keys and Page Up/Down dispatch
/// [ScrollIntent], handled by Flutter's [ScrollAction].
///
/// Use from [MaterialApp.builder] / [MaterialApp.router] `builder` so the
/// subtree sits under the same [FocusManager] and [Navigator] as your routes.
///
/// Text fields and other controls that consume arrow keys keep priority when
/// they have focus; [ScrollAction] only scrolls appropriate [Scrollable]s.
class AppKeyboardScrollScope extends StatelessWidget {
  const AppKeyboardScrollScope({super.key, required this.child});

  final Widget? child;

  static final Map<ShortcutActivator, Intent> _shortcuts =
      <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.arrowUp): const ScrollIntent(
          direction: AxisDirection.up,
        ),
        const SingleActivator(LogicalKeyboardKey.arrowDown): const ScrollIntent(
          direction: AxisDirection.down,
        ),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): const ScrollIntent(
          direction: AxisDirection.left,
        ),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            const ScrollIntent(direction: AxisDirection.right),
        const SingleActivator(LogicalKeyboardKey.pageUp): const ScrollIntent(
          direction: AxisDirection.up,
          type: ScrollIncrementType.page,
        ),
        const SingleActivator(LogicalKeyboardKey.pageDown): const ScrollIntent(
          direction: AxisDirection.down,
          type: ScrollIncrementType.page,
        ),
      };

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{ScrollIntent: ScrollAction()},
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
