import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/app_constants.dart';
import '../utils/storage_service.dart';
import 'app_theme.dart';

/// Applies the logged-in user's role theme colour across the app.
class RoleThemeController extends GetxController {
  final Rx<Color> primaryColor = AppTheme.defaultPrimaryColor.obs;

  ThemeData get lightTheme => AppTheme.buildLightTheme(primaryColor.value);
  ThemeData get darkTheme => AppTheme.buildDarkTheme(primaryColor.value);

  void applyThemeColor(String? hexColor) {
    final parsed = AppTheme.parseHexColor(hexColor) ?? AppTheme.defaultPrimaryColor;
    AppTheme.primaryColor = parsed;
    primaryColor.value = parsed;
  }

  void resetToDefault() {
    applyThemeColor(null);
  }

  Future<void> restoreFromStorage() async {
    try {
      final userJson = StorageService.getString(AppConstants.userKey);
      if (userJson == null || userJson.isEmpty) {
        resetToDefault();
        return;
      }
      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      applyThemeColor(userData['themeColor']?.toString());
    } catch (_) {
      resetToDefault();
    }
  }
}
