import '../../config/app_config.dart';

class AppConstants {
  // App Info
  static const String appName = 'Yogasana Championship 2025';

  // Storage Keys
  static const String tokenKey = 'token_key';
  static const String userKey = 'user_data';
  static const String roleKey = 'user_role';
  static const String permissionKeysKey = 'permission_keys';

  // User Roles
  static const String roleUser = 'user';

  // Standard/Groups
  static const List<String> standards = [
    'II, III',
    'IV, V',
    'VI, VII',
    'VIII, IX',
    'X - XII',
    'UG / PG',
  ];

  // Categories
  static const int juryCount = 5;
}

class BaseUrl {
  static String get baseUrl {
    // Get base URL from environment configuration
    return AppConfig.baseUrl;
  }

  static const Duration apiTimeout = Duration(seconds: 30);
}

class EndPoints {
  /// AUTHENTICATION
  static String register = '/auth/register';
  static String logIn = '/auth/login';
  static String logOut = '/auth/logout';
  static String changePassword = '/auth/changePassword';
  static String updateProfile = '/users/profile';

  /// PARTICIPANTS
  static String participantRegistration = '/participants/register';
  static String participantsFilterByEventId(String eventId) =>
      '/participants/$eventId/eventbased';
  static String participantRegistrationEventId(String eventId) =>
      '/participants/$eventId/register';
  static String participantDetailById(String id) => '/participants/getById/$id';
  static String participantUpdate(String id) => '/participants/update/$id';
  static String participantById(String id) => '/participants/$id';
  static String participantScores(String id) => '/participants/$id/scores';
  static String participantStatusVerify(String id, String status) =>
      '/participants/status_verify/$id/$status';

  static String participantImage(String id) => '/participants/image/$id';
  static String participantCertificate(String id) =>
      '/participants/$id/certificate';

  /// PARTICIPANT REGISTRATION
  static String participantRegistrationPhoto(String id) =>
      '/participant-registration/$id/photo';
  static String participantRegistrationBonafiedCertificate(String id) =>
      '/participant-registration/$id/bonafied-certificate';

  /// PARTICIPANT REGISTRATIONS (New API)
  static String participantRegistrationCreate = '/participant-registration';
  static String participantRegistrationList = '/participant-registration/list';
  static String participantRegistrationById(String id) =>
      '/participant-registration/$id';
  static String participantRegistrationUpdate(String id) =>
      '/participant-registration/$id';
  static String participantRegistrationDelete(String id) =>
      '/participant-registration/$id';
  static String participantRegistrationForScoring =
      '/participant-registration/for-scoring';
  static String participantRegistrationImport =
      '/participant-registration/import';
  static String juryScoring = '/jury-scoring';

  /// SCORING
  static String scoringSave = '/scoring/save';
  static String scoringByEventId(String eventId) => '/scoring/event/$eventId';
  static String participantScoresByEventId(String eventId) =>
      '/scoring/event/$eventId';
  static String participantScoresByParticipantId(
    String eventId,
    String participantId,
  ) => '/scoring/event/$eventId/participant/$participantId';

  /// USER MANAGEMENT
  static String userList = '/user/list';
  static String userCreate = '/user';
  static String userUpdate(String id) => '/user/$id';
  static String userById(String id) => '/user/$id';
  static String userPhoto(String id) => '/user/$id/photo';
  static String userLogin = '/user/login';
  static String userLogout = '/user/logout';
  static String userTypes = '/user-type';
  static String juryAssignments(String userId) =>
      '/juries/user/$userId/assignments';

  /// COMPETITIONS
  static String competitionCreate = '/competition';
  static String competitionList = '/competition/list';
  static String competitionUpdate(String id) => '/competition/$id';
  static String competitionById(String id) => '/competition/$id';
  static String competitionBrochure(String id) => '/competition/$id/brochure';

  /// Public competitions list (home / unauthenticated)
  static String competitionPublic = '/competition/public';

  /// COMPETITION OPTIONS
  static String categoryList = '/category';
  static String categoryCreate = '/category';
  static String categoryByCompetition(int competitionId) =>
      '/category/competition/$competitionId';
  static String prizeList = '/prize';
  static String prizeCreate = '/prize';
  static String stageList = '/stage';
  static String stageCreate = '/stage';
  static String stageByCompetition(int competitionId) =>
      '/stage/competition/$competitionId';
  static String groupList = '/group';
  static String groupCreate = '/group';

  /// LOCATIONS
  static String stateList = '/state';
  static String cityListByState(int stateId) => '/city/state/$stateId';

  /// INSTITUTIONS
  static String institutionCreate = '/institution';
  static String institutionList = '/institution/list';
  static String institutionPrint = '/institution/print';
  static String institutionById(String id) => '/institution/$id';
  static String institutionUpdate(String id) => '/institution/$id';
  static String institutionDelete(String id) => '/institution/$id';
  static String institutionSearch = '/institution/search';

  /// INSTITUTION TYPES & CATEGORIES
  static String institutionTypeList = '/institution-type';
  static String institutionTypeById(int id) => '/institution-type/$id';
  static String institutionTypeReorder = '/institution-type/reorder';
  static String institutionCategoryList = '/institution-category';
  static String institutionCategoryCreate = '/institution-category';
  static String institutionCategoryByType(int typeId) =>
      '/institution-category/type/$typeId';
  static String institutionCategoryById(int id) => '/institution-category/$id';
  static String institutionCategoryReorder = '/institution-category/reorder';

  /// REPORTS
  static String competitionReportSummary(int competitionId) =>
      '/reports/competition/$competitionId/summary';

  static String competitionParticipantScores(int competitionId) =>
      '/reports/competition/$competitionId/participant-scores';

  /// REPORTS PRINT (PDF / Excel as blob)
  static String competitionPrizeWinnersPrint(int competitionId) =>
      '/reports/competition/$competitionId/print/prize-winners';

  /// Single prize-winner certificate PDF (query: stageId, categoryId, participantRegistrationId, optional prizeRank)
  static String competitionPrizeWinnerCertificate(int competitionId) =>
      '/reports/competition/$competitionId/print/prize-winner-certificate';

  static String competitionParticipantsPrint(int competitionId) =>
      '/reports/competition/$competitionId/print/participants';

  static String competitionParticipantsExcel(int competitionId) =>
      '/reports/competition/$competitionId/print/participants/excel';

  /// ORGANIZATION / BRANCH SETUP
  static String organizationSetup = '/organization/setup';

  /// Global prize-winner certificate branding (GET/PUT body = template DTO).
  static String certificateTemplate = '/settings/certificate-template';

  /// PERMISSIONS (app-level permission definitions)
  static String permission = '/permission';
  static String permissionById(String id) => '/permission/$id';
}
