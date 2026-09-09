/// Shared flag so form controllers ignore Flutter's first-field focus steal
/// while a browser tab is hidden / caret is being restored.
class AppTextCaretRestore {
  AppTextCaretRestore._();

  static bool suppressFocusTracking = false;
}
