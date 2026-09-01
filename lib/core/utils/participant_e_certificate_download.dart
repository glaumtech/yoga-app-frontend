import 'package:flutter/material.dart';

import '../../data/models/participant_model.dart';
import '../../data/repositories/reports_repository.dart';
import '../../presentation/controllers/reports_participants_tab_logic.dart';

/// Downloads participation e-certificate PDF for a registration (public + reports).
Future<void> downloadParticipantECertificate(
  BuildContext context,
  ParticipantModel participant, {
  required int competitionId,
}) async {
  final registrationId = int.tryParse(participant.id ?? '');
  final stageId = participant.stageId;
  final categoryId = participant.categoryId;
  final groupId = participant.groupId;

  if (registrationId == null || categoryId == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing data for certificate download'),
        ),
      );
    }
    return;
  }

  if (!participant.optForECertificate &&
      participant.certificateAvailable != true) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This participant did not opt for e-certificate'),
        ),
      );
    }
    return;
  }

  final repo = ReportsRepository();
  final resp = await repo.getParticipantECertificatePdf(
    competitionId,
    participantRegistrationId: registrationId,
    stageId: stageId,
    categoryId: categoryId,
    groupId: groupId,
  );

  if (!resp.success || resp.data == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resp.message ?? 'Failed to download e-certificate'),
        ),
      );
    }
    return;
  }

  await ReportsParticipantsTabLogic.downloadReportPdfBytes(
    resp.data!,
    'e_certificate_${competitionId}_$registrationId.pdf',
  );

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('E-certificate download started')),
    );
  }
}
