import 'dart:async' show unawaited;
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

  static bool isCountScoreRow(Map<String, dynamic> row) {
    return (row['scoreType'] ?? '').toString().toUpperCase() == 'COUNT';
  }

  static String formatScoreValue(Map<String, dynamic> row) {
    final raw = row['totalCount'] ?? row['totalGrandTotal'] ?? row['avgGrandTotal'] ?? 0;
    final v = double.tryParse(raw.toString()) ?? 0.0;
    if (isCountScoreRow(row)) {
      return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(0);
    }
    return v.toStringAsFixed(2);
  }

  static String formatCountEntryDate(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return '—';
    final parsed = DateTime.tryParse(t);
    if (parsed == null) return t;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[parsed.month - 1];
    return '${parsed.day} $month ${parsed.year}';
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

  static bool rowCertificateAvailable(Map<String, dynamic> row) {
    if (!row.containsKey('certificateAvailable') &&
        !row.containsKey('certificate_available')) {
      return true;
    }
    Object? v = row['certificateAvailable'];
    v ??= row['certificate_available'];
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

  static Future<void> openCountStatusDialog(
    BuildContext context,
    ReportsParticipantsTabController tabController,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _CountStatusDialog(controller: tabController),
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
        resp.message ?? 'Could not load scores',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return;
    }
    final d = Map<String, dynamic>.from(resp.data!);
    final isCount = isCountScoreRow(d);
    final juryScores = (d['juryScores'] as List?)?.cast<dynamic>() ?? const [];
    final countEntries = (d['countEntries'] as List?)?.cast<dynamic>() ?? const [];

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final total = formatScoreValue(d);
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
        final dayLabel = int.tryParse(juryCount) == 1 ? 'day' : 'days';
        final juryLabel = int.tryParse(juryCount) == 1 ? 'jury' : 'juries';

        final mq = MediaQuery.sizeOf(ctx);
        final dialogWidth = math.min(520.0, mq.width - 40);
        final maxDialogHeight = math.min(mq.height * 0.88, mq.height - 32);
        final listMaxHeight = math.max(140.0, maxDialogHeight - 280);

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 4, 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isCount ? 'Count details' : 'Score details',
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
                                    isCount ? 'COUNT' : 'TOTAL',
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
                                    isCount
                                        ? '$juryCount $dayLabel'
                                        : '$juryCount $juryLabel',
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
                            isCount
                                ? 'Daily count breakdown'
                                : 'Jury score breakdown',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (isCount && countEntries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No counts submitted.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else if (isCount) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Day',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.grey[600],
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              Text(
                                'Count',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _CappedScrollList(
                          maxHeight: listMaxHeight,
                          children: countEntries.map((entry) {
                            final m = (entry as Map).cast<String, dynamic>();
                            final dateLabel = formatCountEntryDate(
                              (m['entryDate'] ?? '').toString(),
                            );
                            final countLabel =
                                (m['countValue'] ?? 0).toString();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    10,
                                    12,
                                    10,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 18,
                                        color: AppTheme.primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          dateLabel.isEmpty
                                              ? '—'
                                              : dateLabel,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: Color(0xFF212121),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        countLabel,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ]
                      else if (juryScores.isEmpty)
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
                        _CappedScrollList(
                          maxHeight: listMaxHeight,
                          children: [
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
                          final asanaSkipped =
                              (m['asanaSkipped'] as Map?)
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
                                                      Builder(
                                                        builder: (context) {
                                                          final skipped =
                                                              asanaSkipped[entry
                                                                      .key] ==
                                                                  true;
                                                          return Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 8,
                                                              vertical: 5,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: skipped
                                                                  ? Colors
                                                                        .orange
                                                                        .withValues(
                                                                      alpha:
                                                                          0.12,
                                                                    )
                                                                  : AppTheme
                                                                        .softTintSurface(),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                8,
                                                              ),
                                                              border: Border.all(
                                                                color: skipped
                                                                    ? Colors
                                                                          .orange
                                                                          .withValues(
                                                                        alpha:
                                                                            0.55,
                                                                      )
                                                                    : AppTheme
                                                                          .primaryColor
                                                                          .withValues(
                                                                        alpha:
                                                                            0.35,
                                                                      ),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              skipped
                                                                  ? '${entry.key}: ${entry.value} (SKIPPED)'
                                                                  : '${entry.key}: ${entry.value}',
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: skipped
                                                                    ? Colors
                                                                          .orange[900]
                                                                    : AppTheme
                                                                          .chipTintText(),
                                                              ),
                                                            ),
                                                          );
                                                        },
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

class _CappedScrollList extends StatefulWidget {
  const _CappedScrollList({
    required this.maxHeight,
    required this.children,
  });

  final double maxHeight;
  final List<Widget> children;

  @override
  State<_CappedScrollList> createState() => _CappedScrollListState();
}

class _CappedScrollListState extends State<_CappedScrollList> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        child: ListView(
          controller: _controller,
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(right: 8, bottom: 4),
          children: widget.children,
        ),
      ),
    );
  }
}

class _CountStatusDialog extends StatefulWidget {
  const _CountStatusDialog({required this.controller});

  final ReportsParticipantsTabController controller;

  @override
  State<_CountStatusDialog> createState() => _CountStatusDialogState();
}

class _CountStatusDialogState extends State<_CountStatusDialog> {
  late DateTime _from;
  late DateTime _to;
  bool _loading = true;
  String _error = '';
  List<String> _availableDates = const [];
  List<Map<String, dynamic>> _updated = const [];
  List<Map<String, dynamic>> _notUpdated = const [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, now.day);
    _to = _from;
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final resp = await widget.controller.fetchCountSubmissionStatus(
      from: _from,
      to: _to,
    );
    if (!mounted) return;
    if (!resp.success || resp.data == null) {
      setState(() {
        _loading = false;
        _error = resp.message ?? 'Could not load count status';
        _updated = const [];
        _notUpdated = const [];
      });
      return;
    }
    final d = Map<String, dynamic>.from(resp.data!);
    setState(() {
      _loading = false;
      _availableDates = ((d['availableDates'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();
      _updated = ((d['updated'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _notUpdated = ((d['notUpdated'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = DateTime(picked.year, picked.month, picked.day);
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = DateTime(picked.year, picked.month, picked.day);
        if (_to.isBefore(_from)) _from = _to;
      }
    });
    await _load();
  }

  Future<void> _selectAvailableDate(String raw) async {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return;
    final day = DateTime(parsed.year, parsed.month, parsed.day);
    setState(() {
      _from = day;
      _to = day;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final wide = mq.width >= 760;
    final dialogWidth = math.min(wide ? 920.0 : mq.width - 32, mq.width - 32);
    final dialogHeight = math.min(mq.height * 0.88, mq.height - 32);
    final selectedYmd =
        '${_from.year.toString().padLeft(4, '0')}-'
        '${_from.month.toString().padLeft(2, '0')}-'
        '${_from.day.toString().padLeft(2, '0')}';
    final toYmd =
        '${_to.year.toString().padLeft(4, '0')}-'
        '${_to.month.toString().padLeft(2, '0')}-'
        '${_to.day.toString().padLeft(2, '0')}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: dialogHeight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Count status by date',
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _dateButton(
                        label: 'From',
                        value: ReportsParticipantsTabLogic.formatCountEntryDate(
                          selectedYmd,
                        ),
                        onTap: () => unawaited(_pickDate(isFrom: true)),
                      ),
                      _dateButton(
                        label: 'To',
                        value: ReportsParticipantsTabLogic.formatCountEntryDate(
                          toYmd,
                        ),
                        onTap: () => unawaited(_pickDate(isFrom: false)),
                      ),
                    ],
                  ),
                  if (_availableDates.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Dates with counts',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _availableDates.map((d) {
                        final selected = d == selectedYmd && d == toYmd;
                        return ChoiceChip(
                          label: Text(
                            ReportsParticipantsTabLogic.formatCountEntryDate(d),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : Colors.grey[800],
                            ),
                          ),
                          selected: selected,
                          selectedColor: AppTheme.primaryColor,
                          onSelected: (_) => unawaited(_selectAvailableDate(d)),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _error,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _statusPanel(
                                    title: 'Count updated',
                                    count: _updated.length,
                                    color: AppTheme.primaryColor,
                                    emptyText:
                                        'No participants entered a count for the selected date(s).',
                                    children: _updated,
                                    showCount: true,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statusPanel(
                                    title: 'Count not updated',
                                    count: _notUpdated.length,
                                    color: Colors.orange.shade800,
                                    emptyText:
                                        'All participants entered a count for the selected date(s).',
                                    children: _notUpdated,
                                    showCount: false,
                                  ),
                                ),
                              ],
                            )
                          : ListView(
                              children: [
                                SizedBox(
                                  height: math.max(220, dialogHeight * 0.38),
                                  child: _statusPanel(
                                    title: 'Count updated',
                                    count: _updated.length,
                                    color: AppTheme.primaryColor,
                                    emptyText:
                                        'No participants entered a count for the selected date(s).',
                                    children: _updated,
                                    showCount: true,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: math.max(220, dialogHeight * 0.38),
                                  child: _statusPanel(
                                    title: 'Count not updated',
                                    count: _notUpdated.length,
                                    color: Colors.orange.shade800,
                                    emptyText:
                                        'All participants entered a count for the selected date(s).',
                                    children: _notUpdated,
                                    showCount: false,
                                  ),
                                ),
                              ],
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateButton({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          color: Colors.grey[50],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPanel({
    required String title,
    required int count,
    required Color color,
    required String emptyText,
    required List<Map<String, dynamic>> children,
    required bool showCount,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: children.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        emptyText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    itemCount: children.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final row = children[index];
                      final name = (row['participantName'] ?? '').toString().trim();
                      final id = (row['registrationNo'] ?? '').toString().trim();
                      final countValue = (row['countValue'] ?? '').toString();
                      final inst = (row['institutionName'] ?? '').toString().trim();
                      final category = [
                        (row['categoryName'] ?? '').toString(),
                        (row['stageName'] ?? '').toString(),
                        (row['groupName'] ?? '').toString(),
                      ].where((e) => e.trim().isNotEmpty).join(' · ');
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: color,
                              child: Text(
                                ReportsParticipantsTabLogic.avatarInitial(name),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.isEmpty ? '—' : name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: Color(0xFF212121),
                                    ),
                                  ),
                                  Text(
                                    id.isEmpty ? '—' : id,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  if (!showCount &&
                                      (inst.isNotEmpty || category.isNotEmpty))
                                    Text(
                                      [if (inst.isNotEmpty) inst, if (category.isNotEmpty) category]
                                          .join(' · '),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (showCount)
                              Text(
                                countValue,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: color,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
