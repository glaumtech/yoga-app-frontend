import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import 'package:yoga_champ/routes/app_routes.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/about/about_screen.dart';
import '../presentation/screens/contact/contact_screen.dart';
import '../presentation/screens/admin/admin_dashboard_screen.dart';

import '../presentation/screens/schools/schools_screen.dart';
import '../presentation/screens/reports/reports_screen.dart';
import '../presentation/screens/sponsors/sponsors_screen.dart';
import '../presentation/screens/users/user_management_screen.dart';
import '../presentation/screens/users/users_list_screen.dart';
import '../presentation/screens/competitions/create_competition_screen.dart';
import '../presentation/screens/participants/participant_management_screen.dart';
import '../presentation/screens/participants/user_competition_registration_screen.dart';
import '../presentation/screens/scoring/jury_scoring_screen.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/storage_service.dart';
import '../presentation/controllers/auth_controller.dart';
import '../presentation/controllers/user_management_controller.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final token = StorageService.getString(AppConstants.tokenKey);
      final location = state.matchedLocation;

      // Public routes that don't require authentication
      final publicRoutes = [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.signUp,
        AppRoutes.about,
        AppRoutes.contact,
      ];

      // Check if current route is public
      final isPublicRoute = publicRoutes.any(
        (route) => location == route || location.startsWith(route),
      );

      // Public competition registration route is allowed without auth.
      final isRegister = location.startsWith('/register/');

      // Always allow navigation to auth routes (login/signup)
      if (location == AppRoutes.login || location == AppRoutes.signUp) {
        return null;
      }

      // If not logged in and trying to access protected routes
      // Note: home is treated as public for unauthenticated users
      final isHomeRoute = location == AppRoutes.home;
      if (token == null && !isPublicRoute && !isHomeRoute && !isRegister) {
        return AppRoutes.login;
      }

      // If logged in, check admin routes and redirect JURY users
      if (token != null) {
        try {
          // Try to get user from UserManagementController first (new login system)
          bool isAdmin = false;
          bool isJury = false;

          try {
            final userController = Get.find<UserManagementController>();
            final currentUser = userController.currentUser.value;
            if (currentUser != null) {
              final userTypeName = currentUser.userTypeName ?? currentUser.type;
              final userTypeUpper = userTypeName.toUpperCase();

              // Check specific user types from database
              // SUB_ADMIN and SPOT_REG_ADMIN have admin access
              isAdmin =
                  userTypeUpper == 'SUB_ADMIN' ||
                  userTypeUpper == 'SPOT_REG_ADMIN' ||
                  userTypeUpper.contains('SUB ADMIN') ||
                  userTypeUpper.contains('SPOT REG ADMIN');

              isJury =
                  userTypeUpper == 'JURY' || userTypeUpper.contains('JURY');

              // Redirect JURY users to jury scoring screen FIRST
              // Allow only: login, signup, splash, and the jury scoring route itself
              if (isJury &&
                  location != AppRoutes.juryScoring &&
                  location != AppRoutes.login &&
                  location != AppRoutes.signUp &&
                  location != AppRoutes.splash) {
                // Redirect from any route (including home) to jury scoring
                print(
                  'Redirecting JURY user from $location to ${AppRoutes.juryScoring}',
                );
                return AppRoutes.juryScoring;
              }
            }
          } catch (e) {
            print('Error getting user from UserManagementController: $e');
            // Fallback to AuthController if UserManagementController not available
            final authController = Get.find<AuthController>();
            isAdmin = authController.isAdmin;
            final roleName = authController.currentUser.value?.roleName ?? '';
            isJury = roleName.toUpperCase().contains('JURY');

            // Redirect JURY users to jury scoring screen FIRST
            // Allow only: login, signup, splash, and the jury scoring route itself
            if (isJury &&
                location != AppRoutes.juryScoring &&
                location != AppRoutes.login &&
                location != AppRoutes.signUp &&
                location != AppRoutes.splash) {
              // Redirect from any route (including home) to jury scoring
              print(
                'Redirecting JURY user (fallback) from $location to ${AppRoutes.juryScoring}',
              );
              return AppRoutes.juryScoring;
            }
          }

          // Admin-only routes (not accessible to judges)
          final adminOnlyRoutes = [
            AppRoutes.adminDashboard,
            AppRoutes.createCompetition,
            AppRoutes.userManagement,
            AppRoutes.usersList,
            AppRoutes.participantManagement,
            AppRoutes.reports,
            AppRoutes.sponsors,
          ];

          // Routes accessible to admin, judges, and juries
          final adminJudgeJuryRoutes = [AppRoutes.juryScoring];

          final isAdminOnlyRoute = adminOnlyRoutes.any(
            (route) => location == route || location.startsWith(route),
          );

          final isAdminJudgeJuryRoute = adminJudgeJuryRoutes.any(
            (route) => location == route || location.startsWith(route),
          );

          // If trying to access admin-only route but not admin
          if (isAdminOnlyRoute && !isAdmin) {
            // Redirect JURY users to jury scoring, others to home
            return isJury ? AppRoutes.juryScoring : AppRoutes.home;
          }

          // If trying to access admin/judge/jury route, allow if admin, judge, or jury
          if (isAdminJudgeJuryRoute && !isAdmin && !isJury) {
            return AppRoutes.home;
          }
        } catch (e) {
          // Controller not initialized, allow navigation
        }
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),

      // Public
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.contact,
        name: 'contact',
        builder: (context, state) => const ContactScreen(),
      ),

      // User-facing participant registration by competition (anyone can access)
      GoRoute(
        path: AppRoutes.registerCompetition,
        name: 'register-competition',
        builder: (context, state) {
          final competitionId = state.pathParameters['competitionId'] ?? '';
          if (competitionId.isEmpty) {
            return const HomeScreen();
          }
          return UserCompetitionRegistrationScreen(
            competitionId: competitionId,
          );
        },
      ),

      // Admin
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.userManagement,
        name: 'user-management',
        builder: (context, state) => const UserManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.usersList,
        name: 'users-list',
        builder: (context, state) => const UsersListScreen(),
      ),
      GoRoute(
        path: AppRoutes.createCompetition,
        name: 'create-competition',
        builder: (context, state) => const CreateCompetitionScreen(),
      ),
      GoRoute(
        path: AppRoutes.participantManagement,
        name: 'participant-management',
        builder: (context, state) => const ParticipantManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.schoolsList,
        name: 'schools-list',
        builder: (context, state) => const SchoolsScreen(),
      ),
      GoRoute(
        path: AppRoutes.reports,
        name: 'reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.sponsors,
        name: 'sponsors',
        builder: (context, state) => const SponsorsScreen(),
      ),

      // Scoring
      GoRoute(
        path: AppRoutes.juryScoring,
        name: 'jury-scoring',
        builder: (context, state) => const JuryScoringScreen(),
      ),
    ],
  );
}
