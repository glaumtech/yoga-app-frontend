import 'dart:html' as html;

/// Fires [onHidden] / [onVisible] only when the browser tab is actually hidden.
///
/// Window blur/focus is not a hide. Flutter web moves DOM focus into its text
/// input on every keystroke, and the browser also blurs when DevTools or the
/// address bar is used. Treating that as a hide/show made caret restore call
/// `requestKeyboard` in a loop and tripped engine asserts
/// (`Could not find View with id 0`, `isEnabled`, disposed view render).
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

  final visibilitySub =
      html.document.onVisibilityChange.listen(handleVisibility);

  return visibilitySub.cancel;
}
