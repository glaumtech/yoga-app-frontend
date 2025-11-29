import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/judge_model.dart';
import '../models/api_response.dart';

class JudgeRepository {
  final APIService _apiService = APIService();

  Future<ApiResponse<List<JudgeModel>>> getAllJudges() async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.judgeList,
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<JudgeModel> judges = [];

        // Handle different response formats
        if (response.data is List) {
          judges = (response.data as List).map((json) {
            return JudgeModel.fromJson(
              json is Map<String, dynamic>
                  ? json
                  : json as Map<String, dynamic>,
            );
          }).toList();
        } else if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic listData =
              dataMap['data'] ??
              dataMap['judges'] ??
              dataMap['results'] ??
              dataMap['users'];

          if (listData is List) {
            judges = listData.map((json) {
              return JudgeModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : json as Map<String, dynamic>,
              );
            }).toList();
          }
        }

        return ApiResponse(success: true, data: judges);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch judges',
      );
    } catch (e, stackTrace) {
      print('Error in getAllJudges: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error loading judges: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<JudgeModel>> getJudgeById(String id) async {
    try {
      final response = await _apiService.getResponse<Map<String, dynamic>>(
        url: EndPoints.judgeById(id),
        apiType: APIType.aGet,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final judge = JudgeModel.fromJson(response.data!);
        return ApiResponse(success: true, data: judge);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch judge',
      );
    } catch (e, stackTrace) {
      print('Error in getJudgeById: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error loading judge: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<JudgeModel>> createJudge(JudgeModel judge) async {
    try {
      final judgeJson = judge.toJson(includePassword: true);

      final response = await _apiService.getResponse<Map<String, dynamic>>(
        url: EndPoints.judgeRegister,
        apiType: APIType.aPost,
        body: judgeJson,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final createdJudge = JudgeModel.fromJson(response.data!);
        return ApiResponse(success: true, data: createdJudge);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to create judge',
      );
    } catch (e, stackTrace) {
      print('Error in createJudge: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error creating judge: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<JudgeModel>> updateJudge({
    required String id,
    required JudgeModel judge,
  }) async {
    try {
      final judgeJson = judge.toJson(includePassword: true);
      // Remove id from JSON for update
      judgeJson.remove('id');

      // Remove empty password fields - only send if password is being changed
      if (judge.password == null || judge.password!.isEmpty) {
        judgeJson.remove('password');
      }
      if (judge.confirmPassword == null || judge.confirmPassword!.isEmpty) {
        judgeJson.remove('confirmPassword');
      }

      print('Updating judge - ID: $id');
      print('Judge JSON: $judgeJson');
      print('Has password: ${judgeJson.containsKey('password')}');
      print('Has confirmPassword: ${judgeJson.containsKey('confirmPassword')}');

      final response = await _apiService.getResponse<Map<String, dynamic>>(
        url: EndPoints.judgeUpdate(id),
        apiType: APIType.aPut,
        body: judgeJson,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      print(
        'Update judge response: ${response.success}, message: ${response.message}',
      );

      if (!response.success) {
        print('Update failed - Status code: ${response.statusCode}');
        print('Update failed - Response data: ${response.data}');
      }

      if (response.success && response.data != null) {
        final updatedJudge = JudgeModel.fromJson(response.data!);
        return ApiResponse(success: true, data: updatedJudge);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to update judge',
      );
    } catch (e, stackTrace) {
      print('Error in updateJudge: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error updating judge: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<bool>> deleteJudge(String id) async {
    try {
      final response = await _apiService.getResponse<bool>(
        url: EndPoints.judgeById(id),
        apiType: APIType.aDelete,
      );
      return response;
    } catch (e, stackTrace) {
      print('Error in deleteJudge: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error deleting judge: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<JudgeModel?>> getJudgeByUserId(String userId) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.judgeByUserId(userId),
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        // Handle response format: {"data": {"jury": {"id": 7, "name": "John Doe", ...}}}
        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          Map<String, dynamic>? juryData;

          // Check if data contains jury object
          if (dataMap.containsKey('data') &&
              dataMap['data'] is Map<String, dynamic>) {
            final innerData = dataMap['data'] as Map<String, dynamic>;
            if (innerData.containsKey('jury') &&
                innerData['jury'] is Map<String, dynamic>) {
              juryData = innerData['jury'] as Map<String, dynamic>;
            }
          }

          // Fallback: check if jury is directly in data
          if (juryData == null &&
              dataMap.containsKey('jury') &&
              dataMap['jury'] is Map<String, dynamic>) {
            juryData = dataMap['jury'] as Map<String, dynamic>;
          }

          // Parse jury data into JudgeModel
          if (juryData != null) {
            try {
              final judge = JudgeModel.fromJson(juryData);
              return ApiResponse(success: true, data: judge);
            } catch (e) {
              print('Error parsing judge data: $e');
              print('Jury data: $juryData');
            }
          }
        }
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Judge not found',
        data: null,
      );
    } catch (e, stackTrace) {
      print('Error in getJudgeByUserId: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error fetching judge: ${e.toString()}',
        data: null,
      );
    }
  }
}
