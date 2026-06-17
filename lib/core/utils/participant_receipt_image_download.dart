import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

import '../../presentation/controllers/reports_participants_tab_logic.dart';
/// Captures the receipt widget and downloads it as a JPG image.
Future<void> downloadParticipantReceiptImage(
  BuildContext context,
  GlobalKey receiptKey, {
  String? registrationNo,
}) async {
  try {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing receipt image…'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 100));

    final boundary = receiptKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('Receipt is not ready to capture');
    }

    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      throw Exception('Failed to capture receipt image');
    }

    final decoded = img.decodeImage(byteData.buffer.asUint8List());
    if (decoded == null) {
      throw Exception('Failed to encode receipt image');
    }
    final jpgBytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 92));

    final reg = registrationNo?.trim();
    final filename = reg != null && reg.isNotEmpty
        ? 'registration_receipt_$reg.jpg'
        : 'registration_receipt.jpg';

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
