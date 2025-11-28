import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/team_model.dart';
import '../models/api_response.dart';
import '../models/assignment_group_model.dart';

class TeamRepository {
  final APIService _apiService = APIService();

  Future<ApiResponse<List<TeamModel>>> getAllTeams() async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.teamList,
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<TeamModel> teams = [];

        // Handle different response formats
        if (response.data is List) {
          teams = (response.data as List).map((json) {
            return TeamModel.fromJson(
              json is Map<String, dynamic>
                  ? json
                  : json as Map<String, dynamic>,
            );
          }).toList();
        } else if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic listData =
              dataMap['data'] ?? dataMap['teams'] ?? dataMap['results'];

          if (listData is List) {
            teams = listData.map((json) {
              return TeamModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : json as Map<String, dynamic>,
              );
            }).toList();
          }
        }

        return ApiResponse(success: true, data: teams);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch teams',
      );
    } catch (e, stackTrace) {
      print('Error in getAllTeams: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error loading teams: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<List<TeamModel>>> getTeamsByEventId(String eventId) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.teamByEventId(eventId),
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<TeamModel> teams = [];

        // Handle different response formats
        if (response.data is List) {
          teams = (response.data as List).map((json) {
            return TeamModel.fromJson(
              json is Map<String, dynamic>
                  ? json
                  : json as Map<String, dynamic>,
            );
          }).toList();
        } else if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic listData =
              dataMap['data'] ?? dataMap['teams'] ?? dataMap['results'];

          if (listData is List) {
            teams = listData.map((json) {
              return TeamModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : json as Map<String, dynamic>,
              );
            }).toList();
          }
        }

        return ApiResponse(success: true, data: teams);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch teams',
      );
    } catch (e, stackTrace) {
      print('Error in getTeamsByEventId: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error loading teams: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<TeamModel>> createTeam(
    TeamModel team, {
    List<Map<String, dynamic>>? juryList,
  }) async {
    try {
      final teamJson = team.toJson();

      // Transform the request body to match API format
      final requestBody = <String, dynamic>{
        'name': teamJson['teamName'], // Change teamName to name
        'eventId': teamJson['eventId'],
        'category': teamJson['category'],
      };

      // Add juryList if provided, otherwise use juryIds
      if (juryList != null && juryList.isNotEmpty) {
        requestBody['juryList'] = juryList;
      } else if (teamJson['juryIds'] != null) {
        // Fallback to juryIds if juryList not provided
        requestBody['juryIds'] = teamJson['juryIds'];
      }

      final response = await _apiService.getResponse<Map<String, dynamic>>(
        url: EndPoints.teamCreate,
        apiType: APIType.aPost,
        body: requestBody,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final createdTeam = TeamModel.fromJson(response.data!);
        return ApiResponse(success: true, data: createdTeam);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to create team',
      );
    } catch (e, stackTrace) {
      print('Error in createTeam: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error creating team: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<TeamModel>> getTeamById(String id) async {
    try {
      final response = await _apiService.getResponse<Map<String, dynamic>>(
        url: EndPoints.teamById(id),
        apiType: APIType.aGet,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final team = TeamModel.fromJson(response.data!);
        return ApiResponse(success: true, data: team);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch team',
      );
    } catch (e, stackTrace) {
      print('Error in getTeamById: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error loading team: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<TeamModel>> updateTeam(
    String teamId,
    TeamModel team, {
    List<Map<String, dynamic>>? juryList,
  }) async {
    try {
      final teamJson = team.toJson();

      // Transform the request body to match API format
      final requestBody = <String, dynamic>{
        'name': teamJson['teamName'], // Change teamName to name
        'eventId': teamJson['eventId'],
        'category': teamJson['category'],
      };

      // Add juryList if provided, otherwise use juryIds
      if (juryList != null && juryList.isNotEmpty) {
        requestBody['juryList'] = juryList;
      } else if (teamJson['juryIds'] != null) {
        // Fallback to juryIds if juryList not provided
        requestBody['juryIds'] = teamJson['juryIds'];
      }

      final response = await _apiService.getResponse<Map<String, dynamic>>(
        url: EndPoints.teamUpdate(teamId),
        apiType: APIType.aPut,
        body: requestBody,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final updatedTeam = TeamModel.fromJson(response.data!);
        return ApiResponse(success: true, data: updatedTeam);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to update team',
      );
    } catch (e, stackTrace) {
      print('Error in updateTeam: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error updating team: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<bool>> assignParticipants({
    required int eventId,
    required String teamId,
    required List<Map<String, dynamic>> juryDtos,
    required List<Map<String, dynamic>> participants,
    required String category,
  }) async {
    try {
      final requestBody = {
        'eventId': eventId,
        'teamId': teamId,
        'juryDtos': juryDtos,
        'participants': participants,
        'category': category,
      };

      final response = await _apiService.getResponse<Map<String, dynamic>>(
        url: EndPoints.assignParticipants,
        apiType: APIType.aPost,
        body: requestBody,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success) {
        return ApiResponse(success: true, data: true);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to assign participants',
      );
    } catch (e, stackTrace) {
      print('Error in assignParticipants: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error assigning participants: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<List<AssignmentGroupModel>>> getAssignedParticipants(
    String eventId, {
    int page = 0,
    int size = 10,
    String? teamId,
  }) async {
    try {
      final requestBody = {'page': page, 'size': size};

      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.assignedParticipants(eventId),
        apiType: APIType.aPost,
        body: requestBody,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<AssignmentGroupModel> assignmentGroups = [];

        // Handle different response formats
        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;

          // Check for groups structure: data.groups[]
          // Note: API service already extracts the 'data' field, so dataMap is the inner data object
          if (dataMap['groups'] != null && dataMap['groups'] is List) {
            final groups = dataMap['groups'] as List;
            // Parse each group as an AssignmentGroupModel
            for (final group in groups) {
              if (group is Map<String, dynamic>) {
                // Filter by teamId if provided
                if (teamId != null && teamId.isNotEmpty) {
                  final groupTeamId = group['teamId']?.toString();
                  if (groupTeamId != teamId) {
                    continue; // Skip groups that don't match the teamId
                  }
                }

                try {
                  final assignmentGroup = AssignmentGroupModel.fromJson(group);
                  assignmentGroups.add(assignmentGroup);
                } catch (e) {
                  print('Error parsing assignment group: $e');
                  print('Group JSON: $group');
                }
              }
            }
          }

          // Fallback: Check for nested data structure
          if (assignmentGroups.isEmpty) {
            if (dataMap['data'] != null &&
                dataMap['data'] is Map<String, dynamic>) {
              final innerData = dataMap['data'] as Map<String, dynamic>;
              if (innerData['groups'] != null && innerData['groups'] is List) {
                final groups = innerData['groups'] as List;
                for (final group in groups) {
                  if (group is Map<String, dynamic>) {
                    try {
                      final assignmentGroup = AssignmentGroupModel.fromJson(
                        group,
                      );
                      assignmentGroups.add(assignmentGroup);
                    } catch (e) {
                      print('Error parsing assignment group: $e');
                      print('Group JSON: $group');
                    }
                  }
                }
              }
            }
          }
        }

        return ApiResponse(success: true, data: assignmentGroups);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch assigned participants',
      );
    } catch (e, stackTrace) {
      print('Error in getAssignedParticipants: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error loading assigned participants: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<List<AssignmentGroupModel>>>
  getAssignedParticipantsByJudgeId(
    String eventId,
    String judgeId, {
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.assignedParticipantsByJudgeId(eventId, judgeId),
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<AssignmentGroupModel> assignmentGroups = [];

        // Handle different response formats
        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;

          // Check for groups structure: data.groups[]
          // Note: API service already extracts the 'data' field, so dataMap is the inner data object
          if (dataMap['groups'] != null && dataMap['groups'] is List) {
            final groups = dataMap['groups'] as List;
            // Parse each group as an AssignmentGroupModel
            for (final group in groups) {
              if (group is Map<String, dynamic>) {
                try {
                  final assignmentGroup = AssignmentGroupModel.fromJson(group);
                  assignmentGroups.add(assignmentGroup);
                } catch (e) {
                  print('Error parsing assignment group: $e');
                  print('Group JSON: $group');
                }
              }
            }
          }

          // Fallback: Check for nested data structure
          if (assignmentGroups.isEmpty) {
            if (dataMap['data'] != null &&
                dataMap['data'] is Map<String, dynamic>) {
              final innerData = dataMap['data'] as Map<String, dynamic>;
              if (innerData['groups'] != null && innerData['groups'] is List) {
                final groups = innerData['groups'] as List;
                for (final group in groups) {
                  if (group is Map<String, dynamic>) {
                    try {
                      final assignmentGroup = AssignmentGroupModel.fromJson(
                        group,
                      );
                      assignmentGroups.add(assignmentGroup);
                    } catch (e) {
                      print('Error parsing assignment group: $e');
                      print('Group JSON: $group');
                    }
                  }
                }
              }
            }
          }
        }

        return ApiResponse(success: true, data: assignmentGroups);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch assigned participants',
      );
    } catch (e, stackTrace) {
      print('Error in getAssignedParticipantsByJudgeId: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error loading assigned participants: ${e.toString()}',
      );
    }
  }
}
