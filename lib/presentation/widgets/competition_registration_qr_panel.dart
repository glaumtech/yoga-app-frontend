import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/competition_registration_url.dart';
import '../../data/models/competition_model.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show AnchorElement, Blob, Url;

/// Registration QR panel for wall/poster display (backend PNG + canonical URL).
class CompetitionRegistrationQrPanel extends StatelessWidget {
  final CompetitionModel competition;
  final bool compact;

  const CompetitionRegistrationQrPanel({
    super.key,
    required this.competition,
    this.compact = false,
  });

  String? get _competitionId => competition.id;

  String get _shareUrl {
    final id = _competitionId ?? '';
    return registrationShareUrlForCompetition(
      registrationUrl: competition.registrationUrl,
      competitionId: id,
    );
  }

  String get _qrImageUrl {
    final id = _competitionId;
    if (id == null || id.isEmpty) return '';
    return '${BaseUrl.baseUrl}${EndPoints.competitionRegistrationQr(id)}';
  }

  @override
  Widget build(BuildContext context) {
    final id = _competitionId;
    if (id == null || id.isEmpty) {
      return const SizedBox.shrink();
    }

    final qrSize = compact ? 160.0 : 220.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'REGISTRATION QR',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 6),
            Text(
              'Print this QR and place at the registration desk or venue wall. '
              'Participants scan to open the registration page.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _qrImageUrl,
              width: qrSize,
              height: qrSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: qrSize,
                height: qrSize,
                color: Colors.grey[200],
                child: const Icon(Icons.qr_code_2, size: 48),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            _shareUrl,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _copyLink(context),
                icon: const Icon(Icons.link, size: 18),
                label: const Text('COPY LINK'),
              ),
              FilledButton.icon(
                onPressed: () => _downloadPng(context),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('DOWNLOAD PNG'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _shareUrl));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registration link copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadPng(BuildContext context) async {
    final id = _competitionId;
    if (id == null) return;

    try {
      final response = await http.get(Uri.parse(_qrImageUrl));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to download QR (status ${response.statusCode})',
              ),
            ),
          );
        }
        return;
      }

      final bytes = response.bodyBytes;
      final safeName = competition.competitionName
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final filename =
          'registration_qr_${id}${safeName.isNotEmpty ? '_$safeName' : ''}.png';

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final blobUrl = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: blobUrl)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(blobUrl);
      } else {
        await Clipboard.setData(
          const ClipboardData(text: 'QR download is supported on web.'),
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb ? 'QR download started' : 'QR saved to clipboard hint',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download QR: $e')),
        );
      }
    }
  }
}

/// Modal shown after creating a competition.
Future<void> showCompetitionRegistrationQrDialog(
  BuildContext context,
  CompetitionModel competition,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        competition.competitionName.isNotEmpty
            ? competition.competitionName
            : 'Competition QR',
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: CompetitionRegistrationQrPanel(competition: competition),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('CLOSE'),
        ),
      ],
    ),
  );
}
