import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/event_model.dart';
import '../models/api_response.dart';

class EventRepository {
  final APIService _apiService = APIService();

  Future<ApiResponse<List<EventModel>>> getAllEvents() async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.eventList,
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      print('getAllEvents response.success: ${response.success}');
      print('getAllEvents response.data type: ${response.data.runtimeType}');
      print('getAllEvents response.data: ${response.data}');

      if (response.success && response.data != null) {
        List<EventModel> events = [];

        // Handle different response formats
        if (response.data is List) {
          // Direct list response
          print(
            'Response is a List with ${(response.data as List).length} items',
          );
          events = (response.data as List).map((json) {
            print('Parsing event: $json');
            try {
              return EventModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : json as Map<String, dynamic>,
              );
            } catch (e) {
              print('Error parsing event: $e');
              rethrow;
            }
          }).toList();
        } else if (response.data is Map<String, dynamic>) {
          // Response wrapped in a map - check for 'data' field
          final dataMap = response.data as Map<String, dynamic>;
          print('Response is a Map with keys: ${dataMap.keys}');

          // Handle nested structure: { "data": { "events": [...] } }
          dynamic listData;

          // First check if 'data' exists and is a Map (nested structure like { "data": { "events": [...] } })
          if (dataMap['data'] is Map<String, dynamic>) {
            final innerData = dataMap['data'] as Map<String, dynamic>;
            print('Found nested data structure with keys: ${innerData.keys}');
            // Check for events inside the nested data
            listData =
                innerData['events'] ??
                innerData['data'] ??
                innerData['results'] ??
                innerData['users'];
          } else if (dataMap['data'] is List) {
            // Direct list in 'data' field
            listData = dataMap['data'];
          } else {
            // Check for direct list fields (events might be at root level)
            listData =
                dataMap['events'] ??
                dataMap['data'] ??
                dataMap['results'] ??
                dataMap['users'];
          }

          if (listData is List) {
            print('Found list in map with ${listData.length} items');
            events = listData.map((json) {
              print('Parsing event: $json');
              try {
                return EventModel.fromJson(
                  json is Map<String, dynamic>
                      ? json
                      : json as Map<String, dynamic>,
                );
              } catch (e) {
                print('Error parsing event: $e');
                print('Failed to parse event JSON: $json');
                rethrow;
              }
            }).toList();
          } else {
            print('No list found in map. Available keys: ${dataMap.keys}');
            if (dataMap['data'] is Map) {
              print('Nested data keys: ${(dataMap['data'] as Map).keys}');
            }
            // Try to extract events from the entire response structure
            print('Full response data structure: $dataMap');
          }
        } else {
          print('Unexpected response data type: ${response.data.runtimeType}');
        }

        print('Parsed ${events.length} events');
        return ApiResponse(success: true, data: events);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch events',
      );
    } catch (e, stackTrace) {
      print('Error in getAllEvents: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error loading events: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<EventModel>> getEventById(String id) async {
    try {
      final response = await _apiService.getResponse<Map<String, dynamic>>(
        url: EndPoints.eventById(id),
        apiType: APIType.aGet,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final event = EventModel.fromJson(response.data!);
        return ApiResponse(success: true, data: event);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch event',
      );
    } catch (e, stackTrace) {
      print('Error in getEventById: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error loading event: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<EventModel>> createEvent({
    required EventModel event,
    XFile? bannerFile,
  }) async {
    try {
      // Prepare event data (without bannerUrl)
      final eventJson = event.toJson();
      // Remove bannerUrl from JSON as it will come from file upload
      eventJson.remove('bannerUrl');

      http.MultipartFile? multipartFile;

      // Handle banner file upload
      final banner = bannerFile;
      if (banner != null) {
        try {
          final fileBytes = await banner.readAsBytes();
          final fileName = banner.name.split('/').last;
          multipartFile = http.MultipartFile.fromBytes(
            'file', // Must match @RequestPart(value = "file") on server
            fileBytes,
            filename: fileName,
          );
          print('Multipart file created successfully for CREATE');
        } catch (e, stackTrace) {
          print('Error reading banner file: $e');
          print('Stack trace: $stackTrace');
        }
      } else {
        print('No banner file provided for CREATE');
      }

      // If banner file exists, use multipart upload
      if (multipartFile != null) {
        // Send event data as JSON string in 'data' field (like participant registration)
        final dataJsonString = jsonEncode(eventJson);
        final fields = <String, String>{'data': dataJsonString};

        print('Creating event with multipart - data: $dataJsonString');
        print('Banner file: ${bannerFile?.name ?? 'unknown'}');

        final response = await _apiService.postMultipart<Map<String, dynamic>>(
          url: EndPoints.eventRegister,
          fields: fields,
          file: multipartFile,
          fromJson: (json) => json as Map<String, dynamic>,
        );

        print(
          'Create event response: ${response.success}, message: ${response.message}',
        );

        if (response.success && response.data != null) {
          final event = EventModel.fromJson(response.data!);
          return ApiResponse(success: true, data: event);
        }

        return ApiResponse(
          success: false,
          message: response.message ?? 'Failed to create event',
        );
      } else {
        // No banner file, use regular POST with JSON body
        print('Creating event without banner - body: $eventJson');

        final response = await _apiService.getResponse<Map<String, dynamic>>(
          url: EndPoints.eventRegister,
          apiType: APIType.aPost,
          body: eventJson,
          fromJson: (json) => json as Map<String, dynamic>,
        );

        print(
          'Create event response: ${response.success}, message: ${response.message}',
        );

        if (response.success && response.data != null) {
          final event = EventModel.fromJson(response.data!);
          return ApiResponse(success: true, data: event);
        }

        return ApiResponse(
          success: false,
          message: response.message ?? 'Failed to create event',
        );
      }
    } catch (e, stackTrace) {
      print('Error in createEvent: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error creating event: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<EventModel>> updateEvent({
    required String id,
    required EventModel event,
    XFile? bannerFile,
  }) async {
    try {
      // Prepare event data
      final eventJson = event.toJson();
      // Always remove id from JSON
      eventJson.remove('id');

      // Always use multipart format for event updates
      // Send event data as JSON string in 'data' field
      final dataJsonString = jsonEncode(eventJson);
      final fields = <String, String>{'data': dataJsonString};

      http.MultipartFile multipartFile;

      // Handle banner file upload
      final banner = bannerFile;
      if (banner != null) {
        // If there's a new banner file, remove bannerUrl (will be replaced by file)
        eventJson.remove('bannerUrl');
        try {
          final fileBytes = await banner.readAsBytes();
          final fileName = banner.name.split('/').last;
          multipartFile = http.MultipartFile.fromBytes(
            'file', // Must match @RequestPart(value = "file") on server
            fileBytes,
            filename: fileName,
          );
          print('Updating event with banner file: ${banner.name}');
        } catch (e) {
          print('Error reading banner file: $e');
          // Fallback to empty file if reading fails
          multipartFile = http.MultipartFile.fromBytes(
            'file',
            [],
            filename: '',
          );
        }
      } else {
        // No new banner file, keep bannerUrl in JSON (to preserve existing banner)
        // Create an empty multipart file
        multipartFile = http.MultipartFile.fromBytes('file', [], filename: '');
        print('Updating event without new banner');
        if (eventJson.containsKey('bannerUrl')) {
          print('Preserving existing bannerUrl: ${eventJson['bannerUrl']}');
        }
      }

      print('Updating event with multipart - data: $dataJsonString');

      final response = await _apiService.putMultipart<Map<String, dynamic>>(
        url: EndPoints.eventUpdate(id),
        fields: fields,
        file: multipartFile,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      print(
        'Update event response: ${response.success}, message: ${response.message}',
      );

      if (response.success && response.data != null) {
        final event = EventModel.fromJson(response.data!);
        return ApiResponse(success: true, data: event);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to update event',
      );
    } catch (e, stackTrace) {
      print('Error in updateEvent: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error updating event: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<bool>> deleteEvent(String id) async {
    try {
      final response = await _apiService.getResponse<bool>(
        url: EndPoints.eventById(id),
        apiType: APIType.aDelete,
      );
      return response;
    } catch (e, stackTrace) {
      print('Error in deleteEvent: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse(
        success: false,
        message: 'Error deleting event: ${e.toString()}',
      );
    }
  }
}
