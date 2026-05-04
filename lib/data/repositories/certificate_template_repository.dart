import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../models/api_response.dart';
import '../models/certificate_template_model.dart';

class CertificateTemplateRepository {
  final APIService _api = APIService();

  Map<String, dynamic>? _unwrapPayload(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final nested = map['certificateTemplate'];
    if (nested is Map<String, dynamic>) return nested;
    if (nested is Map) return Map<String, dynamic>.from(nested);
    if (map.containsKey('subtitle') ||
        map.containsKey('organizedByLine') ||
        map.containsKey('backgroundPreset')) {
      return map;
    }
    return null;
  }

  Future<ApiResponse<CertificateTemplateModel>> getTemplate() async {
    final res = await _api.getResponse<dynamic>(
      url: EndPoints.certificateTemplate,
      apiType: APIType.aGet,
      fromJson: (j) => j,
    );

    if (!res.success || res.data == null) {
      return ApiResponse(
        success: false,
        message: res.message ?? 'Failed to load certificate template',
        statusCode: res.statusCode,
      );
    }

    final payload = _unwrapPayload(res.data);
    if (payload == null) {
      return ApiResponse(
        success: false,
        message: 'Unexpected certificate template response',
        statusCode: res.statusCode,
      );
    }

    return ApiResponse(
      success: true,
      data: CertificateTemplateModel.fromJson(payload),
      statusCode: res.statusCode,
    );
  }

  Future<ApiResponse<CertificateTemplateModel>> saveTemplate(
    CertificateTemplateModel model,
  ) async {
    final res = await _api.getResponse<dynamic>(
      url: EndPoints.certificateTemplate,
      apiType: APIType.aPut,
      body: model.toJson(),
      fromJson: (j) => j,
    );

    if (!res.success || res.data == null) {
      return ApiResponse(
        success: false,
        message: res.message ?? 'Failed to save certificate template',
        statusCode: res.statusCode,
      );
    }

    final payload = _unwrapPayload(res.data);
    if (payload == null) {
      return ApiResponse(
        success: true,
        data: model,
        statusCode: res.statusCode,
      );
    }

    return ApiResponse(
      success: true,
      data: CertificateTemplateModel.fromJson(payload),
      statusCode: res.statusCode,
    );
  }
}
