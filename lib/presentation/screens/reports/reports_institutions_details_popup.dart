import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/reports_repository.dart';
import '../../controllers/reports_participants_list_preset.dart';
import '../../controllers/reports_participants_tab_logic.dart';
import '../../widgets/responsive_admin_table.dart';
import 'reports_registered_participants_popup.dart';

/// Filter kind for the institutions participated popup.
enum InstitutionsListKind {
  all,
  schools,
  colleges,
  yogaCenters,
}

/// Popup showing institution rows from the competition report summary.
class ReportsInstitutionsDetailsPopup {
  ReportsInstitutionsDetailsPopup._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<Map<String, dynamic>> institutions,
    required InstitutionsListKind kind,
    required String competitionId,
    String? competitionName,
    String? yogaTeacherName,
    String? yogaTeacherCell,
  }) {
    final filtered = _filterByKind(institutions, kind);

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _InstitutionsDetailsDialog(
          title: title,
          competitionId: competitionId,
          competitionName: competitionName,
          kind: kind,
          institutions: filtered,
          yogaTeacherName: yogaTeacherName,
          yogaTeacherCell: yogaTeacherCell,
        );
      },
    );
  }

  static List<Map<String, dynamic>> _filterByKind(
    List<Map<String, dynamic>> institutions,
    InstitutionsListKind kind,
  ) {
    if (kind == InstitutionsListKind.all) {
      return List<Map<String, dynamic>>.from(institutions);
    }
    return institutions.where((row) {
      final type = (row['institutionType'] ?? '').toString().toUpperCase();
      switch (kind) {
        case InstitutionsListKind.schools:
          return type.contains('SCHOOL');
        case InstitutionsListKind.colleges:
          return type.contains('COLLEGE');
        case InstitutionsListKind.yogaCenters:
          return type.contains('YOGA');
        case InstitutionsListKind.all:
          return true;
      }
    }).toList();
  }
}

class _InstitutionsDetailsDialog extends StatefulWidget {
  const _InstitutionsDetailsDialog({
    required this.title,
    required this.competitionId,
    required this.kind,
    required this.institutions,
    this.competitionName,
    this.yogaTeacherName,
    this.yogaTeacherCell,
  });

  final String title;
  final String competitionId;
  final InstitutionsListKind kind;
  final String? competitionName;
  final List<Map<String, dynamic>> institutions;
  final String? yogaTeacherName;
  final String? yogaTeacherCell;

  @override
  State<_InstitutionsDetailsDialog> createState() =>
      _InstitutionsDetailsDialogState();
}

class _InstitutionsDetailsDialogState extends State<_InstitutionsDetailsDialog> {
  static const double _minTableWidth = 920;
  static const BorderSide _cellBorderSide = BorderSide(
    color: AppColors.border,
    width: 1,
  );

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  /// `true` = descending (highest first), `false` = ascending.
  bool _participantCountDesc = true;
  bool _downloadingPdf = false;

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

  String _addressAndLocation(Map<String, dynamic> row) {
    final address = (row['address'] ?? '').toString().trim();
    final location = (row['location'] ?? '').toString().trim();
    final parts = <String>[
      if (address.isNotEmpty) address,
      if (location.isNotEmpty) location,
    ];
    if (parts.isEmpty) return '—';
    return parts.join('\n');
  }

  List<Map<String, dynamic>> get _visibleRows {
    final q = _query.trim().toLowerCase();
    final list = q.isEmpty
        ? List<Map<String, dynamic>>.from(widget.institutions)
        : widget.institutions.where((row) {
            final name =
                (row['institutionName'] ?? '').toString().toLowerCase();
            final email = (row['emailId'] ?? '').toString().toLowerCase();
            final address = (row['address'] ?? '').toString().toLowerCase();
            final location = (row['location'] ?? '').toString().toLowerCase();
            final type =
                (row['institutionType'] ?? '').toString().toLowerCase();
            return name.contains(q) ||
                email.contains(q) ||
                address.contains(q) ||
                location.contains(q) ||
                type.contains(q);
          }).toList();

    list.sort((a, b) {
      final ac = (a['participantCount'] as num?)?.toInt() ?? 0;
      final bc = (b['participantCount'] as num?)?.toInt() ?? 0;
      return _participantCountDesc ? bc.compareTo(ac) : ac.compareTo(bc);
    });
    return list;
  }

  String? _kindApiValue() {
    switch (widget.kind) {
      case InstitutionsListKind.all:
        return null;
      case InstitutionsListKind.schools:
        return 'SCHOOL';
      case InstitutionsListKind.colleges:
        return 'COLLEGE';
      case InstitutionsListKind.yogaCenters:
        return 'YOGA_CENTER';
    }
  }

  Future<void> _downloadPdf() async {
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

    if (_visibleRows.isEmpty) {
      Get.snackbar(
        'Download',
        'No institutions to download.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _downloadingPdf = true);
    try {
      final resp = await ReportsRepository().getCompetitionInstitutionsPrintPdf(
        competitionId,
        institutionKind: _kindApiValue(),
        sortDesc: _participantCountDesc,
        search: _query.trim().isEmpty ? null : _query.trim(),
        title: widget.title,
      );

      if (!resp.success || resp.data == null || resp.data!.isEmpty) {
        Get.snackbar(
          'Download',
          resp.message ?? 'Failed to generate Institutions PDF',
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
      final filename =
          '${safeTitle.isEmpty ? 'institutions' : safeTitle}_$competitionId.pdf';

      await ReportsParticipantsTabLogic.downloadReportPdfBytes(
        resp.data!,
        filename,
      );
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }

  void _toggleParticipantCountSort() {
    setState(() => _participantCountDesc = !_participantCountDesc);
  }

  void _openInstitutionParticipants(Map<String, dynamic> row) {
    final institutionId = (row['institutionId'] as num?)?.toInt();
    if (institutionId == null || institutionId <= 0) {
      Get.snackbar(
        'Unavailable',
        'Institution id is missing for this row.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }
    if (widget.competitionId.trim().isEmpty) {
      Get.snackbar(
        'Competition required',
        'Select a competition first.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    final name = (row['institutionName'] ?? '').toString().trim();
    final teacherName = widget.yogaTeacherName?.trim() ?? '';
    final teacherCell = widget.yogaTeacherCell?.trim() ?? '';
    ReportsRegisteredParticipantsPopup.show(
      context,
      competitionId: widget.competitionId,
      preset: ReportsParticipantsListPreset.institution(
        institutionId,
        institutionName: name.isNotEmpty ? name : null,
        yogaTeacherName: teacherName.isEmpty ? null : teacherName,
        yogaTeacherCell: teacherCell.isEmpty ? null : teacherCell,
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

  Widget _participantCountHeader() {
    return Tooltip(
      message: _participantCountDesc
          ? 'Sorted high to low — click for ascending'
          : 'Sorted low to high — click for descending',
      child: InkWell(
        onTap: _toggleParticipantCountSort,
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
                      color: !_participantCountDesc
                          ? AppTheme.primaryColor
                          : AppTheme.sectionHeaderText()
                              .withValues(alpha: 0.35),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -6),
                      child: Icon(
                        Icons.arrow_drop_down,
                        size: 14,
                        color: _participantCountDesc
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
  }) {
    return SizedBox(
      width: width,
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
            flex: 26,
            child: _headerLabel('INSTITUTION NAME'),
          ),
          _headerExpanded(
            flex: 34,
            child: _headerLabel('ADDRESS AND LOCATION'),
          ),
          _headerExpanded(flex: 24, child: _headerLabel('EMAIL ID')),
          _headerCell(
            width: 120,
            last: true,
            align: TextAlign.center,
            child: _participantCountHeader(),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(Map<String, dynamic> row) {
    final name = _text(row['institutionName']);
    final count = (row['participantCount'] as num?)?.toInt() ?? 0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _bodyCell(
            width: 56,
            child: Align(
              alignment: Alignment.center,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  _initial(name),
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
            flex: 26,
            child: Text(
              name,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          _bodyExpanded(
            flex: 34,
            child: Text(
              _addressAndLocation(row),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
                height: 1.35,
              ),
            ),
          ),
          _bodyExpanded(
            flex: 24,
            child: Text(
              _text(row['emailId']),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          _bodyCell(
            width: 120,
            last: true,
            child: Align(
              alignment: Alignment.center,
              child: Tooltip(
                message: 'Click to view the participant',
                waitDuration: const Duration(milliseconds: 300),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: () => _openInstitutionParticipants(row),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor:
                              AppTheme.primaryColor.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
        math.min(isMobile ? mq.width - 24 : 1100.0, mq.width - 24);
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
                            '${rows.length} institution${rows.length == 1 ? '' : 's'}'
                            '${_query.trim().isNotEmpty && rows.length != widget.institutions.length ? ' (of ${widget.institutions.length})' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _downloadingPdf
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
                            tooltip: 'Download PDF',
                            onPressed: _downloadPdf,
                            icon: const Icon(Icons.print, color: Colors.white),
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                        ),
                        hintText:
                            'Search institution name, address, email...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: isMobile ? 12 : 10,
                        ),
                        suffixIcon: _query.trim().isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey[700],
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
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
                child: widget.institutions.isEmpty
                    ? Center(
                        child: Text(
                          'No institutions found for this filter.',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : rows.isEmpty
                        ? Center(
                            child: Text(
                              'No institutions match your search.',
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
                                          for (final row in rows)
                                            _dataRow(row),
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
