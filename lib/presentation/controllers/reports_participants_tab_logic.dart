import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:html' as html show Blob, Url, AnchorElement;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/reports_repository.dart';
import 'reports_participants_tab_controller.dart';

/// Business logic and side-effects for [ReportsParticipantsTab] (keeps the screen file UI-focused).
class ReportsParticipantsTabLogic {
  ReportsParticipantsTabLogic._();

  static List<int> tablePageIndices(int currentPage, int totalPages) {
    if (totalPages <= 0) return const <int>[];
    if (totalPages <= 7) {
      return List<int>.generate(totalPages, (i) => i);
    }
    const window = 5;
    var start = currentPage - (window ~/ 2);
    if (start < 0) start = 0;
    if (start + window > totalPages) {
      start = math.max(0, totalPages - window);
    }
    return List<int>.generate(
      math.min(window, totalPages - start),
      (i) => start + i,
    );
  }

  static String avatarInitial(String? name) {
    final t = (name ?? '').trim();
    if (t.isEmpty) return '?';
    return t.substring(0, 1).toUpperCase();
  }

  static bool rowOptForECertificate(Map<String, dynamic> row) {
    Object? v = row['optForECertificate'];
    v ??= row['opt_for_e_certificate'];
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase().trim();
    return s == 'true' || s == '1' || s == 'yes';
  }

  static Future<void> downloadReportPdfBytes(
    Uint8List bytes,
    String filename,
  ) async {
    await downloadFileBytes(
      bytes,
      filename,
      mimeType: 'application/pdf',
    );
  }

  static Future<void> downloadFileBytes(
    Uint8List bytes,
    String filename, {
    required String mimeType,
  }) async {
    if (bytes.isEmpty) return;

    if (kIsWeb) {
      final blob = html.Blob([bytes], mimeType);
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: blobUrl)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(blobUrl);
      return;
    }

    final dataUri = Uri.dataFromBytes(bytes, mimeType: mimeType);
    if (await canLaunchUrl(dataUri)) {
      await launchUrl(dataUri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> downloadParticipantECertificate(
    ReportsParticipantsTabController controller,
    Map<String, dynamic> row,
  ) async {
    final competitionId = int.tryParse(
      controller.reportsController.selectedCompetitionId.value ?? '',
    );
    final participantRegistrationId =
        (row['participantRegistrationId'] as num?)?.toInt();
    final stageId = (row['stageId'] as num?)?.toInt();
    final categoryId = (row['categoryId'] as num?)?.toInt();
    final groupRaw = row['groupId'];
    int? groupId;
    if (groupRaw != null) {
      groupId = (groupRaw as num?)?.toInt();
    }

    if (competitionId == null ||
        participantRegistrationId == null ||
        stageId == null ||
        categoryId == null) {
      Get.snackbar(
        'Error',
        'Missing data for certificate download',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final repo = ReportsRepository();
    final resp = await repo.getParticipantECertificatePdf(
      competitionId,
      participantRegistrationId: participantRegistrationId,
      stageId: stageId,
      categoryId: categoryId,
      groupId: groupId,
    );

    if (!resp.success || resp.data == null) {
      Get.snackbar(
        'Error',
        resp.message ?? 'Failed to download e-certificate',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    await downloadReportPdfBytes(
      resp.data!,
      'e_certificate_${competitionId}_$participantRegistrationId.pdf',
    );
  }

  static Future<void> openParticipantScoreDetails(
    BuildContext context,
    ReportsParticipantsTabController tabController,
    Map<String, dynamic> row,
  ) async {
    final resp = await tabController.fetchScoreDetails(row);
    if (!context.mounted) return;
    if (!resp.success || resp.data == null) {
      Get.snackbar(
        'Details',
        resp.message ?? 'Could not load jury scores',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }
    final d = Map<String, dynamic>.from(resp.data!);
    final juryScores = (d['juryScores'] as List?)?.cast<dynamic>() ?? const [];

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final total =
            (double.tryParse((d['totalGrandTotal'] ?? 0).toString()) ?? 0.0)
                .toStringAsFixed(2);
        final pName = (d['participantName'] ?? 'Participant').toString();
        final initial = avatarInitial(pName);
        final metaLine = [
          if ((d['registrationNo'] ?? '').toString().isNotEmpty)
            d['registrationNo'].toString(),
          if ((d['institutionName'] ?? '').toString().isNotEmpty)
            d['institutionName'].toString(),
        ].join(' · ');
        final bucketLine = [
          (d['categoryName'] ?? '').toString(),
          (d['stageName'] ?? '').toString(),
          (d['groupName'] ?? '').toString(),
        ].where((e) => e.isNotEmpty).join(' · ');
        final juryCount = (d['juryCount'] ?? 0).toString();

        final mq = MediaQuery.sizeOf(ctx);
        final dialogWidth = math.min(520.0, mq.width - 40);
        final maxDialogHeight = math.min(mq.height * 0.88, mq.height - 32);

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: maxDialogHeight,
            ),
            child: ListView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                Material(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 4, 2),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Score details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF212121),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          icon: Icon(Icons.close, color: Colors.grey[800]),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.sectionHeaderBackground(),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppTheme.primaryColor,
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pName,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF212121),
                                      ),
                                    ),
                                    if (metaLine.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        metaLine,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w600,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                    if (bucketLine.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          for (final part
                                              in bucketLine.split(' · '))
                                            if (part.isNotEmpty)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.grey[400]!,
                                                  ),
                                                ),
                                                child: Text(
                                                  part,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF424242),
                                                  ),
                                                ),
                                              ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'TOTAL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    total,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primaryColor,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$juryCount ${int.tryParse(juryCount) == 1 ? 'jury' : 'juries'}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Jury score breakdown',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (juryScores.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No jury scores.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        ...juryScores.map((js) {
                          final m = (js as Map).cast<String, dynamic>();
                          final juryName =
                              (m['juryName'] ?? '').toString().trim();
                          final juryId = (m['juryId'] ?? '').toString();
                          final juryLabel =
                              juryName.isNotEmpty ? juryName : juryId;
                          final jt = (double.tryParse(
                                    (m['grandTotal'] ?? 0).toString(),
                                  ) ??
                                  0.0)
                              .toStringAsFixed(2);
                          final asanaScores =
                              (m['asanaScores'] as Map?)
                                      ?.cast<String, dynamic>() ??
                                  {};

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: AppTheme.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        width: 4,
                                        color: AppTheme.primaryColor,
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            10,
                                            12,
                                            10,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.how_to_reg_outlined,
                                                    size: 18,
                                                    color:
                                                        AppTheme.primaryColor,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      juryLabel,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 14,
                                                        color:
                                                            Color(0xFF212121),
                                                      ),
                                                    ),
                                                  ),
                                                  DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      color: AppTheme
                                                          .primaryColor
                                                          .withValues(
                                                        alpha: 0.1,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        8,
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                      child: Text(
                                                        jt,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          fontSize: 14,
                                                          color: AppTheme
                                                              .primaryColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (asanaScores.isNotEmpty) ...[
                                                const SizedBox(height: 10),
                                                Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children: [
                                                    for (final entry
                                                        in asanaScores.entries)
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 5,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppTheme
                                                              .softTintSurface(),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          border: Border.all(
                                                            color: AppTheme
                                                                .primaryColor
                                                                .withValues(
                                                              alpha: 0.35,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          '${entry.key}: ${entry.value}',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: AppTheme
                                                                .chipTintText(),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
