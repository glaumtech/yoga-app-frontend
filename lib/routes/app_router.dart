import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:yoga_champ/routes/app_routes.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/jury_token_login_screen.dart';
import '../presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/auth/verify_otp_screen.dart';
import '../presentation/screens/auth/reset_password_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/home/public_competitions_screen.dart';
import '../presentation/screens/home/public_competition_participants_screen.dart';
import '../presentation/screens/about/about_screen.dart';
import '../presentation/screens/contact/contact_screen.dart';
import '../presentation/screens/legal/static_legal_screen.dart';
import '../presentation/screens/admin/admin_dashboard_screen.dart';

import '../presentation/screens/schools/schools_screen.dart';
import '../presentation/screens/reports/reports_screen.dart';
import '../presentation/screens/reports/participant_registration_details_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/sponsors/sponsors_screen.dart';
import '../presentation/screens/users/user_management_screen.dart';
import '../presentation/screens/users/users_list_screen.dart';
import '../presentation/screens/competitions/create_competition_screen.dart';
import '../presentation/screens/participants/participant_management_screen.dart';
import '../presentation/screens/participants/user_competition_registration_screen.dart';
import '../presentation/screens/participants/participant_video_upload_screen.dart';
import '../presentation/screens/scoring/jury_scoring_screen.dart';
import '../presentation/screens/organization_setup/organization_setup_screen.dart';
import '../presentation/screens/organization_update/organization_update_screen.dart';
import '../core/constants/app_constants.dart';
import '../core/navigation/root_navigator_key.dart';
import '../core/utils/organization_mandatory_checker.dart';
import '../core/utils/permission_store.dart';
import '../core/utils/storage_service.dart';
import '../core/utils/online_participant_login_url.dart';

import '../data/models/user_management_model.dart';

Page<void> _noTransitionPage(GoRouterState state, Widget child) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

class AppRouter {
  static void refresh() {
    try {
      router.refresh();
    } catch (_) {}
  }

  static bool _isBranchAdminFromStorage() {
    final userJson = StorageService.getString(AppConstants.userKey);
    if (userJson == null || userJson.isEmpty) return false;
    try {
      final user = UserManagementModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      return isBranchAdminRole(user.userTypeName, fallbackType: user.type);
    } catch (_) {
      return false;
    }
  }

  static bool _requiresMandatoryOrganizationUpdate() {
    return StorageService.getBool(AppConstants.orgMandatoryUpdateRequiredKey) ==
        true;
  }

  static bool _requiresFirstCompetition() {
    return StorageService.getBool(AppConstants.firstCompetitionRequiredKey) ==
        true;
  }

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: kIsWeb ? flutterWebInitialLocation() : AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error?.toString() ?? 'Unknown routing error'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go to home'),
            ),
          ],
        ),
      ),
    ),
    redirect: (context, state) {
      final token = StorageService.getString(AppConstants.tokenKey);
      final location = state.matchedLocation.isEmpty
          ? AppRoutes.splash
          : state.matchedLocation;

      // Public routes that don't require authentication
      final publicRoutes = [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.signUp,
        AppRoutes.forgotPassword,
        AppRoutes.verifyOtp,
        AppRoutes.resetPassword,
        AppRoutes.juryLogin,
        AppRoutes.about,
        AppRoutes.contact,
      ];

      // Check if current route is public
      final isPublicRoute = publicRoutes.any(
        (route) => location == route || location.startsWith(route),
      );

      // Public competition registration route is allowed without auth.
      final isRegister = location.startsWith('/register/');

      // Legal / policy pages are public.
      final isLegal = location.startsWith('/legal/');

      // School screens should be accessible without login (public).
      // Covers list/create/edit/delete under the same prefix.
      final isPublicSchools = location.startsWith('/admin/schools');

      // Always allow navigation to auth routes (login/signup)
      if (location == AppRoutes.login ||
          location == AppRoutes.signUp ||
          location == AppRoutes.forgotPassword ||
          location == AppRoutes.verifyOtp ||
          location == AppRoutes.resetPassword ||
          location == AppRoutes.juryLogin) {
        return null;
      }

      // If not logged in and trying to access protected routes
      // Note: home is treated as public for unauthenticated users
      final isHomeRoute = location == AppRoutes.home;
      final isPublicCompetitions =
          location == AppRoutes.competitions ||
          location.startsWith('${AppRoutes.competitions}/');
      if (token == null &&
          !isPublicRoute &&
          !isHomeRoute &&
          !isPublicCompetitions &&
          !isRegister &&
          !isLegal &&
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
              location != AppRoutes.juryLogin &&
              location != AppRoutes.signUp &&
              location != AppRoutes.splash &&
              !isPublicRoute &&
              !isHomeRoute &&
              !isPublicCompetitions &&
              !isRegister &&
              !isLegal &&
              !isPublicSchools) {
            return AppRoutes.juryScoring;
          }

          // Super admin with incomplete organization details: lock to org complete only.
          final isOrgCompleteRoute = location == AppRoutes.organizationComplete ||
              location.startsWith(AppRoutes.organizationComplete);
          if (_requiresMandatoryOrganizationUpdate() &&
              _isBranchAdminFromStorage() &&
              !isOrgCompleteRoute) {
            return AppRoutes.organizationComplete;
          }

          // Branch admin with no competition yet: lock to competition creation only.
          final isCompetitionCreateRoute =
              location == AppRoutes.createCompetition ||
              location.startsWith(AppRoutes.createCompetition);
          if (!_requiresMandatoryOrganizationUpdate() &&
              _requiresFirstCompetition() &&
              _isBranchAdminFromStorage() &&
              !isCompetitionCreateRoute) {
            return AppRoutes.createCompetition;
          }

          // Permission-based route access
          List<String>? requiredKeys;
          if (location == AppRoutes.adminDashboard ||
              location.startsWith(AppRoutes.adminDashboard)) {
            // Allow dashboard for any admin menu permission
            requiredKeys = PermissionStore.adminDashboardAccessKeys;
          } else if (location == AppRoutes.createCompetition ||
              location.startsWith('/admin/competitions')) {
            if (_requiresFirstCompetition() && _isBranchAdminFromStorage()) {
              requiredKeys = null;
            } else {
              requiredKeys = const ['MENU_COMPETITIONS'];
            }
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
          } else if (location == AppRoutes.organizationComplete ||
              location.startsWith(AppRoutes.organizationComplete)) {
            requiredKeys = null;
          } else if (location == AppRoutes.organizationUpdate ||
              location.startsWith('/organization/update')) {
            requiredKeys = const ['ORGANIZATION_UPDATE'];
          }

          if (requiredKeys != null &&
              !requiredKeys.any(hasKey) &&
              !(_requiresFirstCompetition() && _isBranchAdminFromStorage())) {
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
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyOtp,
        name: 'verify-otp',
        builder: (context, state) => const VerifyOtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),

      // Public
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.competitions,
        name: 'competitions',
        builder: (context, state) {
          final status = state.uri.queryParameters['status'];
          return PublicCompetitionsScreen(statusFilter: status);
        },
        routes: [
          GoRoute(
            path: ':competitionId/participants',
            name: 'public-competition-participants',
            builder: (context, state) {
              final competitionId = state.pathParameters['competitionId'] ?? '';
              final name = state.uri.queryParameters['name'] ?? '';
              final isPast = state.uri.queryParameters['past'] == '1';
              return PublicCompetitionParticipantsScreen(
                competitionId: competitionId,
                competitionName: name,
                isPastCompetition: isPast,
              );
            },
          ),
        ],
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
      GoRoute(
        path: AppRoutes.legal,
        name: 'legal',
        builder: (context, state) {
          final docType = state.pathParameters['docType'] ?? '';
          final screen = StaticLegalScreen.forDocType(docType);
          if (screen == null) {
            return const ContactScreen();
          }
          return screen;
        },
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
      GoRoute(
        path: AppRoutes.participantVideoUploadWithRegNo,
        name: 'participant-video-upload-regno',
        builder: (context, state) => ParticipantVideoUploadScreen(
          registrationNo: registrationNoFromGoRouterState(state),
        ),
      ),
      GoRoute(
        path: AppRoutes.participantVideoUpload,
        name: 'participant-video-upload',
        builder: (context, state) => ParticipantVideoUploadScreen(
          registrationNo: registrationNoFromGoRouterState(state),
        ),
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
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const UserManagementScreen()),
      ),
      GoRoute(
        path: AppRoutes.usersList,
        name: 'users-list',
        builder: (context, state) => const UsersListScreen(),
      ),
      GoRoute(
        path: AppRoutes.createCompetition,
        name: 'create-competition',
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const CreateCompetitionScreen()),
      ),
      GoRoute(
        path: AppRoutes.participantManagement,
        name: 'participant-management',
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const ParticipantManagementScreen()),
      ),
      GoRoute(
        path: AppRoutes.schoolsList,
        name: 'schools-list',
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const SchoolsScreen()),
      ),
      GoRoute(
        path: AppRoutes.reports,
        name: 'reports',
        pageBuilder: (context, state) =>
            _noTransitionPage(state, const ReportsScreen()),
        routes: [
          GoRoute(
            path: 'registration/:registrationId',
            name: 'participant-registration-details',
            pageBuilder: (context, state) {
              final registrationId =
                  state.pathParameters['registrationId'] ?? '';
              final participantName = state.uri.queryParameters['name'];
              final competitionName = state.uri.queryParameters['competition'];
              final registrationNo = state.uri.queryParameters['regNo'];
              return _noTransitionPage(
                state,
                ParticipantRegistrationDetailsScreen(
                  registrationId: registrationId,
                  participantName: participantName,
                  competitionName: competitionName,
                  registrationNo: registrationNo,
                ),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => _noTransitionPage(
          state,
          SettingsScreen(initialTab: state.uri.queryParameters['tab']),
        ),
      ),
      GoRoute(
        path: AppRoutes.sponsors,
        name: 'sponsors',
        builder: (context, state) => const SponsorsScreen(),
      ),

      GoRoute(
        path: AppRoutes.juryLogin,
        name: 'jury-login',
        builder: (context, state) => JuryTokenLoginScreen(
          token: state.uri.queryParameters['token'],
        ),
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
      GoRoute(
        path: AppRoutes.organizationUpdate,
        name: 'organization-update',
        builder: (context, state) => const OrganizationUpdateScreen(),
      ),
      GoRoute(
        path: AppRoutes.organizationComplete,
        name: 'organization-complete',
        builder: (context, state) => const OrganizationUpdateScreen(),
      ),
    ],
  );
}
