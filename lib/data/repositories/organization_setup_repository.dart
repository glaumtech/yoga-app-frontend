import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../data/models/api_response.dart';
import '../../data/models/organization_setup_model.dart';
import '../../services/api_service.dart';

class OrganizationSetupRepository {
  final APIService _apiService = APIService();

  Future<ApiResponse<OrganizationSetupResponseModel>> setupOrganization({
    required OrganizationSetupRequestModel setupRequest,
    File? logoFile,
    Uint8List? logoBytes,
    String? logoFileName,
  }) async {
    try {
      final fields = <String, String>{'data': setupRequest.toDataField()};

      http.MultipartFile? multipartFile;
      if (logoFile != null || logoBytes != null) {
        Uint8List fileBytes;
        String fileName;

        if (logoBytes != null) {
          fileBytes = logoBytes;
          fileName = logoFileName ?? 'logo.png';
        } else if (logoFile != null) {
          fileBytes = await logoFile.readAsBytes();
          fileName = logoFile.path.split('/').last;
        } else {
          throw Exception('No logo provided');
        }

        multipartFile = http.MultipartFile.fromBytes(
          'logo',
          fileBytes,
          filename: fileName,
        );
      }

      final fileToUpload =
          multipartFile ??
          http.MultipartFile.fromString('logo', '', filename: '');

      final response = await _apiService.postMultipart<Map<String, dynamic>>(
        url: EndPoints.organizationSetup,
        fields: fields,
        file: fileToUpload,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final model = OrganizationSetupResponseModel.fromJson(data);
        return ApiResponse(
          success: true,
          data: model,
          message: response.message,
        );
      }

      return ApiResponse(
        success: false,
        message: response.message ?? 'Setup failed',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error during setup: ${e.toString()}',
      );
    }
  }
}
