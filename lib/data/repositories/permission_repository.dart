import '../../services/api_service.dart';
import '../models/api_response.dart';
import '../models/app_permission_record_model.dart';
import '../../core/constants/app_constants.dart';

class PermissionRepository {
  final APIService _api = APIService();

  Future<ApiResponse<List<AppPermissionRecord>>> getAllPermissions() async {
    try {
      final response = await _api.getResponse<dynamic>(
        url: EndPoints.permission,
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (!response.success || response.data == null) {
        return ApiResponse<List<AppPermissionRecord>>(
          success: false,
          message: response.message ?? 'Failed to load permissions',
          statusCode: response.statusCode,
        );
      }

      // `data` from API is `{ "permissions": [ ... ] }`
      final root = response.data;
      Map<String, dynamic>? map = root is Map<String, dynamic> ? root : null;
      final rawList = map?['permissions'] as List<dynamic>? ?? const [];
      final list = rawList
          .whereType<Map<String, dynamic>>()
          .map(AppPermissionRecord.fromJson)
          .toList();

      return ApiResponse<List<AppPermissionRecord>>(
        success: true,
        data: list,
        message: response.message,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<List<AppPermissionRecord>>(
        success: false,
        message: e.toString(),
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<AppPermissionRecord>> createPermission({
    required String permissionName,
    String? description,
    String? permissionKey,
    String? type,
    String? menu,
    String? subMenu,
    String? tab,
  }) async {
    try {
      final body = <String, dynamic>{
        'permissionName': permissionName.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (permissionKey != null && permissionKey.trim().isNotEmpty)
          'permissionKey': permissionKey.trim(),
        if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
        if (menu != null && menu.trim().isNotEmpty) 'menu': menu.trim(),
        if (subMenu != null && subMenu.trim().isNotEmpty)
          'subMenu': subMenu.trim(),
        if (tab != null && tab.trim().isNotEmpty) 'tab': tab.trim(),
      };

      final response = await _api.getResponse<dynamic>(
        url: EndPoints.permission,
        apiType: APIType.aPost,
        body: body,
        fromJson: (json) => json,
      );

      if (!response.success || response.data == null) {
        return ApiResponse<AppPermissionRecord>(
          success: false,
          message: response.message ?? 'Failed to create permission',
          statusCode: response.statusCode,
        );
      }

      // `data` from API is `{ "permission": { ... } }`
      final root = response.data;
      final map = root is Map<String, dynamic> ? root : null;
      final permRaw = map?['permission'];
      if (permRaw is Map<String, dynamic>) {
        return ApiResponse<AppPermissionRecord>(
          success: true,
          data: AppPermissionRecord.fromJson(permRaw),
          message: response.message,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<AppPermissionRecord>(
        success: false,
        message: 'Unexpected response when creating permission',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<AppPermissionRecord>(
        success: false,
        message: e.toString(),
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<AppPermissionRecord>> updatePermission({
    required int id,
    required String permissionName,
    String? description,
    String? permissionKey,
    String? type,
    String? menu,
    String? subMenu,
    String? tab,
  }) async {
    try {
      final body = <String, dynamic>{
        'permissionName': permissionName.trim(),
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (permissionKey != null && permissionKey.trim().isNotEmpty)
          'permissionKey': permissionKey.trim(),
        if (type != null && type.trim().isNotEmpty) 'type': type.trim(),
        if (menu != null && menu.trim().isNotEmpty) 'menu': menu.trim(),
        if (subMenu != null && subMenu.trim().isNotEmpty)
          'subMenu': subMenu.trim(),
        if (tab != null && tab.trim().isNotEmpty) 'tab': tab.trim(),
      };

      final response = await _api.getResponse<dynamic>(
        url: EndPoints.permissionById(id.toString()),
        apiType: APIType.aPut,
        body: body,
        fromJson: (json) => json,
      );

      if (!response.success || response.data == null) {
        return ApiResponse<AppPermissionRecord>(
          success: false,
          message: response.message ?? 'Failed to update permission',
          statusCode: response.statusCode,
        );
      }

      final root = response.data;
      final map = root is Map<String, dynamic> ? root : null;
      final permRaw = map?['permission'];
      if (permRaw is Map<String, dynamic>) {
        return ApiResponse<AppPermissionRecord>(
          success: true,
          data: AppPermissionRecord.fromJson(permRaw),
          message: response.message,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<AppPermissionRecord>(
        success: false,
        message: 'Unexpected response when updating permission',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<AppPermissionRecord>(
        success: false,
        message: e.toString(),
        statusCode: 0,
      );
    }
  }

  Future<ApiResponse<dynamic>> deletePermission({required int id}) async {
    try {
      final response = await _api.getResponse<dynamic>(
        url: EndPoints.permissionById(id.toString()),
        apiType: APIType.aDelete,
        fromJson: (json) => json,
      );

      return ApiResponse<dynamic>(
        success: response.success,
        message: response.message,
        statusCode: response.statusCode,
        data: response.data,
      );
    } catch (e) {
      return ApiResponse<dynamic>(
        success: false,
        message: e.toString(),
        statusCode: 0,
      );
    }
  }
}
