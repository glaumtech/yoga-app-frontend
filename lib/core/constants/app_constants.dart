import '../../config/app_config.dart';

class AppConstants {
  // App Info
  static const String appName = 'Yoga Competition Application';

  // Storage Keys
  static const String tokenKey = 'token_key';
  static const String userKey = 'user_data';
  static const String roleKey = 'user_role';
  static const String permissionKeysKey = 'permission_keys';
  static const String usersListRecentCompetitionsKey =
      'users_list_recent_competitions';

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
  static String participantRegistrationDetailsPdf(String id) =>
      '/participant-registration/$id/registration-details';
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
  static const String userLoginWithToken = '/user/login/token';
  static String userLogout = '/user/logout';
  static String juryLoginTokenGenerate(String userId) =>
      '/juries/user/$userId/login-token';
  static String juryLoginTokenRevoke(String userId) =>
      '/juries/user/$userId/login-token';
  static String userTypes = '/user-type';
  static String juryAssignments(String userId) =>
      '/juries/user/$userId/assignments';

  /// COMPETITIONS
  static String competitionCreate = '/competition';
  static String competitionList = '/competition/list';
  static String competitionUpdate(String id) => '/competition/$id';
  static String competitionById(String id) => '/competition/$id';
  static String competitionDeletionInfo(String id) =>
      '/competition/$id/deletion-info';
  static String competitionBrochure(String id) => '/competition/$id/brochure';
  static String competitionRegistrationQr(String id) =>
      '/competition/$id/registration-qr';

  /// Public competitions list (home / unauthenticated)
  static String competitionPublic = '/competition/public';

  /// Payment gateway
  static String paymentPackages = '/payment/packages';
  static String subscriptionModes = '/subscription-mode';
  static String paymentSubscriptionOrder = '/payment/subscription/order';
  static String paymentSubscriptionVerify = '/payment/subscription/verify';
  static String paymentRegistrationOrder = '/payment/registration/order';
  static String paymentRegistrationVerify = '/payment/registration/verify';
  static String paymentCompetitionMaintenanceOrder(int competitionId) =>
      '/payment/competition/$competitionId/maintenance-order';
  static String paymentCompetitionMaintenanceVerify(int competitionId) =>
      '/payment/competition/$competitionId/maintenance-verify';
  static String apiCreateOrder = '/api/create-order';
  static String apiVerifyPayment = '/api/verify-payment';
  static String apiMarkPaymentFailed = '/api/mark-payment-failed';
  static String paymentOnDemandContext = '/payment/on-demand/context';
  static String participantRegistrationPaymentVerify(String id) =>
      '/participant-registration/$id/payment/verify';
  static String participantRegistrationPaymentReject(String id) =>
      '/participant-registration/$id/payment/reject';

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
  static String cityCreate = '/city';
  static String cityListByState(int stateId) => '/city/state/$stateId';
  static String districtListByState(int stateId) => '/district/state/$stateId';
  static String villageListByStateAndDistrict(int stateId, int districtId) =>
      '/city/villages/state/$stateId/district/$districtId';

  /// INSTITUTIONS
  static String institutionCreate = '/institution';
  static String institutionList = '/institution/list';
  static String institutionPrint = '/institution/print';
  static String institutionPostalPrint = '/institution/print/postal';
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

  static String competitionParticipantScoresTable(int competitionId) =>
      '/reports/competition/$competitionId/participant-scores/table';

  static String competitionParticipantsTable(int competitionId) =>
      '/reports/competition/$competitionId/participants/table';

  static String competitionParticipantScoreDetails(int competitionId) =>
      '/reports/competition/$competitionId/participant-scores/details';

  /// REPORTS PRINT (PDF / Excel as blob)
  static String competitionPrizeWinnersPrint(int competitionId) =>
      '/reports/competition/$competitionId/print/prize-winners';

  /// Winner certificate PDF generated from certificate-template design.
  /// Query params: competitionId, stageId, categoryId, participantRegistrationId, optional prizeRank
  static String winnerCertificateFromTemplate =
      '/settings/certificate-templates/winner-certificate/download';

  static String competitionParticipantsPrint(int competitionId) =>
      '/reports/competition/$competitionId/print/participants';

  static String competitionParticipantsExcel(int competitionId) =>
      '/reports/competition/$competitionId/print/participants/excel';

  static String competitionParticipantECertificatePrint(int competitionId) =>
      '/reports/competition/$competitionId/print/participant-e-certificate';

  /// ORGANIZATION / BRANCH SETUP
  static String organizationSetupFoundation = '/organization/setup/foundation';
  static String organizationSetupFoundationWithPayment =
      '/organization/setup/foundation-with-payment';
  static String organizationSetupComplete = '/organization/setup/complete';
  static String organizationSetupAdmins = '/organization/setup/admins';

  /// Branch-level certificate template CRUD.
  static String certificateTemplates = '/settings/certificate-templates';
  static String certificateTemplateById(int id) =>
      '/settings/certificate-templates/$id';
  static String certificateTemplateSetDefault(int id) =>
      '/settings/certificate-templates/$id/default';

  /// PERMISSIONS (app-level permission definitions)
  static String permission = '/permission';
  static String permissionById(String id) => '/permission/$id';
}
