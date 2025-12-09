import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../config/app_config.dart';

class AppConstants {
  // App Info
  static const String appName = 'Yogasana Championship 2025';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String tokenKey = 'token_key';
  static const String userKey = 'user_data';
  static const String roleKey = 'user_role';

  // User Roles
  static const String roleUser = 'user';
  static const String roleAdmin = 'admin';

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
  static const String categoryCommon = 'Common';
  static const String categorySpecial = 'Special';

  // Genders
  static const String genderMale = 'Male';
  static const String genderFemale = 'Female';

  // Jury Count
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

  /// EVENTS
  static String eventRegister = '/event/register';
  static String eventList = '/event/list';
  static String eventUpdate(String id) => '/event/update/$id';
  static String eventById(String id) => '/event/$id';
  static String eventImage(String id) => '/event/image/$id';

  /// JUDGES
  static String judgeList = '/judge/list';
  static String judgeRegister = '/judge/register';
  static String judgeUpdate(String id) => '/judge/update/$id';
  static String judgeById(String id) => '/judge/$id';
  static String judgeByUserId(String userId) => '/judge/judge-id/$userId';

  /// TEAMS
  static String teamList = '/team/all';
  static String teamCreate = '/team/register';
  static String teamUpdate(String id) => '/team/update/$id';
  static String teamById(String id) => '/team/$id';
  static String teamDelete(String id) => '/team/delete/$id';
  static String teamByEventId(String eventId) => '/team/$eventId/all';

  /// PARTICIPANT ASSIGNMENTS
  static String assignParticipants = '/assign-participants/assign';
  static String assignedParticipants(String eventId) =>
      '/assign-participants/$eventId/assignments';
  static String assignedParticipantsByJudgeId(String eventId, String judgeId) =>
      '/assign-participants/event/$eventId?juryId=$judgeId';

  /// SCORING
  static String scoringSave = '/scoring/save';
  static String scoringByEventId(String eventId) => '/scoring/event/$eventId';
  static String participantScoresByEventId(String eventId) =>
      '/scoring/event/$eventId';
  static String participantScoresByParticipantId(
    String eventId,
    String participantId,
  ) => '/scoring/event/$eventId/participant/$participantId';
}
