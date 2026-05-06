import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../models/api_response.dart';
import '../models/certificate_template_model.dart';

class CertificateTemplateRepository {
  final APIService _api = APIService();

  Map<String, dynamic>? _unwrapTemplatePayload(dynamic data) {
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

  List<CertificateTemplateModel> _unwrapTemplateList(dynamic data) {
    if (data is! Map) return const [];
    final map = Map<String, dynamic>.from(data);
    final raw = map['certificateTemplates'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => CertificateTemplateModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ApiResponse<List<CertificateTemplateModel>>> listTemplates({
    int? branchId,
  }) async {
    final q = <String>[];
    if (branchId != null) q.add('branchId=$branchId');
    final url = q.isEmpty
        ? EndPoints.certificateTemplates
        : '${EndPoints.certificateTemplates}?${q.join('&')}';

    final res = await _api.getResponse<dynamic>(
      url: url,
      apiType: APIType.aGet,
      fromJson: (j) => j,
    );

    if (!res.success || res.data == null) {
      return ApiResponse(
        success: false,
        message: res.message ?? 'Failed to load certificate templates',
        statusCode: res.statusCode,
      );
    }

    return ApiResponse(
      success: true,
      data: _unwrapTemplateList(res.data),
      statusCode: res.statusCode,
    );
  }

  Future<ApiResponse<CertificateTemplateModel>> getTemplateById(int id) async {
    final res = await _api.getResponse<dynamic>(
      url: EndPoints.certificateTemplateById(id),
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

    final payload = _unwrapTemplatePayload(res.data);
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

  Future<ApiResponse<CertificateTemplateModel>> createTemplate(
    CertificateTemplateModel model,
  ) async {
    final res = await _api.getResponse<dynamic>(
      url: EndPoints.certificateTemplates,
      apiType: APIType.aPost,
      body: model.toJson(),
      fromJson: (j) => j,
    );

    if (!res.success || res.data == null) {
      return ApiResponse(
        success: false,
        message: res.message ?? 'Failed to create certificate template',
        statusCode: res.statusCode,
      );
    }

    final payload = _unwrapTemplatePayload(res.data);
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

  Future<ApiResponse<CertificateTemplateModel>> updateTemplate(
    int id,
    CertificateTemplateModel model,
  ) async {
    final res = await _api.getResponse<dynamic>(
      url: EndPoints.certificateTemplateById(id),
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

    final payload = _unwrapTemplatePayload(res.data);
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

  Future<ApiResponse<void>> deleteTemplate(int id) async {
    final res = await _api.getResponse<dynamic>(
      url: EndPoints.certificateTemplateById(id),
      apiType: APIType.aDelete,
      fromJson: (j) => j,
    );
    return ApiResponse(
      success: res.success,
      message: res.message,
      statusCode: res.statusCode,
    );
  }

  Future<ApiResponse<CertificateTemplateModel>> setDefaultTemplate({
    required int templateId,
  }) async {
    final res = await _api.getResponse<dynamic>(
      url: EndPoints.certificateTemplateSetDefault(templateId),
      apiType: APIType.aPatch,
      fromJson: (j) => j,
    );

    if (!res.success) {
      return ApiResponse(
        success: false,
        message: res.message ?? 'Failed to set default template',
        statusCode: res.statusCode,
      );
    }

    final payload = _unwrapTemplatePayload(res.data);
    if (payload != null) {
      return ApiResponse(
        success: true,
        data: CertificateTemplateModel.fromJson(payload),
        statusCode: res.statusCode,
      );
    }
    return ApiResponse(
      success: true,
      statusCode: res.statusCode,
    );
  }
}
