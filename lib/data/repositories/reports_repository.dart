import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/api_response.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
    String? yogaTeacherName,
    String? yogaTeacherCell,
    String? search,
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
    if (yogaTeacherName != null && yogaTeacherName.trim().isNotEmpty) {
      segments.add(
        'yogaTeacherName=${Uri.encodeQueryComponent(yogaTeacherName.trim())}',
      );
    }
    if (yogaTeacherCell != null && yogaTeacherCell.trim().isNotEmpty) {
      segments.add(
        'yogaTeacherCell=${Uri.encodeQueryComponent(yogaTeacherCell.trim())}',
      );
    }
    if (search != null && search.trim().isNotEmpty) {
      segments.add('search=${Uri.encodeQueryComponent(search.trim())}');
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
    String? yogaTeacherName,
    String? yogaTeacherCell,
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
      yogaTeacherName: yogaTeacherName,
      yogaTeacherCell: yogaTeacherCell,
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
    String? yogaTeacherName,
    String? yogaTeacherCell,
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
      yogaTeacherName: yogaTeacherName,
      yogaTeacherCell: yogaTeacherCell,
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
    int? stageId,
    int? categoryId,
    int? groupId,
  }) async {
    try {
      final params = <String>[
        'participantRegistrationId=$participantRegistrationId',
      ];
      if (stageId != null) {
        params.add('stageId=$stageId');
      }
      if (categoryId != null) {
        params.add('categoryId=$categoryId');
      }
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

      final errorBody = utf8.decode(response.bodyBytes, allowMalformed: true).trim();
      return ApiResponse(
        success: false,
        message: errorBody.isNotEmpty
            ? errorBody
            : 'Failed to download e-certificate (status ${response.statusCode})',
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

  Future<ApiResponse<Uint8List>> getCompetitionInstitutionsPrintPdf(
    int competitionId, {
    String? institutionKind,
    bool sortDesc = true,
    String? search,
    String? title,
  }) async {
    try {
      final params = <String>[];
      if (institutionKind != null && institutionKind.trim().isNotEmpty) {
        params.add(
          'institutionKind=${Uri.encodeQueryComponent(institutionKind.trim())}',
        );
      }
      params.add('sortDesc=$sortDesc');
      if (search != null && search.trim().isNotEmpty) {
        params.add('search=${Uri.encodeQueryComponent(search.trim())}');
      }
      if (title != null && title.trim().isNotEmpty) {
        params.add('title=${Uri.encodeQueryComponent(title.trim())}');
      }
      final q = params.isEmpty ? '' : '?${params.join('&')}';

      final path = EndPoints.competitionInstitutionsPrint(competitionId);
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

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return ApiResponse(
          success: true,
          data: response.bodyBytes,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        message:
            'Failed to generate Institutions PDF (status ${response.statusCode})',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error generating Institutions PDF: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<Uint8List>> getCompetitionMastersPrintPdf(
    int competitionId, {
    bool sortDesc = true,
    String? search,
    String? title,
  }) async {
    try {
      final params = <String>[
        'sortDesc=$sortDesc',
      ];
      if (search != null && search.trim().isNotEmpty) {
        params.add('search=${Uri.encodeQueryComponent(search.trim())}');
      }
      if (title != null && title.trim().isNotEmpty) {
        params.add('title=${Uri.encodeQueryComponent(title.trim())}');
      }
      final q = '?${params.join('&')}';

      final path = EndPoints.competitionMastersPrint(competitionId);
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

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return ApiResponse(
          success: true,
          data: response.bodyBytes,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        message:
            'Failed to generate Masters PDF (status ${response.statusCode})',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error generating Masters PDF: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<Uint8List>> getCompetitionMastersExcel(
    int competitionId, {
    bool sortDesc = true,
    String? search,
    String? title,
  }) async {
    try {
      final params = <String>[
        'sortDesc=$sortDesc',
      ];
      if (search != null && search.trim().isNotEmpty) {
        params.add('search=${Uri.encodeQueryComponent(search.trim())}');
      }
      if (title != null && title.trim().isNotEmpty) {
        params.add('title=${Uri.encodeQueryComponent(title.trim())}');
      }
      final q = '?${params.join('&')}';

      final path = EndPoints.competitionMastersExcel(competitionId);
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

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return ApiResponse(
          success: true,
          data: response.bodyBytes,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        message:
            'Failed to generate Masters Excel (status ${response.statusCode})',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error generating Masters Excel: ${e.toString()}',
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
    List<String>? categoryTypes,
    bool? spotRegistration,
    int? age,
    String? registrationPrefix,
    String? institutionKind,
    bool? hasInstitution,
    String? search,
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
        categoryTypes: categoryTypes,
        spotRegistration: spotRegistration,
        age: age,
        registrationPrefix: registrationPrefix,
        institutionKind: institutionKind,
        hasInstitution: hasInstitution,
        search: search,
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

  Future<ApiResponse<Uint8List>> getRegisteredParticipantsExcel(
    int competitionId, {
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
    String? search,
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
        categoryTypes: categoryTypes,
        spotRegistration: spotRegistration,
        age: age,
        registrationPrefix: registrationPrefix,
        institutionKind: institutionKind,
        hasInstitution: hasInstitution,
        search: search,
      );

      final path =
          EndPoints.competitionRegisteredParticipantsExcel(competitionId);
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

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return ApiResponse(
          success: true,
          data: response.bodyBytes,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        message:
            'Failed to generate Registered Participants Excel (status ${response.statusCode})',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message:
            'Error generating Registered Participants Excel: ${e.toString()}',
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

  Future<ApiResponse<Map<String, dynamic>>> getCompetitionFinancialReport(
    int competitionId,
  ) async {
    final response = await _apiService.getResponse<Map<String, dynamic>>(
      url: EndPoints.competitionFinancialReport(competitionId),
      apiType: APIType.aGet,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: response.data);
    }

    return ApiResponse(
      success: false,
      message: response.message ?? 'Failed to load financial report',
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<Uint8List>> getCompetitionFinancialReportPrintPdf(
    int competitionId,
  ) async {
    try {
      final path = EndPoints.competitionFinancialReportPrint(competitionId);
      final url = BaseUrl.baseUrl + path;
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

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return ApiResponse(
          success: true,
          data: response.bodyBytes,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        message:
            'Failed to generate Financial Report PDF (status ${response.statusCode})',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error generating Financial Report PDF: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> createCysTransfer({
    required int competitionId,
    required double amount,
    String? referenceNumber,
    String? transferDate,
    Uint8List? screenshotBytes,
    String? screenshotFilename,
  }) async {
    final fields = <String, String>{
      'amount': amount.toStringAsFixed(2),
      if (referenceNumber != null && referenceNumber.trim().isNotEmpty)
        'referenceNumber': referenceNumber.trim(),
      if (transferDate != null && transferDate.trim().isNotEmpty)
        'transferDate': transferDate.trim(),
    };
    http.MultipartFile? file;
    if (screenshotBytes != null && screenshotBytes.isNotEmpty) {
      final name = screenshotFilename ?? 'screenshot.jpg';
      file = http.MultipartFile.fromBytes(
        'screenshot',
        screenshotBytes,
        filename: name,
        contentType: _imageMediaType(name),
      );
    }
    final response = await _apiService.postMultipart<Map<String, dynamic>>(
      url: EndPoints.competitionCysTransfers(competitionId),
      fields: fields,
      file: file,
      fromJson: (json) =>
          json is Map<String, dynamic>
              ? json
              : Map<String, dynamic>.from(json as Map),
    );
    if (response.success) {
      return ApiResponse(success: true, data: response.data, message: response.message);
    }
    return ApiResponse(
      success: false,
      message: response.message ?? 'Failed to save transfer',
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateCysTransfer({
    required int competitionId,
    required int transferId,
    double? amount,
    String? referenceNumber,
    String? transferDate,
    bool clearScreenshot = false,
    Uint8List? screenshotBytes,
    String? screenshotFilename,
  }) async {
    final fields = <String, String>{
      if (amount != null) 'amount': amount.toStringAsFixed(2),
      if (referenceNumber != null) 'referenceNumber': referenceNumber,
      if (transferDate != null) 'transferDate': transferDate,
      'clearScreenshot': clearScreenshot.toString(),
    };
    http.MultipartFile? file;
    if (screenshotBytes != null && screenshotBytes.isNotEmpty) {
      final name = screenshotFilename ?? 'screenshot.jpg';
      file = http.MultipartFile.fromBytes(
        'screenshot',
        screenshotBytes,
        filename: name,
        contentType: _imageMediaType(name),
      );
    }
    final response = await _apiService.postMultipart<Map<String, dynamic>>(
      url: EndPoints.competitionCysTransferById(competitionId, transferId),
      fields: fields,
      file: file,
      fromJson: (json) =>
          json is Map<String, dynamic>
              ? json
              : Map<String, dynamic>.from(json as Map),
    );
    if (response.success) {
      return ApiResponse(success: true, data: response.data, message: response.message);
    }
    return ApiResponse(
      success: false,
      message: response.message ?? 'Failed to update transfer',
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<void>> deleteCysTransfer({
    required int competitionId,
    required int transferId,
  }) async {
    final response = await _apiService.getResponse<Map<String, dynamic>>(
      url: EndPoints.competitionCysTransferById(competitionId, transferId),
      apiType: APIType.aDelete,
      fromJson: (json) => json as Map<String, dynamic>,
    );
    if (response.success) {
      return ApiResponse(success: true, message: response.message);
    }
    return ApiResponse(
      success: false,
      message: response.message ?? 'Failed to delete transfer',
      statusCode: response.statusCode,
    );
  }

  String cysTransferScreenshotUrl(int competitionId, int transferId) {
    return BaseUrl.baseUrl +
        EndPoints.competitionCysTransferScreenshot(competitionId, transferId);
  }

  MediaType _imageMediaType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    return MediaType('image', 'jpeg');
  }
}
