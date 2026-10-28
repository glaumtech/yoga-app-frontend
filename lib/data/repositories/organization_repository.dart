import '../../core/constants/app_constants.dart';
import '../../services/api_service.dart';
import '../models/api_response.dart';

class OrganizationListItem {
  OrganizationListItem({
    required this.id,
    required this.organizationName,
    this.organizationCode,
  });

  final int id;
  final String organizationName;
  final String? organizationCode;

  factory OrganizationListItem.fromJson(Map<String, dynamic> json) {
    return OrganizationListItem(
      id: (json['id'] as num).toInt(),
      organizationName: (json['organizationName'] ?? '').toString(),
      organizationCode: json['organizationCode']?.toString(),
    );
  }
}

class OrganizationRepository {
  final APIService _apiService = APIService();

  Future<ApiResponse<List<OrganizationListItem>>> listOrganizations() async {
    final response = await _apiService.getResponse<Map<String, dynamic>>(
      url: EndPoints.organizations,
      apiType: APIType.aGet,
      fromJson: (json) => json as Map<String, dynamic>,
    );

    if (!response.success || response.data == null) {
      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to load organizations',
        statusCode: response.statusCode,
      );
    }

    final raw = response.data!['organizations'];
    if (raw is! List) {
      return ApiResponse(success: false, message: 'Invalid organizations response');
    }

    final items = raw
        .whereType<Map>()
        .map((e) => OrganizationListItem.fromJson(e.cast<String, dynamic>()))
        .where((o) => o.organizationName.isNotEmpty)
        .toList()
      ..sort((a, b) => a.organizationName.toLowerCase().compareTo(
            b.organizationName.toLowerCase(),
          ));

    return ApiResponse(success: true, data: items, message: response.message);
  }
}
