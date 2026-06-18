import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/competition_controller.dart';
import '../../controllers/user_management_controller.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/permission_store.dart';
import '../../../core/utils/role_display_name.dart';
import '../../../routes/app_routes.dart';
import 'home_landing_sections.dart';

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
      Get.find<CompetitionController>().ensureHomeCompetitionsLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      final authController = Get.find<AuthController>();
      final userController = Get.put(UserManagementController());
      final competitionController = Get.find<CompetitionController>();

      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Obx(() {
            final isAuthenticated = userController.isAuthenticated;
            final permissionStore = Get.isRegistered<PermissionStore>()
                ? Get.find<PermissionStore>()
                : Get.put(PermissionStore());
            final isAdminLoggedIn = permissionStore.has(
              'SHOW_DASHBOARD_ICON_ON_HOME_SCREEN',
            );

            return HomeLandingNavBar(
              isAuthenticated: isAuthenticated,
              onLogin: () => context.go(AppRoutes.login),
              onAdmin: isAdminLoggedIn
                  ? () => context.push(AppRoutes.adminDashboard)
                  : null,
              onUserMenu: isAuthenticated
                  ? () => _showUserMenu(
                      context,
                      authController: authController,
                      userController: userController,
                      isAdminLoggedIn: isAdminLoggedIn,
                      isJuryLoggedIn: permissionStore.has('SHOW_JURY_SCREEN'),
                    )
                  : null,
            );
          }),
        ),
        body: SingleChildScrollView(
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

  void _showUserMenu(
    BuildContext context, {
    required AuthController authController,
    required UserManagementController userController,
    required bool isAdminLoggedIn,
    required bool isJuryLoggedIn,
  }) {
    final user = userController.currentUser.value;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(
                    alpha: 0.12,
                  ),
                  child: Icon(Icons.person, color: AppTheme.primaryColor),
                ),
                title: Text(user?.name ?? 'Profile'),
                subtitle: user?.userTypeName != null
                    ? Text(displayRoleName(user!.userTypeName))
                    : null,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('My account'),
                onTap: () {
                  Navigator.pop(ctx);
                  if (isAdminLoggedIn) {
                    context.push(AppRoutes.userManagement);
                  } else if (isJuryLoggedIn) {
                    context.go(AppRoutes.juryScoring);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await authController.signOut();
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
