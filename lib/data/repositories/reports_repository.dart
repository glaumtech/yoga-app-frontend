import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/api_response.dart';

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
}

