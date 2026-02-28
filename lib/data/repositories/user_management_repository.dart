import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_management_model.dart';
import '../models/user_type_model.dart';
import '../models/jury_assignment_model.dart';
import '../models/api_response.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/storage_service.dart';

class UserManagementRepository {
  final APIService _apiService = APIService();

  Future<ApiResponse<List<UserManagementModel>>> getAllUsers({
    int? competitionId,
    int? userTypeId,
    String? search,
    int page = 0,
    int limit = 10,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
  }) async {
    try {
      // New API format: POST /user/list with JSON body
      final requestBody = <String, dynamic>{};
      if (competitionId != null) requestBody['competitionId'] = competitionId;
      if (userTypeId != null) requestBody['userTypeId'] = userTypeId;
      if (search != null && search.isNotEmpty) requestBody['search'] = search;
      requestBody['page'] = page;
      requestBody['limit'] = limit;
      requestBody['sortBy'] = sortBy;
      requestBody['sortOrder'] = sortOrder;

      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.userList,
        apiType: APIType.aPost,
        body: requestBody,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<UserManagementModel> users = [];

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic listData = dataMap['users'];

          if (listData is List) {
            users = listData.map((json) {
              return UserManagementModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : json as Map<String, dynamic>,
              );
            }).toList();
          }
        } else if (response.data is List) {
          // Fallback for old format
          users = (response.data as List).map((json) {
            return UserManagementModel.fromJson(
              json is Map<String, dynamic>
                  ? json
                  : json as Map<String, dynamic>,
            );
          }).toList();
        }

        return ApiResponse(success: true, data: users);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch users',
      );
    } catch (e, stackTrace) {
      print('Error in getAllUsers: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error loading users: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<UserManagementModel>> createUser({
    required UserManagementModel user,
    File? photoFile,
    Uint8List? photoBytes,
    String? photoFileName,
    List<Map<String, dynamic>>? volunteers,
  }) async {
    try {
      // New API format: multipart/form-data with 'data' (JSON string) and optional 'photo'
      // Convert user data to JSON string
      final userJson = user.toJson(includePassword: true, useNewFormat: true);

      // Add volunteers if provided
      if (volunteers != null && volunteers.isNotEmpty) {
        userJson['volunteers'] = volunteers;
      }

      final dataJsonString = jsonEncode(userJson);

      final fields = <String, String>{'data': dataJsonString};

      http.MultipartFile? multipartFile;

      if (photoFile != null || photoBytes != null) {
        // Convert File or bytes to MultipartFile
        Uint8List fileBytes;
        String fileName;

        if (photoBytes != null) {
          // Web: use bytes directly
          fileBytes = photoBytes;
          fileName = photoFileName ?? 'photo.jpg';
        } else if (photoFile != null) {
          // Mobile/Desktop: read from file
          fileBytes = await photoFile.readAsBytes();
          fileName = photoFile.path.split('/').last;
        } else {
          throw Exception('No photo provided');
        }

        multipartFile = http.MultipartFile.fromBytes(
          'photo',
          fileBytes,
          filename: fileName,
        );
      }

      // Use multipart request (with or without file)
      // When no photo, create an empty multipart file as placeholder
      final fileToUpload =
          multipartFile ??
          http.MultipartFile.fromString('photo', '', filename: '');

      final response = await _apiService.postMultipart<Map<String, dynamic>>(
        url: EndPoints.userCreate,
        fields: fields,
        file: fileToUpload,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final createdUser = UserManagementModel.fromJson(response.data!);
        return ApiResponse(success: true, data: createdUser);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to create user',
      );
    } catch (e, stackTrace) {
      print('Error in createUser: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error creating user: ${e.toString()}',
      );
    }
  }

  // Volunteers are now included in the createUser request
  // This method is kept for backward compatibility but should use createUser instead
  Future<ApiResponse<List<UserManagementModel>>> createVolunteers({
    required List<UserManagementModel> volunteers,
    required int competitionId,
  }) async {
    try {
      // Convert volunteers to the new format
      final volunteersData = volunteers.map((v) {
        return {
          'volunteerNo':
              v.volunteerNo ?? 'VOL-${DateTime.now().millisecondsSinceEpoch}',
          'volunteerName': v.name,
          'password': v.password ?? 'defaultPassword123',
          'cell': v.cell ?? '',
        };
      }).toList();

      // Create a user with VOLUNTEERS type and volunteers array
      final user = UserManagementModel(
        name: 'Volunteers Group',
        type: 'VOLUNTEERS',
        userTypeId: 4,
        competitionId: competitionId,
      );

      final response = await createUser(user: user, volunteers: volunteersData);

      if (response.success) {
        // Return the volunteers from the response
        final volunteersList =
            response.data?.volunteers
                ?.map((v) => UserManagementModel.fromJson(v))
                .toList() ??
            [];
        return ApiResponse(success: true, data: volunteersList);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to create volunteers',
      );
    } catch (e, stackTrace) {
      print('Error in createVolunteers: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error creating volunteers: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<UserManagementModel>> updateUser({
    required String id,
    required UserManagementModel user,
    File? photoFile,
    Uint8List? photoBytes,
    String? photoFileName,
  }) async {
    try {
      // New API format: multipart/form-data with 'data' (JSON string) and optional 'photo'
      // Convert user data to JSON string
      // Only include password if it's actually provided (not null and not empty)
      final shouldIncludePassword =
          user.password != null &&
          user.password!.isNotEmpty &&
          user.password!.length >= 6;
      final userJson = user.toJson(
        includePassword: shouldIncludePassword,
        useNewFormat: true,
      );
      // Remove id from JSON as it's in the URL
      userJson.remove('id');

      final dataJsonString = jsonEncode(userJson);

      final fields = <String, String>{'data': dataJsonString};

      http.MultipartFile? multipartFile;

      if (photoFile != null || photoBytes != null) {
        // Convert File or bytes to MultipartFile
        Uint8List fileBytes;
        String fileName;

        if (photoBytes != null) {
          // Web: use bytes directly
          fileBytes = photoBytes;
          fileName = photoFileName ?? 'photo.jpg';
        } else if (photoFile != null) {
          // Mobile/Desktop: read from file
          fileBytes = await photoFile.readAsBytes();
          fileName = photoFile.path.split('/').last;
        } else {
          throw Exception('No photo provided');
        }

        multipartFile = http.MultipartFile.fromBytes(
          'photo',
          fileBytes,
          filename: fileName,
        );
      }

      // Use multipart request (with or without file)
      final fileToUpload =
          multipartFile ??
          http.MultipartFile.fromString('photo', '', filename: '');

      final response = await _apiService.putMultipart<Map<String, dynamic>>(
        url: EndPoints.userUpdate(id),
        fields: fields,
        file: fileToUpload,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final updatedUser = UserManagementModel.fromJson(response.data!);
        return ApiResponse(success: true, data: updatedUser);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to update user',
      );
    } catch (e, stackTrace) {
      print('Error in updateUser: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error updating user: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<bool>> deleteUser(String id) async {
    try {
      final response = await _apiService.getResponse<bool>(
        url: EndPoints.userById(id),
        apiType: APIType.aDelete,
      );
      return response;
    } catch (e, stackTrace) {
      print('Error in deleteUser: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error deleting user: ${e.toString()}',
      );
    }
  }

  /// Login user
  /// Returns token and user data
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String name,
    required String password,
    int? competitionId,
  }) async {
    try {
      final requestBody = <String, dynamic>{'name': name, 'password': password};

      if (competitionId != null) {
        requestBody['competitionId'] = competitionId;
      }

      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.userLogin,
        apiType: APIType.aPost,
        body: requestBody,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // Extract token and user data
        final token = data['token']?.toString();
        final tokenType = data['tokenType']?.toString() ?? 'Bearer';
        final userData = data['user'] as Map<String, dynamic>?;

        if (token != null && token.isNotEmpty) {
          // Store token
          await StorageService.setString(AppConstants.tokenKey, token);

          // Store user data if available
          if (userData != null) {
            await StorageService.setString(
              AppConstants.userKey,
              jsonEncode(userData),
            );
          }

          return ApiResponse(
            success: true,
            data: {
              'token': token,
              'tokenType': tokenType,
              'user': userData != null
                  ? UserManagementModel.fromJson(userData)
                  : null,
            },
            message: response.message ?? 'Login successful',
          );
        } else {
          return ApiResponse(
            success: false,
            message: 'Token not received from server',
          );
        }
      } else {
        return ApiResponse(
          success: false,
          message: response.message ?? 'Login failed',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error during login: ${e.toString()}',
      );
    }
  }

  /// Logout user
  /// Invalidates the token
  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.userLogout,
        apiType: APIType.aPost,
        fromJson: (json) => json,
      );

      // Clear local storage regardless of API response
      await StorageService.remove(AppConstants.tokenKey);
      await StorageService.remove(AppConstants.userKey);

      if (response.success) {
        return ApiResponse(
          success: true,
          data: {'tokenInvalidated': true},
          message: response.message ?? 'Logged out successfully',
        );
      } else {
        // Even if API call fails, we've cleared local storage
        return ApiResponse(
          success: true,
          data: {'tokenInvalidated': true},
          message: 'Logged out locally',
        );
      }
    } catch (e) {
      // Clear local storage even if there's an error
      await StorageService.remove(AppConstants.tokenKey);
      await StorageService.remove(AppConstants.userKey);

      return ApiResponse(
        success: true,
        data: {'tokenInvalidated': true},
        message: 'Logged out locally (error: ${e.toString()})',
      );
    }
  }

  /// Get all user types with their permissions
  Future<ApiResponse<List<UserTypeModel>>> getUserTypes() async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.userTypes,
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final userTypesList = data['userTypes'] as List<dynamic>?;

        if (userTypesList != null) {
          final userTypes = userTypesList
              .map(
                (json) => UserTypeModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();

          return ApiResponse(
            success: true,
            data: userTypes,
            message: response.message ?? 'User types retrieved successfully',
          );
        } else {
          return ApiResponse(
            success: false,
            message: 'No user types found in response',
          );
        }
      } else {
        return ApiResponse(
          success: false,
          message: response.message ?? 'Failed to retrieve user types',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error retrieving user types: ${e.toString()}',
      );
    }
  }

  /// Get jury assignments for a user
  Future<ApiResponse<JuryAssignmentModel>> getJuryAssignments(
    String userId,
  ) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.juryAssignments(userId),
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // Extract assignments from data
        final assignmentsData = data['assignments'] as Map<String, dynamic>?;

        if (assignmentsData != null) {
          final assignment = JuryAssignmentModel.fromJson(assignmentsData);
          return ApiResponse(
            success: true,
            data: assignment,
            message:
                response.message ?? 'Jury assignments retrieved successfully',
          );
        } else {
          return ApiResponse(
            success: false,
            message: 'No assignments found in response',
          );
        }
      } else {
        return ApiResponse(
          success: false,
          message: response.message ?? 'Failed to retrieve jury assignments',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error retrieving jury assignments: ${e.toString()}',
      );
    }
  }
}
