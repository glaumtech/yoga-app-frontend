import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'config/app_config.dart';
import 'core/utils/storage_service.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/participant_controller.dart';
import 'presentation/controllers/event_controller.dart';
import 'presentation/controllers/judge_controller.dart';
import 'presentation/controllers/team_controller.dart';
import 'presentation/controllers/scoring_controller.dart';
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.setEnvironment(Environment.prod);

  // Initialize storage (await to ensure it's ready)
  await StorageService.init();

  // Initialize GetX controllers (permanent to survive browser refresh)
  Get.put(AuthController(), permanent: true);
  Get.put(ParticipantController(), permanent: true);
  Get.put(EventController(), permanent: true);
  Get.put(JudgeController(), permanent: true);
  Get.put(TeamController(), permanent: true);
  Get.put(ScoringController(), permanent: true);

  runApp(const MyApp());
}
