import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/storage_service.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/participant_controller.dart';
import 'presentation/controllers/event_controller.dart';
import 'presentation/controllers/judge_controller.dart';
import 'presentation/controllers/admin_controller.dart';
import 'presentation/controllers/team_controller.dart';
import 'routes/app_router.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage
  StorageService.init();

  // Initialize GetX controllers (permanent to survive browser refresh)
  Get.put(AuthController(), permanent: true);
  Get.put(ParticipantController(), permanent: true);
  Get.put(EventController(), permanent: true);
  Get.put(JudgeController(), permanent: true);
  Get.put(AdminController(), permanent: true);
  Get.put(TeamController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
    );
  }
}
