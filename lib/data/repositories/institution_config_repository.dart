import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../models/api_response.dart';
import '../models/institution_category_model.dart';
import '../models/institution_type_model.dart';

class InstitutionConfigRepository {
  final APIService _api = APIService();

  Future<ApiResponse<List<InstitutionTypeModel>>> getTypes() async {
    final res = await _api.getResponse<dynamic>(
      url: EndPoints.institutionTypeList,
      apiType: APIType.aGet,
      fromJson: (j) => j,
    );

    if (!res.success || res.data == null) {
      return ApiResponse(
        success: false,
        message: res.message ?? 'Failed to load institution types',
        statusCode: res.statusCode,
      );
    }

    final root = res.data;
    final map = root is Map<String, dynamic> ? root : null;
    final rawList =
        (map?['data']?['institutionTypes'] ?? map?['institutionTypes']) as List?;
    final list = (rawList ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(InstitutionTypeModel.fromJson)
        .toList();

    return ApiResponse(success: true, data: list, statusCode: res.statusCode);
  }

  Future<ApiResponse<InstitutionTypeModel>> createType({
    required String typeName,
    required String displayName,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'typeName': typeName.trim(),
      'displayName': displayName.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };

    final res = await _api.getResponse<dynamic>(
      url: EndPoints.institutionTypeList,
      apiType: APIType.aPost,
      body: body,
      fromJson: (j) => j,
    );

    if (!res.success || res.data == null) {
      return ApiResponse(
        success: false,
        message: res.message ?? 'Failed to create institution type',
        statusCode: res.statusCode,
      );
    }

    final map = res.data is Map<String, dynamic> ? res.data : null;
    final raw = map?['data']?['institutionType'] ?? map?['institutionType'];
    if (raw is Map<String, dynamic>) {
      return ApiResponse(
        success: true,
        data: InstitutionTypeModel.fromJson(raw),
        statusCode: res.statusCode,
      );
    }

    return ApiResponse(
      success: false,
      message: 'Unexpected response when creating institution type',
      statusCode: res.statusCode,
    );
  }

  Future<ApiResponse<InstitutionTypeModel>> updateType({
    required int id,
    required String typeName,
    required String displayName,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'typeName': typeName.trim(),
      'displayName': displayName.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };

    final res = await _api.getResponse<dynamic>(
      url: EndPoints.institutionTypeById(id),
      apiType: APIType.aPut,
      body: body,
      fromJson: (j) => j,
    );

    if (!res.success || res.data == null) {
      return ApiResponse(
        success: false,
        message: res.message ?? 'Failed to update institution type',
        statusCode: res.statusCode,
      );
    }

    final map = res.data is Map<String, dynamic> ? res.data : null;
    final raw = map?['data']?['institutionType'] ?? map?['institutionType'];
    if (raw is Map<String, dynamic>) {
      return ApiResponse(
        success: true,
        data: InstitutionTypeModel.fromJson(raw),
        statusCode: res.statusCode,
      );
    }

    return ApiResponse(
      success: false,
      message: 'Unexpected response when updating institution type',
      statusCode: res.statusCode,
    );
  }

  Future<ApiResponse<void>> deleteType(int id) async {
    final res = await _api.getResponse<dynamic>(
      url: EndPoints.institutionTypeById(id),
      apiType: APIType.aDelete,
      fromJson: (j) => j,
    );
    return ApiResponse(
      success: res.success,
      message: res.message,
      statusCode: res.statusCode,
    );
  }

  Future<ApiResponse<void>> reorderTypes(List<int> orderedIds) async {
    final res = await _api.getResponse<dynamic>(
      url: EndPoints.institutionTypeReorder,
      apiType: APIType.aPut,
      body: {'orderedIds': orderedIds},
      fromJson: (j) => j,
    );
    return ApiResponse(
      success: res.success,
      message: res.message,
      statusCode: res.statusCode,
    );
  }

  Future<ApiResponse<List<InstitutionCategoryModel>>> getCategoriesByType(
    int typeId,
  ) async {
    final res = await _api.getResponse<dynamic>(
      url: EndPoints.institutionCategoryByType(typeId),
      apiType: APIType.aGet,
      fromJson: (j) => j,
    );

    if (!res.success || res.data == null) {
      return ApiResponse(
        success: false,
        message: res.message ?? 'Failed to load institution categories',
        statusCode: res.statusCode,
      );
    }

    final root = res.data;
    final map = root is Map<String, dynamic> ? root : null;
    final rawList =
        (map?['data']?['categories'] ?? map?['categories']) as List?;
    final list = (rawList ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(InstitutionCategoryModel.fromJson)
        .toList();

    return ApiResponse(success: true, data: list, statusCode: res.statusCode);
  }

  Future<ApiResponse<InstitutionCategoryModel>> createCategory({
    required int institutionTypeId,
    required String categoryName,
    required String displayName,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'institutionTypeId': institutionTypeId,
      'categoryName': categoryName.trim(),
      'displayName': displayName.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };

    final res = await _api.getResponse<dynamic>(
      url: EndPoints.institutionCategoryCreate,
      apiType: APIType.aPost,
      body: body,
      fromJson: (j) => j,
    );

    if (!res.success || res.data == null) {
      return ApiResponse(
        success: false,
        message: res.message ?? 'Failed to create institution category',
        statusCode: res.statusCode,
      );
    }

    final map = res.data is Map<String, dynamic> ? res.data : null;
    final raw =
        map?['data']?['institutionCategory'] ?? map?['institutionCategory'];
    if (raw is Map<String, dynamic>) {
      return ApiResponse(
        success: true,
        data: InstitutionCategoryModel.fromJson(raw),
        statusCode: res.statusCode,
      );
    }

    return ApiResponse(
      success: false,
      message: 'Unexpected response when creating institution category',
      statusCode: res.statusCode,
    );
  }

  Future<ApiResponse<InstitutionCategoryModel>> updateCategory({
    required int id,
    required int institutionTypeId,
    required String categoryName,
    required String displayName,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'institutionTypeId': institutionTypeId,
      'categoryName': categoryName.trim(),
      'displayName': displayName.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };

    final res = await _api.getResponse<dynamic>(
      url: EndPoints.institutionCategoryById(id),
      apiType: APIType.aPut,
      body: body,
      fromJson: (j) => j,
    );

    if (!res.success || res.data == null) {
      return ApiResponse(
        success: false,
        message: res.message ?? 'Failed to update institution category',
        statusCode: res.statusCode,
      );
    }

    final map = res.data is Map<String, dynamic> ? res.data : null;
    final raw =
        map?['data']?['institutionCategory'] ?? map?['institutionCategory'];
    if (raw is Map<String, dynamic>) {
      return ApiResponse(
        success: true,
        data: InstitutionCategoryModel.fromJson(raw),
        statusCode: res.statusCode,
      );
    }

    return ApiResponse(
      success: false,
      message: 'Unexpected response when updating institution category',
      statusCode: res.statusCode,
    );
  }

  Future<ApiResponse<void>> deleteCategory(int id) async {
    final res = await _api.getResponse<dynamic>(
      url: EndPoints.institutionCategoryById(id),
      apiType: APIType.aDelete,
      fromJson: (j) => j,
    );
    return ApiResponse(
      success: res.success,
      message: res.message,
      statusCode: res.statusCode,
    );
  }

  Future<ApiResponse<void>> reorderCategories({
    required int institutionTypeId,
    required List<int> orderedIds,
  }) async {
    final res = await _api.getResponse<dynamic>(
      url: EndPoints.institutionCategoryReorder,
      apiType: APIType.aPut,
      body: {
        'institutionTypeId': institutionTypeId,
        'orderedIds': orderedIds,
      },
      fromJson: (j) => j,
    );
    return ApiResponse(
      success: res.success,
      message: res.message,
      statusCode: res.statusCode,
    );
  }
}

