import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/competition_model.dart';
import '../models/competition_option_model.dart';
import '../models/api_response.dart';

// Response class for competitions list with pagination
class CompetitionsListResponse {
  final List<CompetitionModel> competitions;
  final Map<String, dynamic>? pagination;

  CompetitionsListResponse({required this.competitions, this.pagination});
}

class CompetitionRepository {
  final APIService _apiService = APIService();

  Future<ApiResponse<CompetitionModel>> createCompetition({
    required CompetitionModel competition,
    XFile? brochureFile,
    File? brochureFileLocal,
    Uint8List? brochureBytes,
  }) async {
    try {
      // Prepare competition data as JSON string
      final competitionJson = competition.toJson();
      final dataJsonString = jsonEncode(competitionJson);

      // Prepare brochure file (if provided)
      http.MultipartFile multipartFile;

      if (kIsWeb && brochureBytes != null) {
        multipartFile = http.MultipartFile.fromBytes(
          'brochure',
          brochureBytes,
          filename: 'competition_brochure.pdf',
        );
      } else if (brochureFile != null) {
        final fileBytes = await brochureFile.readAsBytes();
        multipartFile = http.MultipartFile.fromBytes(
          'brochure',
          fileBytes,
          filename: brochureFile.name,
        );
      } else if (brochureFileLocal != null) {
        final fileBytes = await brochureFileLocal.readAsBytes();
        multipartFile = http.MultipartFile.fromBytes(
          'brochure',
          fileBytes,
          filename: brochureFileLocal.path.split('/').last,
        );
      } else {
        // No brochure provided - send empty file
        multipartFile = http.MultipartFile.fromBytes(
          'brochure',
          [],
          filename: '',
        );
      }

      // Send data as JSON string in 'data' field (backend requirement)
      final fields = <String, String>{'data': dataJsonString};

      print('Creating competition with multipart - data: $dataJsonString');
      print(
        'Brochure file: ${multipartFile.filename} (${multipartFile.length} bytes)',
      );

      final response = await _apiService.postMultipart<Map<String, dynamic>>(
        url: EndPoints.competitionCreate,
        fields: fields,
        file: multipartFile,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      print(
        'Create competition response: ${response.success}, message: ${response.message}',
      );

      if (response.success && response.data != null) {
        final createdCompetition = CompetitionModel.fromJson(response.data!);
        return ApiResponse(success: true, data: createdCompetition);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to create competition',
      );
    } catch (e, stackTrace) {
      print('Error in createCompetition: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error creating competition: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<CompetitionModel>> updateCompetition({
    required CompetitionModel competition,
    XFile? brochureFile,
    File? brochureFileLocal,
    Uint8List? brochureBytes,
  }) async {
    try {
      if (competition.id == null) {
        return ApiResponse(
          success: false,
          message: 'Competition ID is required for update',
        );
      }

      // Prepare competition data as JSON string
      // For update, don't include metadata (id, createdAt, updatedAt) in the data field
      final competitionJson = competition.toJson(includeMetadata: false);
      final dataJsonString = jsonEncode(competitionJson);

      print('Update competition request data: $dataJsonString');

      // Prepare brochure file (if provided)
      http.MultipartFile multipartFile;

      if (kIsWeb && brochureBytes != null) {
        multipartFile = http.MultipartFile.fromBytes(
          'brochure',
          brochureBytes,
          filename: 'competition_brochure.pdf',
        );
      } else if (brochureFile != null) {
        final fileBytes = await brochureFile.readAsBytes();
        multipartFile = http.MultipartFile.fromBytes(
          'brochure',
          fileBytes,
          filename: brochureFile.name,
        );
      } else if (brochureFileLocal != null) {
        final fileBytes = await brochureFileLocal.readAsBytes();
        multipartFile = http.MultipartFile.fromBytes(
          'brochure',
          fileBytes,
          filename: brochureFileLocal.path.split('/').last,
        );
      } else {
        // No brochure provided - send empty file
        multipartFile = http.MultipartFile.fromBytes(
          'brochure',
          [],
          filename: '',
        );
      }

      // Send data as JSON string in 'data' field (backend requirement)
      final fields = <String, String>{'data': dataJsonString};

      print('Updating competition with multipart - data: $dataJsonString');
      print(
        'Brochure file: ${multipartFile.filename} (${multipartFile.length} bytes)',
      );

      final response = await _apiService.putMultipart<Map<String, dynamic>>(
        url: EndPoints.competitionUpdate(competition.id!),
        fields: fields,
        file: multipartFile,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      print(
        'Update competition response: ${response.success}, message: ${response.message}',
      );

      if (response.success && response.data != null) {
        final updatedCompetition = CompetitionModel.fromJson(response.data!);
        return ApiResponse(success: true, data: updatedCompetition);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to update competition',
      );
    } catch (e, stackTrace) {
      print('Error in updateCompetition: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error updating competition: ${e.toString()}',
      );
    }
  }

  /// Public API for home screen: GET /competition/public
  Future<ApiResponse<List<HomeCompetitionModel>>>
  getCompetitionsPublic() async {
    try {
      final response = await _apiService
          .getResponse<List<HomeCompetitionModel>>(
            url: EndPoints.competitionPublic,
            apiType: APIType.aGet,
            fromJson: (json) {
              if (json == null) return <HomeCompetitionModel>[];
              if (json is List) {
                return json
                    .map(
                      (e) => HomeCompetitionModel.fromJson(
                        e as Map<String, dynamic>,
                      ),
                    )
                    .toList();
              }
              return <HomeCompetitionModel>[];
            },
          );
      return response;
    } catch (e, stackTrace) {
      print('Error in getCompetitionsPublic: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error loading competitions: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<CompetitionsListResponse>> getAllCompetitions({
    String? search,
    String? status,
    int? page,
    int? limit,
    String? sortBy,
    String? order,
  }) async {
    try {
      // Build request body (CompetitionFilterRequest DTO)
      final requestBody = <String, dynamic>{};

      if (search != null && search.isNotEmpty) {
        requestBody['search'] = search;
      }
      if (status != null && status.isNotEmpty) {
        requestBody['status'] = status;
      }
      requestBody['page'] = page ?? 0; // Default: 0
      requestBody['limit'] = limit ?? 20; // Default: 20
      requestBody['sortBy'] = sortBy ?? 'createdAt'; // Default: createdAt
      requestBody['order'] = order ?? 'desc'; // Default: desc

      print('Competition list request body: ${jsonEncode(requestBody)}');

      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.competitionList,
        apiType: APIType.aPost,
        body: requestBody,
        fromJson: (json) => json,
      );

      print('Response success: ${response.success}');
      print('Response data type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');

      if (response.success && response.data != null) {
        List<CompetitionModel> competitions = [];
        Map<String, dynamic>? paginationData;

        // Response structure from API: { "success": true, "data": { "competitions": [...], "pagination": {...} } }
        // APIService may extract the inner "data" object, so response.data might be:
        // Option 1: { "competitions": [...], "pagination": {...} } (extracted by APIService)
        // Option 2: { "data": { "competitions": [...], "pagination": {...} }, "success": true, "message": "..." } (full response)
        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          print('DataMap keys: ${dataMap.keys}');

          // Check if we have the inner data object (extracted by APIService)
          if (dataMap.containsKey('competitions')) {
            // Option 1: response.data is already the inner data object
            final competitionsList = dataMap['competitions'];
            if (competitionsList is List) {
              competitions = competitionsList.map((json) {
                try {
                  return CompetitionModel.fromJson(
                    json is Map<String, dynamic>
                        ? json
                        : json as Map<String, dynamic>,
                  );
                } catch (e) {
                  print('Error parsing competition: $e, json: $json');
                  rethrow;
                }
              }).toList();
            }

            if (dataMap.containsKey('pagination')) {
              paginationData = dataMap['pagination'] as Map<String, dynamic>?;
            }
          } else if (dataMap.containsKey('data')) {
            // Option 2: response.data is the full response, extract inner data
            final innerData = dataMap['data'];
            if (innerData is Map<String, dynamic>) {
              final competitionsList = innerData['competitions'];
              if (competitionsList is List) {
                competitions = competitionsList.map((json) {
                  try {
                    return CompetitionModel.fromJson(
                      json is Map<String, dynamic>
                          ? json
                          : json as Map<String, dynamic>,
                    );
                  } catch (e) {
                    print('Error parsing competition: $e, json: $json');
                    rethrow;
                  }
                }).toList();
              }

              if (innerData.containsKey('pagination')) {
                paginationData =
                    innerData['pagination'] as Map<String, dynamic>?;
              }
            }
          }
        } else if (response.data is List) {
          // Fallback: if response.data is directly a list
          competitions = (response.data as List).map((json) {
            return CompetitionModel.fromJson(
              json is Map<String, dynamic>
                  ? json
                  : json as Map<String, dynamic>,
            );
          }).toList();
        }

        print('Parsed ${competitions.length} competitions');
        print('Pagination data: $paginationData');

        final listResponse = CompetitionsListResponse(
          competitions: competitions,
          pagination: paginationData,
        );

        print('Pagination info: $paginationData');

        return ApiResponse<CompetitionsListResponse>(
          success: true,
          data: listResponse,
        );
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch competitions',
      );
    } catch (e) {
      print('Error in getAllCompetitions: $e');
      return ApiResponse(
        success: false,
        message: 'Error fetching competitions: ${e.toString()}',
      );
    }
  }

  // Get all categories
  Future<ApiResponse<List<CompetitionOptionModel>>> getAllCategories() async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.categoryList,
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<CompetitionOptionModel> categories = [];

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic listData =
              dataMap['data']?['categories'] ?? dataMap['categories'];

          if (listData is List) {
            categories = listData.map((json) {
              return CompetitionOptionModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : json as Map<String, dynamic>,
              );
            }).toList();
          }
        } else if (response.data is List) {
          categories = (response.data as List).map((json) {
            return CompetitionOptionModel.fromJson(
              json is Map<String, dynamic>
                  ? json
                  : json as Map<String, dynamic>,
            );
          }).toList();
        }

        return ApiResponse(success: true, data: categories);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch categories',
      );
    } catch (e) {
      print('Error in getAllCategories: $e');
      return ApiResponse(
        success: false,
        message: 'Error fetching categories: ${e.toString()}',
      );
    }
  }

  // Get categories by competition ID
  Future<ApiResponse<List<CompetitionOptionModel>>> getCategoriesByCompetition(
    int competitionId,
  ) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.categoryByCompetition(competitionId),
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<CompetitionOptionModel> categories = [];

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          // API returns: { "data": { "categories": [...] } }
          dynamic listData =
              dataMap['data']?['categories'] ?? dataMap['categories'];

          if (listData is List) {
            categories = listData.map((json) {
              return CompetitionOptionModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : json as Map<String, dynamic>,
              );
            }).toList();
          }
        } else if (response.data is List) {
          categories = (response.data as List).map((json) {
            return CompetitionOptionModel.fromJson(
              json is Map<String, dynamic>
                  ? json
                  : json as Map<String, dynamic>,
            );
          }).toList();
        }

        return ApiResponse(success: true, data: categories);
      }

      return ApiResponse(
        success: false,
        message:
            response.message ?? 'Failed to fetch categories for competition',
      );
    } catch (e) {
      print('Error in getCategoriesByCompetition: $e');
      return ApiResponse(
        success: false,
        message: 'Error fetching categories for competition: ${e.toString()}',
      );
    }
  }

  // Get all prizes
  Future<ApiResponse<List<CompetitionOptionModel>>> getAllPrizes() async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.prizeList,
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<CompetitionOptionModel> prizes = [];

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic listData = dataMap['data']?['prizes'] ?? dataMap['prizes'];

          if (listData is List) {
            prizes = listData.map((json) {
              return CompetitionOptionModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : json as Map<String, dynamic>,
              );
            }).toList();
          }
        } else if (response.data is List) {
          prizes = (response.data as List).map((json) {
            return CompetitionOptionModel.fromJson(
              json is Map<String, dynamic>
                  ? json
                  : json as Map<String, dynamic>,
            );
          }).toList();
        }

        return ApiResponse(success: true, data: prizes);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch prizes',
      );
    } catch (e) {
      print('Error in getAllPrizes: $e');
      return ApiResponse(
        success: false,
        message: 'Error fetching prizes: ${e.toString()}',
      );
    }
  }

  // Get all stages
  Future<ApiResponse<List<CompetitionOptionModel>>> getAllStages() async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.stageList,
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<CompetitionOptionModel> stages = [];

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic listData = dataMap['data']?['stages'] ?? dataMap['stages'];

          if (listData is List) {
            stages = listData.map((json) {
              return CompetitionOptionModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : json as Map<String, dynamic>,
              );
            }).toList();
          }
        } else if (response.data is List) {
          stages = (response.data as List).map((json) {
            return CompetitionOptionModel.fromJson(
              json is Map<String, dynamic>
                  ? json
                  : json as Map<String, dynamic>,
            );
          }).toList();
        }

        return ApiResponse(success: true, data: stages);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch stages',
      );
    } catch (e) {
      print('Error in getAllStages: $e');
      return ApiResponse(
        success: false,
        message: 'Error fetching stages: ${e.toString()}',
      );
    }
  }

  // Get stages by competition ID
  Future<ApiResponse<List<CompetitionOptionModel>>> getStagesByCompetition(
    int competitionId,
  ) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.stageByCompetition(competitionId),
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<CompetitionOptionModel> stages = [];

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          // API returns: { "data": { "stages": [...] } }
          dynamic listData = dataMap['data']?['stages'] ?? dataMap['stages'];

          if (listData is List) {
            stages = listData.map((json) {
              return CompetitionOptionModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : json as Map<String, dynamic>,
              );
            }).toList();
          }
        } else if (response.data is List) {
          stages = (response.data as List).map((json) {
            return CompetitionOptionModel.fromJson(
              json is Map<String, dynamic>
                  ? json
                  : json as Map<String, dynamic>,
            );
          }).toList();
        }

        return ApiResponse(success: true, data: stages);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch stages for competition',
      );
    } catch (e) {
      print('Error in getStagesByCompetition: $e');
      return ApiResponse(
        success: false,
        message: 'Error fetching stages for competition: ${e.toString()}',
      );
    }
  }

  // Get all groups
  Future<ApiResponse<List<CompetitionOptionModel>>> getAllGroups() async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.groupList,
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<CompetitionOptionModel> groups = [];

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic listData = dataMap['data']?['groups'] ?? dataMap['groups'];

          if (listData is List) {
            groups = listData.map((json) {
              return CompetitionOptionModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : json as Map<String, dynamic>,
              );
            }).toList();
          }
        } else if (response.data is List) {
          groups = (response.data as List).map((json) {
            return CompetitionOptionModel.fromJson(
              json is Map<String, dynamic>
                  ? json
                  : json as Map<String, dynamic>,
            );
          }).toList();
        }

        return ApiResponse(success: true, data: groups);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch groups',
      );
    } catch (e) {
      print('Error in getAllGroups: $e');
      return ApiResponse(
        success: false,
        message: 'Error fetching groups: ${e.toString()}',
      );
    }
  }

  // Create new category
  Future<ApiResponse<CompetitionOptionModel>> createCategory({
    required String name,
    String? description,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      };

      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.categoryCreate,
        apiType: APIType.aPost,
        body: requestBody,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        CompetitionOptionModel? category;

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic categoryData = dataMap['data'] ?? dataMap;

          if (categoryData is Map<String, dynamic>) {
            category = CompetitionOptionModel.fromJson(categoryData);
          }
        }

        if (category != null) {
          return ApiResponse(success: true, data: category);
        }
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to create category',
      );
    } catch (e) {
      print('Error in createCategory: $e');
      return ApiResponse(
        success: false,
        message: 'Error creating category: ${e.toString()}',
      );
    }
  }

  // Create new prize
  Future<ApiResponse<CompetitionOptionModel>> createPrize({
    required String name,
    String? description,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      };

      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.prizeCreate,
        apiType: APIType.aPost,
        body: requestBody,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        CompetitionOptionModel? prize;

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic prizeData = dataMap['data'] ?? dataMap;

          if (prizeData is Map<String, dynamic>) {
            prize = CompetitionOptionModel.fromJson(prizeData);
          }
        }

        if (prize != null) {
          return ApiResponse(success: true, data: prize);
        }
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to create prize',
      );
    } catch (e) {
      print('Error in createPrize: $e');
      return ApiResponse(
        success: false,
        message: 'Error creating prize: ${e.toString()}',
      );
    }
  }

  // Create new stage
  Future<ApiResponse<CompetitionOptionModel>> createStage({
    required String name,
    String? description,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      };

      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.stageCreate,
        apiType: APIType.aPost,
        body: requestBody,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        CompetitionOptionModel? stage;

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic stageData = dataMap['data'] ?? dataMap;

          if (stageData is Map<String, dynamic>) {
            stage = CompetitionOptionModel.fromJson(stageData);
          }
        }

        if (stage != null) {
          return ApiResponse(success: true, data: stage);
        }
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to create stage',
      );
    } catch (e) {
      print('Error in createStage: $e');
      return ApiResponse(
        success: false,
        message: 'Error creating stage: ${e.toString()}',
      );
    }
  }

  // Create new group
  Future<ApiResponse<CompetitionOptionModel>> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      };

      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.groupCreate,
        apiType: APIType.aPost,
        body: requestBody,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        CompetitionOptionModel? group;

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic groupData = dataMap['data'] ?? dataMap;

          if (groupData is Map<String, dynamic>) {
            group = CompetitionOptionModel.fromJson(groupData);
          }
        }

        if (group != null) {
          return ApiResponse(success: true, data: group);
        }
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to create group',
      );
    } catch (e) {
      print('Error in createGroup: $e');
      return ApiResponse(
        success: false,
        message: 'Error creating group: ${e.toString()}',
      );
    }
  }

  // Get competition by ID
  Future<ApiResponse<CompetitionModel>> getCompetitionById(int id) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.competitionById(id.toString()),
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        CompetitionModel? competition;

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          // Check if data is nested
          dynamic competitionData = dataMap['data'] ?? dataMap;
          if (competitionData is Map<String, dynamic>) {
            competition = CompetitionModel.fromJson(competitionData);
          }
        }

        if (competition != null) {
          return ApiResponse(success: true, data: competition);
        }
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch competition',
      );
    } catch (e) {
      print('Error in getCompetitionById: $e');
      return ApiResponse(
        success: false,
        message: 'Error fetching competition: ${e.toString()}',
      );
    }
  }
}
