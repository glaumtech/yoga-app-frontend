import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import '../../core/constants/app_constants.dart';
import '../../core/utils/file_upload_client.dart';
import '../../core/utils/storage_service.dart';
import '../../services/api_service.dart';
import '../models/api_response.dart';
import '../models/participant_video_model.dart';

class ParticipantVideoRepository {
  final APIService _apiService = APIService();

  Map<String, String> _authHeaders({bool json = true}) {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    final token = StorageService.getString(
      AppConstants.participantVideoTokenKey,
    );
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<ApiResponse<ParticipantVideoSession>> login({
    required String registrationNo,
    required String dateOfBirth,
  }) {
    return _apiService.getResponse<ParticipantVideoSession>(
      url: EndPoints.participantVideoLogin,
      apiType: APIType.aPost,
      header: {'Content-Type': 'application/json'},
      body: {
        'registrationNo': registrationNo,
        'dateOfBirth': dateOfBirth,
      },
      fromJson: (json) => ParticipantVideoSession.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }

  Future<ApiResponse<ParticipantVideoSession>> me() {
    return _apiService.getResponse<ParticipantVideoSession>(
      url: EndPoints.participantVideoMe,
      apiType: APIType.aGet,
      header: _authHeaders(),
      fromJson: (json) => ParticipantVideoSession.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }

  Future<ApiResponse<ParticipantVideoSession>> start() {
    return _apiService.getResponse<ParticipantVideoSession>(
      url: EndPoints.participantVideoStart,
      apiType: APIType.aPost,
      header: _authHeaders(),
      body: <String, dynamic>{},
      fromJson: (json) => ParticipantVideoSession.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }

  Future<ApiResponse<ParticipantVideoSession>> saveCount({
    required String entryDate,
    required int count,
  }) {
    return _apiService.getResponse<ParticipantVideoSession>(
      url: EndPoints.participantVideoCount,
      apiType: APIType.aPut,
      header: _authHeaders(),
      body: {
        'entryDate': entryDate,
        'count': count,
      },
      fromJson: (json) => ParticipantVideoSession.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }

  Future<ApiResponse<ParticipantVideoSession>> saveUrl({
    required String entryDate,
    required String videoUrl,
  }) {
    return _apiService.getResponse<ParticipantVideoSession>(
      url: EndPoints.participantVideoUrl,
      apiType: APIType.aPut,
      header: _authHeaders(),
      body: {
        'entryDate': entryDate,
        'videoUrl': videoUrl,
      },
      fromJson: (json) => ParticipantVideoSession.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }

  Future<ApiResponse<ParticipantVideoSession>> uploadVideo({
    required String entryDate,
    required Uint8List bytes,
    required String filename,
    required void Function(double progress) onProgress,
  }) async {
    final url = Uri.parse(BaseUrl.baseUrl + EndPoints.participantVideoUpload);
    try {
      final response = await uploadFileWithProgress(
        url: url,
        headers: _authHeaders(json: false),
        field: 'file',
        bytes: bytes,
        filename: filename,
        contentType: 'video/mp4',
        extraFields: {'entryDate': entryDate},
        onProgress: onProgress,
      );
      log('Video upload responded ${response.statusCode}: ${response.body}');
      return _parseUploadResponse(response);
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message:
            'The upload timed out. Try again on a faster connection or with a '
            'smaller file.',
        statusCode: 0,
      );
    } on UploadException catch (e) {
      return ApiResponse(success: false, message: e.message, statusCode: 0);
    } catch (e) {
      log('Video upload threw: $e');
      return ApiResponse(
        success: false,
        message: 'Video upload failed: $e',
        statusCode: 0,
      );
    }
  }

  ApiResponse<ParticipantVideoSession> _parseUploadResponse(
    UploadResponse response,
  ) {
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        json = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Non-JSON body (proxy or container error page) is handled below.
    }

    final serverMessage = json?['message']?.toString().trim();
    final isHttpOk = response.statusCode >= 200 && response.statusCode < 300;

    if (json == null) {
      return ApiResponse(
        success: false,
        message: response.body.trim().isEmpty
            ? 'Upload failed (HTTP ${response.statusCode}) with an empty response.'
            : 'Upload failed (HTTP ${response.statusCode}): ${_snippet(response.body)}',
        statusCode: response.statusCode,
      );
    }

    if (json['success'] == true && isHttpOk) {
      return ApiResponse(
        success: true,
        message: serverMessage,
        data: json['data'] is Map
            ? ParticipantVideoSession.fromJson(
                Map<String, dynamic>.from(json['data'] as Map),
              )
            : null,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse(
      success: false,
      message: serverMessage == null || serverMessage.isEmpty
          ? 'Upload failed (HTTP ${response.statusCode}).'
          : serverMessage,
      statusCode: response.statusCode,
    );
  }

  static String _snippet(String body) {
    final text = body
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return text.length <= 200 ? text : '${text.substring(0, 200)}...';
  }
}
