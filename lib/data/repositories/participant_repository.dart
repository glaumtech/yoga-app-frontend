import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/participant_model.dart';
import '../models/api_response.dart';
import '../models/score_response_model.dart';

class ParticipantRepository {
  final APIService _apiService = APIService();

  Future<ApiResponse<ParticipantModel>> createParticipant({
    required ParticipantModel participant,
    dynamic photoFile, // File on mobile, null on web
    XFile? photoXFile,
    required String eventId,
  }) async {
    try {
      // Use multipart request for file upload
      // API expects 'data' as JSON string and 'photo' as file
      final participantJson = participant.toJson(includeCreatedAt: false);
      final dataJsonString = jsonEncode(participantJson);

      final fields = <String, String>{'data': dataJsonString};

      http.MultipartFile multipartFile;

      // Prefer XFile (works on web) over File (dart:io)
      if (photoXFile != null) {
        try {
          final fileBytes = await photoXFile.readAsBytes();
          final fileName = photoXFile.name.split('/').last;
          multipartFile = http.MultipartFile.fromBytes(
            'photo',
            fileBytes,
            filename: fileName,
          );
        } catch (e) {
          print('Error reading XFile: $e');
          // Fallback: create empty multipart file
          multipartFile = http.MultipartFile.fromBytes(
            'photo',
            [],
            filename: '',
          );
        }
      } else if (photoFile != null) {
        try {
          // Try to read file bytes (works on mobile, not web)
          // Use dynamic call to avoid compile-time errors on web
          final fileBytes = await (photoFile as dynamic).readAsBytes();
          final fileName = (photoFile as dynamic).path.split('/').last;
          multipartFile = http.MultipartFile.fromBytes(
            'photo',
            fileBytes,
            filename: fileName,
          );
        } catch (e) {
          print(
            'Error reading File: $e - File operations not supported on web',
          );
          // Fallback: create empty multipart file
          multipartFile = http.MultipartFile.fromBytes(
            'photo',
            [],
            filename: '',
          );
        }
      } else {
        // No photo provided
        multipartFile = http.MultipartFile.fromBytes('photo', [], filename: '');
      }

      // Use event-specific registration endpoint
      final response = await _apiService.postMultipart<Map<String, dynamic>>(
        url: EndPoints.participantRegistrationEventId(eventId),
        fields: fields,
        file: multipartFile,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final participant = ParticipantModel.fromJson(response.data!);
        return ApiResponse(success: true, data: participant);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to create participant',
      );
    } catch (e, stackTrace) {
      print('Error in createParticipant: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error creating participant: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<ParticipantModel>> updateParticipant({
    required String id,
    required ParticipantModel participant,
    dynamic photoFile, // File on mobile, null on web
    XFile? photoXFile,
  }) async {
    try {
      // Always use multipart request (same format as create)
      // API expects 'data' as JSON string and 'photo' as file
      final participantJson = participant.toJson(includeCreatedAt: false);
      final dataJsonString = jsonEncode(participantJson);

      final fields = <String, String>{'data': dataJsonString};

      http.MultipartFile multipartFile;

      // Prefer XFile (works on web) over File (dart:io)
      if (photoXFile != null) {
        try {
          final fileBytes = await photoXFile.readAsBytes();
          final fileName = photoXFile.name.split('/').last;
          multipartFile = http.MultipartFile.fromBytes(
            'photo',
            fileBytes,
            filename: fileName,
          );
        } catch (e) {
          print('Error reading XFile: $e');
          // Create empty multipart file if error
          multipartFile = http.MultipartFile.fromBytes(
            'photo',
            [],
            filename: '',
          );
        }
      } else if (photoFile != null) {
        try {
          // Read file bytes (works on mobile, not web)
          final fileBytes = await (photoFile as dynamic).readAsBytes();
          final fileName = (photoFile as dynamic).path.split('/').last;
          multipartFile = http.MultipartFile.fromBytes(
            'photo',
            fileBytes,
            filename: fileName,
          );
        } catch (e) {
          print('Error reading File: $e');
          // Create empty multipart file if error
          multipartFile = http.MultipartFile.fromBytes(
            'photo',
            [],
            filename: '',
          );
        }
      } else {
        // No photo provided - send empty multipart file (same as create)
        multipartFile = http.MultipartFile.fromBytes('photo', [], filename: '');
      }

      // Use multipart upload for PUT (always use multipart, same as create)
      final response = await _apiService.putMultipart<Map<String, dynamic>>(
        url: EndPoints.participantUpdate(id),
        fields: fields,
        file: multipartFile,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final participant = ParticipantModel.fromJson(response.data!);
        return ApiResponse(success: true, data: participant);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to update participant',
      );
    } catch (e, stackTrace) {
      print('Error in updateParticipant: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error updating participant: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<bool>> deleteParticipant(String id) async {
    final response = await _apiService.getResponse<bool>(
      url: EndPoints.participantById(id),
      apiType: APIType.aDelete,
    );
    return response;
  }

  Future<ApiResponse<ParticipantModel>> updateScores({
    required String id,
    required Map<String, double> juryScores,
  }) async {
    final grandTotal = juryScores.values.fold(0.0, (sum, score) => sum + score);

    final response = await _apiService.getResponse<Map<String, dynamic>>(
      url: EndPoints.participantScores(id),
      apiType: APIType.aPut,
      body: {'juryScores': juryScores, 'grandTotal': grandTotal},
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      final participant = ParticipantModel.fromJson(response.data!);
      return ApiResponse(success: true, data: participant);
    }

    return ApiResponse(
      success: false,
      message: response.message ?? 'Failed to update scores',
    );
  }

  Future<ApiResponse<bool>> updateParticipantStatus({
    required String id,
    required String status,
  }) async {
    try {
      final endpoint = EndPoints.participantStatusVerify(id, status);
      print('Updating participant status - ID: $id, Status: $status');
      print('Endpoint: $endpoint');
      print('Full URL: ${BaseUrl.baseUrl}$endpoint');

      final response = await _apiService.getResponse<dynamic>(
        url: endpoint,
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      print(
        'Update status response: ${response.success}, message: ${response.message}',
      );
      print('Response status code: ${response.statusCode}');
      if (response.data != null) {
        print('Response data: ${response.data}');
      }

      if (response.success) {
        return ApiResponse(success: true, data: true);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to update participant status',
        statusCode: response.statusCode,
      );
    } catch (e, stackTrace) {
      print('Error in updateParticipantStatus: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error updating participant status: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<ParticipantFilterData>> getParticipantsByEventId({
    required String eventId,
    ParticipantFilterRequest? filter,
  }) async {
    try {
      // Use filter if provided, otherwise use default empty filter
      final filterRequest = filter ?? ParticipantFilterRequest();
      final filterJson = filterRequest.toJson();

      print('getParticipantsByEventId - eventId: $eventId');
      print('getParticipantsByEventId - filter: $filterJson');

      final response = await _apiService.getResponse<Map<String, dynamic>>(
        url: EndPoints.participantsFilterByEventId(eventId),
        apiType: APIType.aPost,
        body: filterJson,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      print('getParticipantsByEventId response.success: ${response.success}');
      print('getParticipantsByEventId response.data: ${response.data}');

      if (response.success && response.data != null) {
        final filterData = ParticipantFilterData.fromJson(response.data!);
        return ApiResponse(success: true, data: filterData);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch participants for event',
      );
    } catch (e, stackTrace) {
      print('Error in getParticipantsByEventId: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error loading participants: ${e.toString()}',
      );
    }
  }

  /// Get participant details by ID using GET API
  Future<ApiResponse<ParticipantModel>> getParticipantById(String id) async {
    try {
      print('getParticipantById - id: $id');
      print('Endpoint: ${EndPoints.participantDetailById(id)}');

      final response = await _apiService.getResponse<Map<String, dynamic>>(
        url: EndPoints.participantDetailById(id),
        apiType: APIType.aGet,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      print('getParticipantById response.success: ${response.success}');
      print('getParticipantById response.data: ${response.data}');

      if (response.success && response.data != null) {
        final participant = ParticipantModel.fromJson(response.data!['user']);
        return ApiResponse(success: true, data: participant);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch participant details',
      );
    } catch (e, stackTrace) {
      print('Error in getParticipantById: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error loading participant: ${e.toString()}',
      );
    }
  }

  /// Save scores using the new scoring API format
  Future<ApiResponse<Map<String, dynamic>>> saveScores({
    required String eventId,
    required List<Map<String, dynamic>> scoreOfParticipants,
  }) async {
    try {
      final requestBody = {
        'eventId': int.tryParse(eventId) ?? eventId,
        'scoreOfParticipants': scoreOfParticipants,
      };

      final response = await _apiService.getResponse<Map<String, dynamic>>(
        url: EndPoints.scoringSave,
        apiType: APIType.aPost,
        body: requestBody,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success) {
        return ApiResponse(success: true, data: response.data ?? {});
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to save scores',
      );
    } catch (e, stackTrace) {
      print('Error in saveScores: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error saving scores: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<ScoreResponseModel>> getParticipantScoresByEventId(
    String eventId,
  ) async {
    try {
      final response = await _apiService.getResponse<Map<String, dynamic>>(
        url: EndPoints.participantScoresByEventId(eventId),
        apiType: APIType.aGet,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        // Parse the nested structure
        final data = response.data!;
        final scoreResponse = ScoreResponseModel.fromJson(data);
        return ApiResponse(success: true, data: scoreResponse);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch scores',
      );
    } catch (e, stackTrace) {
      print('Error in getParticipantScoresByEventId: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error fetching scores: ${e.toString()}',
      );
    }
  }
}
