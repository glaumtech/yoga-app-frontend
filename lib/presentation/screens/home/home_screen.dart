import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/competition_controller.dart';
import '../../controllers/user_management_controller.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/permission_store.dart';
import '../../../routes/app_routes.dart';
import 'home_landing_sections.dart';
import '../../widgets/pinned_scroll_views.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final competitionController = Get.isRegistered<CompetitionController>()
          ? Get.find<CompetitionController>()
          : Get.put(CompetitionController());
      competitionController.ensureHomeCompetitionsLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      final authController = Get.find<AuthController>();
      final userController = Get.put(UserManagementController());
      final competitionController = Get.isRegistered<CompetitionController>()
          ? Get.find<CompetitionController>()
          : Get.put(CompetitionController());

      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Obx(() {
            final isAuthenticated = userController.isAuthenticated;
            final user = userController.currentUser.value;
            final permissionStore = Get.isRegistered<PermissionStore>()
                ? Get.find<PermissionStore>()
                : Get.put(PermissionStore());
            final isAdminLoggedIn = permissionStore.has(
              'SHOW_DASHBOARD_ICON_ON_HOME_SCREEN',
            );
            final isJuryLoggedIn = permissionStore.has('SHOW_JURY_SCREEN');

            return HomeLandingNavBar(
              isAuthenticated: isAuthenticated,
              onLogin: () => context.go(AppRoutes.login),
              onLogout: isAuthenticated
                  ? () async {
                      await authController.signOut();
                      if (context.mounted) {
                        context.go(AppRoutes.login);
                      }
                    }
                  : null,
              onAdmin: isAdminLoggedIn
                  ? () => context.push(AppRoutes.adminDashboard)
                  : null,
              showUserProfile: isAuthenticated,
              userName: user?.name,
              userRole: user?.userTypeName?.trim().toUpperCase(),
              onUserAccount:
                  isAuthenticated && (isAdminLoggedIn || isJuryLoggedIn)
                  ? () {
                      if (isAdminLoggedIn) {
                        context.push(AppRoutes.userManagement);
                      } else {
                        context.go(AppRoutes.juryScoring);
                      }
                    }
                  : null,
            );
          }),
        ),
        body: PinnedVerticalScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeHeroSection(
                onExplore: () => context.push(AppRoutes.competitions),
              ),
              Obx(() {
                if (competitionController.isLoadingHomeCompetitions.value &&
                    competitionController.homeCompetitions.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return HomeCompetitionSections(
                  competitions: competitionController.homeCompetitions.toList(),
                );
              }),
              const HomeLandingFooter(),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building HomeScreen: $e');
      return Scaffold(
        appBar: AppBar(title: const Text(AppConstants.appName)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading home screen',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }
}
