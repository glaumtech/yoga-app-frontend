import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../models/api_response.dart';
import '../models/master_record_model.dart';
import 'competition_repository.dart';

enum MasterTableType { categories, stages, prizes }

class MastersRepository {
  final APIService _api = APIService();

  String _listUrl(MasterTableType type) {
    switch (type) {
      case MasterTableType.categories:
        return EndPoints.categoryList;
      case MasterTableType.stages:
        return EndPoints.stageList;
      case MasterTableType.prizes:
        return EndPoints.prizeList;
    }
  }

  String _byIdUrl(MasterTableType type, int id) {
    switch (type) {
      case MasterTableType.categories:
        return EndPoints.categoryById(id);
      case MasterTableType.stages:
        return EndPoints.stageById(id);
      case MasterTableType.prizes:
        return EndPoints.prizeById(id);
    }
  }

  String _entityKey(MasterTableType type) {
    switch (type) {
      case MasterTableType.categories:
        return 'categories';
      case MasterTableType.stages:
        return 'stages';
      case MasterTableType.prizes:
        return 'prizes';
    }
  }

  String _singularKey(MasterTableType type) {
    switch (type) {
      case MasterTableType.categories:
        return 'category';
      case MasterTableType.stages:
        return 'stage';
      case MasterTableType.prizes:
        return 'prize';
    }
  }

  Future<ApiResponse<List<MasterRecordModel>>> list(MasterTableType type) async {
    try {
      final response = await _api.getResponse<dynamic>(
        url: _listUrl(type),
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (!response.success || response.data == null) {
        return ApiResponse(
          success: false,
          message: response.message ?? 'Failed to load ${_entityKey(type)}',
          statusCode: response.statusCode,
        );
      }

      final listKey = _entityKey(type);
      final items = _extractList(response.data, listKey);
      return ApiResponse(success: true, data: items);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error loading ${_entityKey(type)}: $e',
      );
    }
  }

  Future<ApiResponse<MasterRecordModel>> create({
    required MasterTableType type,
    required String name,
    String? description,
  }) async {
    try {
      final body = _buildBody(name: name, description: description);

      final response = await _api.getResponse<dynamic>(
        url: _listUrl(type),
        apiType: APIType.aPost,
        body: body,
        fromJson: (json) => json,
      );

      if (!response.success || response.data == null) {
        return ApiResponse(
          success: false,
          message: response.message ?? 'Failed to create ${_singularKey(type)}',
          statusCode: response.statusCode,
        );
      }

      final record = _parseSingle(response.data, _singularKey(type));
      if (record != null) {
        return ApiResponse(success: true, data: record);
      }

      return ApiResponse(
        success: false,
        message: 'Unexpected response when creating ${_singularKey(type)}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error creating ${_singularKey(type)}: $e',
      );
    }
  }

  Future<ApiResponse<MasterRecordModel>> update({
    required MasterTableType type,
    required int id,
    required String name,
    String? description,
  }) async {
    try {
      final body = _buildBody(name: name, description: description);

      final response = await _api.getResponse<dynamic>(
        url: _byIdUrl(type, id),
        apiType: APIType.aPut,
        body: body,
        fromJson: (json) => json,
      );

      if (!response.success || response.data == null) {
        return ApiResponse(
          success: false,
          message: response.message ?? 'Failed to update ${_singularKey(type)}',
          statusCode: response.statusCode,
        );
      }

      final record = _parseSingle(response.data, _singularKey(type));
      if (record != null) {
        return ApiResponse(success: true, data: record);
      }

      return ApiResponse(
        success: false,
        message: 'Unexpected response when updating ${_singularKey(type)}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error updating ${_singularKey(type)}: $e',
      );
    }
  }

  Future<ApiResponse<void>> delete({
    required MasterTableType type,
    required int id,
  }) async {
    try {
      final response = await _api.getResponse<dynamic>(
        url: _byIdUrl(type, id),
        apiType: APIType.aDelete,
        fromJson: (json) => json,
      );

      if (response.success) {
        return ApiResponse(
          success: true,
          message: response.message ?? 'Deleted successfully',
        );
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to delete ${_singularKey(type)}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error deleting ${_singularKey(type)}: $e',
      );
    }
  }

  Map<String, dynamic> _buildBody({
    required String name,
    String? description,
  }) {
    return {
      'name': name.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    };
  }

  List<MasterRecordModel> _extractList(dynamic raw, String listKey) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => MasterRecordModel.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.id > 0 && e.name.trim().isNotEmpty)
          .toList();
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      dynamic listData = map['data']?[listKey] ?? map[listKey];
      if (listData is List) {
        return listData
            .whereType<Map>()
            .map((e) => MasterRecordModel.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.id > 0 && e.name.trim().isNotEmpty)
            .toList();
      }
    }

    return [];
  }

  MasterRecordModel? _parseSingle(dynamic raw, String entityKey) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final nested = map[entityKey];
      if (nested is Map) {
        return MasterRecordModel.fromJson(Map<String, dynamic>.from(nested));
      }
      if (map['data'] is Map) {
        final inner = Map<String, dynamic>.from(map['data'] as Map);
        final nestedInner = inner[entityKey];
        if (nestedInner is Map) {
          return MasterRecordModel.fromJson(Map<String, dynamic>.from(nestedInner));
        }
      }
      if (map.containsKey('id')) {
        return MasterRecordModel.fromJson(map);
      }
    }

    final option = CompetitionRepository.parseCreatedOption(raw, entityKey: entityKey);
    if (option != null) {
      return MasterRecordModel(id: option.id, name: option.name);
    }

    return null;
  }
}
