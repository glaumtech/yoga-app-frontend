import 'dart:developer';

import 'package:get/get.dart';

import '../../presentation/controllers/auth_controller.dart';
import '../../routes/app_router.dart';
import '../../routes/app_routes.dart';
import '../constants/app_constants.dart';
import '../utils/storage_service.dart';

/// Redirects to login when an API response indicates the session is no longer valid.
class SessionExpiryHandler {
  SessionExpiryHandler._();

  static bool _isHandling = false;

  static bool _isAuthRequest(String requestUrl) {
    return requestUrl == EndPoints.logIn ||
        requestUrl == EndPoints.register ||
        requestUrl == EndPoints.logOut ||
        requestUrl == EndPoints.forgotPassword ||
        requestUrl == EndPoints.verifyOtp ||
        requestUrl == EndPoints.resetPassword;
  }

  /// Payment gateway errors (e.g. invalid Razorpay keys) must not sign the user out.
  static bool _isPaymentRequest(String requestUrl) {
    return requestUrl.contains('/api/create-order') ||
        requestUrl.contains('/api/verify-payment') ||
        requestUrl.contains('/api/mark-payment-failed') ||
        requestUrl.contains('/payment/') ||
        (requestUrl.contains('/participant-registration/') &&
            requestUrl.contains('/payment/'));
  }

  static bool _isPaymentGatewayError({
    String? message,
    Map<String, dynamic>? body,
  }) {
    final combinedMessage = [
      message,
      body?['message']?.toString(),
    ].whereType<String>().join(' ').toLowerCase();

    return combinedMessage.contains('razorpay');
  }

  static bool _hasStoredSession() {
    final token = StorageService.getString(AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  static bool isUnauthorizedResponse({
    required int statusCode,
    String? message,
    Map<String, dynamic>? body,
  }) {
    if (statusCode == 401 || statusCode == 403) {
      return true;
    }

    final error = body?['error']?.toString().toLowerCase().trim();
    if (error == 'unauthorized') {
      return true;
    }

    final combinedMessage = [
      message,
      body?['message']?.toString(),
    ].whereType<String>().join(' ').toLowerCase();

    if (combinedMessage.contains('unauthorized')) {
      return true;
    }

    if (combinedMessage.contains('access denied') &&
        combinedMessage.contains('authentication')) {
      return true;
    }

    return false;
  }

  static void handleIfNeeded({
    required String requestUrl,
    required int statusCode,
    String? message,
    Map<String, dynamic>? body,
  }) {
    if (_isHandling ||
        _isAuthRequest(requestUrl) ||
        _isPaymentRequest(requestUrl) ||
        !_hasStoredSession()) {
      return;
    }

    if (_isPaymentGatewayError(message: message, body: body)) {
      return;
    }

    if (!isUnauthorizedResponse(
      statusCode: statusCode,
      message: message,
      body: body,
    )) {
      return;
    }

    _isHandling = true;

    Future<void>.microtask(() async {
      try {
        if (Get.isRegistered<AuthController>()) {
          await Get.find<AuthController>().signOut();
        } else {
          await StorageService.clear();
        }

        AppRouter.router.go(AppRoutes.login);
      } catch (e, stackTrace) {
        log(
          'Session expiry handling failed: $e',
          stackTrace: stackTrace,
          name: 'SessionExpiryHandler',
        );
        try {
          await StorageService.clear();
          AppRouter.router.go(AppRoutes.login);
        } catch (_) {}
      } finally {
        Future<void>.delayed(const Duration(seconds: 2), () {
          _isHandling = false;
        });
      }
    });
  }
}
