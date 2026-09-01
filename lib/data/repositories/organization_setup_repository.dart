import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/storage_service.dart';
import '../../data/models/api_response.dart';
import '../../data/models/organization_setup_model.dart';
import '../../services/api_service.dart';

class OrganizationSetupRepository {
  final APIService _apiService = APIService();

  Future<ApiResponse<OrganizationSetupFoundationResponseModel>> setupFoundation({
    required OrganizationSetupFoundationRequestModel request,
    File? logoFile,
    Uint8List? logoBytes,
    String? logoFileName,
    Uint8List? panImageBytes,
    String? panImageFileName,
    Uint8List? aadharFrontImageBytes,
    String? aadharFrontImageFileName,
    Uint8List? aadharBackImageBytes,
    String? aadharBackImageFileName,
    XFile? paymentProofXFile,
  }) async {
    return _postFoundationMultipart(
      url: EndPoints.organizationSetupFoundation,
      request: request,
      logoFile: logoFile,
      logoBytes: logoBytes,
      logoFileName: logoFileName,
      panImageBytes: panImageBytes,
      panImageFileName: panImageFileName,
      aadharFrontImageBytes: aadharFrontImageBytes,
      aadharFrontImageFileName: aadharFrontImageFileName,
      aadharBackImageBytes: aadharBackImageBytes,
      aadharBackImageFileName: aadharBackImageFileName,
      paymentProofXFile: paymentProofXFile,
    );
  }

  Future<ApiResponse<OrganizationSetupFoundationWithPaymentResponseModel>>
  setupFoundationWithPaymentOrder({
    required OrganizationSetupFoundationRequestModel request,
    File? logoFile,
    Uint8List? logoBytes,
    String? logoFileName,
    Uint8List? panImageBytes,
    String? panImageFileName,
    Uint8List? aadharFrontImageBytes,
    String? aadharFrontImageFileName,
    Uint8List? aadharBackImageBytes,
    String? aadharBackImageFileName,
    XFile? paymentProofXFile,
  }) async {
    final response = await _postFoundationMultipartRaw(
      url: EndPoints.organizationSetupFoundationWithPayment,
      request: request,
      logoBytes: logoBytes,
      logoFileName: logoFileName,
      panImageBytes: panImageBytes,
      panImageFileName: panImageFileName,
      aadharFrontImageBytes: aadharFrontImageBytes,
      aadharFrontImageFileName: aadharFrontImageFileName,
      aadharBackImageBytes: aadharBackImageBytes,
      aadharBackImageFileName: aadharBackImageFileName,
      paymentProofXFile: paymentProofXFile,
    );

    if (response.success && response.data != null) {
      return ApiResponse(
        success: true,
        data: OrganizationSetupFoundationWithPaymentResponseModel.fromJson(
          response.data!,
        ),
        message: response.message,
      );
    }
    return ApiResponse(
      success: false,
      message: response.message ?? 'Foundation+payment setup failed',
    );
  }

  Future<ApiResponse<OrganizationSetupFoundationResponseModel>>
  _postFoundationMultipart({
    required String url,
    required OrganizationSetupFoundationRequestModel request,
    File? logoFile,
    Uint8List? logoBytes,
    String? logoFileName,
    Uint8List? panImageBytes,
    String? panImageFileName,
    Uint8List? aadharFrontImageBytes,
    String? aadharFrontImageFileName,
    Uint8List? aadharBackImageBytes,
    String? aadharBackImageFileName,
    XFile? paymentProofXFile,
  }) async {
    final raw = await _postFoundationMultipartRaw(
      url: url,
      request: request,
      logoBytes: logoBytes,
      logoFileName: logoFileName,
      panImageBytes: panImageBytes,
      panImageFileName: panImageFileName,
      aadharFrontImageBytes: aadharFrontImageBytes,
      aadharFrontImageFileName: aadharFrontImageFileName,
      aadharBackImageBytes: aadharBackImageBytes,
      aadharBackImageFileName: aadharBackImageFileName,
      paymentProofXFile: paymentProofXFile,
    );
    if (raw.success && raw.data != null) {
      return ApiResponse(
        success: true,
        data: OrganizationSetupFoundationResponseModel.fromJson(raw.data!),
        message: raw.message,
      );
    }
    return ApiResponse(
      success: false,
      message: raw.message ?? 'Foundation setup failed',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> _postFoundationMultipartRaw({
    required String url,
    required OrganizationSetupFoundationRequestModel request,
    Uint8List? logoBytes,
    String? logoFileName,
    Uint8List? panImageBytes,
    String? panImageFileName,
    Uint8List? aadharFrontImageBytes,
    String? aadharFrontImageFileName,
    Uint8List? aadharBackImageBytes,
    String? aadharBackImageFileName,
    XFile? paymentProofXFile,
    String? dataJsonOverride,
  }) async {
    try {
      final fullUrl = BaseUrl.baseUrl + url;
      final httpRequest = http.MultipartRequest('POST', Uri.parse(fullUrl));

      try {
        final token = StorageService.getString(AppConstants.tokenKey);
        if (token != null && token.isNotEmpty) {
          httpRequest.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {}

      httpRequest.fields['data'] = dataJsonOverride ?? request.toDataField();

      if (logoBytes != null) {
        final bytes = logoBytes;
        final name = logoFileName ?? 'logo.png';
        httpRequest.files.add(
          http.MultipartFile.fromBytes('logo', bytes, filename: name),
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

      if (paymentProofXFile != null) {
        final bytes = await paymentProofXFile.readAsBytes();
        final name = paymentProofXFile.name.split('/').last;
        httpRequest.files.add(
          http.MultipartFile.fromBytes(
            'paymentProof',
            bytes,
            filename: name,
          ),
        );
      }

      final streamed = await httpRequest.send().timeout(BaseUrl.apiTimeout);
      final body = await http.Response.fromStream(streamed);
      final Map<String, dynamic> jsonBody =
          jsonDecode(body.body) as Map<String, dynamic>;

      if (body.statusCode == 200 || body.statusCode == 201) {
        final data = jsonBody['data'];
        return ApiResponse(
          success: jsonBody['success'] == true,
          data: data is Map<String, dynamic> ? data : null,
          message: jsonBody['message']?.toString(),
          statusCode: body.statusCode,
        );
      }
      return ApiResponse(
        success: false,
        message: jsonBody['message']?.toString() ?? 'Request failed',
        statusCode: body.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error during setup: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse<OrganizationSetupFoundationResponseModel>> setupComplete({
    required OrganizationSetupCompleteRequestModel request,
    Uint8List? logoBytes,
    String? logoFileName,
    Uint8List? panImageBytes,
    String? panImageFileName,
    Uint8List? aadharFrontImageBytes,
    String? aadharFrontImageFileName,
    Uint8List? aadharBackImageBytes,
    String? aadharBackImageFileName,
    XFile? paymentProofXFile,
  }) async {
    final raw = await _postFoundationMultipartRaw(
      url: EndPoints.organizationSetupComplete,
      request: OrganizationSetupFoundationRequestModel(
        organization: request.organization,
        branch: request.branch,
        selectedPackageId: request.selectedPackageId,
        checkoutMethod: request.checkoutMethod,
      ),
      logoBytes: logoBytes,
      logoFileName: logoFileName,
      panImageBytes: panImageBytes,
      panImageFileName: panImageFileName,
      aadharFrontImageBytes: aadharFrontImageBytes,
      aadharFrontImageFileName: aadharFrontImageFileName,
      aadharBackImageBytes: aadharBackImageBytes,
      aadharBackImageFileName: aadharBackImageFileName,
      paymentProofXFile: paymentProofXFile,
      dataJsonOverride: request.toDataField(),
    );
    if (raw.success && raw.data != null) {
      return ApiResponse(
        success: true,
        data: OrganizationSetupFoundationResponseModel.fromJson(raw.data!),
        message: raw.message,
      );
    }
    return ApiResponse(
      success: false,
      message: raw.message ?? 'Complete setup failed',
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> setupAdmins({
    required OrganizationSetupAdminsRequestModel request,
    XFile? orgAdminPhoto,
    XFile? branchAdminPhoto,
  }) async {
    try {
      final fullUrl = BaseUrl.baseUrl + EndPoints.organizationSetupAdmins;
      final httpRequest = http.MultipartRequest('POST', Uri.parse(fullUrl));

      try {
        final token = StorageService.getString(AppConstants.tokenKey);
        if (token != null && token.isNotEmpty) {
          httpRequest.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {}

      httpRequest.fields['data'] = jsonEncode(request.toJson());

      if (orgAdminPhoto != null) {
        final bytes = await orgAdminPhoto.readAsBytes();
        final name = orgAdminPhoto.name.split('/').last;
        httpRequest.files.add(
          http.MultipartFile.fromBytes(
            'orgAdminPhoto',
            bytes,
            filename: name,
          ),
        );
      }

      if (branchAdminPhoto != null) {
        final bytes = await branchAdminPhoto.readAsBytes();
        final name = branchAdminPhoto.name.split('/').last;
        httpRequest.files.add(
          http.MultipartFile.fromBytes(
            'branchAdminPhoto',
            bytes,
            filename: name,
          ),
        );
      }

      final streamed = await httpRequest.send().timeout(BaseUrl.apiTimeout);
      final body = await http.Response.fromStream(streamed);
      final Map<String, dynamic> jsonBody =
          jsonDecode(body.body) as Map<String, dynamic>;

      if (body.statusCode == 200 || body.statusCode == 201) {
        final data = jsonBody['data'];
        return ApiResponse(
          success: jsonBody['success'] == true,
          data: data is Map<String, dynamic> ? data : null,
          message: jsonBody['message']?.toString(),
          statusCode: body.statusCode,
        );
      }
      return ApiResponse(
        success: false,
        message: jsonBody['message']?.toString() ?? 'Request failed',
        statusCode: body.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error creating admin users: ${e.toString()}',
      );
    }
  }
}
