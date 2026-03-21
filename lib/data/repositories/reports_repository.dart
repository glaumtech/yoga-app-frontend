import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/api_response.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/utils/storage_service.dart';

class ReportsRepository {
  final APIService _apiService = APIService();

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
    int? stageId,
    int? categoryId,
    int? groupId,
  }) async {
    final params = <String>[];
    if (stageId != null) params.add('stageId=$stageId');
    if (categoryId != null) params.add('categoryId=$categoryId');
    if (groupId != null) params.add('groupId=$groupId');

    final response = await _apiService.getResponse<Map<String, dynamic>>(
      url: params.isEmpty
          ? EndPoints.competitionParticipantScores(competitionId)
          : '${EndPoints.competitionParticipantScores(competitionId)}?${params.join('&')}',
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

  Future<ApiResponse<Uint8List>> getPrizeWinnerCertificatePdf(
    int competitionId, {
    required int stageId,
    required int categoryId,
    required int participantRegistrationId,
    int? prizeRank,
  }) async {
    try {
      final params = <String>[
        'stageId=$stageId',
        'categoryId=$categoryId',
        'participantRegistrationId=$participantRegistrationId',
      ];
      if (prizeRank != null) {
        params.add('prizeRank=$prizeRank');
      }
      final url = BaseUrl.baseUrl +
          EndPoints.competitionPrizeWinnerCertificate(competitionId) +
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

      final response =
          await http.get(uri, headers: headers).timeout(BaseUrl.apiTimeout);

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
      final url = BaseUrl.baseUrl + EndPoints.competitionPrizeWinnersPrint(competitionId);
      final uri = Uri.parse(url);

      final token = StorageService.getString(AppConstants.tokenKey);
      final headers = <String, String>{
        'Accept': 'application/pdf',
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(uri, headers: headers).timeout(BaseUrl.apiTimeout);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: response.bodyBytes,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        message: 'Failed to generate Prize Winners PDF (status ${response.statusCode})',
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

  Future<ApiResponse<Uint8List>> getCompetitionParticipantsPrintPdf(
    int competitionId, {
    int? stageId,
    int? categoryId,
    int? groupId,
  }) async {
    try {
      final params = <String>[];
      if (stageId != null) params.add('stageId=$stageId');
      if (categoryId != null) params.add('categoryId=$categoryId');
      if (groupId != null) params.add('groupId=$groupId');

      final path = EndPoints.competitionParticipantsPrint(competitionId);
      final url =
          params.isEmpty ? (BaseUrl.baseUrl + path) : (BaseUrl.baseUrl + path + '?${params.join('&')}');

      final uri = Uri.parse(url);

      final token = StorageService.getString(AppConstants.tokenKey);
      final headers = <String, String>{
        'Accept': 'application/pdf',
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(uri, headers: headers).timeout(BaseUrl.apiTimeout);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: response.bodyBytes,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        message: 'Failed to generate Participants PDF (status ${response.statusCode})',
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
    int? stageId,
    int? categoryId,
    int? groupId,
  }) async {
    try {
      final params = <String>[];
      if (stageId != null) params.add('stageId=$stageId');
      if (categoryId != null) params.add('categoryId=$categoryId');
      if (groupId != null) params.add('groupId=$groupId');

      final path = EndPoints.competitionParticipantsExcel(competitionId);
      final url = params.isEmpty
          ? (BaseUrl.baseUrl + path)
          : (BaseUrl.baseUrl + path + '?${params.join('&')}');

      final uri = Uri.parse(url);

      final token = StorageService.getString(AppConstants.tokenKey);
      final headers = <String, String>{
        'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'Content-Type': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(uri, headers: headers).timeout(BaseUrl.apiTimeout);

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
