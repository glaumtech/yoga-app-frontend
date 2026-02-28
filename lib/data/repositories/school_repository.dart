import 'dart:convert';
import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/school_model.dart';
import '../models/api_response.dart';

// Response class for institutions list with pagination
class SchoolsListResponse {
  final List<SchoolModel> institutions;
  final Map<String, dynamic>? pagination;

  SchoolsListResponse({required this.institutions, this.pagination});
}

class SchoolRepository {
  final APIService _apiService = APIService();

  // Create institution
  Future<ApiResponse<SchoolModel>> createInstitution({
    required String institutionName,
    required String address,
    required int stateId,
    required int cityId,
    required String institutionType,
    required String pincode,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'institutionName': institutionName,
        'address': address,
        'stateId': stateId,
        'cityId': cityId,
        'institutionType': institutionType,
        'pincode': pincode,
      };

      print('Creating institution with data: ${requestBody}');

      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.institutionCreate,
        apiType: APIType.aPost,
        body: requestBody,
        fromJson: (json) => json,
      );

      print(
        'Create institution response: ${response.success}, message: ${response.message}',
      );

      if (response.success && response.data != null) {
        SchoolModel? institution;

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic institutionData = dataMap['data'] ?? dataMap;

          if (institutionData is Map<String, dynamic>) {
            institution = SchoolModel.fromJson(institutionData);
          }
        }

        if (institution != null) {
          return ApiResponse(success: true, data: institution);
        }
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to create institution',
      );
    } catch (e) {
      print('Error in createInstitution: $e');
      return ApiResponse(
        success: false,
        message: 'Error creating institution: ${e.toString()}',
      );
    }
  }

  // Get institutions list with filters
  Future<ApiResponse<SchoolsListResponse>> getInstitutionsList({
    String? search,
    int? stateId,
    int? cityId,
    String? institutionType,
    int? page,
    int? limit,
    String? sortBy,
    String? order,
  }) async {
    try {
      final requestBody = <String, dynamic>{};

      if (search != null && search.isNotEmpty) {
        requestBody['search'] = search;
      }
      if (stateId != null && stateId > 0) {
        requestBody['stateId'] = stateId;
      }
      if (cityId != null && cityId > 0) {
        requestBody['cityId'] = cityId;
      }
      if (institutionType != null && institutionType.isNotEmpty) {
        requestBody['institutionType'] = institutionType;
      }
      requestBody['page'] = page ?? 0;
      requestBody['limit'] = limit ?? 20;
      requestBody['sortBy'] = sortBy ?? 'createdAt';
      requestBody['order'] = order ?? 'desc';

      print('Institution list request body: ${jsonEncode(requestBody)}');

      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.institutionList,
        apiType: APIType.aPost,
        body: requestBody,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<SchoolModel> institutions = [];
        Map<String, dynamic>? paginationData;

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;

          if (dataMap.containsKey('institutions')) {
            final institutionsList = dataMap['institutions'];
            if (institutionsList is List) {
              institutions = institutionsList.map((json) {
                return SchoolModel.fromJson(
                  json is Map<String, dynamic>
                      ? json
                      : json as Map<String, dynamic>,
                );
              }).toList();
            }

            if (dataMap.containsKey('pagination')) {
              paginationData = dataMap['pagination'] as Map<String, dynamic>?;
            }
          } else if (dataMap.containsKey('data')) {
            final innerData = dataMap['data'];
            if (innerData is Map<String, dynamic>) {
              final institutionsList = innerData['institutions'];
              if (institutionsList is List) {
                institutions = institutionsList.map((json) {
                  return SchoolModel.fromJson(
                    json is Map<String, dynamic>
                        ? json
                        : json as Map<String, dynamic>,
                  );
                }).toList();
              }

              if (innerData.containsKey('pagination')) {
                paginationData =
                    innerData['pagination'] as Map<String, dynamic>?;
              }
            }
          }
        }

        final listResponse = SchoolsListResponse(
          institutions: institutions,
          pagination: paginationData,
        );

        return ApiResponse<SchoolsListResponse>(
          success: true,
          data: listResponse,
        );
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch institutions',
      );
    } catch (e) {
      print('Error in getInstitutionsList: $e');
      return ApiResponse(
        success: false,
        message: 'Error fetching institutions: ${e.toString()}',
      );
    }
  }

  // Get institution by ID
  Future<ApiResponse<SchoolModel>> getInstitutionById(String id) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.institutionById(id),
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      print('=== getInstitutionById START ===');
      print('Response success: ${response.success}');
      print('Response data type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');
      if (response.data is Map) {
        print('Response data is Map with keys: ${(response.data as Map).keys}');
      }

      if (response.success && response.data != null) {
        SchoolModel? institution;

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          print('DataMap keys: ${dataMap.keys}');

          // APIService already extracts parsed['data'], so response.data is { "institution": {...} }
          // Check if we have 'institution' key directly
          dynamic institutionData;

          if (dataMap.containsKey('institution')) {
            // Structure: { "institution": {...} }
            institutionData = dataMap['institution'];
            print('Found institution in dataMap["institution"]');
          } else if (dataMap.containsKey('data')) {
            // Fallback: Check if there's nested data.data.institution
            final innerData = dataMap['data'];
            if (innerData is Map<String, dynamic>) {
              print('Inner data keys: ${innerData.keys}');
              if (innerData.containsKey('institution')) {
                institutionData = innerData['institution'];
                print('Found institution in dataMap["data"]["institution"]');
              } else {
                // Inner data might be the institution itself
                institutionData = innerData;
                print('Using inner data as institution');
              }
            } else {
              institutionData = innerData;
            }
          } else {
            // Fallback: dataMap might be the institution itself
            institutionData = dataMap;
            print('Using dataMap as institution');
          }

          if (institutionData is Map<String, dynamic>) {
            print('Institution data keys: ${institutionData.keys}');
            print('Institution data: $institutionData');
            institution = SchoolModel.fromJson(institutionData);

            print(
              'Parsed institution - stateId: ${institution.stateId}, stateName: ${institution.stateName}',
            );
            print(
              'Parsed institution - cityId: ${institution.cityId}, cityName: ${institution.cityName}',
            );
            print(
              'Parsed institution - id: ${institution.id}, name: ${institution.institutionName}',
            );
          } else {
            print(
              'ERROR: institutionData is not Map<String, dynamic>, type: ${institutionData.runtimeType}',
            );
          }
        } else if (response.data is List) {
          // Handle case where response is a list
          final dataList = response.data as List;
          if (dataList.isNotEmpty && dataList[0] is Map<String, dynamic>) {
            institution = SchoolModel.fromJson(
              dataList[0] as Map<String, dynamic>,
            );
          }
        }

        if (institution != null) {
          // Validate that institution has required fields
          if (institution.institutionName.isEmpty) {
            print('WARNING: Parsed institution has empty institutionName');
          }
          if (institution.stateId == null) {
            print('WARNING: Parsed institution has null stateId');
          }
          if (institution.cityId == null) {
            print('WARNING: Parsed institution has null cityId');
          }
          return ApiResponse(success: true, data: institution);
        } else {
          print('ERROR: Failed to parse institution from response');
          print('Response data was: ${response.data}');
        }
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch institution',
      );
    } catch (e, stackTrace) {
      print('Error in getInstitutionById: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error fetching institution: ${e.toString()}',
      );
    }
  }

  // Update institution
  Future<ApiResponse<SchoolModel>> updateInstitution({
    required String id,
    String? institutionName,
    String? address,
    int? stateId,
    int? cityId,
    String? institutionType,
    String? pincode,
  }) async {
    try {
      final requestBody = <String, dynamic>{};

      if (institutionName != null) {
        requestBody['institutionName'] = institutionName;
      }
      if (address != null) {
        requestBody['address'] = address;
      }
      if (stateId != null && stateId > 0) {
        requestBody['stateId'] = stateId;
      }
      if (cityId != null && cityId > 0) {
        requestBody['cityId'] = cityId;
      }
      if (institutionType != null) {
        requestBody['institutionType'] = institutionType;
      }
      if (pincode != null) {
        requestBody['pincode'] = pincode;
      }

      print('Updating institution $id with data: ${requestBody}');

      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.institutionUpdate(id),
        apiType: APIType.aPut,
        body: requestBody,
        fromJson: (json) => json,
      );

      print(
        'Update institution response: ${response.success}, message: ${response.message}',
      );

      if (response.success && response.data != null) {
        SchoolModel? institution;

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic institutionData = dataMap['data'] ?? dataMap;

          if (institutionData is Map<String, dynamic>) {
            institution = SchoolModel.fromJson(institutionData);
          }
        }

        if (institution != null) {
          return ApiResponse(success: true, data: institution);
        }
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to update institution',
      );
    } catch (e) {
      print('Error in updateInstitution: $e');
      return ApiResponse(
        success: false,
        message: 'Error updating institution: ${e.toString()}',
      );
    }
  }

  // Delete institution
  Future<ApiResponse<void>> deleteInstitution(String id) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.institutionDelete(id),
        apiType: APIType.aDelete,
        fromJson: (json) => json,
      );

      if (response.success) {
        return ApiResponse(success: true);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to delete institution',
      );
    } catch (e) {
      print('Error in deleteInstitution: $e');
      return ApiResponse(
        success: false,
        message: 'Error deleting institution: ${e.toString()}',
      );
    }
  }

  // Search institutions by name
  Future<ApiResponse<SchoolsListResponse>> searchInstitutions({
    required String query,
  }) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: '${EndPoints.institutionSearch}?q=$query',
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        final dataMap = response.data as Map<String, dynamic>;
        final institutionsData = dataMap['institutions'] as List<dynamic>?;

        if (institutionsData != null) {
          final institutions = institutionsData
              .map((json) => SchoolModel.fromJson(json as Map<String, dynamic>))
              .toList();

          final schoolsResponse = SchoolsListResponse(
            institutions: institutions,
            pagination: {'count': dataMap['count']},
          );

          return ApiResponse<SchoolsListResponse>(
            success: true,
            message: response.message ?? 'Institutions retrieved successfully',
            data: schoolsResponse,
          );
        }
      }

      return ApiResponse<SchoolsListResponse>(
        success: false,
        message: response.message ?? 'Failed to search institutions',
      );
    } catch (e) {
      print('Error searching institutions: $e');
      return ApiResponse<SchoolsListResponse>(
        success: false,
        message: 'Error searching institutions: ${e.toString()}',
      );
    }
  }
}
