import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/storage_service.dart';
import '../models/participant_model.dart';
import '../models/api_response.dart';
import '../models/score_response_model.dart';

/// Response wrapper for participants with remaining count
class ParticipantsForScoringResponse {
  final List<ParticipantModel> participants;
  final int? remainingCount;

  ParticipantsForScoringResponse({
    required this.participants,
    this.remainingCount,
  });
}

class ParticipantRepository {
  final APIService _apiService = APIService();

  Future<ApiResponse<Map<String, dynamic>>> importParticipantRegistrationsExcel({
    required int competitionId,
    required String filename,
    Uint8List? bytes,
    String? filePath,
  }) async {
    try {
      final fields = <String, String>{'competitionId': competitionId.toString()};
      final lower = filename.toLowerCase();
      final contentType = lower.endsWith('.xls')
          ? MediaType('application', 'vnd.ms-excel')
          : MediaType(
              'application',
              'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            );
      http.MultipartFile multipartFile;

      if (!kIsWeb && filePath != null && filePath.trim().isNotEmpty) {
        multipartFile = await http.MultipartFile.fromPath(
          'file',
          filePath,
          filename: filename,
          contentType: contentType,
        );
      } else {
        final safeBytes = bytes ?? Uint8List(0);
        multipartFile = http.MultipartFile.fromBytes(
          'file',
          safeBytes,
          filename: filename,
          contentType: contentType,
        );
      }

      final response = await _apiService.postMultipart<Map<String, dynamic>>(
        url: EndPoints.participantRegistrationImport,
        fields: fields,
        file: multipartFile,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Import failed: ${e.toString()}',
      );
    }
  }

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

  Future<ApiResponse<SingleParticipantScoreResponseModel>>
  getParticipantScoresByParticipantId(
    String eventId,
    String participantId,
  ) async {
    try {
      final response = await _apiService.getResponse<Map<String, dynamic>>(
        url: EndPoints.participantScoresByParticipantId(eventId, participantId),
        apiType: APIType.aGet,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        // Parse the nested structure
        final data = response.data!;
        final scoreResponse = SingleParticipantScoreResponseModel.fromJson(
          data,
        );
        return ApiResponse(success: true, data: scoreResponse);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch participant score',
      );
    } catch (e, stackTrace) {
      print('Error in getParticipantScoresByParticipantId: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error fetching participant score: ${e.toString()}',
      );
    }
  }

  // Create participant registration (new API)
  Future<ApiResponse<Map<String, dynamic>>> createParticipantRegistration({
    required Map<String, dynamic> registrationData,
    dynamic photoFile,
    XFile? photoXFile,
    dynamic bonafiedCertificateFile,
    XFile? bonafiedCertificateXFile,
    XFile? paymentProofXFile,
  }) async {
    try {
      // Encode registration data as JSON string
      final dataJsonString = jsonEncode(registrationData);
      final fields = <String, String>{'data': dataJsonString};

      print('=== Creating Participant Registration ===');
      print('Registration Data: $dataJsonString');
      print('Has Photo: ${photoXFile != null || photoFile != null}');
      print(
        'Has Bonafied Certificate: ${bonafiedCertificateXFile != null || bonafiedCertificateFile != null}',
      );

      final fullUrl = BaseUrl.baseUrl + EndPoints.participantRegistrationCreate;
      print('Full URL: $fullUrl');

      final request = http.MultipartRequest('POST', Uri.parse(fullUrl));

      // Add authorization token
      try {
        final token = await StorageService.getString(AppConstants.tokenKey);
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        print('Error getting token: $e');
      }

      // Add fields - ensure data is properly added
      request.fields.addAll(fields);
      print('Fields added: ${request.fields}');

      // Add photo file
      if (photoXFile != null) {
        try {
          final fileBytes = await photoXFile.readAsBytes();
          final fileName = photoXFile.name.split('/').last;
          final multipartFile = http.MultipartFile.fromBytes(
            'photo',
            fileBytes,
            filename: fileName,
          );
          request.files.add(multipartFile);
        } catch (e) {
          print('Error reading photo XFile: $e');
        }
      } else if (photoFile != null) {
        try {
          final fileBytes = await (photoFile as dynamic).readAsBytes();
          final fileName = (photoFile as dynamic).path.split('/').last;
          final multipartFile = http.MultipartFile.fromBytes(
            'photo',
            fileBytes,
            filename: fileName,
          );
          request.files.add(multipartFile);
        } catch (e) {
          print('Error reading photo File: $e');
        }
      }

      // Add bonafied certificate file
      if (bonafiedCertificateXFile != null) {
        try {
          final fileBytes = await bonafiedCertificateXFile.readAsBytes();
          final fileName = bonafiedCertificateXFile.name.split('/').last;
          final multipartFile = http.MultipartFile.fromBytes(
            'bonafiedCertificate',
            fileBytes,
            filename: fileName,
          );
          request.files.add(multipartFile);
        } catch (e) {
          print('Error reading bonafied certificate XFile: $e');
        }
      } else if (bonafiedCertificateFile != null) {
        try {
          final fileBytes = await (bonafiedCertificateFile as dynamic)
              .readAsBytes();
          final fileName = (bonafiedCertificateFile as dynamic).path
              .split('/')
              .last;
          final multipartFile = http.MultipartFile.fromBytes(
            'bonafiedCertificate',
            fileBytes,
            filename: fileName,
          );
          request.files.add(multipartFile);
        } catch (e) {
          print('Error reading bonafied certificate File: $e');
        }
      }

      if (paymentProofXFile != null) {
        try {
          final fileBytes = await paymentProofXFile.readAsBytes();
          final fileName = paymentProofXFile.name.split('/').last;
          request.files.add(
            http.MultipartFile.fromBytes(
              'paymentProof',
              fileBytes,
              filename: fileName,
            ),
          );
        } catch (e) {
          print('Error reading payment proof: $e');
        }
      }

      // Send request
      print(
        'Sending multipart request with ${request.fields.length} fields and ${request.files.length} files',
      );
      print('Request fields: ${request.fields}');
      final streamedResponse = await request.send().timeout(BaseUrl.apiTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Parse response manually
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('Error parsing response JSON: $e');
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'Invalid response from server: ${response.body}',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: responseData['data'] != null
              ? (responseData['data'] as Map<String, dynamic>)
              : responseData,
          message: responseData['message'] as String?,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message:
              responseData['message'] as String? ??
              'Failed to create registration',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('Error in createParticipantRegistration: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error creating registration: ${e.toString()}',
      );
    }
  }

  // List participant registrations
  Future<ApiResponse<Map<String, dynamic>>> listParticipantRegistrations({
    String? search,
    int? competitionId,
    int? categoryId,
    int? institutionId,
    int? groupId,
    String? status,
    int page = 0,
    int limit = 20,
    String sortBy = 'createdAt',
    String order = 'desc',
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'order': order,
      };

      if (search != null && search.isNotEmpty) {
        requestBody['search'] = search;
      }
      if (competitionId != null) {
        requestBody['competitionId'] = competitionId;
      }
      if (categoryId != null) {
        requestBody['categoryId'] = categoryId;
      }
      if (institutionId != null) {
        requestBody['institutionId'] = institutionId;
      }
      if (groupId != null) {
        requestBody['groupId'] = groupId;
      }
      if (status != null && status.isNotEmpty) {
        requestBody['status'] = status;
      }

      final response = await _apiService.getResponse<Map<String, dynamic>>(
        url: EndPoints.participantRegistrationList,
        apiType: APIType.aPost,
        body: requestBody,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      print('Error in listParticipantRegistrations: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error listing registrations: ${e.toString()}',
      );
    }
  }

  // Get registration by ID
  Future<ApiResponse<Map<String, dynamic>>> getParticipantRegistrationById(
    String id,
  ) async {
    try {
      final response = await _apiService.getResponse<Map<String, dynamic>>(
        url: EndPoints.participantRegistrationById(id),
        apiType: APIType.aGet,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return response;
    } catch (e) {
      print('Error in getParticipantRegistrationById: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error fetching registration: ${e.toString()}',
      );
    }
  }

  // Update participant registration
  Future<ApiResponse<Map<String, dynamic>>> updateParticipantRegistration({
    required String id,
    required Map<String, dynamic> registrationData,
    dynamic photoFile,
    XFile? photoXFile,
    dynamic bonafiedCertificateFile,
    XFile? bonafiedCertificateXFile,
  }) async {
    try {
      final dataJsonString = jsonEncode(registrationData);
      final fields = <String, String>{'data': dataJsonString};

      final fullUrl =
          BaseUrl.baseUrl + EndPoints.participantRegistrationUpdate(id);
      final request = http.MultipartRequest('PUT', Uri.parse(fullUrl));

      // Add authorization token
      try {
        final token = await StorageService.getString(AppConstants.tokenKey);
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        print('Error getting token: $e');
      }

      // Add fields
      request.fields.addAll(fields);

      // Add photo file
      if (photoXFile != null) {
        try {
          final fileBytes = await photoXFile.readAsBytes();
          final fileName = photoXFile.name.split('/').last;
          final multipartFile = http.MultipartFile.fromBytes(
            'photo',
            fileBytes,
            filename: fileName,
          );
          request.files.add(multipartFile);
        } catch (e) {
          print('Error reading photo XFile: $e');
        }
      } else if (photoFile != null) {
        try {
          final fileBytes = await (photoFile as dynamic).readAsBytes();
          final fileName = (photoFile as dynamic).path.split('/').last;
          final multipartFile = http.MultipartFile.fromBytes(
            'photo',
            fileBytes,
            filename: fileName,
          );
          request.files.add(multipartFile);
        } catch (e) {
          print('Error reading photo File: $e');
        }
      }

      // Add bonafied certificate file
      if (bonafiedCertificateXFile != null) {
        try {
          final fileBytes = await bonafiedCertificateXFile.readAsBytes();
          final fileName = bonafiedCertificateXFile.name.split('/').last;
          final multipartFile = http.MultipartFile.fromBytes(
            'bonafiedCertificate',
            fileBytes,
            filename: fileName,
          );
          request.files.add(multipartFile);
        } catch (e) {
          print('Error reading bonafied certificate XFile: $e');
        }
      } else if (bonafiedCertificateFile != null) {
        try {
          final fileBytes = await (bonafiedCertificateFile as dynamic)
              .readAsBytes();
          final fileName = (bonafiedCertificateFile as dynamic).path
              .split('/')
              .last;
          final multipartFile = http.MultipartFile.fromBytes(
            'bonafiedCertificate',
            fileBytes,
            filename: fileName,
          );
          request.files.add(multipartFile);
        } catch (e) {
          print('Error reading bonafied certificate File: $e');
        }
      }

      // Send request
      final streamedResponse = await request.send().timeout(BaseUrl.apiTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: responseData['data'] != null
              ? (responseData['data'] as Map<String, dynamic>)
              : responseData,
          message: responseData['message'] as String?,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message:
              responseData['message'] as String? ??
              'Failed to update registration',
        );
      }
    } catch (e) {
      print('Error in updateParticipantRegistration: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Error updating registration: ${e.toString()}',
      );
    }
  }

  // Delete participant registration
  Future<ApiResponse<void>> deleteParticipantRegistration(String id) async {
    try {
      final response = await _apiService.getResponse<void>(
        url: EndPoints.participantRegistrationDelete(id),
        apiType: APIType.aDelete,
        fromJson: (json) => null,
      );

      return ApiResponse<void>(
        success: response.success,
        message: response.message,
      );
    } catch (e) {
      print('Error in deleteParticipantRegistration: $e');
      return ApiResponse<void>(
        success: false,
        message: 'Error deleting registration: ${e.toString()}',
      );
    }
  }

  /// Get participants for scoring based on filters
  Future<ApiResponse<ParticipantsForScoringResponse>>
  getParticipantsForScoring({
    required int competitionId,
    required int juryId,
    int? stageId,
    int? categoryId,
    int? groupId,
    String? institutionId,
    bool? male,
    bool? female,
    List<int>? replaceParticipantIds,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'competitionId': competitionId,
        'juryId': juryId,
      };

      // Add optional filters
      if (stageId != null) {
        requestBody['stageId'] = stageId;
      }
      if (categoryId != null) {
        requestBody['categoryId'] = categoryId;
      }
      if (groupId != null) {
        requestBody['groupId'] = groupId;
      }
      if (institutionId != null && institutionId.trim().isNotEmpty) {
        requestBody['institutionId'] = int.tryParse(institutionId) ?? institutionId;
      }
      if (male != null) {
        requestBody['male'] = male;
      }
      if (female != null) {
        requestBody['female'] = female;
      }
      if (replaceParticipantIds != null && replaceParticipantIds.isNotEmpty) {
        requestBody['replaceParticipantIds'] = replaceParticipantIds;
      }

      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.participantRegistrationForScoring,
        apiType: APIType.aPost,
        body: requestBody,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<ParticipantModel> participants = [];
        int? remainingCount;

        // Handle different response structures
        if (response.data is List) {
          participants = (response.data as List)
              .map(
                (json) =>
                    ParticipantModel.fromJson(json as Map<String, dynamic>),
              )
              .toList();
        } else if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;

          // Extract remainingCount if available
          if (dataMap.containsKey('remainingCount')) {
            remainingCount = dataMap['remainingCount'] as int?;
          }

          // Check for 'participants' or 'data' field
          dynamic participantsList =
              dataMap['participants'] ?? dataMap['data'] ?? dataMap['users'];

          if (participantsList is List) {
            participants = participantsList
                .map(
                  (json) =>
                      ParticipantModel.fromJson(json as Map<String, dynamic>),
                )
                .toList();
          }
        }

        return ApiResponse(
          success: true,
          data: ParticipantsForScoringResponse(
            participants: participants,
            remainingCount: remainingCount,
          ),
          message: response.message ?? 'Participants retrieved successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: response.message ?? 'Failed to retrieve participants',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error retrieving participants: ${e.toString()}',
      );
    }
  }

  /// Submit asana score for a participant
  Future<ApiResponse<Map<String, dynamic>>> submitAsanaScore({
    required int competitionId,
    required int juryId,
    required int participantRegistrationId,
    required int stageId,
    required int categoryId,
    required int groupId,
    required String asanaName,
    required double score,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'competitionId': competitionId,
        'juryId': juryId,
        'participantRegistrationId': participantRegistrationId,
        'stageId': stageId,
        'categoryId': categoryId,
        'groupId': groupId,
        'asanaName': asanaName,
        'score': score,
      };

      print('=== Submitting Asana Score ===');
      print('Endpoint: ${EndPoints.juryScoring}');
      print('Request Body: $requestBody');

      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.juryScoring,
        apiType: APIType.aPost,
        body: requestBody,
        fromJson: (json) => json,
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Success: ${response.success}');
      print('Response Message: ${response.message}');
      print('Response Data: ${response.data}');

      if (response.success) {
        return ApiResponse(
          success: true,
          data: response.data as Map<String, dynamic>? ?? {},
          message: response.message ?? 'Score submitted successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: response.message ?? 'Failed to submit score',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      print('ERROR in submitAsanaScore: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error submitting score: ${e.toString()}',
      );
    }
  }

  /// Submit scores for multiple participants with multiple asanas in bulk
  Future<ApiResponse<Map<String, dynamic>>> submitBulkScores({
    required int competitionId,
    required int juryId,
    int? stageId,
    required int categoryId,
    int? groupId,
    required List<Map<String, dynamic>> participantScores,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'competitionId': competitionId,
        'juryId': juryId,
        'categoryId': categoryId,
        'participantScores': participantScores,
      };
      if (stageId != null) {
        requestBody['stageId'] = stageId;
      }
      if (groupId != null) {
        requestBody['groupId'] = groupId;
      }

      print('=== Submitting Bulk Scores ===');
      print('Endpoint: ${EndPoints.juryScoring}');
      print('Request Body: ${jsonEncode(requestBody)}');

      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.juryScoring,
        apiType: APIType.aPost,
        body: requestBody,
        fromJson: (json) => json,
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Success: ${response.success}');
      print('Response Message: ${response.message}');
      print('Response Data: ${response.data}');

      if (response.success) {
        return ApiResponse(
          success: true,
          data: response.data as Map<String, dynamic>? ?? {},
          message: response.message ?? 'Scores submitted successfully',
        );
      } else {
        return ApiResponse(
          success: false,
          message: response.message ?? 'Failed to submit scores',
          statusCode: response.statusCode,
        );
      }
    } catch (e, stackTrace) {
      print('ERROR in submitBulkScores: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error submitting scores: ${e.toString()}',
      );
    }
  }
}
