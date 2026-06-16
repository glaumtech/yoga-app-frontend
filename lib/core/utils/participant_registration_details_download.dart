import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../core/utils/storage_service.dart';
import '../../presentation/controllers/reports_participants_tab_logic.dart';

/// Downloads registration details PDF for a participant (public + admin).
Future<void> downloadParticipantRegistrationDetailsPdf(
  BuildContext context,
  String registrationId,
) async {
  if (registrationId.trim().isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing registration id')));
    }
    return;
  }

  try {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing registration details…'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    final url =
        '${BaseUrl.baseUrl}${EndPoints.participantRegistrationDetailsPdf(registrationId)}';
    final headers = <String, String>{
      'Accept': 'application/pdf, application/octet-stream, */*',
    };
    final token = StorageService.getString(AppConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(Uri.parse(url), headers: headers);

    if (!context.mounted) return;

    if (response.statusCode == 200) {
      await ReportsParticipantsTabLogic.downloadReportPdfBytes(
        response.bodyBytes,
        'participant_registration_$registrationId.pdf',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration details download started')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to download registration details (${response.statusCode})',
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to download: $e')));
    }
  }
}
