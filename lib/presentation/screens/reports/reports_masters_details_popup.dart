import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/reports_repository.dart';
import '../../controllers/reports_participants_list_preset.dart';
import '../../controllers/reports_participants_tab_logic.dart';
import '../../widgets/responsive_admin_table.dart';
import 'reports_institutions_details_popup.dart';
import 'reports_registered_participants_popup.dart';

/// Popup showing Top Master's Report rows in a table.
class ReportsMastersDetailsPopup {
  ReportsMastersDetailsPopup._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<Map<String, dynamic>> masters,
    required String competitionId,
    String? competitionName,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _MastersDetailsDialog(
          title: title,
          competitionId: competitionId,
          competitionName: competitionName,
          masters: List<Map<String, dynamic>>.from(masters),
        );
      },
    );
  }
}

class _MastersDetailsDialog extends StatefulWidget {
  const _MastersDetailsDialog({
    required this.title,
    required this.competitionId,
    required this.masters,
    this.competitionName,
  });

  final String title;
  final String competitionId;
  final String? competitionName;
  final List<Map<String, dynamic>> masters;

  @override
  State<_MastersDetailsDialog> createState() => _MastersDetailsDialogState();
}

class _MastersDetailsDialogState extends State<_MastersDetailsDialog> {
  static const double _minTableWidth = 860;
  static const BorderSide _cellBorderSide = BorderSide(
    color: AppColors.border,
    width: 1,
  );

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _studentCountDesc = true;
  bool _downloading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _text(dynamic value) {
    final s = (value ?? '').toString().trim();
    return s.isEmpty ? '—' : s;
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == '—') return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  List<Map<String, dynamic>> get _visibleRows {
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty
        ? List<Map<String, dynamic>>.from(widget.masters)
        : widget.masters.where((row) {
            final name =
                (row['yogaTeacherName'] ?? '').toString().toLowerCase();
            final cell =
                (row['yogaTeacherCell'] ?? '').toString().toLowerCase();
            return name.contains(q) || cell.contains(q);
          }).toList();

    list.sort((a, b) {
      final ac = (a['participantCount'] as num?)?.toInt() ?? 0;
      final bc = (b['participantCount'] as num?)?.toInt() ?? 0;
      return _studentCountDesc ? bc.compareTo(ac) : ac.compareTo(bc);
    });
    return list;
  }

  void _toggleStudentCountSort() {
    setState(() => _studentCountDesc = !_studentCountDesc);
  }

  Future<void> _askDownloadFormat() async {
    if (_visibleRows.isEmpty) {
      Get.snackbar(
        'Download',
        'No masters to download.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Download'),
          content: const Text('Choose download format'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('pdf'),
              child: const Text('PDF'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop('excel'),
              child: const Text('Excel'),
            ),
          ],
        );
      },
    );

    if (choice == null || !mounted) return;
    await _downloadMasters(asExcel: choice == 'excel');
  }

  Future<void> _downloadMasters({required bool asExcel}) async {
    final competitionId = int.tryParse(widget.competitionId);
    if (competitionId == null) {
      Get.snackbar(
        'Download',
        'Invalid competition id.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _downloading = true);
    try {
      final repo = ReportsRepository();
      final search = _query.trim().isEmpty ? null : _query.trim();
      final resp = asExcel
          ? await repo.getCompetitionMastersExcel(
              competitionId,
              sortDesc: _studentCountDesc,
              search: search,
              title: widget.title,
            )
          : await repo.getCompetitionMastersPrintPdf(
              competitionId,
              sortDesc: _studentCountDesc,
              search: search,
              title: widget.title,
            );

      if (!resp.success || resp.data == null || resp.data!.isEmpty) {
        Get.snackbar(
          'Download',
          resp.message ??
              (asExcel
                  ? 'Failed to generate Masters Excel'
                  : 'Failed to generate Masters PDF'),
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      final safeTitle = widget.title
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');
      final base = safeTitle.isEmpty ? 'masters' : safeTitle;
      final filename =
          asExcel ? '${base}_$competitionId.xlsx' : '${base}_$competitionId.pdf';

      await ReportsParticipantsTabLogic.downloadFileBytes(
        resp.data!,
        filename,
        mimeType: asExcel
            ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            : 'application/pdf',
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _openMasterInstitutions(Map<String, dynamic> row) {
    if (widget.competitionId.trim().isEmpty) {
      Get.snackbar(
        'Competition required',
        'Select a competition first.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    final name = (row['yogaTeacherName'] ?? '').toString().trim();
    final cell = (row['yogaTeacherCell'] ?? '').toString().trim();
    final institutions = (row['institutions'] as List?)
            ?.map((e) => (e as Map).cast<String, dynamic>())
            .toList() ??
        const <Map<String, dynamic>>[];

    if (institutions.isEmpty) {
      Get.snackbar(
        'No institutions',
        'This master has no institution split-up.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    ReportsInstitutionsDetailsPopup.show(
      context,
      title: name.isNotEmpty ? "$name's Institutions" : 'Master Institutions',
      kind: InstitutionsListKind.all,
      institutions: institutions,
      competitionId: widget.competitionId,
      competitionName: widget.competitionName,
      yogaTeacherName: name.isEmpty ? null : name,
      yogaTeacherCell: cell.isEmpty ? null : cell,
    );
  }

  void _openMasterStudents(Map<String, dynamic> row) {
    if (widget.competitionId.trim().isEmpty) {
      Get.snackbar(
        'Competition required',
        'Select a competition first.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    final name = (row['yogaTeacherName'] ?? '').toString().trim();
    if (name.isEmpty) {
      Get.snackbar(
        'Unavailable',
        'Yoga teacher name is missing for this row.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    final cell = (row['yogaTeacherCell'] ?? '').toString().trim();
    ReportsRegisteredParticipantsPopup.show(
      context,
      competitionId: widget.competitionId,
      preset: ReportsParticipantsListPreset.yogaTeacher(
        yogaTeacherName: name,
        yogaTeacherCell: cell.isEmpty ? null : cell,
      ),
    );
  }

  Widget _headerLabel(String label, {TextAlign align = TextAlign.left}) {
    return Text(
      label,
      textAlign: align,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.35,
        color: AppTheme.sectionHeaderText(),
      ),
    );
  }

  Widget _studentCountHeader() {
    return Tooltip(
      message: _studentCountDesc
          ? 'Sorted high to low — click for ascending'
          : 'Sorted low to high — click for descending',
      child: InkWell(
        onTap: _toggleStudentCountSort,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PARTICIPANT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: AppTheme.sectionHeaderText(),
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'COUNT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: AppTheme.sectionHeaderText(),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 2),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_drop_up,
                      size: 14,
                      color: !_studentCountDesc
                          ? AppTheme.primaryColor
                          : AppTheme.sectionHeaderText()
                              .withValues(alpha: 0.35),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -6),
                      child: Icon(
                        Icons.arrow_drop_down,
                        size: 14,
                        color: _studentCountDesc
                            ? AppTheme.primaryColor
                            : AppTheme.sectionHeaderText()
                                .withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        padding: EdgeInsets.symmetric(
          horizontal: last ? 6 : 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
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
    Alignment alignment = Alignment.centerLeft,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
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
    required int flex,
    required Widget child,
    bool last = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            right: last ? BorderSide.none : _cellBorderSide,
            bottom: _cellBorderSide,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _clickableCount({
    required int count,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.primaryColor.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerRow() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _headerCell(
            width: 56,
            align: TextAlign.center,
            child: _headerLabel('ICON', align: TextAlign.center),
          ),
          _headerExpanded(
            flex: 34,
            child: _headerLabel('MASTER NAME'),
          ),
          _headerExpanded(
            flex: 26,
            child: _headerLabel('MOBILE NO'),
          ),
          _headerCell(
            width: 130,
            align: TextAlign.center,
            child: _headerLabel('INSTITUTION COUNT', align: TextAlign.center),
          ),
          _headerCell(
            width: 120,
            last: true,
            align: TextAlign.center,
            child: _studentCountHeader(),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(Map<String, dynamic> row) {
    final name = _text(row['yogaTeacherName']);
    final cell = _text(row['yogaTeacherCell']);
    final institutionCount = (row['institutionCount'] as num?)?.toInt() ?? 0;
    final studentCount = (row['participantCount'] as num?)?.toInt() ?? 0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bodyCell(
            width: 56,
            alignment: Alignment.center,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
              child: Icon(
                Icons.school_outlined,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ),
          ),
          _bodyExpanded(
            flex: 34,
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          _bodyExpanded(
            flex: 26,
            child: Text(
              cell,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          _bodyCell(
            width: 130,
            alignment: Alignment.center,
            child: _clickableCount(
              count: institutionCount,
              tooltip: 'Click to view institutions',
              onTap: () => _openMasterInstitutions(row),
            ),
          ),
          _bodyCell(
            width: 120,
            last: true,
            alignment: Alignment.center,
            child: _clickableCount(
              count: studentCount,
              tooltip: 'Click to view participants',
              onTap: () => _openMasterStudents(row),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final isMobile = mq.width < 700;
    final dialogWidth =
        math.min(isMobile ? mq.width - 24 : 980.0, mq.width - 24);
    final dialogHeight = math.min(mq.height * 0.9, mq.height - 24);
    final rows = _visibleRows;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: AppTheme.primaryColor,
              child: Padding(
                padding: EdgeInsets.fromLTRB(isMobile ? 12 : 16, 10, 4, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          if (widget.competitionName != null &&
                              widget.competitionName!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.competitionName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 2),
                          Text(
                            '${rows.length} master${rows.length == 1 ? '' : 's'}'
                            '${_query.trim().isNotEmpty && rows.length != widget.masters.length ? ' (of ${widget.masters.length})' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _downloading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : IconButton(
                            tooltip: 'Download',
                            onPressed: _askDownloadFormat,
                            icon: const Icon(
                              Icons.download,
                              color: Colors.white,
                            ),
                          ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 12 : 16,
                12,
                isMobile ? 12 : 16,
                8,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search master name or mobile...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: _query.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 12 : 16,
                  0,
                  isMobile ? 12 : 16,
                  12,
                ),
                child: rows.isEmpty
                    ? Center(
                        child: Text(
                          'No masters found.',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : Card(
                        elevation: 1,
                        shadowColor: Colors.black26,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth.isFinite
                                      ? constraints.maxWidth
                                      : _minTableWidth,
                                ),
                                child: HorizontalScrollTable(
                                  minWidth: _minTableWidth,
                                  child: Column(
                                    children: [
                                      _headerRow(),
                                      for (final row in rows) _dataRow(row),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
