import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import '../../core/constants/app_constants.dart';
import '../../core/utils/file_upload_client.dart';
import '../../core/utils/storage_service.dart';
import '../../services/api_service.dart';
import '../models/api_response.dart';
import '../models/participant_feedback_model.dart';

class ParticipantFeedbackRepository {
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

  Future<ApiResponse<ParticipantFeedbackModel?>> getMine() {
    return _apiService.getResponse<ParticipantFeedbackModel?>(
      url: EndPoints.participantFeedbackMe,
      apiType: APIType.aGet,
      header: _authHeaders(),
      fromJson: (json) {
        if (json == null) return null;
        if (json is Map) {
          return ParticipantFeedbackModel.fromJson(
            Map<String, dynamic>.from(json),
          );
        }
        return null;
      },
    );
  }

  Future<ApiResponse<List<ParticipantFeedbackModel>>> listPublicByCompetition(
    String competitionId,
  ) {
    return _apiService.getResponse<List<ParticipantFeedbackModel>>(
      url: EndPoints.participantFeedbackPublicByCompetition(competitionId),
      apiType: APIType.aGet,
      header: {'Content-Type': 'application/json'},
      fromJson: (json) {
        if (json is! List) return <ParticipantFeedbackModel>[];
        return json
            .whereType<Map>()
            .map(
              (item) => ParticipantFeedbackModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      },
    );
  }

  Future<ApiResponse<ParticipantFeedbackModel>> save({
    required String reviewText,
    required bool isPublic,
    Uint8List? imageBytes,
    String? imageFileName,
    bool clearImage = false,
  }) async {
    final hasImage = imageBytes != null &&
        imageBytes.isNotEmpty &&
        (imageFileName ?? '').trim().isNotEmpty;

    if (!hasImage) {
      return _apiService.getResponse<ParticipantFeedbackModel>(
        url: EndPoints.participantFeedback,
        apiType: APIType.aPost,
        header: _authHeaders(),
        body: {
          'reviewText': reviewText,
          'isPublic': isPublic,
          'clearImage': clearImage,
        },
        fromJson: (json) => ParticipantFeedbackModel.fromJson(
          json is Map ? Map<String, dynamic>.from(json) : null,
        ),
      );
    }

    final url = Uri.parse(BaseUrl.baseUrl + EndPoints.participantFeedback);
    try {
      final response = await uploadFileWithProgress(
        url: url,
        headers: _authHeaders(json: false),
        field: 'image',
        bytes: imageBytes,
        filename: imageFileName!.trim(),
        contentType: _contentTypeFor(imageFileName),
        extraFields: {
          'reviewText': reviewText,
          'isPublic': isPublic.toString(),
          'clearImage': clearImage.toString(),
        },
        onProgress: (_) {},
      );
      return _parseSaveResponse(response);
    } on UploadException catch (e) {
      return ApiResponse(success: false, message: e.message, statusCode: 0);
    } catch (e) {
      log('Feedback save threw: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to save feedback: $e',
        statusCode: 0,
      );
    }
  }

  ApiResponse<ParticipantFeedbackModel> _parseSaveResponse(
    UploadResponse response,
  ) {
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        json = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    final serverMessage = json?['message']?.toString().trim();
    final isHttpOk = response.statusCode >= 200 && response.statusCode < 300;

    if (json == null) {
      return ApiResponse(
        success: false,
        message: 'Save failed (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (json['success'] == true && isHttpOk) {
      return ApiResponse(
        success: true,
        message: serverMessage,
        data: json['data'] is Map
            ? ParticipantFeedbackModel.fromJson(
                Map<String, dynamic>.from(json['data'] as Map),
              )
            : null,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse(
      success: false,
      message: (serverMessage == null || serverMessage.isEmpty)
          ? 'Failed to save feedback'
          : serverMessage,
      statusCode: response.statusCode,
    );
  }

  String _contentTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpeg') || lower.endsWith('.jpg')) return 'image/jpeg';
    return 'application/octet-stream';
  }
}
