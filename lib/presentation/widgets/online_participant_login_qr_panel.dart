import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/online_participant_login_url.dart';
import '../../data/models/participant_model.dart';
import '../../routes/app_routes.dart';
import '../controllers/reports_participants_tab_logic.dart';

/// QR shown after online-category registration. Scan opens DOB-only login.
class OnlineParticipantLoginQrPanel extends StatelessWidget {
  final ParticipantModel participant;

  const OnlineParticipantLoginQrPanel({super.key, required this.participant});

  String get _loginUrl {
    return onlineParticipantLoginUrlFor(
      onlineLoginUrl: participant.onlineLoginUrl,
      registrationNo: participant.registrationNo ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final registrationNo = participant.registrationNo?.trim() ?? '';
    if (registrationNo.isEmpty || !participant.isOnlineCategory) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            'ONLINE LOGIN QR',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Scan this QR, or use Open login page on this computer. '
            'The link must use the same address as this running app.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: QrImageView(
              data: _loginUrl,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            registrationNo,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 8),
          SelectableText(
            _loginUrl,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () {
                  final regNo = participant.registrationNo?.trim() ?? '';
                  context.go(
                    AppRoutes.participantVideoUploadPath(
                      registrationNo: regNo,
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('OPEN LOGIN PAGE'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _copyLink(context),
                icon: const Icon(Icons.link, size: 18),
                label: const Text('COPY LINK'),
              ),
              OutlinedButton.icon(
                onPressed: () => _downloadPng(context),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('DOWNLOAD QR'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _loginUrl));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Online login link copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadPng(BuildContext context) async {
    try {
      final painter = QrPainter(
        data: _loginUrl,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        gapless: true,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
      );
      final imageData = await painter.toImageData(
        768,
        format: ui.ImageByteFormat.png,
      );
      if (imageData == null) {
        throw Exception('Could not generate QR image');
      }
      final bytes = imageData.buffer.asUint8List();
      final safeReg = (participant.registrationNo ?? 'participant')
          .replaceAll(RegExp(r'[^\w-]'), '_');
      await ReportsParticipantsTabLogic.downloadFileBytes(
        bytes,
        'online_login_qr_$safeReg.png',
        mimeType: 'image/png',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR download started'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to download QR: $e')));
      }
    }
  }
}
