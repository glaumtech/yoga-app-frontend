class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String signUp = '/signup';

  // Public
  static const String home = '/home';
  static const String events = '/events';
  static const String eventDetails = '/events/:id';
  static const String about = '/about';
  static const String contact = '/contact';

  // Participant
  static const String userDashboard = '/user-dashboard';
  static const String myRegistrations = '/my-registrations';
  static const String registrationForm = '/registration-form';
  static const String register = '/register/:eventId';
  static const String assignParticipant = '/assign-participant/:eventId';

  // Admin
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String eventManagement = '/admin/events';
  static const String participantList = '/participant-list';
  static const String scheduleManagement = '/admin/schedule';
  static const String adminScoring = '/admin-scoring';
  static const String judgeManagement = '/admin/judges';

  // Judge
  static const String assignedParticipants = '/assigned-participants/:eventId';
}
