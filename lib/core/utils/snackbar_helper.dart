import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../navigation/root_scaffold_messenger_key.dart';

/// Top-right floating snackbars with a readable width.
class SnackbarHelper {
  static const double _minWidth = 320;
  static const double _maxWidth = 480;
  static const double _widthFraction = 0.38;

  static ScaffoldMessengerState? _messenger(BuildContext? context) {
    return rootScaffoldMessengerKey.currentState ??
        (context != null ? ScaffoldMessenger.maybeOf(context) : null);
  }

  static MediaQueryData _media(BuildContext? context) {
    if (context != null && context.mounted) {
      return MediaQuery.of(context);
    }
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return MediaQueryData.fromView(view);
  }

  static void _show(
    BuildContext? context, {
    required String message,
    required Color backgroundColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = _messenger(context);
    if (messenger == null) return;

    final media = _media(context);
    final screenWidth = media.size.width;
    final width = math.min(
      _maxWidth,
      math.max(_minWidth, screenWidth * _widthFraction),
    );
    final top = media.padding.top + 16;
    const snackHeight = 56.0;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          width: width,
          elevation: 4,
          duration: duration,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.only(
            bottom: media.size.height - top - snackHeight,
            right: 16,
            left: screenWidth - width - 16,
          ),
        ),
      );
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, backgroundColor: Colors.green);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message: message, backgroundColor: Colors.red);
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: Colors.blueGrey,
      duration: const Duration(seconds: 3),
    );
  }
}
