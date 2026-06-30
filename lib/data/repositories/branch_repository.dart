import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../core/utils/storage_service.dart';
import '../../data/models/api_response.dart';
import '../../data/models/organization_setup_model.dart';
import '../../services/api_service.dart';

class BranchRepository {
  final APIService _apiService = APIService();

  Future<ApiResponse<BranchDtoModel>> getBranch(int id) async {
    final response = await _apiService.getResponse<Map<String, dynamic>>(
      url: EndPoints.branchById(id),
      apiType: APIType.aGet,
    );

    if (!response.success || response.data == null) {
      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to load branch',
      );
    }

    final branchJson = response.data!['branch'];
    if (branchJson is! Map<String, dynamic>) {
      return ApiResponse(
        success: false,
        message: 'Invalid branch response',
      );
    }

    return ApiResponse(
      success: true,
      data: BranchDtoModel.fromJson(branchJson),
      message: response.message,
    );
  }

  Future<Uint8List?> fetchLogoBytes(int branchId) =>
      _fetchImageBytes(EndPoints.branchLogo(branchId));

  Future<Uint8List?> fetchPanImageBytes(int branchId) =>
      _fetchImageBytes(EndPoints.branchPanImage(branchId));

  Future<Uint8List?> fetchAadharImageBytes(int branchId) =>
      fetchAadharFrontImageBytes(branchId);

  Future<Uint8List?> fetchAadharFrontImageBytes(int branchId) =>
      _fetchImageBytes(EndPoints.branchAadharFrontImage(branchId));

  Future<Uint8List?> fetchAadharBackImageBytes(int branchId) =>
      _fetchImageBytes(EndPoints.branchAadharBackImage(branchId));

  Future<Uint8List?> _fetchImageBytes(String path) async {
    try {
      final fullUrl = BaseUrl.baseUrl + path;
      final headers = <String, String>{};
      final token = StorageService.getString(AppConstants.tokenKey);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(Uri.parse(fullUrl), headers: headers)
          .timeout(BaseUrl.apiTimeout);
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final bytes = Uint8List.fromList(response.bodyBytes);
        if (_looksLikeJsonError(bytes)) {
          return null;
        }
        return bytes;
      }
    } catch (_) {}
    return null;
  }

  bool _looksLikeJsonError(Uint8List bytes) {
    for (var i = 0; i < bytes.length && i < 64; i++) {
      final b = bytes[i];
      if (b <= 32) continue;
      return b == 0x7b || b == 0x5b;
    }
    return false;
  }

  Future<ApiResponse<BranchDtoModel>> updateBranch({
    required int id,
    required BranchRequestModel request,
    Uint8List? logoBytes,
    String? logoFileName,
    Uint8List? panImageBytes,
    String? panImageFileName,
    Uint8List? aadharFrontImageBytes,
    String? aadharFrontImageFileName,
    Uint8List? aadharBackImageBytes,
    String? aadharBackImageFileName,
  }) async {
    try {
      final fullUrl = BaseUrl.baseUrl + EndPoints.branchById(id);
      final httpRequest = http.MultipartRequest('PUT', Uri.parse(fullUrl));

      final token = StorageService.getString(AppConstants.tokenKey);
      if (token != null && token.isNotEmpty) {
        httpRequest.headers['Authorization'] = 'Bearer $token';
      }

      httpRequest.fields['data'] = jsonEncode(request.toJson());

      if (logoBytes != null) {
        httpRequest.files.add(
          http.MultipartFile.fromBytes(
            'logo',
            logoBytes,
            filename: logoFileName ?? 'logo.png',
          ),
        );
      }

      if (panImageBytes != null) {
        httpRequest.files.add(
          http.MultipartFile.fromBytes(
            'panImage',
            panImageBytes,
            filename: panImageFileName ?? 'epan.pdf',
          ),
        );
      }

      if (aadharFrontImageBytes != null) {
        httpRequest.files.add(
          http.MultipartFile.fromBytes(
            'aadharFrontImage',
            aadharFrontImageBytes,
            filename: aadharFrontImageFileName ?? 'eaadhar.pdf',
          ),
        );
      }

      if (aadharBackImageBytes != null) {
        httpRequest.files.add(
          http.MultipartFile.fromBytes(
            'aadharBackImage',
            aadharBackImageBytes,
            filename: aadharBackImageFileName ?? 'aadhar-back.png',
          ),
        );
      }

      final streamed = await httpRequest.send().timeout(BaseUrl.apiTimeout);
      final body = await http.Response.fromStream(streamed);
      final Map<String, dynamic> jsonBody =
          jsonDecode(body.body) as Map<String, dynamic>;

      if (body.statusCode == 200) {
        final branchJson = jsonBody['data']?['branch'];
        if (jsonBody['success'] == true && branchJson is Map<String, dynamic>) {
          return ApiResponse(
            success: true,
            data: BranchDtoModel.fromJson(branchJson),
            message: jsonBody['message']?.toString(),
          );
        }
      }

      return ApiResponse(
        success: false,
        message: jsonBody['message']?.toString() ?? 'Failed to update branch',
        statusCode: body.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error updating branch: ${e.toString()}',
      );
    }
  }
}

class OrganizationRepository {
  final APIService _apiService = APIService();

  Future<ApiResponse<OrganizationDtoModel>> updateOrganization({
    required int id,
    required OrganizationRequestModel request,
  }) async {
    final response = await _apiService.getResponse<Map<String, dynamic>>(
      url: EndPoints.organizationById(id),
      apiType: APIType.aPut,
      body: request.toJson(),
    );

    if (!response.success || response.data == null) {
      return ApiResponse(
        success: false,
        message: response.message ?? 'Failed to update organization',
      );
    }

    final orgJson = response.data!['organization'];
    if (orgJson is! Map<String, dynamic>) {
      return ApiResponse(
        success: false,
        message: 'Invalid organization response',
      );
    }

    return ApiResponse(
      success: true,
      data: OrganizationDtoModel.fromJson(orgJson),
      message: response.message,
    );
  }
}
