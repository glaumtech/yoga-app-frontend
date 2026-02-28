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
}
