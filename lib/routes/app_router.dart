import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import 'package:yoga_champ/routes/app_routes.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/events/events_list_screen.dart';
import '../presentation/screens/events/event_details_screen.dart';
import '../presentation/screens/about/about_screen.dart';
import '../presentation/screens/contact/contact_screen.dart';
import '../presentation/screens/participant/user_dashboard_screen.dart';
import '../presentation/screens/participant/my_registrations_screen.dart';
import '../presentation/screens/participant/registration_form_screen.dart';
import '../presentation/screens/participant/participant_list_screen.dart';
import '../presentation/screens/participant/assign_participant_screen.dart';
import '../presentation/screens/admin/admin_dashboard_screen.dart';
import '../presentation/screens/admin/event_management_screen.dart';
import '../presentation/screens/admin/judge_management_screen.dart';
import '../presentation/screens/admin/schedule_management_screen.dart';
import '../presentation/screens/admin/admin_scoring_screen.dart';
import '../presentation/screens/admin/participant_scores_list_screen.dart';
import '../presentation/screens/admin/participant_score_detail_screen.dart';
import '../presentation/screens/schools/schools_screen.dart';
import '../presentation/screens/admin/reports_screen.dart';
import '../presentation/screens/sponsors/sponsors_screen.dart';
import '../presentation/screens/users/user_management_screen.dart';
import '../presentation/screens/users/users_list_screen.dart';
import '../presentation/screens/competitions/create_competition_screen.dart';
import '../presentation/screens/participants/participant_management_screen.dart';
import '../presentation/screens/judge/judge_assigned_participants_screen.dart';
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
        AppRoutes.events,
        AppRoutes.about,
        AppRoutes.contact,
      ];

      // Check if current route is public
      final isPublicRoute = publicRoutes.any(
        (route) => location == route || location.startsWith(route),
      );

      // Check if route is event details (public)
      final isEventDetails =
          location.startsWith('/events/') && location != AppRoutes.events;

      // Check if route is assign participant or register (requires auth)
      final isAssignParticipant = location.startsWith('/assign-participant/');
      final isRegister = location.startsWith('/register/');
      final isAssignedParticipants = location.startsWith(
        '/assigned-participants/',
      );
      final isParticipantScores = location.startsWith('/admin/scores/');

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
          !isEventDetails &&
          !isAssignParticipant &&
          !isRegister &&
          !isAssignedParticipants &&
          !isParticipantScores) {
        return AppRoutes.login;
      }

      // If logged in, check admin routes and redirect JURY users
      if (token != null) {
        try {
          // Try to get user from UserManagementController first (new login system)
          bool isAdmin = false;
          bool isJudge = false;
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

              // JURY has judge/jury access
              isJudge =
                  userTypeUpper == 'JURY' || userTypeUpper.contains('JURY');

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
            isJudge = roleName.toUpperCase().contains('JUDGE');
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
            AppRoutes.eventManagement,
            AppRoutes.judgeManagement,
            AppRoutes.scheduleManagement,
            AppRoutes.participantScoresList,
            AppRoutes.participantScoreDetail,
          ];

          // Check if route is participant scores (admin only)
          final isParticipantScoresRoute = location.startsWith(
            '/admin/scores/',
          );

          // Routes accessible to both admin and judges
          final adminAndJudgeRoutes = [
            AppRoutes.adminScoring,
            AppRoutes.participantList,
          ];

          // Routes accessible to admin, judges, and juries
          final adminJudgeJuryRoutes = [AppRoutes.juryScoring];

          // Judge-only routes (check path patterns)
          final isJudgeOnlyRoute = location.startsWith(
            '/assigned-participants/',
          );

          final isAdminOnlyRoute =
              adminOnlyRoutes.any(
                (route) => location == route || location.startsWith(route),
              ) ||
              isParticipantScoresRoute;

          final isAdminOrJudgeRoute = adminAndJudgeRoutes.any(
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

          // If trying to access admin/judge route, allow if admin or judge
          if (isAdminOrJudgeRoute && !isAdmin && !isJudge) {
            // Redirect JURY users to jury scoring, others to home
            return isJury ? AppRoutes.juryScoring : AppRoutes.home;
          }

          // If trying to access admin/judge/jury route, allow if admin, judge, or jury
          if (isAdminJudgeJuryRoute && !isAdmin && !isJudge && !isJury) {
            return AppRoutes.home;
          }

          // If trying to access judge-only route but not judge
          if (isJudgeOnlyRoute && !isJudge && !isAdmin) {
            // Redirect JURY users to jury scoring, others to home
            return isJury ? AppRoutes.juryScoring : AppRoutes.home;
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
        path: AppRoutes.events,
        name: 'events',
        builder: (context, state) => const EventsListScreen(),
      ),
      GoRoute(
        path: AppRoutes.eventDetails,
        name: 'event-details',
        builder: (context, state) {
          final eventId = state.pathParameters['id'] ?? '';
          return EventDetailsScreen(eventId: eventId);
        },
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

      // Participant
      GoRoute(
        path: AppRoutes.userDashboard,
        name: 'user-dashboard',
        builder: (context, state) => const UserDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.myRegistrations,
        name: 'my-registrations',
        builder: (context, state) => const MyRegistrationsScreen(),
      ),
      // GoRoute(
      //   path: AppRoutes.registrationForm,
      //   name: 'registration-form',
      //   builder: (context, state) => const RegistrationFormScreen(),
      // ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId'] ?? '';
          if (eventId.isEmpty) {
            // Redirect to events list if eventId is missing
            return const EventsListScreen();
          }
          // Get participant ID from query parameters (for edit mode)
          final participantId = state.uri.queryParameters['participantId'];
          return RegistrationFormScreen(
            eventId: eventId,
            participantId: participantId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.assignParticipant,
        name: 'assign-participant',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId'] ?? '';

          return AssignParticipantScreen(eventId: eventId);
        },
      ),

      // Admin
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.eventManagement,
        name: 'event-management',
        builder: (context, state) => const EventManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.judgeManagement,
        name: 'judge-management',
        builder: (context, state) => const JudgeManagementScreen(),
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
        path: AppRoutes.participantList,
        name: 'participant-list',
        builder: (context, state) => const ParticipantListScreen(),
      ),
      GoRoute(
        path: AppRoutes.scheduleManagement,
        name: 'schedule-management',
        builder: (context, state) => const ScheduleManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminScoring,
        name: 'admin-scoring',
        builder: (context, state) => const AdminScoringScreen(),
      ),
      GoRoute(
        path: AppRoutes.participantScoresList,
        name: 'participant-scores-list',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId'] ?? '';
          if (eventId.isEmpty) {
            return const AdminDashboardScreen();
          }
          return ParticipantScoresListScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: AppRoutes.participantScoreDetail,
        name: 'participant-score-detail',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId'] ?? '';
          final participantId = state.pathParameters['participantId'] ?? '';
          if (eventId.isEmpty || participantId.isEmpty) {
            return const AdminDashboardScreen();
          }
          return ParticipantScoreDetailScreen(
            eventId: eventId,
            participantId: participantId,
          );
        },
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

      // Judge
      GoRoute(
        path: AppRoutes.assignedParticipants,
        name: 'assigned-participants',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId'] ?? '';
          if (eventId.isEmpty) {
            // Redirect to events list if eventId is missing
            return const EventsListScreen();
          }
          return JudgeAssignedParticipantsScreen(eventId: eventId);
        },
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
