import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../presentation/widgets/pinned_scroll_views.dart';
import 'keyboard_scroll_action.dart';
import 'keyboard_scroll_registry.dart';

/// Wraps a vertical [SingleChildScrollView] so ↑/↓ and Page Up/Down scroll it,
/// including on **web** while a [TextFormField] inside has focus.
class KeyboardScrollable extends StatefulWidget {
  const KeyboardScrollable({
    super.key,
    required this.child,
    this.padding,
    this.controller,
    this.physics,
    this.primary,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool? primary;

  @override
  State<KeyboardScrollable> createState() => _KeyboardScrollableState();
}

class _KeyboardScrollableState extends State<KeyboardScrollable> {
  ScrollController? _ownedController;
  static int _nextToken = 0;
  late final Object _registryToken = 'KeyboardScrollable#${ _nextToken++ }';

  ScrollController get _controller => widget.controller ?? _ownedController!;

  static final Map<ShortcutActivator, Intent> _shortcuts =
      <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.arrowUp): const ScrollIntent(
          direction: AxisDirection.up,
        ),
        const SingleActivator(LogicalKeyboardKey.arrowDown): const ScrollIntent(
          direction: AxisDirection.down,
        ),
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
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownedController = ScrollController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRegistry());
  }

  @override
  void didUpdateWidget(KeyboardScrollable oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRegistry());
  }

  void _syncRegistry() {
    if (!mounted) return;
    KeyboardScrollRegistry.register(
      token: _registryToken,
      controller: _controller,
      scopeContext: context,
    );
  }

  @override
  void dispose() {
    KeyboardScrollRegistry.unregister(_registryToken);
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          ScrollIntent: KeyboardScrollAction(controller: _controller),
        },
        child: PinnedVerticalScrollView(
          controller: _controller,
          padding: widget.padding,
          physics: widget.physics,
          primary: widget.primary,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Adds keyboard scroll shortcuts around an existing scrollable that uses
/// [controller] (e.g. [ListView.builder]).
class KeyboardScrollableViewport extends StatefulWidget {
  const KeyboardScrollableViewport({
    super.key,
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  State<KeyboardScrollableViewport> createState() =>
      _KeyboardScrollableViewportState();
}

class _KeyboardScrollableViewportState extends State<KeyboardScrollableViewport> {
  static int _nextToken = 0;
  late final Object _registryToken = 'KeyboardScrollableViewport#${ _nextToken++ }';

  static final Map<ShortcutActivator, Intent> _shortcuts =
      <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.arrowUp): const ScrollIntent(
          direction: AxisDirection.up,
        ),
        const SingleActivator(LogicalKeyboardKey.arrowDown): const ScrollIntent(
          direction: AxisDirection.down,
        ),
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRegistry());
  }

  @override
  void didUpdateWidget(KeyboardScrollableViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncRegistry());
  }

  void _syncRegistry() {
    if (!mounted) return;
    KeyboardScrollRegistry.register(
      token: _registryToken,
      controller: widget.controller,
      scopeContext: context,
    );
  }

  @override
  void dispose() {
    KeyboardScrollRegistry.unregister(_registryToken);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          ScrollIntent: KeyboardScrollAction(controller: widget.controller),
        },
        child: PinnedVerticalScrollViewport(
          controller: widget.controller,
          child: widget.child,
        ),
      ),
    );
  }
}

/// [ListView] with keyboard ↑/↓ / Page Up/Down scrolling.
class KeyboardScrollableList extends StatefulWidget {
  const KeyboardScrollableList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.physics,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  @override
  State<KeyboardScrollableList> createState() => _KeyboardScrollableListState();
}

class _KeyboardScrollableListState extends State<KeyboardScrollableList> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardScrollableViewport(
      controller: _controller,
      child: ListView.builder(
        controller: _controller,
        padding: widget.padding,
        physics: widget.physics,
        itemCount: widget.itemCount,
        itemBuilder: widget.itemBuilder,
      ),
    );
  }
}
