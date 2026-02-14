import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_management_model.dart';
import '../models/api_response.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class UserManagementRepository {
  final APIService _apiService = APIService();

  Future<ApiResponse<List<UserManagementModel>>> getAllUsers({
    int? eventId,
  }) async {
    try {
      String url = EndPoints.userList;
      if (eventId != null) {
        url = '${EndPoints.userList}?eventId=$eventId';
      }

      final response = await _apiService.getResponse<dynamic>(
        url: url,
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<UserManagementModel> users = [];

        if (response.data is List) {
          users = (response.data as List).map((json) {
            return UserManagementModel.fromJson(
              json is Map<String, dynamic>
                  ? json
                  : json as Map<String, dynamic>,
            );
          }).toList();
        } else if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic listData =
              dataMap['data'] ?? dataMap['users'] ?? dataMap['results'];

          if (listData is List) {
            users = listData.map((json) {
              return UserManagementModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : json as Map<String, dynamic>,
              );
            }).toList();
          }
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
  }) async {
    try {
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

        final multipartFile = http.MultipartFile.fromBytes(
          'photo',
          fileBytes,
          filename: fileName,
        );

        // Convert user data to string map
        final userJson = user.toJson(includePassword: true);
        final fields = <String, String>{};
        userJson.forEach((key, value) {
          if (value is List) {
            fields[key] = value.join(',');
          } else {
            fields[key] = value.toString();
          }
        });

        // Use multipart request for file upload
        final response = await _apiService.postMultipart<Map<String, dynamic>>(
          url: EndPoints.userCreate,
          fields: fields,
          file: multipartFile,
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
      } else {
        // Regular POST request without file
        final response = await _apiService.getResponse<Map<String, dynamic>>(
          url: EndPoints.userCreate,
          apiType: APIType.aPost,
          body: user.toJson(includePassword: true),
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
      }
    } catch (e, stackTrace) {
      print('Error in createUser: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error creating user: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<List<UserManagementModel>>> createVolunteers({
    required List<UserManagementModel> volunteers,
    required int eventId,
  }) async {
    try {
      final volunteersData = volunteers
          .map((v) => v.toJson(includePassword: true))
          .toList();

      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.userCreateVolunteers,
        apiType: APIType.aPost,
        body: {'volunteers': volunteersData, 'eventId': eventId},
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<UserManagementModel> createdVolunteers = [];

        if (response.data is List) {
          createdVolunteers = (response.data as List).map((json) {
            return UserManagementModel.fromJson(
              json is Map<String, dynamic>
                  ? json
                  : json as Map<String, dynamic>,
            );
          }).toList();
        } else if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          if (dataMap['volunteers'] is List) {
            createdVolunteers = (dataMap['volunteers'] as List).map((json) {
              return UserManagementModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : json as Map<String, dynamic>,
              );
            }).toList();
          }
        }

        return ApiResponse(success: true, data: createdVolunteers);
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
  }) async {
    try {
      if (photoFile != null) {
        // Convert File to MultipartFile
        final fileBytes = await photoFile.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'photo',
          fileBytes,
          filename: photoFile.path.split('/').last,
        );

        // Convert user data to string map
        final userJson = user.toJson(includePassword: true);
        userJson.remove('id');
        final fields = <String, String>{};
        userJson.forEach((key, value) {
          if (value is List) {
            fields[key] = value.join(',');
          } else {
            fields[key] = value.toString();
          }
        });

        // Use multipart request for file upload
        final response = await _apiService.putMultipart<Map<String, dynamic>>(
          url: EndPoints.userUpdate(id),
          fields: fields,
          file: multipartFile,
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
      } else {
        // Regular PUT request without file
        final userJson = user.toJson(includePassword: true);
        userJson.remove('id');

        final response = await _apiService.getResponse<Map<String, dynamic>>(
          url: EndPoints.userUpdate(id),
          apiType: APIType.aPut,
          body: userJson,
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
      }
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
}
