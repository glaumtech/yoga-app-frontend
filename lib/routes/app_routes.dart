class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String signUp = '/signup';

  // Public
  static const String home = '/home';
  static const String competitions = '/competitions';
  static const String about = '/about';
  static const String contact = '/contact';
  static const String legal = '/legal/:docType';

  static String legalPath(String docType) => '/legal/$docType';

  /// Public competitions list; [status] is `ongoing`, `upcoming`, or `completed`.
  static String competitionsList({String? status}) {
    if (status == null || status.trim().isEmpty) {
      return competitions;
    }
    return '$competitions?status=${Uri.encodeQueryComponent(status.trim())}';
  }

  /// Public participant list for one competition (from home competitions list).
  static const String publicCompetitionParticipants =
      '/competitions/:competitionId/participants';

  static String publicCompetitionParticipantsPath(
    String competitionId, {
    String? competitionName,
    bool isPastCompetition = false,
  }) {
    final params = <String, String>{};
    final name = competitionName?.trim();
    if (name != null && name.isNotEmpty) {
      params['name'] = name;
    }
    if (isPastCompetition) {
      params['past'] = '1';
    }
    return Uri(
      path: '/competitions/$competitionId/participants',
      queryParameters: params.isEmpty ? null : params,
    ).toString();
  }

  /// User-facing participant registration for a competition (anyone can access).
  static const String registerCompetition =
      '/register/competition/:competitionId';
  static String registerCompetitionPath(String competitionId) =>
      '/register/competition/$competitionId';

  // Admin
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String reports = '/admin/reports';
  static const String participantRegistrationDetails =
      '/admin/reports/registration/:registrationId';

  static String participantRegistrationDetailsPath(
    String registrationId, {
    String? participantName,
    String? competitionName,
    String? registrationNo,
  }) {
    final params = <String, String>{};
    final name = participantName?.trim();
    if (name != null && name.isNotEmpty) {
      params['name'] = name;
    }
    final competition = competitionName?.trim();
    if (competition != null && competition.isNotEmpty) {
      params['competition'] = competition;
    }
    final regNo = registrationNo?.trim();
    if (regNo != null && regNo.isNotEmpty) {
      params['regNo'] = regNo;
    }
    return Uri(
      path: '/admin/reports/registration/$registrationId',
      queryParameters: params.isEmpty ? null : params,
    ).toString();
  }
  static const String settings = '/admin/settings';
  static const String sponsors = '/admin/sponsors';
  static const String userManagement = '/admin/users';
  static const String usersList = '/admin/users/list';
  static const String createCompetition = '/admin/competitions/create';
  static const String participantManagement = '/admin/participants';
  static const String schoolsList = '/admin/schools';

  // Jury
  static const String juryLogin = '/jury/login';
  static const String juryScoring = '/jury/scoring';

  // Organization Setup
  static const String organizationSetup = '/organization/setup';
}
