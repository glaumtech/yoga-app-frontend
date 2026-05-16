import '../../services/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/state_model.dart';
import '../models/city_model.dart';
import '../models/api_response.dart';

class LocationRepository {
  final APIService _apiService = APIService();

  // Get all states
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

  // Get cities by state ID
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

  /// Distinct district names for a state (from `cities` table).
  Future<ApiResponse<List<String>>> getDistrictsByStateId(int stateId) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.districtListByState(stateId),
        apiType: APIType.aGet,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        List<String> districts = [];

        if (response.data is Map<String, dynamic>) {
          final dataMap = response.data as Map<String, dynamic>;
          dynamic listData =
              dataMap['data']?['districts'] ?? dataMap['districts'];

          if (listData is List) {
            districts = listData
                .map((e) => e?.toString().trim() ?? '')
                .where((s) => s.isNotEmpty)
                .toList();
          }
        } else if (response.data is List) {
          districts = (response.data as List)
              .map((e) => e?.toString().trim() ?? '')
              .where((s) => s.isNotEmpty)
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

  // Get villages by state ID and district
  Future<ApiResponse<List<CityModel>>> getVillagesByStateAndDistrict({
    required int stateId,
    required String district,
  }) async {
    try {
      final response = await _apiService.getResponse<dynamic>(
        url: EndPoints.villageListByStateAndDistrict(stateId, district.trim()),
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

  // Create city
  Future<ApiResponse<CityModel>> createCity({
    required String cityName,
    String district = '',
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
          'district': district.trim(),
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
}
