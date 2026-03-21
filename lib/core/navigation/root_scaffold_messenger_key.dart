import 'package:flutter/material.dart';

/// Used by [MaterialApp.router] so code without a [BuildContext] (e.g. GetX
/// controllers) can show [SnackBar]s. [Get.snackbar] needs [GetMaterialApp].
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
