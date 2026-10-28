import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../controllers/reports_controller.dart';
import '../../controllers/reports_feedback_tab_controller.dart';
import '../../widgets/searchable_dropdown_field.dart';

class ReportsFeedbackTab extends StatelessWidget {
  const ReportsFeedbackTab({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = Get.put(
      ReportsFeedbackTabController(),
      permanent: false,
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Obx(() {
      final reports = Get.find<ReportsController>();
      final selectedCompetition =
          (reports.selectedCompetitionId.value ?? '').trim();
      if (!tabController.isApplicationAdmin &&
          int.tryParse(selectedCompetition) == null) {
        if (reports.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return const Center(
          child: Text('Select a competition to manage feedback.'),
        );
      }
      final waitingForCompetition = !tabController.isApplicationAdmin &&
          selectedCompetition.isNotEmpty &&
          tabController.loadedCompetitionId.value != selectedCompetition &&
          tabController.feedbacks.isEmpty;
      if (waitingForCompetition && !tabController.isLoading.value) {
        final competitionId = selectedCompetition;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!Get.isRegistered<ReportsFeedbackTabController>()) return;
          final current = Get.find<ReportsFeedbackTabController>();
          if (current.loadedCompetitionId.value == competitionId) return;
          current.load();
        });
      }
      final selectedOrg =
          tabController.reportsController.selectedOrganizationId.value ?? '';
      final waitingForOrganization = tabController.isApplicationAdmin &&
          selectedOrg.isNotEmpty &&
          tabController.loadedOrganizationId.value != selectedOrg;
      final waitingForFirstPayload = tabController.isLoading.value &&
          tabController.feedbacks.isEmpty &&
          tabController.competitionOptions.isEmpty;
      if ((tabController.isLoading.value && tabController.data.value == null) ||
          waitingForOrganization ||
          waitingForCompetition ||
          waitingForFirstPayload) {
        return const Center(child: CircularProgressIndicator());
      }
      if (tabController.error.value.isNotEmpty &&
          tabController.data.value == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 12),
                Text(
                  tabController.error.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[700]),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: tabController.load,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      final rows = tabController.visibleFeedbacks;
      final canManage = tabController.canManage;

      return RefreshIndicator(
        onRefresh: tabController.load,
        child: _VisibleScrollbar(
          child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            isMobile ? 12 : 16,
            isMobile ? 12 : 16,
            isMobile ? 12 : 16,
            28,
          ),
          children: [
            if (tabController.isLoading.value)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            _HeaderCard(
              isMobile: isMobile,
              canManage: canManage,
              saving: tabController.isSaving.value,
              count: rows.length,
              onNew: () => _openFeedbackDialog(context, tabController),
            ),
            const SizedBox(height: 14),
            _FilterRow(
              controller: tabController,
              isMobile: isMobile,
            ),
            const SizedBox(height: 14),
            if (rows.isEmpty)
              _EmptyState(
                canManage: canManage,
                onNew: tabController.isSaving.value
                    ? null
                    : () => _openFeedbackDialog(context, tabController),
              )
            else
              _FeedbackTable(
                rows: rows,
                canManage: canManage,
                isMobile: isMobile,
                controller: tabController,
              ),
          ],
          ),
        ),
      );
    });
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.isMobile,
    required this.canManage,
    required this.saving,
    required this.count,
    required this.onNew,
  });

  final bool isMobile;
  final bool canManage;
  final bool saving;
  final int count;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Feedback report',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                if (canManage)
                  FilledButton.icon(
                    onPressed: saving ? null : onNew,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New feedback'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              canManage
                  ? 'Submit feedback for a competition. Application Admin sees every feedback you create.'
                  : 'Feedback submitted by organizers for the selected organization.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 14),
            _StatChip(label: 'Feedback', value: '$count'),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
          children: [
            TextSpan(text: '$label  '),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.controller, required this.isMobile});

  final ReportsFeedbackTabController controller;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final types = controller.types;
    final typeItems = [
      const SearchableDropdownItem(value: '', label: 'All types'),
      ...types.map(
        (type) => SearchableDropdownItem(
          value: type['value'] ?? '',
          label: type['label'] ?? '',
        ),
      ),
    ];

    final typeField = SearchableDropdownField(
      items: typeItems.where((item) => item.value.isNotEmpty).toList(),
      emptyOptionLabel: 'All types',
      emptyOptionValue: '',
      selectedValue: controller.typeFilter.value,
      labelText: 'Type',
      hintText: 'All types',
      searchHint: 'Search type...',
      emptyListMessage: 'No types found',
      onChanged: (value) => controller.typeFilter.value = value,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 320,
              ),
              child: typeField,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _ExcelDownloadButton(controller: controller),
      ],
    );
  }
}

class _ExcelDownloadButton extends StatelessWidget {
  const _ExcelDownloadButton({required this.controller});

  final ReportsFeedbackTabController controller;

  @override
  Widget build(BuildContext context) {
    final downloading = controller.isDownloading.value;
    return Tooltip(
      message: 'Download Excel',
      child: Material(
        color: downloading
            ? const Color(0xFF217346).withValues(alpha: 0.7)
            : const Color(0xFF217346),
        borderRadius: BorderRadius.circular(8),
        elevation: 0,
        child: InkWell(
          onTap: downloading ? null : controller.downloadExcel,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 40,
            height: 40,
            child: downloading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Center(
                    child: Text(
                      'X',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.canManage, required this.onNew});

  final bool canManage;
  final VoidCallback? onNew;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, size: 40, color: Colors.grey.shade500),
            const SizedBox(height: 10),
            Text(
              canManage
                  ? 'No feedback for this competition yet.'
                  : 'No feedback for this organization.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            if (canManage) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onNew,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New feedback'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackTable extends StatelessWidget {
  const _FeedbackTable({
    required this.rows,
    required this.canManage,
    required this.isMobile,
    required this.controller,
  });

  final List<Map<String, dynamic>> rows;
  final bool canManage;
  final bool isMobile;
  final ReportsFeedbackTabController controller;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _FeedbackCard(
              index: i + 1,
              row: rows[i],
              canManage: canManage,
              controller: controller,
            ),
            if (i != rows.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Fill the card. Scroll only when the window is narrower than the
          // columns need.
          const minTableWidth = 1100.0;
          final tableWidth = constraints.maxWidth < minTableWidth
              ? minTableWidth
              : constraints.maxWidth;
          return _VisibleScrollbar(
            axis: Axis.horizontal,
            child: SingleChildScrollView(
            primary: true,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(Colors.grey.shade50),
                dataRowMinHeight: 56,
                dataRowMaxHeight: 88,
                columnSpacing: 18,
                horizontalMargin: 16,
                columns: [
                  _centeredColumn(
                    'S.No',
                    columnWidth: const FixedColumnWidth(56),
                  ),
                  _centeredColumn(
                    'Competition',
                    columnWidth: const FlexColumnWidth(1.5),
                  ),
                  _centeredColumn(
                    'Type',
                    columnWidth: const FixedColumnWidth(130),
                  ),
                  _centeredColumn(
                    'Feedback',
                    columnWidth: const FlexColumnWidth(2.6),
                  ),
                  if (!canManage)
                    _centeredColumn(
                      'Organizer',
                      columnWidth: const FlexColumnWidth(1.1),
                    ),
                  _centeredColumn(
                    'Date',
                    columnWidth: const FixedColumnWidth(188),
                  ),
                  if (!canManage)
                    _centeredColumn(
                      'View',
                      columnWidth: const FixedColumnWidth(72),
                    ),
                  if (canManage)
                    _centeredColumn(
                      'Actions',
                      columnWidth: const FixedColumnWidth(108),
                    ),
                ],
                rows: [
                  for (var i = 0; i < rows.length; i++)
                    DataRow(
                      cells: [
                        DataCell(_centeredCell(Text('${i + 1}'))),
                        DataCell(_centeredCell(Text(
                          (rows[i]['competitionName'] ?? '').toString(),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ))),
                        DataCell(_centeredCell(_TypeChip(
                          label: (rows[i]['typeLabel'] ?? rows[i]['type'] ?? '')
                              .toString(),
                        ))),
                        DataCell(
                          _centeredCell(Text(
                            (rows[i]['message'] ?? '').toString(),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          )),
                          onTap: () => _showFeedbackDetails(context, rows[i]),
                        ),
                        if (!canManage)
                          DataCell(_centeredCell(Text(
                            (rows[i]['createdByName'] ?? '').toString(),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ))),
                        DataCell(_centeredCell(Text(
                          (rows[i]['createdAt'] ?? '').toString(),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ))),
                        if (!canManage)
                          DataCell(
                            _centeredCell(
                              IconButton(
                                tooltip: 'View feedback',
                                visualDensity: VisualDensity.compact,
                                onPressed: () =>
                                    _showFeedbackDetails(context, rows[i]),
                                icon: Icon(
                                  Icons.visibility_outlined,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        if (canManage)
                          DataCell(_centeredCell(
                            _RowActions(row: rows[i], controller: controller),
                          )),
                      ],
                    ),
                ],
              ),
            ),
            ),
          );
        },
      ),
    );
  }
}

class _VisibleScrollbar extends StatefulWidget {
  const _VisibleScrollbar({
    required this.child,
    this.axis = Axis.vertical,
  });

  final Widget child;
  final Axis axis;

  @override
  State<_VisibleScrollbar> createState() => _VisibleScrollbarState();
}

class _VisibleScrollbarState extends State<_VisibleScrollbar> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      trackVisibility: true,
      notificationPredicate: (notification) =>
          notification.metrics.axis == widget.axis,
      child: PrimaryScrollController(
        controller: _controller,
        child: widget.child,
      ),
    );
  }
}

DataColumn _centeredColumn(String label, {required TableColumnWidth columnWidth}) {
  return DataColumn(
    columnWidth: columnWidth,
    headingRowAlignment: MainAxisAlignment.center,
    label: Expanded(
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
}

Widget _centeredCell(Widget child) {
  return SizedBox(
    width: double.infinity,
    child: Align(
      alignment: Alignment.center,
      child: child,
    ),
  );
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.index,
    required this.row,
    required this.canManage,
    required this.controller,
  });

  final int index;
  final Map<String, dynamic> row;
  final bool canManage;
  final ReportsFeedbackTabController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$index',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: (row['typeLabel'] ?? row['type'] ?? '').toString(),
                ),
                const Spacer(),
                if (canManage) _RowActions(row: row, controller: controller),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              (row['competitionName'] ?? '').toString(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (!canManage) ...[
              const SizedBox(height: 4),
              Text(
                (row['createdByName'] ?? '').toString(),
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
            ],
            const SizedBox(height: 8),
            Text((row['message'] ?? '').toString()),
            const SizedBox(height: 8),
            Text(
              (row['createdAt'] ?? '').toString(),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({required this.row, required this.controller});

  final Map<String, dynamic> row;
  final ReportsFeedbackTabController controller;

  @override
  Widget build(BuildContext context) {
    final saving = controller.isSaving.value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Edit',
          visualDensity: VisualDensity.compact,
          onPressed: saving
              ? null
              : () => _openFeedbackDialog(
                    context,
                    controller,
                    existing: row,
                  ),
          icon: Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
        ),
        IconButton(
          tooltip: 'Delete',
          visualDensity: VisualDensity.compact,
          onPressed: saving ? null : () => _confirmDelete(context, controller, row),
          icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
        ),
      ],
    );
  }
}

void _showFeedbackDetails(BuildContext context, Map<String, dynamic> row) {
  final competition = (row['competitionName'] ?? '').toString();
  final type = (row['typeLabel'] ?? row['type'] ?? '').toString();
  final organizer = (row['createdByName'] ?? '').toString();
  final date = (row['createdAt'] ?? '').toString();
  final message = (row['message'] ?? '').toString();

  showDialog<void>(
    context: context,
    builder: (ctx) {
      final width = MediaQuery.sizeOf(ctx).width;
      return AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Feedback',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(ctx).pop(),
              icon: Icon(Icons.close, color: Colors.grey.shade700),
            ),
          ],
        ),
        content: SizedBox(
          width: width < 640 ? width : 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (competition.isNotEmpty)
                  _detailLine('Competition', competition),
                if (type.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Type',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _TypeChip(label: type),
                ],
                if (organizer.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _detailLine('Organizer', organizer),
                ],
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _detailLine('Date', date),
                ],
                const SizedBox(height: 14),
                Text(
                  'Feedback',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(
                    message.isEmpty ? '—' : message,
                    style: const TextStyle(fontSize: 14, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

Widget _detailLine(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
        ),
      ),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  ReportsFeedbackTabController controller,
  Map<String, dynamic> row,
) async {
  final id = int.tryParse('${row['id']}');
  if (id == null) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete feedback'),
      content: const Text(
        'This removes the feedback. Application Admin will no longer see it.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await controller.deleteFeedback(id);
  }
}

Future<void> _openFeedbackDialog(
  BuildContext context,
  ReportsFeedbackTabController controller, {
  Map<String, dynamic>? existing,
}) async {
  final competitions = controller.reportsController.competitions
      .where((c) => (c.id ?? '').isNotEmpty)
      .toList();
  var competitionId = existing?['competitionId']?.toString() ??
      controller.reportsController.selectedCompetitionId.value ??
      '';
  if (competitionId.isEmpty && competitions.isNotEmpty) {
    competitionId = competitions.first.id ?? '';
  }
  var type = (existing?['type'] ?? '').toString();
  final messageCtrl = TextEditingController(
    text: (existing?['message'] ?? '').toString(),
  );

  try {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final screenWidth = MediaQuery.of(ctx).size.width;
            final isNarrow = screenWidth < 640;
            final dialogWidth =
                isNarrow ? (screenWidth - 48).clamp(280.0, 560.0) : 560.0;
            final saving = controller.isSaving.value;

            Future<void> save() async {
              final selectedCompetition = int.tryParse(competitionId);
              if (selectedCompetition == null) {
                SnackbarHelper.showError(ctx, 'Select a competition');
                return;
              }
              if (type.trim().isEmpty) {
                SnackbarHelper.showError(ctx, 'Select a type');
                return;
              }
              if (messageCtrl.text.trim().isEmpty) {
                SnackbarHelper.showError(ctx, 'Enter feedback');
                return;
              }
              final feedbackId = existing == null
                  ? null
                  : int.tryParse('${existing['id']}');
              final ok = await controller.saveFeedback(
                feedbackId: feedbackId,
                competitionId: selectedCompetition,
                type: type,
                message: messageCtrl.text,
              );
              if (ok && ctx.mounted) Navigator.of(ctx).pop();
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 16 : 32,
                vertical: 24,
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      existing == null ? 'New feedback' : 'Edit feedback',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: Icon(Icons.close, color: Colors.grey.shade700),
                  ),
                ],
              ),
              content: SizedBox(
                width: dialogWidth,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SearchableDropdownField(
                        items: competitions
                            .map(
                              (c) => SearchableDropdownItem(
                                value: c.id!,
                                label: c.competitionName,
                              ),
                            )
                            .toList(),
                        selectedValue: competitionId,
                        labelText: 'Competition',
                        hintText: 'Select competition',
                        searchHint: 'Search competition...',
                        emptyListMessage: 'No competitions found',
                        onChanged: (value) =>
                            setState(() => competitionId = value),
                      ),
                      const SizedBox(height: 14),
                      SearchableDropdownField(
                        items: controller.types
                            .map(
                              (item) => SearchableDropdownItem(
                                value: item['value'] ?? '',
                                label: item['label'] ?? '',
                              ),
                            )
                            .toList(),
                        selectedValue: type,
                        labelText: 'Type',
                        hintText: 'Select type',
                        searchHint: 'Search type...',
                        emptyListMessage: 'No types found',
                        onChanged: (value) => setState(() => type = value),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: messageCtrl,
                        minLines: 4,
                        maxLines: 6,
                        maxLength: 2000,
                        decoration: InputDecoration(
                          labelText: 'Feedback',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving ? null : save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(existing == null ? 'Save' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    messageCtrl.dispose();
  }
}
