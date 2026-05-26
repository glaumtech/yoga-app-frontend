import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../presentation/widgets/webcam_capture_dialog.dart';

/// Picks images from gallery or captures from camera / webcam.
///
/// On mobile, [ImageSource.camera] uses the system camera.
/// On web and desktop (Windows/macOS/Linux), camera opens an in-app webcam UI.
class PhotoCaptureService {
  PhotoCaptureService._();

  static final ImagePicker _picker = ImagePicker();

  static bool get needsWebcamCapture {
    if (kIsWeb) return true;
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (_) {
      return false;
    }
  }

  static BuildContext? _resolveContext(BuildContext? context) {
    if (context != null && context.mounted) return context;
    final ctx = Get.context;
    if (ctx != null && ctx.mounted) return ctx;
    return null;
  }

  static Future<XFile?> pickImage({
    required ImageSource source,
    BuildContext? context,
    int imageQuality = 85,
  }) async {
    if (source == ImageSource.gallery) {
      return _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: imageQuality,
      );
    }

    if (needsWebcamCapture) {
      final ctx = _resolveContext(context);
      if (ctx == null) {
        throw StateError(
          'Camera requires a valid BuildContext on web and desktop.',
        );
      }
      return WebcamCaptureDialog.show(ctx);
    }

    return _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: imageQuality,
    );
  }
}
