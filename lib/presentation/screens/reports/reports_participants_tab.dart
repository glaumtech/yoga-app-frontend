import 'dart:async' show Timer, unawaited;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:html' as html show Blob, Url, AnchorElement;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../controllers/reports_participants_tab_controller.dart';
import '../../widgets/location/district_search_field.dart';
import '../../../data/models/school_model.dart';
import '../../../data/models/state_model.dart';
import '../../../data/repositories/reports_repository.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mint header and grid styling for the participant scores table (reports).
const Color _kParticipantTableHeaderBg = Color(0xFFE8F5E9);
const Color _kParticipantTableBorder = Color(0xFFE0E0E0);
/// Header label when not the active (green) sort column — dark blue-grey.
const Color _kParticipantTableHeaderMuted = Color(0xFF37474F);

enum _ParticipantHeaderSort {
  /// No sort affordance (e.g. ICON, TYPE).
  none,
  /// Grey up/down icon (sortable look only).
  inactive,
  /// Green label + down arrow (active sort column look).
  active,
}

List<int> _participantTablePageIndices(int currentPage, int totalPages) {
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

String _participantSheetAvatarInitial(String? name) {
  final t = (name ?? '').trim();
  if (t.isEmpty) return '?';
  return t.substring(0, 1).toUpperCase();
}

Future<void> _openParticipantScoreDetails(
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
      final initial = _participantSheetAvatarInitial(pName);
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                          color: _kParticipantTableHeaderBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kParticipantTableBorder),
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
                                    style: const TextStyle(
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
                                    Border.all(color: _kParticipantTableBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.04),
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
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                      child: Text(
                                                        jt,
                                                        style: const TextStyle(
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
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                          horizontal: 8,
                                                          vertical: 5,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                            0xFFF1F8E9,
                                                          ),
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
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: Color(
                                                              0xFF33691E,
                                                            ),
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

class ReportsParticipantsTab extends StatelessWidget {
  const ReportsParticipantsTab({super.key});

  Future<void> _downloadPdf(Uint8List bytes, String filename) async {
    if (bytes.isEmpty) return;

    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: blobUrl)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(blobUrl);
      return;
    }

    final dataUri = Uri.dataFromBytes(bytes, mimeType: 'application/pdf');
    if (await canLaunchUrl(dataUri)) {
      await launchUrl(dataUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _downloadExcel(Uint8List bytes, String filename) async {
    if (bytes.isEmpty) return;

    const excelMime =
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

    if (kIsWeb) {
      final blob = html.Blob([bytes], excelMime);
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: blobUrl)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(blobUrl);
      return;
    }

    final dataUri = Uri.dataFromBytes(bytes, mimeType: excelMime);
    if (await canLaunchUrl(dataUri)) {
      await launchUrl(dataUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabController = Get.put(
      ReportsParticipantsTabController(),
      permanent: false,
    );

    Future<void> _printParticipants() async {
      final repo = ReportsRepository();
      final competitionId = int.tryParse(
        tabController.reportsController.selectedCompetitionId.value ?? '',
      );
      if (competitionId == null) return;

      final resp = await repo.getCompetitionParticipantsPrintPdf(
        competitionId,
        stageIds: tabController.selectedStageIds.isEmpty
            ? null
            : List<int>.from(tabController.selectedStageIds),
        categoryIds: tabController.selectedCategoryIds.isEmpty
            ? null
            : List<int>.from(tabController.selectedCategoryIds),
        groupIds: tabController.selectedGroupIds.isEmpty
            ? null
            : List<int>.from(tabController.selectedGroupIds),
        stateId: tabController.selectedStateId.value,
        cityId: null,
        institutionId: tabController.selectedInstitutionId.value,
        district: (() {
          final d = tabController.selectedDistrictFilter.value?.trim();
          if (d == null || d.isEmpty) return null;
          return d;
        })(),
        genders: tabController.selectedGenders.isEmpty
            ? null
            : List<String>.from(tabController.selectedGenders),
      );

      if (!resp.success || resp.data == null) {
        Get.snackbar(
          'Error',
          resp.message ?? 'Failed to generate Participants PDF',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await _downloadPdf(resp.data!, 'participants_$competitionId.pdf');
    }

    Future<void> _downloadParticipantsExcel() async {
      final competitionId = int.tryParse(
        tabController.reportsController.selectedCompetitionId.value ?? '',
      );
      if (competitionId == null) return;

      if (tabController.selectedStageIds.length != 1) {
        Get.snackbar(
          'Stage required',
          'Select exactly one stage in Report filters to download Excel.',
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
        );
        return;
      }

      final resp = await tabController.getParticipantsScoresExcel();

      if (!resp.success || resp.data == null) {
        Get.snackbar(
          'Error',
          resp.message ?? 'Failed to generate Participants Excel',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await _downloadExcel(resp.data!, 'participants_$competitionId.xlsx');
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Obx(() {
      if (tabController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (tabController.errorMessage.value.isNotEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 12),
                Text(
                  tabController.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[700]),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: tabController.refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      final compSel =
          tabController.reportsController.selectedCompetitionId.value ?? '';
      final hasCompetition = compSel.isNotEmpty;
      final items = tabController.tableItems;
      final q = tabController.participantSearchQuery.value.trim();

      return RefreshIndicator(
        onRefresh: tabController.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          children: [
            _buildFilters(
              context,
              tabController,
              isMobile,
              onPrint: _printParticipants,
              onDownloadExcel: _downloadParticipantsExcel,
            ),
            const SizedBox(height: 12),
            if (!hasCompetition)
              _infoCard('Select a competition to view participant scores.')
            else if (items.isEmpty)
              _infoCard(
                q.isNotEmpty
                    ? 'No participants match your search.'
                    : 'No participant scores found yet.',
              )
            else ...[
              _buildParticipantScoresStyledTable(
                context,
                tabController,
                items,
                isMobile,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildParticipantScoresStyledTable(
    BuildContext context,
    ReportsParticipantsTabController tabController,
    List<Map<String, dynamic>> items,
    bool isMobile,
  ) {
    return _ReportsParticipantScoresTable(
      hostContext: context,
      controller: tabController,
      items: items,
      isMobile: isMobile,
    );
  }

  Widget _buildFilters(
    BuildContext context,
    ReportsParticipantsTabController controller,
    bool isMobile, {
    required VoidCallback onPrint,
    required VoidCallback onDownloadExcel,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: AppTheme.primaryColor,
                  size: isMobile ? 18 : 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Filters',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    controller.clearFilters();
                    await controller.refresh();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(0, 0),
                  ),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.participantSearchFieldController,
                    onChanged: controller.setParticipantSearchQuery,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppTheme.primaryColor,
                      ),
                      hintText: 'Search participant name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Obx(() {
                  final n = controller.activeFilterCount;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (ctx) =>
                              _ParticipantFiltersDialog(controller: controller),
                        );
                      },
                      icon: Badge(
                        isLabelVisible: n > 0,
                        label: Text('$n'),
                        child: const Icon(
                          Icons.tune,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      label: Text(
                        isMobile ? 'Filters' : 'Report filters',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Print Participants',
                  icon: const Icon(Icons.print, color: AppTheme.primaryColor),
                  onPressed: onPrint,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
                const SizedBox(width: 6),
                Obx(() {
                  final stageSelected = controller.selectedStageIds.length == 1;
                  return IconButton(
                    tooltip: stageSelected
                        ? 'Download Participants Excel'
                        : 'Select exactly one stage in Report filters (Excel)',
                    icon: Icon(
                      Icons.download,
                      color: stageSelected
                          ? AppTheme.primaryColor
                          : Colors.grey,
                    ),
                    onPressed: stageSelected ? onDownloadExcel : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Use Report filters for stage, category, group, state, district, institution, and gender.',
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String message) {
    return Card(
      elevation: 2,
      color: Colors.blueGrey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.blueGrey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashboard-style grid table with mint header and numbered pagination.
class _ReportsParticipantScoresTable extends StatelessWidget {
  const _ReportsParticipantScoresTable({
    required this.hostContext,
    required this.controller,
    required this.items,
    required this.isMobile,
  });

  final BuildContext hostContext;
  final ReportsParticipantsTabController controller;
  final List<Map<String, dynamic>> items;
  final bool isMobile;

  static const BorderSide _cellBorderSide = BorderSide(
    color: _kParticipantTableBorder,
    width: 1,
  );

  static String _initialForName(String? name) {
    final t = (name ?? '').trim();
    if (t.isEmpty) return '?';
    return t.substring(0, 1).toUpperCase();
  }

  static Widget _headerLabel(
    String label, {
    TextAlign align = TextAlign.left,
    _ParticipantHeaderSort sort = _ParticipantHeaderSort.none,
  }) {
    final isActive = sort == _ParticipantHeaderSort.active;
    final showSortIcon =
        sort == _ParticipantHeaderSort.inactive || isActive;
    final labelColor =
        isActive ? AppTheme.primaryColor : _kParticipantTableHeaderMuted;

    return Row(
      mainAxisAlignment: align == TextAlign.right
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            label,
            textAlign: align,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.35,
              color: labelColor,
            ),
          ),
        ),
        if (showSortIcon) ...[
          const SizedBox(width: 4),
          Icon(
            isActive ? Icons.arrow_downward : Icons.swap_vert,
            size: 16,
            color: isActive ? AppTheme.primaryColor : Colors.grey[600],
          ),
        ],
      ],
    );
  }

  static Widget _dataChip(String text) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Chip(
      label: Text(
        text.trim(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF424242),
        ),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      backgroundColor: const Color(0xFFEEEEEE),
      side: BorderSide(color: Colors.grey[400]!),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    );
  }

  Widget _headerCell({
    required Widget child,
    required double width,
    bool last = false,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _kParticipantTableHeaderBg,
          border: Border(
            right: last ? BorderSide.none : _cellBorderSide,
            bottom: _cellBorderSide,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _headerExpanded({
    required Widget child,
    required int flex,
    bool last = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _kParticipantTableHeaderBg,
          border: Border(
            right: last ? BorderSide.none : _cellBorderSide,
            bottom: _cellBorderSide,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _bodyCell({
    required Widget child,
    required double width,
    bool last = false,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            right: last ? BorderSide.none : _cellBorderSide,
            bottom: _cellBorderSide,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _bodyExpanded({
    required Widget child,
    required int flex,
    bool last = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            right: last ? BorderSide.none : _cellBorderSide,
            bottom: _cellBorderSide,
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final outerPad = isMobile ? 24.0 : 32.0;
    final minTableWidth = math.max(920.0, screenW - outerPad);

    return Card(
      elevation: 1,
      shadowColor: Colors.black26,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _kParticipantTableBorder),
      ),
      child: Material(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: minTableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _headerCell(
                            width: 48,
                            child: _headerLabel('ICON'),
                          ),
                          _headerExpanded(
                            flex: 22,
                            child: _headerLabel(
                              'NAME & REG. NO.',
                              sort: _ParticipantHeaderSort.inactive,
                            ),
                          ),
                          _headerExpanded(
                            flex: 22,
                            child: _headerLabel('TYPE & CATEGORY'),
                          ),
                          _headerExpanded(
                            flex: 30,
                            child: _headerLabel('INSTITUTION'),
                          ),
                          _headerCell(
                            width: 72,
                            child: _headerLabel(
                              'JURIES',
                              align: TextAlign.right,
                              sort: _ParticipantHeaderSort.inactive,
                            ),
                          ),
                          _headerCell(
                            width: 92,
                            last: true,
                            child: _headerLabel(
                              'TOTAL',
                              align: TextAlign.right,
                              sort: _ParticipantHeaderSort.active,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final row in items)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            unawaited(
                              _openParticipantScoreDetails(
                                hostContext,
                                controller,
                                Map<String, dynamic>.from(row),
                              ),
                            );
                          },
                          hoverColor: AppTheme.primaryColor.withValues(
                            alpha: 0.06,
                          ),
                          splashColor: AppTheme.primaryColor.withValues(
                            alpha: 0.12,
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _bodyCell(
                                  width: 48,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppTheme.primaryColor,
                                      child: Text(
                                        _initialForName(
                                          row['participantName']?.toString(),
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                _bodyExpanded(
                                  flex: 22,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        (row['participantName'] ?? '')
                                            .toString()
                                            .trim()
                                            .isEmpty
                                            ? '—'
                                            : (row['participantName'] ?? '')
                                                  .toString(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          color: Color(0xFF212121),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        (row['registrationNo'] ?? '')
                                            .toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _bodyExpanded(
                                  flex: 22,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        _dataChip(
                                          (row['categoryName'] ?? '')
                                              .toString(),
                                        ),
                                        _dataChip(
                                          (row['stageName'] ?? '').toString(),
                                        ),
                                        _dataChip(
                                          (row['groupName'] ?? '').toString(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                _bodyExpanded(
                                  flex: 30,
                                  child: Text(
                                    (row['institutionName'] ?? '')
                                        .toString()
                                        .trim()
                                        .isEmpty
                                        ? '—'
                                        : (row['institutionName'] ?? '')
                                              .toString(),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.25,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                                _bodyCell(
                                  width: 72,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      (row['juryCount'] ?? 0).toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                _bodyCell(
                                  width: 92,
                                  last: true,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      (double.tryParse(
                                                (row['totalGrandTotal'] ?? 0)
                                                    .toString(),
                                              ) ??
                                              0.0)
                                          .toStringAsFixed(2),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                border: Border(
                  top: BorderSide(color: _kParticipantTableBorder),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Obx(() {
                final pg = controller.tablePage.value;
                final tp = controller.tableTotalPages.value;
                final te = controller.tableTotalElements.value;
                final totalP = tp <= 0 ? 1 : tp;
                final indices = _participantTablePageIndices(pg, totalP);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Page ${pg + 1} of $totalP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total: $te participants',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Previous page',
                      visualDensity: VisualDensity.compact,
                      onPressed: pg > 0
                          ? () => controller.goToTablePage(pg - 1)
                          : null,
                      icon: Icon(
                        Icons.chevron_left,
                        color: pg > 0 ? Colors.grey[800] : Colors.grey[400],
                      ),
                    ),
                    for (final i in indices)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: InkWell(
                          onTap: i == pg
                              ? null
                              : () => controller.goToTablePage(i),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i == pg
                                  ? AppTheme.primaryColor
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: i == pg
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: 'Next page',
                      visualDensity: VisualDensity.compact,
                      onPressed: tp > 0 && pg < tp - 1
                          ? () => controller.goToTablePage(pg + 1)
                          : null,
                      icon: Icon(
                        Icons.chevron_right,
                        color: tp > 0 && pg < tp - 1
                            ? Colors.grey[800]
                            : Colors.grey[400],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantFiltersDialog extends StatefulWidget {
  const _ParticipantFiltersDialog({required this.controller});

  final ReportsParticipantsTabController controller;

  @override
  State<_ParticipantFiltersDialog> createState() =>
      _ParticipantFiltersDialogState();
}

class _ParticipantFiltersDialogState extends State<_ParticipantFiltersDialog> {
  late Set<int> _stages;
  late Set<int> _categories;
  late Set<int> _groups;
  late Set<String> _genders;
  int? _state;
  int? _institution;
  bool _loadingLists = true;

  /// Refresh hints when async loads finish (institution field is not wrapped in Obx).
  Worker? _filterInstitutionsRxWorker;

  final TextEditingController _stateSearchController = TextEditingController();
  final TextEditingController _institutionSearchController =
      TextEditingController();
  final TextEditingController _districtSearchController =
      TextEditingController();
  final FocusNode _stateFocus = FocusNode();
  final FocusNode _institutionFocus = FocusNode();
  final FocusNode _districtFocus = FocusNode();

  /// Focus drops before ListTile [onTap] runs; panels keyed only on [hasFocus]
  /// disappear and swallow the tap. Keep panels mounted briefly after blur.
  Timer? _stateSuggestionsHideTimer;
  Timer? _institutionSuggestionsHideTimer;
  /// Avoids running state→district sync on every keystroke in the state field.
  Timer? _stateSearchDebounce;

  bool _stateSuggestionsVisible = false;
  bool _institutionSuggestionsVisible = false;

  static const Duration _locationSuggestionHideDelay = Duration(
    milliseconds: 220,
  );
  static const Duration _stateSearchDebounceDelay = Duration(milliseconds: 450);

  void _scheduleHideStateSuggestions() {
    _stateSuggestionsHideTimer?.cancel();
    _stateSuggestionsHideTimer = Timer(_locationSuggestionHideDelay, () {
      if (!mounted || _stateFocus.hasFocus) return;
      setState(() => _stateSuggestionsVisible = false);
    });
  }

  void _scheduleHideInstitutionSuggestions() {
    _institutionSuggestionsHideTimer?.cancel();
    _institutionSuggestionsHideTimer = Timer(_locationSuggestionHideDelay, () {
      if (!mounted || _institutionFocus.hasFocus) return;
      setState(() => _institutionSuggestionsVisible = false);
    });
  }

  void _onStateFocusChanged() {
    if (_stateFocus.hasFocus) {
      _stateSuggestionsHideTimer?.cancel();
      setState(() => _stateSuggestionsVisible = true);
    } else {
      _stateSearchDebounce?.cancel();
      _scheduleHideStateSuggestions();
      unawaited(_syncStateFromSearchQuery());
    }
    setState(() {});
  }

  void _onInstitutionFocusChanged() {
    if (_institutionFocus.hasFocus) {
      _institutionSuggestionsHideTimer?.cancel();
      setState(() => _institutionSuggestionsVisible = true);
    } else {
      _scheduleHideInstitutionSuggestions();
      unawaited(_syncInstitutionFromSearchQuery());
    }
    setState(() {});
  }

  /// Ensures the TextField shows programmatic updates (web / nested rebuilds).
  static void _setFilterFieldText(TextEditingController c, String text) {
    c.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// When the typed query matches exactly one state, commit selection and load districts.
  Future<void> _syncStateFromSearchQuery() async {
    final q = _stateSearchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      if (_state != null) {
        setState(() {
          _state = null;
          _institution = null;
          _institutionSearchController.clear();
          _districtSearchController.clear();
        });
        await widget.controller.reloadFilterDistrictsForState(null);
        if (mounted) setState(() {});
      }
      return;
    }

    final m = widget.controller.filterStateOptions
        .where((s) => s.stateName.toLowerCase().contains(q))
        .toList();
    if (m.length != 1) return;

    final s = m.first;
    // Already committed to this state: normalize label only, do not refetch districts.
    if (_state == s.id) {
      if (_stateSearchController.text.trim() != s.stateName.trim()) {
        setState(() {
          _setFilterFieldText(_stateSearchController, s.stateName);
        });
      }
      return;
    }

    setState(() {
      _state = s.id;
      _setFilterFieldText(_stateSearchController, s.stateName);
      _institution = null;
      _institutionSearchController.clear();
      _districtSearchController.clear();
    });

    await widget.controller.reloadFilterDistrictsForState(s.id);
    await widget.controller.reloadFilterInstitutions(
      stateId: s.id,
      cityId: null,
    );
    if (mounted) setState(() {});
  }

  Future<void> _syncInstitutionFromSearchQuery() async {
    if (_state == null || _state! <= 0) return;
    final q = _institutionSearchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      if (_institution != null) {
        setState(() => _institution = null);
      }
      return;
    }

    final m = widget.controller.filterInstitutionOptions
        .where((s) => int.tryParse(s.id ?? '') != null)
        .where((s) => s.institutionName.toLowerCase().contains(q))
        .toList();
    if (m.length != 1) return;

    final inst = m.first;
    final id = int.tryParse(inst.id ?? '');
    if (id == null) return;
    if (_institution == id &&
        _institutionSearchController.text.trim() ==
            inst.institutionName.trim()) {
      return;
    }

    setState(() {
      _institution = id;
      _setFilterFieldText(_institutionSearchController, inst.institutionName);
    });
  }

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    _stages = Set<int>.from(c.selectedStageIds);
    _categories = Set<int>.from(c.selectedCategoryIds);
    _groups = Set<int>.from(c.selectedGroupIds);
    _genders = Set<String>.from(c.selectedGenders);
    _state = c.selectedStateId.value;
    _institution = c.selectedInstitutionId.value;
    _stateFocus.addListener(_onStateFocusChanged);
    _institutionFocus.addListener(_onInstitutionFocusChanged);
    _filterInstitutionsRxWorker = ever(
      widget.controller.filterInstitutionOptions,
      (_) {
        if (mounted) setState(() {});
      },
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loadingLists = true);
    await widget.controller.prefetchFilterListsForDialog();
    if (mounted) {
      _syncSearchLabels();
      setState(() => _loadingLists = false);
    }
  }

  void _syncSearchLabels() {
    final sid = _state;
    if (sid != null) {
      for (final s in widget.controller.filterStateOptions) {
        if (s.id == sid) {
          _setFilterFieldText(_stateSearchController, s.stateName);
          break;
        }
      }
    }
    final iid = _institution;
    if (iid != null) {
      for (final inst in widget.controller.filterInstitutionOptions) {
        final parsed = int.tryParse(inst.id ?? '');
        if (parsed == iid) {
          _setFilterFieldText(
            _institutionSearchController,
            inst.institutionName,
          );
          break;
        }
      }
    }
    final dist = widget.controller.selectedDistrictFilter.value?.trim();
    if (dist != null && dist.isNotEmpty) {
      _setFilterFieldText(_districtSearchController, dist);
    }
  }

  @override
  void dispose() {
    _stateSearchDebounce?.cancel();
    _stateSuggestionsHideTimer?.cancel();
    _institutionSuggestionsHideTimer?.cancel();
    _filterInstitutionsRxWorker?.dispose();
    _stateFocus.removeListener(_onStateFocusChanged);
    _institutionFocus.removeListener(_onInstitutionFocusChanged);
    _stateSearchController.dispose();
    _institutionSearchController.dispose();
    _districtSearchController.dispose();
    _stateFocus.dispose();
    _institutionFocus.dispose();
    _districtFocus.dispose();
    super.dispose();
  }

  Iterable<StateModel> _filteredStates() {
    final q = _stateSearchController.text.trim().toLowerCase();
    final all = widget.controller.filterStateOptions;
    if (q.isEmpty) return all.take(80);
    return all.where((s) => s.stateName.toLowerCase().contains(q)).take(100);
  }

  Iterable<SchoolModel> _filteredInstitutions() {
    final q = _institutionSearchController.text.trim().toLowerCase();
    final all = widget.controller.filterInstitutionOptions.where(
      (s) => int.tryParse(s.id ?? '') != null,
    );
    if (q.isEmpty) return all.take(120);
    return all
        .where((s) => s.institutionName.toLowerCase().contains(q))
        .take(150);
  }

  /// If user typed search text but did not tap a row, resolve a unique match before Apply.
  void _resolveLocationSelectionsBeforeApply() {
    if (_state == null) {
      final q = _stateSearchController.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final m = widget.controller.filterStateOptions
            .where((s) => s.stateName.toLowerCase().contains(q))
            .toList();
        if (m.length == 1) {
          _state = m.first.id;
          _setFilterFieldText(_stateSearchController, m.first.stateName);
        }
      }
    }
    if (_state != null && _institution == null) {
      final q = _institutionSearchController.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final m = widget.controller.filterInstitutionOptions
            .where((s) => int.tryParse(s.id ?? '') != null)
            .where((s) => s.institutionName.toLowerCase().contains(q))
            .toList();
        if (m.length == 1) {
          final id = int.tryParse(m.first.id ?? '');
          if (id != null) {
            _institution = id;
            _setFilterFieldText(
              _institutionSearchController,
              m.first.institutionName,
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 560;
    return AlertDialog(
      title: const Text('Report filters'),
      content: SizedBox(
        width: isMobile ? double.maxFinite : 440,
        child: _loadingLists
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Obx(
                      () => Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _checkboxFilterColumn(
                            title: 'Stage',
                            isMobile: isMobile,
                            options: widget.controller.stageOptions.toList(),
                            selected: _stages,
                            onToggle: (id, on) => setState(() {
                              if (on) {
                                _stages.add(id);
                              } else {
                                _stages.remove(id);
                              }
                            }),
                          ),
                          const SizedBox(height: 10),
                          _checkboxFilterColumn(
                            title: 'Category',
                            isMobile: isMobile,
                            options: widget.controller.categoryOptions.toList(),
                            selected: _categories,
                            onToggle: (id, on) => setState(() {
                              if (on) {
                                _categories.add(id);
                              } else {
                                _categories.remove(id);
                              }
                            }),
                          ),
                          const SizedBox(height: 10),
                          _checkboxFilterColumn(
                            title: 'Group',
                            isMobile: isMobile,
                            options: widget.controller.groupOptions.toList(),
                            selected: _groups,
                            onToggle: (id, on) => setState(() {
                              if (on) {
                                _groups.add(id);
                              } else {
                                _groups.remove(id);
                              }
                            }),
                          ),
                          const SizedBox(height: 10),
                          _genderCheckboxSection(
                            isMobile: isMobile,
                            selected: _genders,
                            onChanged: (g, on) => setState(() {
                              if (on) {
                                _genders.add(g);
                              } else {
                                _genders.remove(g);
                              }
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'State (search)',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      key: const ValueKey('report_filter_state_field'),
                      controller: _stateSearchController,
                      focusNode: _stateFocus,
                      onChanged: (_) {
                        setState(() {});
                        _stateSearchDebounce?.cancel();
                        _stateSearchDebounce = Timer(
                          _stateSearchDebounceDelay,
                          () {
                            if (!mounted) return;
                            unawaited(_syncStateFromSearchQuery());
                          },
                        );
                      },
                      decoration: InputDecoration(
                        hintText: 'Type to search states',
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                      ),
                    ),
                    if (_stateSuggestionsVisible)
                      SizedBox(
                        height: 120,
                        child: Material(
                          elevation: 1,
                          borderRadius: BorderRadius.circular(8),
                          child: ListView(
                            primary: false,
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            children: [
                              ..._filteredStates().map((s) {
                                return ListTile(
                                  dense: true,
                                  title: Text(s.stateName),
                                  onTap: () async {
                                    _stateSuggestionsHideTimer?.cancel();
                                    _stateSearchDebounce?.cancel();
                                    setState(() {
                                      _stateSuggestionsVisible = false;
                                      _state = s.id;
                                      _institution = null;
                                      _setFilterFieldText(
                                        _stateSearchController,
                                        s.stateName,
                                      );
                                      _institutionSearchController.clear();
                                      _districtSearchController.clear();
                                    });
                                    await widget.controller
                                        .reloadFilterDistrictsForState(s.id);
                                    await widget.controller
                                        .reloadFilterInstitutions(
                                          stateId: s.id,
                                          cityId: null,
                                        );
                                    _stateFocus.unfocus();
                                    if (mounted) setState(() {});
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'District (search)',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    _state == null || _state! <= 0
                        ? TextField(
                            key: const ValueKey('report_filter_district_disabled'),
                            readOnly: true,
                            controller: _districtSearchController,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 15,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Select a state first',
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              isDense: true,
                            ),
                          )
                        : DistrictSearchField(
                            key: ValueKey('report_filter_district_$_state'),
                            textEditingController: _districtSearchController,
                            focusNode: _districtFocus,
                            districts: List<String>.from(
                              widget.controller.filterDistrictOptions,
                            ),
                            decorationBuilder: ({Widget? suffixIcon}) =>
                                InputDecoration(
                              prefixIcon: IconTheme(
                                data: IconThemeData(
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                child: suffixIcon ?? const Icon(Icons.search),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              isDense: true,
                            ),
                            isMobile: isMobile,
                            hintText: 'Type to search district',
                          ),
                    const SizedBox(height: 10),
                    Text(
                      'Institution (search)',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      key: const ValueKey('report_filter_institution_field'),
                      controller: _institutionSearchController,
                      focusNode: _institutionFocus,
                      enabled: _state != null && _state! > 0,
                      onChanged: (_) {
                        setState(() {});
                        unawaited(_syncInstitutionFromSearchQuery());
                      },
                      decoration: InputDecoration(
                        hintText: _state == null
                            ? 'Select a state first'
                            : widget.controller.filterInstitutionOptions.isEmpty
                            ? 'No institutions for this location'
                            : 'Type to search institutions',
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                      ),
                    ),
                    if (_state != null &&
                        _state! > 0 &&
                        widget.controller.filterInstitutionOptions.isNotEmpty &&
                        _institutionSuggestionsVisible)
                      SizedBox(
                        height: 200,
                        child: Material(
                          elevation: 1,
                          borderRadius: BorderRadius.circular(8),
                          child: ListView(
                            primary: false,
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            children: [
                              ..._filteredInstitutions().map((inst) {
                                final id = int.tryParse(inst.id ?? '')!;
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    inst.institutionName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    _institutionSuggestionsHideTimer?.cancel();
                                    setState(() {
                                      _institutionSuggestionsVisible = false;
                                      _institution = id;
                                      _setFilterFieldText(
                                        _institutionSearchController,
                                        inst.institutionName,
                                      );
                                    });
                                    _institutionFocus.unfocus();
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            setState(() {
              _resolveLocationSelectionsBeforeApply();
            });
            final sid = _state;
            if (sid != null && sid > 0) {
              await widget.controller.reloadFilterDistrictsForState(sid);
              await widget.controller.reloadFilterInstitutions(
                stateId: sid,
                cityId: null,
              );
            }
            if (!context.mounted) return;
            widget.controller.applyFilters(
              stageIds: _stages.toList(),
              categoryIds: _categories.toList(),
              groupIds: _groups.toList(),
              genders: _genders.toList(),
              stateId: _state,
              institutionId: _institution,
              district: widget.controller.resolveParticipantReportDistrict(
                List<String>.from(widget.controller.filterDistrictOptions),
                _districtSearchController.text,
              ),
            );
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// Shared shell for Stage / Category / Group / Gender: title row + soft card body.
Widget _filterSectionCard({
  required String title,
  required bool isMobile,
  required Widget child,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Material(color: Colors.transparent, child: child),
      ),
    ],
  );
}

Widget _horizontalCheckboxChip({
  required bool isMobile,
  required bool value,
  required String label,
  required void Function(bool? v) onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 2),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _checkboxFilterColumn({
  required String title,
  required bool isMobile,
  required List<Map<String, dynamic>> options,
  required Set<int> selected,
  required void Function(int id, bool on) onToggle,
}) {
  return _filterSectionCard(
    title: title,
    isMobile: isMobile,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: options.isEmpty
          ? Text(
              'No options',
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                color: Colors.grey[600],
              ),
            )
          : Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: options.map((m) {
                final id = (m['id'] as int?) ?? 0;
                final name = (m['name'] ?? '').toString();
                final label = name.isNotEmpty ? name : id.toString();
                return _horizontalCheckboxChip(
                  isMobile: isMobile,
                  value: selected.contains(id),
                  label: label,
                  onChanged: (v) => onToggle(id, v ?? false),
                );
              }).toList(),
            ),
    ),
  );
}

Widget _genderCheckboxSection({
  required bool isMobile,
  required Set<String> selected,
  required void Function(String gender, bool on) onChanged,
}) {
  return _filterSectionCard(
    title: 'Gender',
    isMobile: isMobile,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _horizontalCheckboxChip(
            isMobile: isMobile,
            value: selected.contains('MALE'),
            label: 'Male',
            onChanged: (v) => onChanged('MALE', v ?? false),
          ),
          _horizontalCheckboxChip(
            isMobile: isMobile,
            value: selected.contains('FEMALE'),
            label: 'Female',
            onChanged: (v) => onChanged('FEMALE', v ?? false),
          ),
        ],
      ),
    ),
  );
}
