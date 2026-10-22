import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/api_response.dart';

class LegalDocumentRepository {
  final APIService _apiService = APIService();

  Future<ApiResponse<Map<String, dynamic>>> getLegalDocument(
    String docType,
  ) async {
    final response = await _apiService.getResponse<Map<String, dynamic>>(
      url: EndPoints.legalDocument(docType),
      apiType: APIType.aGet,
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : Map<String, dynamic>.from(json as Map),
    );
    if (response.success && response.data != null) {
      return ApiResponse(success: true, data: response.data);
    }
    return ApiResponse(
      success: false,
      message: response.message ?? 'Failed to load legal document',
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateLegalDocument({
    required String docType,
    required String title,
    required List<String> paragraphs,
  }) async {
    final response = await _apiService.getResponse<Map<String, dynamic>>(
      url: EndPoints.legalDocument(docType),
      apiType: APIType.aPut,
      body: {
        'title': title,
        'paragraphs': paragraphs,
      },
      fromJson: (json) => json is Map<String, dynamic>
          ? json
          : Map<String, dynamic>.from(json as Map),
    );
    if (response.success && response.data != null) {
      return ApiResponse(
        success: true,
        message: response.message,
        data: response.data,
      );
    }
    return ApiResponse(
      success: false,
      message: response.message ?? 'Failed to save legal document',
      statusCode: response.statusCode,
    );
  }
}
