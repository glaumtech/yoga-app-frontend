import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/storage_service.dart';
import '../models/state_model.dart';
import '../models/city_model.dart';
import '../models/district_model.dart';
import '../models/location_import_result.dart';
import '../models/api_response.dart';

class LocationRepository {
  final APIService _apiService = APIService();

  Future<ApiResponse<List<StateModel>>> getAllStates() async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.stateList,
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<StateModel> states = [];

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic listData = dataMap['data']?['states'] ?? dataMap['states'];

          if (listData is List) {
            states = listData.map((json) {
              return StateModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : json as Map<String, dynamic>,
              );
            }).toList();
          }
        } else if (response.data is List) {
          states = (response.data as List).map((json) {
            return StateModel.fromJson(
              json is Map<String, dynamic>
                  ? json
                  : json as Map<String, dynamic>,
            );
          }).toList();
        }

        return ApiResponse(success: true, data: states);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch states',
      );
    } catch (e) {
      print('Error in getAllStates: $e');
      return ApiResponse(
        success: false,
        message: 'Error fetching states: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<List<CityModel>>> getCitiesByStateId(int stateId) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.cityListByState(stateId),
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<CityModel> cities = [];

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic listData = dataMap['data']?['cities'] ?? dataMap['cities'];

          if (listData is List) {
            cities = listData.map((json) {
              return CityModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : json as Map<String, dynamic>,
              );
            }).toList();
          }
        } else if (response.data is List) {
          cities = (response.data as List).map((json) {
            return CityModel.fromJson(
              json is Map<String, dynamic>
                  ? json
                  : json as Map<String, dynamic>,
            );
          }).toList();
        }

        return ApiResponse(success: true, data: cities);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch cities',
      );
    } catch (e) {
      print('Error in getCitiesByStateId: $e');
      return ApiResponse(
        success: false,
        message: 'Error fetching cities: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<List<DistrictModel>>> getDistrictsByStateId(
    int stateId,
  ) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.districtListByState(stateId),
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<DistrictModel> districts = [];

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic listData =
              dataMap['data']?['districts'] ?? dataMap['districts'];

          if (listData is List) {
            districts = listData
                .whereType<Map>()
                .map(
                  (json) => DistrictModel.fromJson(
                    Map<String, dynamic>.from(json),
                  ),
                )
                .toList();
          }
        } else if (response.data is List) {
          districts = (response.data as List)
              .whereType<Map>()
              .map(
                (json) => DistrictModel.fromJson(
                  Map<String, dynamic>.from(json),
                ),
              )
              .toList();
        }

        return ApiResponse(success: true, data: districts);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch districts',
      );
    } catch (e) {
      print('Error in getDistrictsByStateId: $e');
      return ApiResponse(
        success: false,
        message: 'Error fetching districts: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<List<CityModel>>> getVillagesByStateAndDistrict({
    required int stateId,
    required int districtId,
  }) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.villageListByStateAndDistrict(stateId, districtId),
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<CityModel> villages = [];

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic listData =
              dataMap['data']?['villages'] ??
              dataMap['villages'] ??
              dataMap['data']?['cities'] ??
              dataMap['cities'];

          if (listData is List) {
            villages = listData.map((json) {
              return CityModel.fromJson(
                json is Map<String, dynamic>
                    ? json
                    : json as Map<String, dynamic>,
              );
            }).toList();
          }
        } else if (response.data is List) {
          villages = (response.data as List).map((json) {
            return CityModel.fromJson(
              json is Map<String, dynamic>
                  ? json
                  : json as Map<String, dynamic>,
            );
          }).toList();
        }

        return ApiResponse(success: true, data: villages);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch villages',
      );
    } catch (e) {
      print('Error in getVillagesByStateAndDistrict: $e');
      return ApiResponse(
        success: false,
        message: 'Error fetching villages: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<CityModel>> createCity({
    required String cityName,
    required int districtId,
    String pincode = '',
    required int stateId,
    String? description,
  }) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.cityCreate,
        apiType: APIType.aPost,
        body: {
          'cityName': cityName.trim(),
          'districtId': districtId,
          'pincode': pincode.trim(),
          'stateId': stateId,
          'description': description?.trim().isEmpty == true
              ? null
              : description?.trim(),
        },
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        dynamic cityData;
        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          cityData = dataMap['city'] ?? dataMap['data']?['city'] ?? dataMap;
        } else {
          cityData = response.data;
        }

        if (cityData is Map<String, dynamic>) {
          return ApiResponse(success: true, data: CityModel.fromJson(cityData));
        }
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to create city',
      );
    } catch (e) {
      print('Error in createCity: $e');
      return ApiResponse(
        success: false,
        message: 'Error creating city: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<List<CityModel>>> getAllCities() async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.cityList,
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        final cities = _extractCityList(response.data);
        return ApiResponse(success: true, data: cities);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch cities',
      );
    } catch (e) {
      print('Error in getAllCities: $e');
      return ApiResponse(
        success: false,
        message: 'Error fetching cities: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<CityModel>> updateCity({
    required int id,
    required String cityName,
    required int districtId,
    String pincode = '',
    required int stateId,
    String? description,
  }) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.cityById(id),
        apiType: APIType.aPut,
        body: {
          'cityName': cityName.trim(),
          'districtId': districtId,
          'pincode': pincode.trim(),
          'stateId': stateId,
          'description': description?.trim().isEmpty == true
              ? null
              : description?.trim(),
        },
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        final city = _extractCity(response.data);
        if (city != null) {
          return ApiResponse(success: true, data: city);
        }
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to update city',
      );
    } catch (e) {
      print('Error in updateCity: $e');
      return ApiResponse(
        success: false,
        message: 'Error updating city: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<void>> deleteCity(int id) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.cityById(id),
        apiType: APIType.aDelete,
        fromJson: (json) => json,
      );

      if (response.success) {
        return ApiResponse(success: true);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to delete city',
      );
    } catch (e) {
      print('Error in deleteCity: $e');
      return ApiResponse(
        success: false,
        message: 'Error deleting city: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<StateModel>> createState({
    required String stateName,
    required String stateCode,
    String? description,
  }) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.stateCreate,
        apiType: APIType.aPost,
        body: {
          'stateName': stateName.trim(),
          'stateCode': stateCode.trim(),
          'description': description?.trim().isEmpty == true
              ? null
              : description?.trim(),
        },
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        final state = _extractState(response.data);
        if (state != null) {
          return ApiResponse(success: true, data: state);
        }
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to create state',
      );
    } catch (e) {
      print('Error in createState: $e');
      return ApiResponse(
        success: false,
        message: 'Error creating state: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<StateModel>> updateState({
    required int id,
    required String stateName,
    required String stateCode,
    String? description,
  }) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.stateById(id),
        apiType: APIType.aPut,
        body: {
          'stateName': stateName.trim(),
          'stateCode': stateCode.trim(),
          'description': description?.trim().isEmpty == true
              ? null
              : description?.trim(),
        },
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        final state = _extractState(response.data);
        if (state != null) {
          return ApiResponse(success: true, data: state);
        }
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to update state',
      );
    } catch (e) {
      print('Error in updateState: $e');
      return ApiResponse(
        success: false,
        message: 'Error updating state: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<void>> deleteState(int id) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.stateById(id),
        apiType: APIType.aDelete,
        fromJson: (json) => json,
      );

      if (response.success) {
        return ApiResponse(success: true);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to delete state',
      );
    } catch (e) {
      print('Error in deleteState: $e');
      return ApiResponse(
        success: false,
        message: 'Error deleting state: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<List<DistrictModel>>> getAllDistricts() async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.districtList,
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        final districts = _extractDistrictList(response.data);
        return ApiResponse(success: true, data: districts);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to fetch districts',
      );
    } catch (e) {
      print('Error in getAllDistricts: $e');
      return ApiResponse(
        success: false,
        message: 'Error fetching districts: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<DistrictModel>> createDistrict({
    required String districtName,
    required int stateId,
    String? description,
  }) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.districtCreate,
        apiType: APIType.aPost,
        body: {
          'districtName': districtName.trim(),
          'stateId': stateId,
          'description': description?.trim().isEmpty == true
              ? null
              : description?.trim(),
        },
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        final district = _extractDistrict(response.data);
        if (district != null) {
          return ApiResponse(success: true, data: district);
        }
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to create district',
      );
    } catch (e) {
      print('Error in createDistrict: $e');
      return ApiResponse(
        success: false,
        message: 'Error creating district: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<DistrictModel>> updateDistrict({
    required int id,
    required String districtName,
    required int stateId,
    String? description,
  }) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.districtById(id),
        apiType: APIType.aPut,
        body: {
          'districtName': districtName.trim(),
          'stateId': stateId,
          'description': description?.trim().isEmpty == true
              ? null
              : description?.trim(),
        },
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        final district = _extractDistrict(response.data);
        if (district != null) {
          return ApiResponse(success: true, data: district);
        }
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to update district',
      );
    } catch (e) {
      print('Error in updateDistrict: $e');
      return ApiResponse(
        success: false,
        message: 'Error updating district: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<void>> deleteDistrict(int id) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.districtById(id),
        apiType: APIType.aDelete,
        fromJson: (json) => json,
      );

      if (response.success) {
        return ApiResponse(success: true);
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to delete district',
      );
    } catch (e) {
      print('Error in deleteDistrict: $e');
      return ApiResponse(
        success: false,
        message: 'Error deleting district: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<LocationImportResult>> importLocations({
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final uri = Uri.parse(BaseUrl.baseUrl + EndPoints.locationImport);
      final request = http.MultipartRequest('POST', uri);
      final token = StorageService.getString(AppConstants.tokenKey);
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename.trim().isEmpty ? 'locations.csv' : filename.trim(),
        ),
      );

      final streamed = await request.send().timeout(const Duration(minutes: 2));
      final body = await http.Response.fromStream(streamed);
      Map<String, dynamic> jsonBody = {};
      try {
        final decoded = jsonDecode(body.body);
        if (decoded is Map<String, dynamic>) {
          jsonBody = decoded;
        } else if (decoded is Map) {
          jsonBody = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return ApiResponse(
          success: false,
          message: 'Import failed (${body.statusCode})',
          statusCode: body.statusCode,
        );
      }

      if (body.statusCode == 200 && jsonBody['success'] == true) {
        final data = jsonBody['data'];
        if (data is Map) {
          return ApiResponse(
            success: true,
            message: jsonBody['message']?.toString(),
            data: LocationImportResult.fromJson(Map<String, dynamic>.from(data)),
          );
        }
      }

      return ApiResponse(
        success: false,
        message: jsonBody['message']?.toString() ?? 'Failed to import locations',
        statusCode: body.statusCode,
      );
    } catch (e) {
      print('Error in importLocations: $e');
      return ApiResponse(
        success: false,
        message: 'Error importing locations: ${e.toString()}',
      );
    }
  }

  List<CityModel> _extractCityList(dynamic raw) {
    dynamic listData;
    if (raw is Map<String, dynamic>) {
      listData = raw['data']?['cities'] ?? raw['cities'];
    } else if (raw is List) {
      listData = raw;
    }
    if (listData is! List) return [];
    return listData
        .whereType<Map>()
        .map((json) => CityModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  CityModel? _extractCity(dynamic raw) {
    dynamic cityData;
    if (raw is Map<String, dynamic>) {
      cityData = raw['city'] ?? raw['data']?['city'] ?? raw;
    } else {
      cityData = raw;
    }
    if (cityData is Map) {
      return CityModel.fromJson(Map<String, dynamic>.from(cityData));
    }
    return null;
  }

  StateModel? _extractState(dynamic raw) {
    dynamic stateData;
    if (raw is Map<String, dynamic>) {
      stateData = raw['state'] ?? raw['data']?['state'] ?? raw;
    } else {
      stateData = raw;
    }
    if (stateData is Map) {
      return StateModel.fromJson(Map<String, dynamic>.from(stateData));
    }
    return null;
  }

  List<DistrictModel> _extractDistrictList(dynamic raw) {
    dynamic listData;
    if (raw is Map<String, dynamic>) {
      listData = raw['data']?['districts'] ?? raw['districts'];
    } else if (raw is List) {
      listData = raw;
    }
    if (listData is! List) return [];
    return listData
        .whereType<Map>()
        .map((json) => DistrictModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  DistrictModel? _extractDistrict(dynamic raw) {
    dynamic districtData;
    if (raw is Map<String, dynamic>) {
      districtData = raw['district'] ?? raw['data']?['district'] ?? raw;
    } else {
      districtData = raw;
    }
    if (districtData is Map) {
      return DistrictModel.fromJson(Map<String, dynamic>.from(districtData));
    }
    return null;
  }
}
