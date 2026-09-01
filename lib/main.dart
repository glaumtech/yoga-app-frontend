import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/role_theme_controller.dart';
import 'core/navigation/root_scaffold_messenger_key.dart';
import 'core/services/organization_mandatory_gate_service.dart';
import 'core/services/first_competition_gate_service.dart';
import 'core/utils/storage_service.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/participant_controller.dart';
import 'presentation/controllers/competition_controller.dart';
import 'routes/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/keyboard/app_keyboard_scroll_scope.dart';
import 'core/utils/permission_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage (await to ensure it's ready)
  await StorageService.init();

  // Initialize GetX controllers (permanent to survive browser refresh)
  Get.put(AuthController(), permanent: true);
  Get.put(ParticipantController(), permanent: true);
  Get.put(CompetitionController(), permanent: true);
  await Get.put(PermissionStore(), permanent: true).init();

  final roleThemeController = Get.put(RoleThemeController(), permanent: true);
  await roleThemeController.restoreFromStorage();

  final orgGate = Get.put(OrganizationMandatoryGateService(), permanent: true);
  await orgGate.initFromStorage();

  final firstCompetitionGate =
      Get.put(FirstCompetitionGateService(), permanent: true);
  await firstCompetitionGate.initFromStorage();

  if (StorageService.getString(AppConstants.tokenKey) != null) {
    unawaited(
      orgGate.evaluateForCurrentUser().then((_) async {
        await firstCompetitionGate.evaluateForCurrentUser();
        AppRouter.refresh();
      }),
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final roleTheme = Get.find<RoleThemeController>();
    return Obx(
      () => MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: roleTheme.lightTheme,
      darkTheme: roleTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
      shortcuts: AppKeyboardScrollScope.mergeAppShortcuts(
        WidgetsApp.defaultShortcuts,
      ),
      builder: (context, child) {
        return AppKeyboardScrollScope(child: child);
      },
    ),
    );
  }
}
