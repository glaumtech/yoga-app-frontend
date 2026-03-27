class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String signUp = '/signup';

  // Public
  static const String home = '/home';
  static const String about = '/about';
  static const String contact = '/contact';

  /// User-facing participant registration for a competition (anyone can access).
  static const String registerCompetition =
      '/register/competition/:competitionId';
  static String registerCompetitionPath(String competitionId) =>
      '/register/competition/$competitionId';

  // Admin
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String reports = '/admin/reports';
  static const String sponsors = '/admin/sponsors';
  static const String userManagement = '/admin/users';
  static const String usersList = '/admin/users/list';
  static const String createCompetition = '/admin/competitions/create';
  static const String participantManagement = '/admin/participants';
  static const String schoolsList = '/admin/schools';

  // Jury Scoring
  static const String juryScoring = '/jury/scoring';
}
