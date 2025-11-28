import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/storage_service.dart';
import '../models/user_model.dart';
import '../models/api_response.dart';

class AuthRepository {
  final APIService _apiService = APIService();

  Future<ApiResponse<UserModel>> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    required String username,
    required String role,
    String? phoneNo,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
      'username': username,
      'role': role,
    };

    // Add phoneNo as a number if provided
    if (phoneNo != null && phoneNo.isNotEmpty) {
      final phoneNumber = int.tryParse(phoneNo);
      if (phoneNumber != null) {
        body['phoneNo'] = phoneNumber;
      } else {
        // If parsing fails, send as string (fallback)
        body['phoneNo'] = phoneNo;
      }
    }

    final response = await _apiService.getResponse<Map<String, dynamic>>(
      url: EndPoints.register,
      apiType: APIType.aPost,
      body: body,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      final user = UserModel.fromJson(response.data!);
      return ApiResponse(success: true, data: user);
    }

    return ApiResponse(
      success: false,
      message: response.message ?? 'Sign up failed',
    );
  }

  Future<ApiResponse<UserModel>> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.getResponse<Map<String, dynamic>>(
      url: EndPoints.logIn,
      apiType: APIType.aPost,
      body: {'email': email, 'password': password},
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      // Extract token from data object
      String? token;
      if (response.data is Map<String, dynamic>) {
        final dataMap = response.data as Map<String, dynamic>;
        token = dataMap['token'] as String?;
      }
      final user = UserModel.fromJson(response.data!['user']);
      await _saveAuthData(user, token);

      return ApiResponse(success: true, data: user);
    }

    return ApiResponse(
      success: false,
      message: response.message ?? 'Sign in failed',
    );
  }

  Future<void> signOut() async {
    try {
      // Call logout API
      final token = getToken();
      if (token != null && token.isNotEmpty) {
        await _apiService.getResponse<Map<String, dynamic>>(
          url: EndPoints.logOut,
          apiType: APIType.aPost,
          body: {},
          fromJson: (json) => json as Map<String, dynamic>,
        );
      }
    } catch (e) {
      // Log error but continue with local logout
      // This ensures user is logged out locally even if API call fails
      print('Logout API error: $e');
    } finally {
      // Always clear local storage regardless of API call result
      await StorageService.remove(AppConstants.tokenKey);
      await StorageService.remove(AppConstants.userKey);
      await StorageService.remove(AppConstants.roleKey);
    }
  }

  Future<UserModel?> getCurrentUser() async {
    final userData = StorageService.getObject(AppConstants.userKey);
    if (userData != null) {
      return UserModel.fromJson(userData);
    }
    return null;
  }

  String? getToken() {
    return StorageService.getString(AppConstants.tokenKey);
  }

  Future<void> _saveAuthData(UserModel user, String? token) async {
    if (token != null) {
      await StorageService.setString(AppConstants.tokenKey, token);
    }
    await StorageService.setObject(AppConstants.userKey, user.toJson());
    await StorageService.setString(AppConstants.roleKey, user.roleName);
  }
}
