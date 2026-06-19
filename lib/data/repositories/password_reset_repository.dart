import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../models/api_response.dart';

class PasswordResetRepository {
  final APIService _apiService = APIService();

  Future<ApiResponse<void>> forgotPassword({
    required String userName,
    required String email,
  }) async {
    return _apiService.getResponse<void>(
      url: EndPoints.forgotPassword,
      apiType: APIType.aPost,
      body: {
        'userName': userName.trim(),
        'email': email.trim(),
      },
      fromJson: (_) {},
    );
  }

  Future<ApiResponse<String>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    return _apiService.getResponse<String>(
      url: EndPoints.verifyOtp,
      apiType: APIType.aPost,
      body: {
        'email': email.trim(),
        'otp': otp.trim(),
      },
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return json['resetToken']?.toString() ?? '';
        }
        return '';
      },
    );
  }

  Future<ApiResponse<void>> resetPassword({
    required String userName,
    required String email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return _apiService.getResponse<void>(
      url: EndPoints.resetPassword,
      apiType: APIType.aPost,
      body: {
        'userName': userName.trim(),
        'email': email.trim(),
        'resetToken': resetToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      fromJson: (_) {},
    );
  }

  Future<ApiResponse<String>> sendChangePasswordOtp({
    required String currentPassword,
  }) async {
    return _apiService.getResponse<String>(
      url: EndPoints.changePasswordSendOtp,
      apiType: APIType.aPost,
      body: {
        'currentPassword': currentPassword,
      },
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return json['maskedEmail']?.toString() ?? '';
        }
        return '';
      },
    );
  }

  Future<ApiResponse<String>> verifyChangePasswordOtp({
    required String otp,
  }) async {
    return _apiService.getResponse<String>(
      url: EndPoints.changePasswordVerifyOtp,
      apiType: APIType.aPost,
      body: {
        'otp': otp.trim(),
      },
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return json['resetToken']?.toString() ?? '';
        }
        return '';
      },
    );
  }

  Future<ApiResponse<void>> confirmChangePassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return _apiService.getResponse<void>(
      url: EndPoints.changePasswordConfirm,
      apiType: APIType.aPost,
      body: {
        'resetToken': resetToken,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      fromJson: (_) {},
    );
  }
}
