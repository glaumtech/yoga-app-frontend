import 'package:go_router/go_router.dart';
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
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/sponsors/sponsors_screen.dart';
import '../presentation/screens/users/user_management_screen.dart';
import '../presentation/screens/users/users_list_screen.dart';
import '../presentation/screens/competitions/create_competition_screen.dart';
import '../presentation/screens/participants/participant_management_screen.dart';
import '../presentation/screens/participants/user_competition_registration_screen.dart';
import '../presentation/screens/scoring/jury_scoring_screen.dart';
import '../presentation/screens/organization_setup/organization_setup_screen.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/storage_service.dart';

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

      // School screens should be accessible without login (public).
      // Covers list/create/edit/delete under the same prefix.
      final isPublicSchools = location.startsWith('/admin/schools');

      // Always allow navigation to auth routes (login/signup)
      if (location == AppRoutes.login || location == AppRoutes.signUp) {
        return null;
      }

      // If not logged in and trying to access protected routes
      // Note: home is treated as public for unauthenticated users
      final isHomeRoute = location == AppRoutes.home;
      if (token == null &&
          !isPublicRoute &&
          !isHomeRoute &&
          !isRegister &&
          !isPublicSchools) {
        return AppRoutes.login;
      }

      // If logged in, check admin routes and redirect JURY users
      if (token != null) {
        try {
          final keys =
              StorageService.getStringList(AppConstants.permissionKeysKey)
                  .map((e) => e.trim().toUpperCase())
                  .where((e) => e.isNotEmpty)
                  .toSet();
          bool hasKey(String k) => keys.contains(k.trim().toUpperCase());

          // "Jury mode" is permission-driven now.
          final isJury = hasKey('SHOW_JURY_SCREEN');

          // If jury user, force them to jury scoring screen (unless on public/auth routes).
          if (isJury &&
              location != AppRoutes.juryScoring &&
              location != AppRoutes.login &&
              location != AppRoutes.signUp &&
              location != AppRoutes.splash &&
              !isPublicRoute &&
              !isHomeRoute &&
              !isRegister &&
              !isPublicSchools) {
            return AppRoutes.juryScoring;
          }

          // Permission-based route access
          List<String>? requiredKeys;
          if (location == AppRoutes.adminDashboard ||
              location.startsWith(AppRoutes.adminDashboard)) {
            // Allow dashboard for any admin menu permission
            requiredKeys = const [
              'MENU_DASHBOARD',
              'MENU_COMPETITIONS',
              'MENU_USERS',
              'MENU_PARTICIPANTS',
              'MENU_INSTITUTIONS',
              'MENU_REPORTS',
              'MENU_SETTINGS',
              'MENU_SPONSORS',
            ];
          } else if (location == AppRoutes.createCompetition ||
              location.startsWith('/admin/competitions')) {
            requiredKeys = const ['MENU_COMPETITIONS'];
          } else if (location == AppRoutes.userManagement ||
              location.startsWith('/admin/users')) {
            requiredKeys = const ['MENU_USERS'];
          } else if (location == AppRoutes.participantManagement ||
              location.startsWith('/admin/participants')) {
            requiredKeys = const ['MENU_PARTICIPANTS'];
          } else if (location == AppRoutes.schoolsList ||
              location.startsWith('/admin/schools')) {
            // Schools are public (no login required), so skip permission guard.
            requiredKeys = null;
          } else if (location == AppRoutes.reports ||
              location.startsWith('/admin/reports')) {
            requiredKeys = const ['MENU_REPORTS'];
          } else if (location == AppRoutes.settings ||
              location.startsWith('/admin/settings')) {
            requiredKeys = const ['MENU_SETTINGS'];
          } else if (location == AppRoutes.sponsors ||
              location.startsWith('/admin/sponsors')) {
            requiredKeys = const ['MENU_SPONSORS'];
          } else if (location == AppRoutes.juryScoring ||
              location.startsWith('/jury/')) {
            requiredKeys = const ['SHOW_JURY_SCREEN'];
          }

          if (requiredKeys != null && !requiredKeys.any(hasKey)) {
            // If user doesn't have permission for the route, send them home.
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
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
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

      GoRoute(
        path: AppRoutes.organizationSetup,
        name: 'organization-setup',
        builder: (context, state) => const OrganizationSetupScreen(),
      ),
    ],
  );
}
