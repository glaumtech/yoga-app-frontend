import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../core/utils/storage_service.dart';
import '../data/models/api_response.dart';

enum APIType { aPost, aGet, aPut, aPatch, aDelete }

class APIService {
  Future<ApiResponse<T>> getResponse<T>({
    required String url,
    required APIType apiType,
    Map<String, dynamic>? body,
    Map<String, String>? header,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      Map<String, String> headers =
          header ?? {'Content-Type': 'application/json'};

      // Automatically get bearer token from storage (skip for login/signup)
      final isAuthEndpoint =
          url == EndPoints.logIn || url == EndPoints.register;
      if (!isAuthEndpoint) {
        try {
          final token = StorageService.getString(AppConstants.tokenKey);
          if (token != null && token.isNotEmpty) {
            headers['Authorization'] = 'Bearer $token';
            log('----token---$token');
          }
        } catch (e) {
          log('Error getting token: $e');
        }
      } else {
        log('----Skipping token for auth endpoint: $url');
      }
      log('----BODY---$body');

      http.Response result;
      final fullUrl = BaseUrl.baseUrl + url;

      // Make the API call based on type
      switch (apiType) {
        case APIType.aGet:
          log('--- GET URL---$fullUrl');
          result = await http
              .get(Uri.parse(fullUrl), headers: headers)
              .timeout(BaseUrl.apiTimeout);
          break;
        case APIType.aPost:
          log('--- POST URL---$fullUrl');
          result = await http
              .post(
                Uri.parse(fullUrl),
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(BaseUrl.apiTimeout);
          break;
        case APIType.aPut:
          log('--- PUT URL---$fullUrl');
          result = await http
              .put(
                Uri.parse(fullUrl),
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(BaseUrl.apiTimeout);
          break;
        case APIType.aPatch:
          log('--- PATCH URL---$fullUrl');
          result = await http
              .patch(
                Uri.parse(fullUrl),
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(BaseUrl.apiTimeout);
          break;
        case APIType.aDelete:
          log('--- DELETE URL---$fullUrl');
          result = await http
              .delete(Uri.parse(fullUrl), headers: headers)
              .timeout(BaseUrl.apiTimeout);
          break;
      }

      log('----STATUS CODE---${result.statusCode}');
      log('----RESPONSE BODY---${result.body}');

      // Parse and return standardized response
      return _parseResponse<T>(result, fromJson);
    } on SocketException {
      return ApiResponse<T>(
        success: false,
        message: 'No Internet connection. Please check your network.',
        statusCode: 0,
      );
    } on TimeoutException {
      return ApiResponse<T>(
        success: false,
        message: 'Request timeout. Please try again',
        statusCode: 0,
      );
    } on http.ClientException catch (e) {
      log('ClientException: $e');
      final baseUrl = BaseUrl.baseUrl;
      return ApiResponse<T>(
        success: false,
        message: 'Failed to connect to server',
        statusCode: 0,
      );
    } catch (e) {
      log('Exception: $e');
      return ApiResponse<T>(
        success: false,
        message: 'An error occurred: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  ApiResponse<T> _parseResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    try {
      if (response.body.isEmpty || response.body.trim().isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return ApiResponse<T>(
            success: true,
            message: null,
            data: null,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse<T>(
            success: false,
            message: _getErrorMessageForStatusCode(response.statusCode),
            statusCode: response.statusCode,
          );
        }
      }

      // Check if response is HTML (error pages from CDN/gateway)
      if (response.body.trim().toLowerCase().startsWith('<!doctype html') ||
          response.body.trim().toLowerCase().startsWith('<html')) {
        return ApiResponse<T>(
          success: false,
          message: _getErrorMessageForStatusCode(response.statusCode),
          statusCode: response.statusCode,
        );
      }

      final dynamic parsed = jsonDecode(response.body);

      if (parsed is Map<String, dynamic>) {
        final String? status = parsed['status']?.toString().toLowerCase();
        final String? message = parsed['message']?.toString();
        final dynamic data = parsed['data'];

        // Handle success response: {"status":"success","message":"...","data":{...}}
        if (status == 'success') {
          T? resultData;
          if (fromJson != null && data != null) {
            resultData = fromJson(data);
          } else if (data != null) {
            // Safe type casting
            try {
              resultData = data is T ? data : null;
            } catch (e) {
              log('Type cast error: $e');
              resultData = null;
            }
          }

          return ApiResponse<T>(
            success: true,
            message: message,
            data: resultData,
            statusCode: response.statusCode,
          );
        }

        // Handle error response: {"status":"error","message":"...","errorCode":"..."}
        if (status == 'error') {
          return ApiResponse<T>(
            success: false,
            message: message ?? 'An error occurred',
            statusCode: response.statusCode,
          );
        }

        // Handle HTTP status codes when response doesn't have status field
        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Success - return the data or full response
          T? resultData;
          if (fromJson != null && (data != null || parsed.isNotEmpty)) {
            resultData = fromJson(data ?? parsed);
          } else {
            // Safe type casting
            try {
              final value = data ?? parsed;
              resultData = value is T ? value : null;
            } catch (e) {
              log('Type cast error: $e');
              resultData = null;
            }
          }

          return ApiResponse<T>(
            success: true,
            message: message,
            data: resultData,
            statusCode: response.statusCode,
          );
        } else {
          // Error HTTP status code
          return ApiResponse<T>(
            success: false,
            message:
                message ??
                parsed['error']?.toString() ??
                _getErrorMessageForStatusCode(response.statusCode),
            statusCode: response.statusCode,
          );
        }
      }

      // Non-map response (string, array, etc.)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        T? resultData;
        if (fromJson != null) {
          resultData = fromJson(parsed);
        } else {
          // Safe type casting
          try {
            resultData = parsed is T ? parsed : null;
          } catch (e) {
            log('Type cast error: $e');
            resultData = null;
          }
        }

        return ApiResponse<T>(
          success: true,
          data: resultData,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<T>(
          success: false,
          message: _getErrorMessageForStatusCode(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      log('Error parsing response: $e');
      // If parsing fails, check HTTP status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<T>(
          success: true,
          data: response.body as T?,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<T>(
          success: false,
          message: _getErrorMessageForStatusCode(response.statusCode),
          statusCode: response.statusCode,
        );
      }
    }
  }

  String _getErrorMessageForStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad Request. Please check your input';
      case 401:
        return 'Unauthorized. Please login again';
      case 403:
        return 'Access forbidden';
      case 404:
        return 'Resource not found';
      case 408:
        return 'Request timeout. Please try again';
      case 429:
        return 'Too many requests. Please try again later';
      case 500:
        return 'Internal server error. Please try again later';
      case 502:
        return 'Bad gateway. The server is temporarily unavailable';
      case 503:
        return 'Service unavailable. Please try again later';
      case 504:
        return 'Gateway timeout. The server took too long to respond. Please try again';
      default:
        if (statusCode >= 500) {
          return 'Server error. Please try again later';
        } else if (statusCode >= 400) {
          return 'Request error. Please try again';
        } else {
          return 'An error occurred';
        }
    }
  }

  // Multipart upload method for file uploads
  Future<ApiResponse<T>> postMultipart<T>({
    required String url,
    required Map<String, String> fields,
    required http.MultipartFile file,
    Map<String, String>? header,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      Map<String, String> headers = header ?? {};

      // Automatically get bearer token from storage (skip for login/signup)
      final isAuthEndpoint =
          url == EndPoints.logIn || url == EndPoints.register;
      if (!isAuthEndpoint) {
        try {
          final token = StorageService.getString(AppConstants.tokenKey);
          if (token != null && token.isNotEmpty) {
            headers['Authorization'] = 'Bearer $token';
            log('----token---$token');
          }
        } catch (e) {
          log('Error getting token: $e');
        }
      } else {
        log('----Skipping token for auth endpoint: $url');
      }

      final fullUrl = BaseUrl.baseUrl + url;
      log('--- POST MULTIPART URL---$fullUrl');

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(fullUrl));

      // Add headers
      request.headers.addAll(headers);

      // Add fields
      request.fields.addAll(fields);

      // Add file
      request.files.add(file);

      log('----FIELDS---$fields');
      log('----FILE---${file.filename} (${file.length} bytes)');

      // Send request
      final streamedResponse = await request.send().timeout(BaseUrl.apiTimeout);

      // Get response
      final response = await http.Response.fromStream(streamedResponse);

      log('----STATUS CODE---${response.statusCode}');
      log('----RESPONSE BODY---${response.body}');

      // Parse and return standardized response
      return _parseResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse<T>(
        success: false,
        message: 'No Internet connection',
        statusCode: 0,
      );
    } on TimeoutException {
      return ApiResponse<T>(
        success: false,
        message: 'Request timeout. Please try again',
        statusCode: 0,
      );
    } catch (e) {
      log('Exception: $e');
      return ApiResponse<T>(
        success: false,
        message: 'An error occurred. Please try again',
        statusCode: 0,
      );
    }
  }

  // Multipart upload method for PUT requests with file
  Future<ApiResponse<T>> putMultipart<T>({
    required String url,
    required Map<String, String> fields,
    required http.MultipartFile file,
    Map<String, String>? header,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      Map<String, String> headers = header ?? {};

      // Automatically get bearer token from storage (skip for login/signup)
      final isAuthEndpoint =
          url == EndPoints.logIn || url == EndPoints.register;
      if (!isAuthEndpoint) {
        try {
          final token = StorageService.getString(AppConstants.tokenKey);
          if (token != null && token.isNotEmpty) {
            headers['Authorization'] = 'Bearer $token';
            log('----token---$token');
          }
        } catch (e) {
          log('Error getting token: $e');
        }
      } else {
        log('----Skipping token for auth endpoint: $url');
      }

      final fullUrl = BaseUrl.baseUrl + url;
      log('--- PUT MULTIPART URL---$fullUrl');

      // Create multipart request
      final request = http.MultipartRequest('PUT', Uri.parse(fullUrl));

      // Add headers
      request.headers.addAll(headers);

      // Add fields
      request.fields.addAll(fields);

      // Add file
      request.files.add(file);

      log('----FIELDS---$fields');
      log('----FILE---${file.filename} (${file.length} bytes)');

      // Send request
      final streamedResponse = await request.send().timeout(BaseUrl.apiTimeout);

      // Get response
      final response = await http.Response.fromStream(streamedResponse);

      log('----STATUS CODE---${response.statusCode}');
      log('----RESPONSE BODY---${response.body}');

      // Parse and return standardized response
      return _parseResponse<T>(response, fromJson);
    } on SocketException {
      return ApiResponse<T>(
        success: false,
        message: 'No Internet connection',
        statusCode: 0,
      );
    } on TimeoutException {
      return ApiResponse<T>(
        success: false,
        message: 'Request timeout. Please try again',
        statusCode: 0,
      );
    } catch (e) {
      log('Exception: $e');
      return ApiResponse<T>(
        success: false,
        message: 'An error occurred. Please try again',
        statusCode: 0,
      );
    }
  }
}

class ImageStreamingService {
  String getEventBannerUrl(int eventId) {
    return '${BaseUrl.baseUrl}/event/image/$eventId';
  }

  Map<String, String> getHeaders() {
    try {
      final token = StorageService.getString(AppConstants.tokenKey);
      if (token == null || token.isEmpty) {
        log('ImageStreamingService - No token found in storage');
        return {};
      }
      final headers = {'Authorization': 'Bearer $token'};
      log(
        'ImageStreamingService - Headers created with token: ${token.substring(0, 10)}...',
      );
      return headers;
    } catch (e) {
      log('ImageStreamingService - Error getting headers: $e');
      return {};
    }
  }
}
