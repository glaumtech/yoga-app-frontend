import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../models/api_response.dart';
import '../models/competition_scoring_reset_result.dart';

class JuryScoringRepository {
  final APIService _apiService = APIService();

  Future<ApiResponse<CompetitionScoringResetResult>> resetCompetitionScoringData({
    required List<int> competitionIds,
  }) async {
    try {
      final response = await _apiService.getResponse<Map<String, dynamic>>(
        url: EndPoints.juryScoringResetCompetitionData,
        apiType: APIType.aPost,
        body: {'competitionIds': competitionIds},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success) {
        final result = response.data != null
            ? CompetitionScoringResetResult.fromJson(response.data!)
            : const CompetitionScoringResetResult(
                participantScoresDeleted: 0,
                asanaScoresDeleted: 0,
                competitionsProcessed: 0,
              );
        return ApiResponse(
          success: true,
          message: response.message,
          data: result,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to delete scoring data',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error deleting scoring data: ${e.toString()}',
      );
    }
  }
}
