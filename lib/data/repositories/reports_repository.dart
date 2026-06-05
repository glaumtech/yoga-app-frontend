import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/api_response.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/utils/storage_service.dart';

class ReportsRepository {
  final APIService _apiService = APIService();

  /// Query string for participant report endpoints (multi stage/category/group/gender).
  static String participantReportQuery({
    List<int>? stageIds,
    List<int>? categoryIds,
    List<int>? groupIds,
    int? stateId,
    int? cityId,
    int? institutionId,
    int? districtId,
    List<String>? genders,
    List<String>? categoryTypes,
    bool? spotRegistration,
    int? age,
    String? registrationPrefix,
    String? institutionKind,
    bool? hasInstitution,
  }) {
    final segments = <String>[];
    if (stageIds != null) {
      for (final id in stageIds) {
        segments.add('stageId=${Uri.encodeQueryComponent(id.toString())}');
      }
    }
    if (categoryIds != null) {
      for (final id in categoryIds) {
        segments.add('categoryId=${Uri.encodeQueryComponent(id.toString())}');
      }
    }
    if (groupIds != null) {
      for (final id in groupIds) {
        segments.add('groupId=${Uri.encodeQueryComponent(id.toString())}');
      }
    }
    if (stateId != null) {
      segments.add('stateId=${Uri.encodeQueryComponent(stateId.toString())}');
    }
    if (cityId != null) {
      segments.add('cityId=${Uri.encodeQueryComponent(cityId.toString())}');
    }
    if (institutionId != null) {
      segments.add(
        'institutionId=${Uri.encodeQueryComponent(institutionId.toString())}',
      );
    }
    if (districtId != null && districtId > 0) {
      segments.add('districtId=$districtId');
    }
    if (genders != null) {
      for (final g in genders) {
        if (g.isNotEmpty) {
          segments.add('gender=${Uri.encodeQueryComponent(g)}');
        }
      }
    }
    if (categoryTypes != null) {
      for (final ct in categoryTypes) {
        if (ct.isNotEmpty) {
          segments.add(
            'categoryType=${Uri.encodeQueryComponent(ct.toUpperCase())}',
          );
        }
      }
    }
    if (spotRegistration != null) {
      segments.add('spotRegistration=$spotRegistration');
    }
    if (age != null) {
      segments.add('age=${Uri.encodeQueryComponent(age.toString())}');
    }
    if (registrationPrefix != null && registrationPrefix.trim().isNotEmpty) {
      segments.add(
        'registrationPrefix=${Uri.encodeQueryComponent(registrationPrefix.trim().toUpperCase())}',
      );
    }
    if (institutionKind != null && institutionKind.trim().isNotEmpty) {
      segments.add(
        'institutionKind=${Uri.encodeQueryComponent(institutionKind.trim().toUpperCase())}',
      );
    }
    if (hasInstitution == true) {
      segments.add('hasInstitution=true');
    }
    if (segments.isEmpty) return '';
    return '?${segments.join('&')}';
  }

  /// Filters + pagination + optional name/reg search for participants registration table API.
  static String participantsTableQuery({
    required int page,
    required int size,
    String? search,
    List<int>? stageIds,
    List<int>? categoryIds,
    List<int>? groupIds,
    int? stateId,
    int? cityId,
    int? institutionId,
    int? districtId,
    List<String>? genders,
    List<String>? categoryTypes,
    bool? spotRegistration,
    int? age,
    String? registrationPrefix,
    String? institutionKind,
    bool? hasInstitution,
  }) {
    final segments = <String>[];
    final filter = participantReportQuery(
      stageIds: stageIds,
      categoryIds: categoryIds,
      groupIds: groupIds,
      stateId: stateId,
      cityId: cityId,
      institutionId: institutionId,
      districtId: districtId,
      genders: genders,
      categoryTypes: categoryTypes,
      spotRegistration: spotRegistration,
      age: age,
      registrationPrefix: registrationPrefix,
      institutionKind: institutionKind,
      hasInstitution: hasInstitution,
    );
    if (filter.isNotEmpty) {
      segments.add(filter.substring(1));
    }
    segments.add('page=${Uri.encodeQueryComponent(page.toString())}');
    segments.add('size=${Uri.encodeQueryComponent(size.toString())}');
    if (search != null && search.trim().isNotEmpty) {
      segments.add('search=${Uri.encodeQueryComponent(search.trim())}');
    }
    return '?${segments.join('&')}';
  }

  /// Filters + pagination + optional name/reg search for participant scores table API.
  static String participantScoresTableQuery({
    required int page,
    required int size,
    String? search,
    List<int>? stageIds,
    List<int>? categoryIds,
    List<int>? groupIds,
    int? stateId,
    int? cityId,
    int? institutionId,
    int? districtId,
    List<String>? genders,
  }) {
    final segments = <String>[];
    final filter = participantReportQuery(
      stageIds: stageIds,
      categoryIds: categoryIds,
      groupIds: groupIds,
      stateId: stateId,
      cityId: cityId,
      institutionId: institutionId,
      districtId: districtId,
      genders: genders,
    );
    if (filter.isNotEmpty) {
      segments.add(filter.substring(1));
    }
    segments.add('page=${Uri.encodeQueryComponent(page.toString())}');
    segments.add('size=${Uri.encodeQueryComponent(size.toString())}');
    if (search != null && search.trim().isNotEmpty) {
      segments.add('search=${Uri.encodeQueryComponent(search.trim())}');
    }
    return '?${segments.join('&')}';
  }

  /// Report filters + row bucket ids for participant score details API.
  static String participantScoreDetailsQuery({
    required int participantRegistrationId,
    required int rowStageId,
    required int rowCategoryId,
    int? rowGroupId,
    List<int>? stageIds,
    List<int>? categoryIds,
    List<int>? groupIds,
    int? stateId,
    int? cityId,
    int? institutionId,
    int? districtId,
    List<String>? genders,
  }) {
    final segments = <String>[];
    final filter = participantReportQuery(
      stageIds: stageIds,
      categoryIds: categoryIds,
      groupIds: groupIds,
      stateId: stateId,
      cityId: cityId,
      institutionId: institutionId,
      districtId: districtId,
      genders: genders,
    );
    if (filter.isNotEmpty) {
      segments.add(filter.substring(1));
    }
    segments.add(
      'participantRegistrationId=${Uri.encodeQueryComponent(participantRegistrationId.toString())}',
    );
    segments.add('rowStageId=${Uri.encodeQueryComponent(rowStageId.toString())}');
    segments.add('rowCategoryId=${Uri.encodeQueryComponent(rowCategoryId.toString())}');
    if (rowGroupId != null) {
      segments.add('rowGroupId=${Uri.encodeQueryComponent(rowGroupId.toString())}');
    }
    return '?${segments.join('&')}';
  }

  Future<ApiResponse<Map<String, dynamic>>> getCompetitionReportSummary(
    int competitionId,
  ) async {
    final response = await _apiService.getResponse<Map<String, dynamic>>(
      url: EndPoints.competitionReportSummary(competitionId),
      apiType: APIType.aGet,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: response.data);
    }

    return ApiResponse(
      success: false,
      message: response.message ?? 'Failed to load report',
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getCompetitionParticipantScores(
    int competitionId, {
    List<int>? stageIds,
    List<int>? categoryIds,
    List<int>? groupIds,
    int? stateId,
    int? cityId,
    int? institutionId,
    int? districtId,
    List<String>? genders,
  }) async {
    final q = participantReportQuery(
      stageIds: stageIds,
      categoryIds: categoryIds,
      groupIds: groupIds,
      stateId: stateId,
      cityId: cityId,
      institutionId: institutionId,
      districtId: districtId,
      genders: genders,
    );

    final response = await _apiService.getResponse<Map<String, dynamic>>(
      url: q.isEmpty
          ? EndPoints.competitionParticipantScores(competitionId)
          : '${EndPoints.competitionParticipantScores(competitionId)}$q',
      apiType: APIType.aGet,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: response.data);
    }

    return ApiResponse(
      success: false,
      message: response.message ?? 'Failed to load participant scores report',
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getCompetitionParticipantScoresTable(
    int competitionId, {
    required int page,
    int size = 20,
    String? search,
    List<int>? stageIds,
    List<int>? categoryIds,
    List<int>? groupIds,
    int? stateId,
    int? cityId,
    int? institutionId,
    int? districtId,
    List<String>? genders,
  }) async {
    final q = participantScoresTableQuery(
      page: page,
      size: size,
      search: search,
      stageIds: stageIds,
      categoryIds: categoryIds,
      groupIds: groupIds,
      stateId: stateId,
      cityId: cityId,
      institutionId: institutionId,
      districtId: districtId,
      genders: genders,
    );

    final response = await _apiService.getResponse<Map<String, dynamic>>(
      url: '${EndPoints.competitionParticipantScoresTable(competitionId)}$q',
      apiType: APIType.aGet,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: response.data);
    }

    return ApiResponse(
      success: false,
      message: response.message ?? 'Failed to load participant scores table',
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getCompetitionParticipantsTable(
    int competitionId, {
    required int page,
    int size = 20,
    String? search,
    List<int>? stageIds,
    List<int>? categoryIds,
    List<int>? groupIds,
    int? stateId,
    int? cityId,
    int? institutionId,
    int? districtId,
    List<String>? genders,
    List<String>? categoryTypes,
    bool? spotRegistration,
    int? age,
    String? registrationPrefix,
    String? institutionKind,
    bool? hasInstitution,
  }) async {
    final q = participantsTableQuery(
      page: page,
      size: size,
      search: search,
      stageIds: stageIds,
      categoryIds: categoryIds,
      groupIds: groupIds,
      stateId: stateId,
      cityId: cityId,
      institutionId: institutionId,
      districtId: districtId,
      genders: genders,
      categoryTypes: categoryTypes,
      spotRegistration: spotRegistration,
      age: age,
      registrationPrefix: registrationPrefix,
      institutionKind: institutionKind,
      hasInstitution: hasInstitution,
    );

    final response = await _apiService.getResponse<Map<String, dynamic>>(
      url: '${EndPoints.competitionParticipantsTable(competitionId)}$q',
      apiType: APIType.aGet,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: response.data);
    }

    return ApiResponse(
      success: false,
      message: response.message ?? 'Failed to load participants table',
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getParticipantScoreDetails(
    int competitionId, {
    required int participantRegistrationId,
    required int rowStageId,
    required int rowCategoryId,
    int? rowGroupId,
    List<int>? stageIds,
    List<int>? categoryIds,
    List<int>? groupIds,
    int? stateId,
    int? cityId,
    int? institutionId,
    int? districtId,
    List<String>? genders,
  }) async {
    final q = participantScoreDetailsQuery(
      participantRegistrationId: participantRegistrationId,
      rowStageId: rowStageId,
      rowCategoryId: rowCategoryId,
      rowGroupId: rowGroupId,
      stageIds: stageIds,
      categoryIds: categoryIds,
      groupIds: groupIds,
      stateId: stateId,
      cityId: cityId,
      institutionId: institutionId,
      districtId: districtId,
      genders: genders,
    );

    final response = await _apiService.getResponse<Map<String, dynamic>>(
      url: '${EndPoints.competitionParticipantScoreDetails(competitionId)}$q',
      apiType: APIType.aGet,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: response.data);
    }

    return ApiResponse(
      success: false,
      message: response.message ?? 'Failed to load participant score details',
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<Uint8List>> getPrizeWinnerCertificatePdf(
    int competitionId, {
    required int stageId,
    required int categoryId,
    required int participantRegistrationId,
    int? prizeRank,
  }) async {
    try {
      final params = <String>[
        'competitionId=$competitionId',
        'stageId=$stageId',
        'categoryId=$categoryId',
        'participantRegistrationId=$participantRegistrationId',
      ];
      if (prizeRank != null) {
        params.add('prizeRank=$prizeRank');
      }
      final url =
          BaseUrl.baseUrl +
          EndPoints.winnerCertificateFromTemplate +
          '?${params.join('&')}';
      final uri = Uri.parse(url);

      final token = StorageService.getString(AppConstants.tokenKey);
      final headers = <String, String>{
        'Accept': 'application/pdf',
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(uri, headers: headers)
          .timeout(BaseUrl.apiTimeout);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: response.bodyBytes,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        message:
            'Failed to generate prize certificate (status ${response.statusCode})',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error generating prize certificate: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<Uint8List>> getCompetitionPrizeWinnersPrintPdf(
    int competitionId,
  ) async {
    try {
      final url =
          BaseUrl.baseUrl +
          EndPoints.competitionPrizeWinnersPrint(competitionId);
      final uri = Uri.parse(url);

      final token = StorageService.getString(AppConstants.tokenKey);
      final headers = <String, String>{
        'Accept': 'application/pdf',
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(uri, headers: headers)
          .timeout(BaseUrl.apiTimeout);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: response.bodyBytes,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        message:
            'Failed to generate Prize Winners PDF (status ${response.statusCode})',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error generating Prize Winners PDF: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<Uint8List>> getParticipantECertificatePdf(
    int competitionId, {
    required int participantRegistrationId,
    required int stageId,
    required int categoryId,
    int? groupId,
  }) async {
    try {
      final params = <String>[
        'participantRegistrationId=$participantRegistrationId',
        'stageId=$stageId',
        'categoryId=$categoryId',
      ];
      if (groupId != null) {
        params.add('groupId=$groupId');
      }
      final url =
          BaseUrl.baseUrl +
          EndPoints.competitionParticipantECertificatePrint(competitionId) +
          '?${params.join('&')}';
      final uri = Uri.parse(url);

      final token = StorageService.getString(AppConstants.tokenKey);
      final headers = <String, String>{
        'Accept': 'application/pdf',
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(uri, headers: headers)
          .timeout(BaseUrl.apiTimeout);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: response.bodyBytes,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        message:
            'Failed to download e-certificate (status ${response.statusCode})',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error downloading e-certificate: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<Uint8List>> getCompetitionParticipantsPrintPdf(
    int competitionId, {
    List<int>? stageIds,
    List<int>? categoryIds,
    List<int>? groupIds,
    int? stateId,
    int? cityId,
    int? institutionId,
    int? districtId,
    List<String>? genders,
  }) async {
    try {
      final q = participantReportQuery(
        stageIds: stageIds,
        categoryIds: categoryIds,
        groupIds: groupIds,
        stateId: stateId,
        cityId: cityId,
        institutionId: institutionId,
        districtId: districtId,
        genders: genders,
      );

      final path = EndPoints.competitionParticipantsPrint(competitionId);
      final url = BaseUrl.baseUrl + path + q;

      final uri = Uri.parse(url);

      final token = StorageService.getString(AppConstants.tokenKey);
      final headers = <String, String>{
        'Accept': 'application/pdf',
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(uri, headers: headers)
          .timeout(BaseUrl.apiTimeout);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: response.bodyBytes,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        message:
            'Failed to generate Participants PDF (status ${response.statusCode})',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error generating Participants PDF: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<Uint8List>> getCompetitionParticipantsExcel(
    int competitionId, {
    List<int>? stageIds,
    List<int>? categoryIds,
    List<int>? groupIds,
    int? stateId,
    int? cityId,
    int? institutionId,
    int? districtId,
    List<String>? genders,
  }) async {
    try {
      final q = participantReportQuery(
        stageIds: stageIds,
        categoryIds: categoryIds,
        groupIds: groupIds,
        stateId: stateId,
        cityId: cityId,
        institutionId: institutionId,
        districtId: districtId,
        genders: genders,
      );

      final path = EndPoints.competitionParticipantsExcel(competitionId);
      final url = BaseUrl.baseUrl + path + q;

      final uri = Uri.parse(url);

      final token = StorageService.getString(AppConstants.tokenKey);
      final headers = <String, String>{
        'Accept':
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(uri, headers: headers)
          .timeout(BaseUrl.apiTimeout);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: response.bodyBytes,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        message:
            'Failed to generate Participants Excel (status ${response.statusCode})',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error generating Participants Excel: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}
