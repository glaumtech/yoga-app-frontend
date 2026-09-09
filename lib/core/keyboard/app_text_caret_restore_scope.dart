import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../routes/app_router.dart';
import 'app_text_caret_restore.dart';
import 'app_text_caret_restore_visibility_stub.dart'
    if (dart.library.html) 'app_text_caret_restore_visibility_web.dart'
    as visibility;

class _SavedField {
  const _SavedField(this.node, this.caretOffset);

  final FocusNode node;
  final int caretOffset;
}

/// App-wide caret restore after browser-tab / window / sidebar returns.
///
/// Flutter web uses a **single shared** DOM text-input overlay. Focusing that
/// DOM node does NOT select a Flutter field — it follows whichever
/// [FocusNode] Flutter thinks is focused (often the first field).
///
/// So this restores via Flutter [FocusNode] only:
/// - Remember the field only after real click / key press
/// - Freeze that field when the tab hides (ignore first-field focus steals)
/// - On return, [requestFocus] that same node and re-apply the caret
class AppTextCaretRestoreScope extends StatefulWidget {
  const AppTextCaretRestoreScope({super.key, required this.child});

  final Widget? child;

  @override
  State<AppTextCaretRestoreScope> createState() =>
      _AppTextCaretRestoreScopeState();
}

class _AppTextCaretRestoreScopeState extends State<AppTextCaretRestoreScope>
    with WidgetsBindingObserver {
  AppLifecycleListener? _lifecycleListener;
  void Function()? _cancelVisibilityListen;

  FocusNode? _lastField;
  int _lastCaretOffset = 0;
  _SavedField? _frozen;
  bool _frozenActive = false;

  Timer? _restoreDebounce;
  int _restoreGeneration = 0;
  final Map<String, _SavedField> _byRoute = {};
  String? _lastPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
    HardwareKeyboard.instance.addHandler(_onKey);
    AppRouter.router.routerDelegate.addListener(_onRouteChanged);
    _lastPath = _currentPath();

    _lifecycleListener = AppLifecycleListener(
      onResume: _onVisible,
      onShow: _onVisible,
      onHide: _onHidden,
      onPause: _onHidden,
    );
    _cancelVisibilityListen = visibility.listenToPageBecomeVisible(
      onHidden: _onHidden,
      onVisible: _onVisible,
    );
  }

  @override
  void dispose() {
    _restoreDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    HardwareKeyboard.instance.removeHandler(_onKey);
    AppRouter.router.routerDelegate.removeListener(_onRouteChanged);
    _lifecycleListener?.dispose();
    _cancelVisibilityListen?.call();
    super.dispose();
  }

  String _currentPath() {
    try {
      return AppRouter.router.routeInformationProvider.value.uri.path;
    } catch (_) {
      return '';
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onVisible();
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _onHidden();
    }
  }

  void _onPointer(PointerEvent event) {
    if (_frozenActive) return;
    if (event is! PointerDownEvent && event is! PointerUpEvent) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _frozenActive) return;
      _rememberCurrentField();
    });
  }

  bool _onKey(KeyEvent event) {
    if (_frozenActive) return false;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;
    _rememberCurrentField();
    return false;
  }

  void _rememberCurrentField() {
    if (_frozenActive) return;
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null || !primary.hasFocus) return;
    final editable = _editableOf(primary);
    if (editable == null) return;

    final sel = editable.widget.controller.selection;
    final offset = sel.isValid
        ? sel.extentOffset.clamp(0, editable.widget.controller.text.length)
        : editable.widget.controller.text.length;

    _lastField = primary;
    _lastCaretOffset = offset;
    _byRoute[_currentPath()] = _SavedField(primary, offset);
  }

  void _onHidden() {
    if (_frozenActive) return;

    // Snapshot the last user field BEFORE Flutter moves focus to field #1.
    final saved = _lastField != null
        ? _SavedField(_lastField!, _lastCaretOffset)
        : null;
    _frozen = saved;
    _frozenActive = true;
    AppTextCaretRestore.suppressFocusTracking = true;

    final path = _currentPath();
    if (saved != null) {
      _byRoute[path] = saved;
    }
  }

  void _onVisible() {
    final saved = _frozen ?? _byRoute[_currentPath()];
    if (saved == null) {
      _clearFreeze();
      return;
    }
    _scheduleRestore(saved);
  }

  void _onRouteChanged() {
    final newPath = _currentPath();
    final oldPath = _lastPath;
    _lastPath = newPath;

    if (oldPath != null &&
        oldPath != newPath &&
        _lastField != null &&
        !_frozenActive) {
      _byRoute[oldPath] = _SavedField(_lastField!, _lastCaretOffset);
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final saved = _byRoute[newPath];
      if (saved == null) return;
      if (!_canRestore(saved.node)) return;
      _scheduleRestore(saved);
    });
  }

  bool _canRestore(FocusNode node) {
    if (!node.canRequestFocus) return false;
    final ctx = node.context;
    if (ctx == null || !ctx.mounted) return false;
    // IndexedStack offstage pages are not "current"; skip those.
    final route = ModalRoute.of(ctx);
    if (route != null && !route.isCurrent) return false;
    return true;
  }

  void _scheduleRestore(_SavedField saved) {
    _restoreDebounce?.cancel();
    final generation = ++_restoreGeneration;
    _frozenActive = true;
    AppTextCaretRestore.suppressFocusTracking = true;

    // Flutter often assigns focus to the first field a moment after the tab
    // becomes visible — retry until our field wins.
    const delays = <int>[0, 50, 120, 250, 450];
    for (final ms in delays) {
      Future<void>.delayed(Duration(milliseconds: ms), () {
        if (!mounted || generation != _restoreGeneration) return;
        _applyRestore(saved);
      });
    }

    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || generation != _restoreGeneration) return;
      _clearFreeze();
      // Keep remembered field as the one we restored.
      if (saved.node.hasFocus) {
        _lastField = saved.node;
        _lastCaretOffset = saved.caretOffset;
        _byRoute[_currentPath()] = saved;
      }
    });
  }

  void _applyRestore(_SavedField saved) {
    final node = saved.node;
    if (!_canRestore(node)) return;

    // Drop whatever first-field focus Flutter assigned, then take ours.
    final primary = FocusManager.instance.primaryFocus;
    if (primary != null && !identical(primary, node) && primary.hasFocus) {
      primary.unfocus(disposition: UnfocusDisposition.scope);
    }

    node.requestFocus();

    final editable = _editableOf(node);
    if (editable == null) return;

    final controller = editable.widget.controller;
    final text = controller.text;
    final offset = saved.caretOffset.clamp(0, text.length);
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
    editable.requestKeyboard();

    if (kDebugMode) {
      // ignore: avoid_print
      debugPrint(
        '[AppTextCaretRestore] restored focus '
        'hasFocus=${node.hasFocus} offset=$offset',
      );
    }
  }

  void _clearFreeze() {
    _frozenActive = false;
    _frozen = null;
    AppTextCaretRestore.suppressFocusTracking = false;
  }

  EditableTextState? _editableOf(FocusNode node) {
    final context = node.context;
    if (context == null) return null;

    EditableTextState? found;
    context.visitAncestorElements((element) {
      if (element is StatefulElement && element.state is EditableTextState) {
        found = element.state as EditableTextState;
        return false;
      }
      return true;
    });
    if (found != null) return found;

    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is EditableTextState) {
        found = element.state as EditableTextState;
        return;
      }
      element.visitChildren(visit);
    }

    if (context is Element) {
      context.visitChildren(visit);
    }
    return found;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? const SizedBox.shrink();
  }
}
