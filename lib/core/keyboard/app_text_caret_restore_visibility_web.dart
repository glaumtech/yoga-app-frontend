import 'dart:html' as html;

/// Fires [onHidden] / [onVisible] for browser tab visibility and window focus.
/// Flutter's [AppLifecycleListener] alone is not reliable on web.
void Function()? listenToPageBecomeVisible({
  required void Function() onHidden,
  required void Function() onVisible,
}) {
  void handleVisibility([_]) {
    if (html.document.hidden == true) {
      onHidden();
    } else {
      onVisible();
    }
  }

  void handleWindowBlur([_]) => onHidden();

  void handleWindowFocus([_]) {
    if (html.document.hidden == true) return;
    onVisible();
  }

  final visibilitySub =
      html.document.onVisibilityChange.listen(handleVisibility);
  final focusSub = html.window.onFocus.listen(handleWindowFocus);
  final blurSub = html.window.onBlur.listen(handleWindowBlur);

  return () {
    visibilitySub.cancel();
    focusSub.cancel();
    blurSub.cancel();
  };
}
