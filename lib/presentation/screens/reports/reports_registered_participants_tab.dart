import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:html' as html show Blob, Url, AnchorElement;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../routes/app_routes.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/reports_repository.dart';
import '../../controllers/reports_registered_participants_tab_controller.dart';
import '../../controllers/reports_participants_tab_logic.dart';
import 'reports_participants_tab.dart';

const Color _kTableHeaderBg = Color(0xFFE8F5E9);
const Color _kTableBorder = Color(0xFFE0E0E0);
const Color _kTableHeaderMuted = Color(0xFF37474F);

/// Registered participants report (table view, competition filters).
class ReportsRegisteredParticipantsTab extends StatelessWidget {
  const ReportsRegisteredParticipantsTab({super.key});

  Future<void> _downloadPdf(Uint8List bytes, String filename) async {
    await ReportsParticipantsTabLogic.downloadReportPdfBytes(bytes, filename);
  }

  @override
  Widget build(BuildContext context) {
    final tabController = Get.put(
      ReportsRegisteredParticipantsTabController(),
      permanent: false,
    );
    final repo = ReportsRepository();

    Future<void> printReport() async {
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
        institutionId: tabController.selectedInstitutionId.value,
        districtId: tabController.selectedDistrictFilter.value,
        genders: tabController.selectedGenders.isEmpty
            ? null
            : List<String>.from(tabController.selectedGenders),
      );

      if (!resp.success || resp.data == null) {
        Get.snackbar(
          'Error',
          resp.message ?? 'Failed to generate participants PDF',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      await _downloadPdf(
        resp.data!,
        'registered_participants_$competitionId.pdf',
      );
    }

    Future<void> downloadExcel() async {
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

      final resp = await repo.getCompetitionParticipantsExcel(
        competitionId,
        stageIds: List<int>.from(tabController.selectedStageIds),
        categoryIds: tabController.selectedCategoryIds.isEmpty
            ? null
            : List<int>.from(tabController.selectedCategoryIds),
        groupIds: tabController.selectedGroupIds.isEmpty
            ? null
            : List<int>.from(tabController.selectedGroupIds),
        stateId: tabController.selectedStateId.value,
        institutionId: tabController.selectedInstitutionId.value,
        districtId: tabController.selectedDistrictFilter.value,
        genders: tabController.selectedGenders.isEmpty
            ? null
            : List<String>.from(tabController.selectedGenders),
      );

      if (!resp.success || resp.data == null) {
        Get.snackbar(
          'Error',
          resp.message ?? 'Failed to generate Excel',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final bytes = resp.data!;
      if (kIsWeb) {
        const mime =
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        final blob = html.Blob([bytes], mime);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'registered_participants_$competitionId.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final uri = Uri.dataFromBytes(
          bytes,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Obx(() {
      final loading = tabController.isLoading.value;
      final err = tabController.errorMessage.value;
      final hasCompetition =
          (tabController.reportsController.selectedCompetitionId.value ?? '')
              .isNotEmpty;
      final items = tabController.tableItems;
      final q = tabController.participantSearchQuery.value.trim();

      if (err.isNotEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 12),
                Text(err, textAlign: TextAlign.center),
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

      return RefreshIndicator(
        onRefresh: tabController.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            isMobile ? 12 : 16,
            4,
            isMobile ? 12 : 16,
            8,
          ),
          children: [
            ReportsParticipantFiltersBar(
              controller: tabController,
              isMobile: isMobile,
              onPrint: printReport,
              onDownloadExcel: downloadExcel,
              searchHint: 'Search participant name or reg. no.',
              emptyFiltersHint:
                  'Filter by stage, category, group, gender, institution, category type, and registration type. Click dashboard counts to open with presets.',
            ),
            const SizedBox(height: 4),
            if (!hasCompetition)
              _infoCard('Select a competition to view registered participants.')
            else if (items.isEmpty && loading)
              const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              _infoCard(
                q.isNotEmpty
                    ? 'No participants match your search or filters.'
                    : 'No registered participants found.',
              )
            else
              _RegisteredParticipantsTable(
                controller: tabController,
                items: items,
                loading: loading,
              ),
          ],
        ),
      );
    });
  }

  Widget _infoCard(String message) {
    return Card(
      color: Colors.blueGrey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _RegisteredParticipantsTable extends StatelessWidget {
  const _RegisteredParticipantsTable({
    required this.controller,
    required this.items,
    required this.loading,
  });

  final ReportsRegisteredParticipantsTabController controller;
  final List<Map<String, dynamic>> items;
  final bool loading;

  static const double _minWidth = 1000;

  static const BorderSide _cellBorderSide = BorderSide(
    color: _kTableBorder,
    width: 1,
  );

  static Widget _headerLabel(String label, {TextAlign align = TextAlign.left}) {
    return Text(
      label,
      textAlign: align,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.35,
        color: _kTableHeaderMuted,
      ),
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

  static String _formatGender(Map<String, dynamic> row) {
    final raw = (row['sex'] ?? row['gender'] ?? '').toString().trim().toUpperCase();
    if (raw.isEmpty) return '—';
    if (raw == 'MALE' || raw == 'M' || raw == 'BOY' || raw == 'B') return 'Male';
    if (raw == 'FEMALE' || raw == 'F' || raw == 'GIRL' || raw == 'G') {
      return 'Female';
    }
    if (raw.startsWith('MALE')) return 'Male';
    if (raw.startsWith('FEMALE')) return 'Female';
    return raw[0] + raw.substring(1).toLowerCase();
  }

  static Widget _eCertificateStatusIcon(Map<String, dynamic> row) {
    final optedIn = ReportsParticipantsTabLogic.rowOptForECertificate(row);
    return Tooltip(
      message: optedIn
          ? 'Opted in for e-certificate'
          : 'Not opted in for e-certificate',
      child: Icon(
        optedIn ? Icons.check_circle : Icons.cancel_outlined,
        size: 22,
        color: optedIn ? AppTheme.primaryColor : Colors.grey[400],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black26,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _kTableBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final tableWidth = math.max(_minWidth, w.isFinite ? w : _minWidth);

          return Stack(
            alignment: Alignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Column(
                        children: [
                          _headerRow(),
                          for (final row in items)
                            _dataRow(
                              context,
                              row,
                              competitionName:
                                  controller.tableCompetitionName.value,
                            ),
                        ],
                      ),
                    ),
                  ),
                  _pagination(),
                ],
              ),
              if (loading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0xB3FFFFFF),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _headerRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _headerCell(width: 48, child: _headerLabel('ICON')),
          _headerCell(
            width: 48,
            child: Tooltip(
              message: 'E-certificate (opt-in)',
              child: Icon(
                Icons.workspace_premium,
                size: 18,
                color: _kTableHeaderMuted,
              ),
            ),
          ),
          _headerExpanded(flex: 22, child: _headerLabel('NAME & REG. NO.')),
          _headerExpanded(flex: 20, child: _headerLabel('TYPE & CATEGORY')),
          _headerExpanded(flex: 26, child: _headerLabel('INSTITUTION')),
          _headerCell(
            width: 72,
            align: TextAlign.center,
            child: _headerLabel('GENDER', align: TextAlign.center),
          ),
          _headerCell(
            width: 52,
            align: TextAlign.center,
            child: _headerLabel('AGE', align: TextAlign.center),
          ),
          _headerCell(
            width: 88,
            last: true,
            child: _headerLabel('REG. TYPE'),
          ),
        ],
      ),
    );
  }

  void _openRegistrationDetails(
    BuildContext context,
    Map<String, dynamic> row,
    String competitionName,
  ) {
    final registrationId = (row['participantRegistrationId'] as num?)?.toInt();
    if (registrationId == null) {
      Get.snackbar(
        'Unavailable',
        'Registration id is missing for this participant.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    context.push(
      AppRoutes.participantRegistrationDetailsPath(
        registrationId.toString(),
        participantName: row['participantName']?.toString(),
        competitionName: competitionName,
        registrationNo: row['registrationNo']?.toString(),
      ),
    );
  }

  Widget _dataRow(
    BuildContext context,
    Map<String, dynamic> row, {
    required String competitionName,
  }) {
    final spot = row['isSpotRegistration'] == true;
    final regType = spot ? 'Spot' : 'Online';
    final age = row['age']?.toString() ?? '—';
    final participantName = (row['participantName'] ?? '—').toString().trim();
    final displayName =
        participantName.isEmpty ? '—' : participantName;
    final registrationId = (row['participantRegistrationId'] as num?)?.toInt();
    final canOpenDetails = registrationId != null && displayName != '—';

    return IntrinsicHeight(
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
                  ReportsParticipantsTabLogic.avatarInitial(
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
          _bodyCell(
            width: 48,
            child: Align(
              alignment: Alignment.center,
              child: _eCertificateStatusIcon(row),
            ),
          ),
          _bodyExpanded(
            flex: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: canOpenDetails
                      ? () => _openRegistrationDetails(
                            context,
                            row,
                            competitionName,
                          )
                      : null,
                  child: Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: canOpenDetails
                          ? AppTheme.primaryColor
                          : const Color(0xFF212121),
                      decoration: canOpenDetails
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (row['registrationNo'] ?? '').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _bodyExpanded(
            flex: 20,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _dataChip((row['categoryName'] ?? '').toString()),
                  _dataChip((row['stageName'] ?? '').toString()),
                  _dataChip((row['groupName'] ?? '').toString()),
                ],
              ),
            ),
          ),
          _bodyExpanded(
            flex: 26,
            child: Text(
              (row['institutionName'] ?? '—').toString().trim().isEmpty
                  ? '—'
                  : (row['institutionName'] ?? '—').toString(),
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
              alignment: Alignment.center,
              child: Text(
                _formatGender(row),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          _bodyCell(
            width: 52,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                age,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          _bodyCell(
            width: 88,
            last: true,
            child: Text(
              regType,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: spot ? Colors.orange[800] : AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pagination() {
    return Obx(() {
      final pg = controller.tablePage.value;
      final tp = controller.tableTotalPages.value;
      final te = controller.tableTotalElements.value;
      final totalP = tp <= 0 ? 1 : tp;
      final indices = ReportsParticipantsTabLogic.tablePageIndices(pg, totalP);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
          border: Border(top: BorderSide(color: _kTableBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Page ${pg + 1} of $totalP',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Total: $te participants',
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: pg > 0 ? () => controller.goToTablePage(pg - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            for (final i in indices)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  color: i == pg ? AppTheme.primaryColor : Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => controller.goToTablePage(i),
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: i == pg ? Colors.white : Colors.grey[800],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            IconButton(
              onPressed: pg + 1 < totalP
                  ? () => controller.goToTablePage(pg + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      );
    });
  }

  Widget _headerCell({
    required double width,
    required Widget child,
    TextAlign align = TextAlign.left,
    bool last = false,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        alignment: align == TextAlign.center
            ? Alignment.center
            : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _kTableHeaderBg,
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
    required int flex,
    required Widget child,
    bool last = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _kTableHeaderBg,
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
    required double width,
    required Widget child,
    bool last = false,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
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

  Widget _bodyExpanded({required int flex, required Widget child, bool last = false}) {
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
}
