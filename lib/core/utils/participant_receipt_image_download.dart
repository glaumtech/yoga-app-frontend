import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/participant_model.dart';
import '../../data/repositories/participant_repository.dart';
import '../../presentation/controllers/reports_participants_tab_logic.dart';

/// Downloads the payment receipt as a JPG from the server.
Future<void> downloadParticipantReceiptImage(
  BuildContext context,
  GlobalKey receiptKey, {
  String? registrationNo,
  String? registrationId,
}) async {
  final id = registrationId?.trim();
  if (id != null && id.isNotEmpty) {
    if (!context.mounted) return;
    await downloadParticipantReceiptImageByRegistrationId(
      context,
      id,
      registrationNo: registrationNo,
    );
    return;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Missing registration id for receipt download')),
    );
  }
}

/// Loads registration receipt JPEG from the API and triggers download.
Future<void> downloadParticipantReceiptImageByRegistrationId(
  BuildContext context,
  String registrationId, {
  ParticipantModel? seedParticipant,
  String? competitionName,
  String? registrationNo,
}) async {
  if (registrationId.trim().isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing registration id')),
      );
    }
    return;
  }

  try {
    final regNo = registrationNo?.trim() ??
        seedParticipant?.registrationNo?.trim();
    final filename = regNo != null && regNo.isNotEmpty
        ? 'registration_receipt_$regNo.jpg'
        : 'registration_receipt_$registrationId.jpg';

    final jpgBytes = await _fetchReceiptImageBytes(registrationId.trim());

    await ReportsParticipantsTabLogic.downloadFileBytes(
      jpgBytes,
      filename,
      mimeType: 'image/jpeg',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt download started')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download receipt: $e')),
      );
    }
  }
}

Future<Uint8List> _fetchReceiptImageBytes(String registrationId) async {
  final url =
      '${AppConfig.baseUrl}${EndPoints.participantRegistrationDetailsImage(registrationId)}';
  final response = await http.get(
    Uri.parse(url),
    headers: const {'Accept': 'image/jpeg, application/octet-stream, */*'},
  );

  if (response.statusCode == 200) {
    if (response.bodyBytes.isEmpty) {
      throw Exception('Receipt image is empty');
    }
    return response.bodyBytes;
  }

  if (response.statusCode == 404) {
    throw Exception('Registration not found');
  }

  throw Exception('Failed to download receipt (status ${response.statusCode})');
}

/// Kept for callers that still pass list-row data; server renders the receipt.
Future<void> downloadParticipantReceiptImageForParticipant(
  BuildContext context,
  ParticipantModel participant, {
  String? competitionName,
}) async {
  final registrationId = participant.id?.trim();
  if (registrationId == null || registrationId.isEmpty) {
    final repository = ParticipantRepository();
    final response = await repository.getParticipantRegistrationById(
      participant.registrationNo ?? '',
    );
    if (!response.success || response.data == null) {
      throw Exception(response.message ?? 'Failed to load registration');
    }
    if (!context.mounted) return;
    final reg = response.data!['registration'];
    if (reg is! Map<String, dynamic>) {
      throw Exception('Registration data is unavailable');
    }
    final id = reg['id']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('Missing registration id');
    }
    if (!context.mounted) return;
    await downloadParticipantReceiptImageByRegistrationId(
      context,
      id,
      seedParticipant: participant,
      competitionName: competitionName,
      registrationNo: participant.registrationNo,
    );
    return;
  }

  if (!context.mounted) return;
  await downloadParticipantReceiptImageByRegistrationId(
    context,
    registrationId,
    seedParticipant: participant,
    competitionName: competitionName,
    registrationNo: participant.registrationNo,
  );
}
