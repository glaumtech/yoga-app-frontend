import 'package:flutter/material.dart';

import '../navigation/root_navigator_key.dart';

/// Dialogs without [GetMaterialApp] (app uses [MaterialApp.router] + GoRouter).
class DialogHelper {
  static BuildContext? get _context => rootNavigatorKey.currentContext;

  static Future<bool> confirm({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final context = _context;
    if (context == null || !context.mounted) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelText),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result == true;
  }
}
