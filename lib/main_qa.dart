import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'config/app_config.dart';
import 'core/theme/role_theme_controller.dart';
import 'core/utils/permission_store.dart';
import 'core/utils/storage_service.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/competition_controller.dart';
import 'presentation/controllers/participant_controller.dart';
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.setEnvironment(Environment.qa);

  // Initialize storage (await to ensure it's ready)
  await StorageService.init();

  // Initialize GetX controllers (permanent to survive browser refresh)
  Get.put(AuthController(), permanent: true);
  Get.put(ParticipantController(), permanent: true);
  Get.put(CompetitionController(), permanent: true);
  await Get.put(PermissionStore(), permanent: true).init();

  final roleThemeController = Get.put(RoleThemeController(), permanent: true);
  await roleThemeController.restoreFromStorage();

  runApp(const MyApp());
}
