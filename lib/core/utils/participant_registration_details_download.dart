import 'package:flutter/material.dart';

import 'participant_receipt_image_download.dart';

/// Downloads payment receipt as JPG (payment-success layout).
Future<void> downloadParticipantRegistrationDetailsPdf(
  BuildContext context,
  String registrationId,
) async {
  await downloadParticipantReceiptImageByRegistrationId(
    context,
    registrationId,
  );
}
