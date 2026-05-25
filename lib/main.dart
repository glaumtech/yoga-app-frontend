import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/root_scaffold_messenger_key.dart';
import 'core/utils/storage_service.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/participant_controller.dart';
import 'presentation/controllers/competition_controller.dart';
import 'routes/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/permission_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // Initialize storage (await to ensure it's ready)
  await StorageService.init();

  // Initialize GetX controllers (permanent to survive browser refresh)
  Get.put(AuthController(), permanent: true);
  Get.put(ParticipantController(), permanent: true);
  Get.put(CompetitionController(), permanent: true);
  await Get.put(PermissionStore(), permanent: true).init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: AppRouter.router,
    );
  }
}
