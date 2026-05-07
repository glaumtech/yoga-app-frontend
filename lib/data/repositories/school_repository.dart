import 'dart:convert';
import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/school_model.dart';
import '../models/api_response.dart';
import '../models/institution_type_model.dart';
import '../models/institution_category_model.dart';

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
    String? institutionShortName,
    required String address,
    required int stateId,
    required int cityId,
    required int institutionTypeId,
    List<int>? institutionCategoryIds,
    required String pincode,
    String? emailId,
    String? website,
    String? landLine,
    String? mobile,
    String? contributorName,
    String? contributorMobileNo,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'institutionName': institutionName,
        'address': address,
        'stateId': stateId,
        'cityId': cityId,
        'institutionTypeId': institutionTypeId,
        'pincode': pincode,
      };

      if (institutionShortName != null && institutionShortName.isNotEmpty) {
        requestBody['institutionShortName'] = institutionShortName;
      }
      if (institutionCategoryIds != null && institutionCategoryIds.isNotEmpty) {
        requestBody['institutionCategoryIds'] = institutionCategoryIds;
      }
      if (emailId != null && emailId.isNotEmpty) {
        requestBody['emailId'] = emailId;
      }
      if (website != null && website.isNotEmpty) {
        requestBody['website'] = website;
      }
      if (landLine != null && landLine.isNotEmpty) {
        requestBody['landLine'] = landLine;
      }
      if (mobile != null && mobile.isNotEmpty) {
        requestBody['mobile'] = mobile;
      }
      if (contributorName != null && contributorName.isNotEmpty) {
        requestBody['contributorName'] = contributorName;
      }
      if (contributorMobileNo != null && contributorMobileNo.isNotEmpty) {
        requestBody['contributorMobileNo'] = contributorMobileNo;
      }

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
    int? institutionTypeId,
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
      if (institutionTypeId != null && institutionTypeId > 0) {
        requestBody['institutionTypeId'] = institutionTypeId;
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
    String? institutionShortName,
    String? address,
    String? emailId,
    int? stateId,
    int? cityId,
    int? institutionTypeId,
    List<int>? institutionCategoryIds,
    String? pincode,
    String? website,
    String? landLine,
    String? mobile,
    String? contributorName,
    String? contributorMobileNo,
  }) async {
    try {
      final requestBody = <String, dynamic>{};

      if (institutionName != null) {
        requestBody['institutionName'] = institutionName;
      }
      if (institutionShortName != null && institutionShortName.isNotEmpty) {
        requestBody['institutionShortName'] = institutionShortName;
      }
      if (address != null) {
        requestBody['address'] = address;
      }
      if (emailId != null && emailId.isNotEmpty) {
        requestBody['emailId'] = emailId;
      }
      if (website != null) {
        requestBody['website'] = website;
      }
      if (landLine != null) {
        requestBody['landLine'] = landLine;
      }
      if (mobile != null) {
        requestBody['mobile'] = mobile;
      }
      if (contributorName != null) {
        requestBody['contributorName'] = contributorName;
      }
      if (contributorMobileNo != null) {
        requestBody['contributorMobileNo'] = contributorMobileNo;
      }
      if (stateId != null && stateId > 0) {
        requestBody['stateId'] = stateId;
      }
      if (cityId != null && cityId > 0) {
        requestBody['cityId'] = cityId;
      }
      if (institutionTypeId != null && institutionTypeId > 0) {
        requestBody['institutionTypeId'] = institutionTypeId;
      }
      if (institutionCategoryIds != null && institutionCategoryIds.isNotEmpty) {
        requestBody['institutionCategoryIds'] = institutionCategoryIds;
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
    int? stateId,
    int? cityId,
    int? institutionTypeId,
    String? pincode,
  }) async {
    try {
      final queryParameters = <String, String>{'q': query};
      if (stateId != null && stateId > 0) {
        queryParameters['stateId'] = '$stateId';
      }
      if (cityId != null && cityId > 0) {
        queryParameters['cityId'] = '$cityId';
      }
      if (institutionTypeId != null && institutionTypeId > 0) {
        queryParameters['institutionTypeId'] = '$institutionTypeId';
      }
      if (pincode != null && pincode.trim().isNotEmpty) {
        queryParameters['pincode'] = pincode.trim();
      }
      final searchPath = Uri(
        path: EndPoints.institutionSearch,
        queryParameters: queryParameters,
      ).toString();

      final response = await _apiService.getResponse<dynamic>(
        url: searchPath,
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

  // Get all institution types
  Future<ApiResponse<List<InstitutionTypeModel>>>
  getAllInstitutionTypes() async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.institutionTypeList,
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<InstitutionTypeModel> types = [];

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic listData =
              dataMap['data']?['institutionTypes'] ??
              dataMap['institutionTypes'];

          if (listData is List) {
            types = listData.map((json) {
              return InstitutionTypeModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : json as Map<String, dynamic>,
              );
            }).toList();
          }
        } else if (response.data is List) {
          types = (response.data as List).map((json) {
            return InstitutionTypeModel.fromJson(
              json is Map<String, dynamic>
                  ? json
                  : json as Map<String, dynamic>,
            );
          }).toList();
        }

        return ApiResponse(success: true, data: types);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch institution types',
      );
    } catch (e) {
      print('Error in getAllInstitutionTypes: $e');
      return ApiResponse(
        success: false,
        message: 'Error fetching institution types: ${e.toString()}',
      );
    }
  }

  // Get institution categories by type ID
  Future<ApiResponse<List<InstitutionCategoryModel>>>
  getInstitutionCategoriesByType(int institutionTypeId) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.institutionCategoryByType(institutionTypeId),
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<InstitutionCategoryModel> categories = [];

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic listData =
              dataMap['data']?['categories'] ?? dataMap['categories'];

          if (listData is List) {
            categories = listData.map((json) {
              return InstitutionCategoryModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : json as Map<String, dynamic>,
              );
            }).toList();
          }
        } else if (response.data is List) {
          categories = (response.data as List).map((json) {
            return InstitutionCategoryModel.fromJson(
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
        message: response.message ?? 'Failed to fetch institution categories',
      );
    } catch (e) {
      print('Error in getInstitutionCategoriesByType: $e');
      return ApiResponse(
        success: false,
        message: 'Error fetching institution categories: ${e.toString()}',
      );
    }
  }

  // Get institutions for printing
  Future<ApiResponse<SchoolsListResponse>> getInstitutionsForPrint({
    String? search,
    int? stateId,
    int? cityId,
    int? institutionTypeId,
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
      if (institutionTypeId != null && institutionTypeId > 0) {
        requestBody['institutionTypeId'] = institutionTypeId;
      }
      requestBody['page'] = 0;
      requestBody['limit'] = 10000; // Large limit for printing
      requestBody['sortBy'] = sortBy ?? 'institutionName';
      requestBody['order'] = order ?? 'asc';

      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.institutionPrint,
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

            if (dataMap.containsKey('total')) {
              paginationData = {
                'total': dataMap['total'],
                'page': 0,
                'limit': institutions.length,
              };
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

              if (innerData.containsKey('total')) {
                paginationData = {
                  'total': innerData['total'],
                  'page': 0,
                  'limit': institutions.length,
                };
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
        message:
            response.message ?? 'Failed to fetch institutions for printing',
      );
    } catch (e) {
      print('Error in getInstitutionsForPrint: $e');
      return ApiResponse(
        success: false,
        message: 'Error fetching institutions for printing: ${e.toString()}',
      );
    }
  }

  // Create institution category
  Future<ApiResponse<InstitutionCategoryModel>> createInstitutionCategory({
    required String categoryName,
    required String displayName,
    required int institutionTypeId,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'categoryName': categoryName,
        'displayName': displayName,
        'institutionTypeId': institutionTypeId,
      };

      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.institutionCategoryCreate,
        apiType: APIType.aPost,
        body: requestBody,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        InstitutionCategoryModel? category;

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic categoryData = dataMap['data'] ?? dataMap;

          if (categoryData is Map<String, dynamic>) {
            category = InstitutionCategoryModel.fromJson(categoryData);
          }
        }

        if (category != null) {
          return ApiResponse(success: true, data: category);
        }
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to create institution category',
      );
    } catch (e) {
      print('Error in createInstitutionCategory: $e');
      return ApiResponse(
        success: false,
        message: 'Error creating institution category: ${e.toString()}',
      );
    }
  }
}
