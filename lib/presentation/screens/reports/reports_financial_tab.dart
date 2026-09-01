import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/storage_service.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/constants/app_constants.dart';
import '../../controllers/reports_financial_tab_controller.dart';
import '../../controllers/reports_participants_tab_logic.dart';

class ReportsFinancialTab extends StatelessWidget {
  const ReportsFinancialTab({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = Get.put(
      ReportsFinancialTabController(),
      permanent: false,
    );
    final isMobile = MediaQuery.of(context).size.width < 600;
    final money = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Obx(() {
      if (tabController.isLoading.value && tabController.report.value == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (tabController.error.value.isNotEmpty &&
          tabController.report.value == null) {
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

      final report = tabController.report.value;
      if (report == null) {
        return const Center(
          child: Text('Select a competition to view the financial report.'),
        );
      }

      final lines = (report['lines'] as List?) ?? const [];
      final transfers = (report['transfers'] as List?) ?? const [];
      final withTotal = _asDouble(report['withTotal'] ?? report['organizerTotal']);
      final feeTotal = _asDouble(report['feeTotal']);
      final withoutTotal = _asDouble(
        report['withoutTotal'] ?? report['organizerTotal'],
      );
      final organizerTotal = withoutTotal;
      final transferredTotal = _asDouble(report['transferredTotal']);
      final pending = _asDouble(report['pending']);

      return RefreshIndicator(
        onRefresh: tabController.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          children: [
            _HeaderCard(report: report, isMobile: isMobile),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: _SectionTitle('Registration summary')),
                IconButton(
                  tooltip: 'Print financial report',
                  onPressed: tabController.isPrinting.value
                      ? null
                      : () async {
                          final bytes = await tabController.printPdf();
                          if (bytes == null) return;
                          final id = tabController.competitionId;
                          await ReportsParticipantsTabLogic
                              .downloadReportPdfBytes(
                            bytes,
                            'financial_report_${id ?? 'report'}.pdf',
                          );
                        },
                  icon: tabController.isPrinting.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.print, color: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _RegistrationTable(
              lines: lines
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList(),
              withTotal: withTotal,
              feeTotal: feeTotal,
              withoutTotal: withoutTotal,
              money: money,
              isMobile: isMobile,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: _SectionTitle('Transferred from CYS')),
                TextButton.icon(
                  onPressed: tabController.isSaving.value
                      ? null
                      : () => _openTransferDialog(context, tabController),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add transfer'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _TransfersTable(
              transfers: transfers
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList(),
              transferredTotal: transferredTotal,
              money: money,
              isMobile: isMobile,
              controller: tabController,
            ),
            const SizedBox(height: 20),
            _PendingCard(
              organizerTotal: organizerTotal,
              transferredTotal: transferredTotal,
              pending: pending,
              money: money,
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.report, required this.isMobile});
  final Map<String, dynamic> report;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final name = report['competitionName']?.toString() ?? '-';
    final date = report['eventDate']?.toString() ?? '-';
    final year = report['year']?.toString() ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentSoft(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentBorder()),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Competition Name', name),
                const SizedBox(height: 8),
                _kv('Date', date),
                const SizedBox(height: 8),
                _kv('Year', year),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 3, child: _kv('Competition Name', name)),
                Expanded(child: _kv('Date', date)),
                Expanded(child: _kv('Year', year)),
              ],
            ),
    );
  }

  Widget _kv(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _RegistrationTable extends StatelessWidget {
  const _RegistrationTable({
    required this.lines,
    required this.withTotal,
    required this.feeTotal,
    required this.withoutTotal,
    required this.money,
    required this.isMobile,
  });

  final List<Map<String, dynamic>> lines;
  final double withTotal;
  final double feeTotal;
  final double withoutTotal;
  final NumberFormat money;
  final bool isMobile;

  static const double _tableMinWidth = 980;
  static const double _snoW = 56;
  static const double _participantsW = 100;
  static const double _channelW = 100;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const Text('No registrations found for this competition.');
    }

    final headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: Colors.grey.shade800,
    );
    final cellStyle = const TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
    final borderColor = Colors.grey.shade300;
    final headerBg = AppTheme.accentSoft(0.15);
    final totalBg = AppTheme.accentSoft(0.08);

    Widget moneyCell(double value, {bool emphasize = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(
            money.format(value),
            textAlign: TextAlign.center,
            style: cellStyle.copyWith(
              fontWeight: FontWeight.w800,
              color: emphasize ? AppTheme.accent : null,
              fontSize: emphasize ? 13.5 : 13,
            ),
          ),
        );

    Widget textCell(String text, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: cellStyle.copyWith(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        );

    TableRow dataRow({
      required List<Widget> cells,
      Color? color,
    }) {
      return TableRow(
        decoration: color == null ? null : BoxDecoration(color: color),
        children: cells,
      );
    }

    final bodyRows = <TableRow>[
      ...lines.map((line) {
        final channel = (line['channel']?.toString() ?? '').toUpperCase();
        final participants = line['participants'] ?? 0;
        final withAmt = ReportsFinancialTab._asDouble(
          line['withTotal'] ?? line['totalAmount'],
        );
        final feeAmt = ReportsFinancialTab._asDouble(line['feeTotal']);
        final withoutAmt = ReportsFinancialTab._asDouble(
          line['withoutTotal'] ?? line['totalAmount'],
        );
        return dataRow(
          cells: [
            textCell('${line['sno'] ?? ''}'),
            textCell(line['categoryName']?.toString() ?? '-'),
            textCell('$participants'),
            textCell(channel == 'SPOT' ? 'Spot' : 'Online'),
            moneyCell(withAmt),
            moneyCell(feeAmt),
            moneyCell(withoutAmt),
          ],
        );
      }),
      dataRow(
        color: totalBg,
        cells: [
          textCell(''),
          textCell(''),
          textCell(''),
          textCell('Total', bold: true),
          moneyCell(withTotal, emphasize: true),
          moneyCell(feeTotal, emphasize: true),
          moneyCell(withoutTotal, emphasize: true),
        ],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(_tableMinWidth, double.infinity)
            : _tableMinWidth;
        final tableWidth = width < _tableMinWidth ? _tableMinWidth : width;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              children: [
                // Grouped header
                Container(
                  decoration: BoxDecoration(
                    color: headerBg,
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _headerBox('S.No', width: _snoW, style: headerStyle, borderColor: borderColor),
                            _headerBox('Category', flex: 2, style: headerStyle, borderColor: borderColor),
                            _headerBox('Participants', width: _participantsW, style: headerStyle, borderColor: borderColor),
                            _headerBox('Online/Spot', width: _channelW, style: headerStyle, borderColor: borderColor),
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(color: borderColor),
                                      ),
                                    ),
                                    child: Text(
                                      'Amount Details',
                                      textAlign: TextAlign.center,
                                      style: headerStyle.copyWith(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _headerBox(
                                          'with fee',
                                          flex: 1,
                                          style: headerStyle,
                                          borderColor: borderColor,
                                          bottomBorder: false,
                                        ),
                                        _headerBox(
                                          'Fee total',
                                          flex: 1,
                                          style: headerStyle,
                                          borderColor: borderColor,
                                          bottomBorder: false,
                                        ),
                                        _headerBox(
                                          'without fee',
                                          flex: 1,
                                          style: headerStyle,
                                          borderColor: borderColor,
                                          bottomBorder: false,
                                          rightBorder: false,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Table(
                  columnWidths: const {
                    0: FixedColumnWidth(_snoW),
                    1: FlexColumnWidth(2),
                    2: FixedColumnWidth(_participantsW),
                    3: FixedColumnWidth(_channelW),
                    4: FlexColumnWidth(1),
                    5: FlexColumnWidth(1),
                    6: FlexColumnWidth(1),
                  },
                  border: TableBorder(
                    left: BorderSide(color: borderColor),
                    right: BorderSide(color: borderColor),
                    bottom: BorderSide(color: borderColor),
                    horizontalInside: BorderSide(color: Colors.grey.shade200),
                    verticalInside: BorderSide(color: Colors.grey.shade200),
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: bodyRows,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _headerBox(
    String text, {
    double? width,
    int? flex,
    required TextStyle style,
    required Color borderColor,
    bool bottomBorder = true,
    bool rightBorder = true,
  }) {
    final child = Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          right: rightBorder ? BorderSide(color: borderColor) : BorderSide.none,
          bottom: bottomBorder ? BorderSide(color: borderColor) : BorderSide.none,
        ),
      ),
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
    if (flex != null) {
      return Expanded(flex: flex, child: child);
    }
    return child;
  }
}

class _TransfersTable extends StatelessWidget {
  const _TransfersTable({
    required this.transfers,
    required this.transferredTotal,
    required this.money,
    required this.isMobile,
    required this.controller,
  });

  final List<Map<String, dynamic>> transfers;
  final double transferredTotal;
  final NumberFormat money;
  final bool isMobile;
  final ReportsFinancialTabController controller;

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) {
      return const Text('No CYS transfers recorded yet.');
    }

    final borderColor = Colors.grey.shade300;
    final headerBg = AppTheme.accentSoft(0.15);
    final headerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: Colors.grey.shade800,
    );

    Widget header(String text, {TextAlign align = TextAlign.left}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          color: headerBg,
          alignment: align == TextAlign.center
              ? Alignment.center
              : Alignment.centerLeft,
          child: Text(text, textAlign: align, style: headerStyle),
        );

    Widget cell(Widget child, {Alignment align = Alignment.centerLeft}) =>
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          alignment: align,
          child: child,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final minWidth = isMobile ? 700.0 : 760.0;
        final tableWidth = available < minWidth ? minWidth : available;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Table(
              border: TableBorder.all(color: borderColor),
              columnWidths: const {
                0: FixedColumnWidth(56),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.6),
                3: FixedColumnWidth(90),
                4: FixedColumnWidth(110),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  children: [
                    header('S.No', align: TextAlign.center),
                    header('Transferred from CYS'),
                    header('Reference number & Date'),
                    header('Screenshot', align: TextAlign.center),
                    header('Actions', align: TextAlign.center),
                  ],
                ),
                ...transfers.map((t) {
                  final amount = ReportsFinancialTab._asDouble(t['amount']);
                  final ref = t['referenceNumber']?.toString() ?? '-';
                  final date = t['transferDate']?.toString() ?? '-';
                  final url = controller.screenshotUrlFor(t);
                  return TableRow(
                    children: [
                      cell(
                        Text('${t['sno'] ?? ''}', textAlign: TextAlign.center),
                        align: Alignment.center,
                      ),
                      cell(Text(money.format(amount))),
                      cell(
                        Text(
                          '$ref\n$date',
                          style: const TextStyle(height: 1.25),
                        ),
                      ),
                      cell(
                        url == null
                            ? const Text('-')
                            : IconButton(
                                tooltip: 'View screenshot',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                icon: Icon(
                                  Icons.visibility,
                                  color: AppTheme.primaryColor,
                                  size: 22,
                                ),
                                onPressed: () => _previewImage(context, url),
                              ),
                        align: Alignment.center,
                      ),
                      cell(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _openTransferDialog(
                                context,
                                controller,
                                existing: t,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red.shade400,
                              ),
                              onPressed: () async {
                                final id = t['id'];
                                final tid = id is int
                                    ? id
                                    : int.tryParse(id?.toString() ?? '');
                                if (tid == null) return;
                                final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogCtx) => AlertDialog(
                                        title: const Text('Delete transfer?'),
                                        content: const Text(
                                          'This will remove the transfer from the financial report.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              dialogCtx,
                                            ).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              dialogCtx,
                                            ).pop(true),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Colors.red.shade700,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                                if (ok) await controller.deleteTransfer(tid);
                              },
                            ),
                          ],
                        ),
                        align: Alignment.center,
                      ),
                    ],
                  );
                }),
                TableRow(
                  decoration: BoxDecoration(color: AppTheme.accentSoft(0.08)),
                  children: [
                    cell(const SizedBox.shrink()),
                    cell(
                      Text(
                        'Total  ${money.format(transferredTotal)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                    cell(const SizedBox.shrink()),
                    cell(const SizedBox.shrink()),
                    cell(const SizedBox.shrink()),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.organizerTotal,
    required this.transferredTotal,
    required this.pending,
    required this.money,
  });

  final double organizerTotal;
  final double transferredTotal;
  final double pending;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pending',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Organizer amount / Without total (${money.format(organizerTotal)}) − Total of Transferred (${money.format(transferredTotal)})',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),
          Text(
            money.format(pending),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: pending > 0 ? Colors.orange.shade800 : AppTheme.accent,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openTransferDialog(
  BuildContext context,
  ReportsFinancialTabController controller, {
  Map<String, dynamic>? existing,
}) async {
  final amountCtrl = TextEditingController(
    text: existing == null
        ? ''
        : ReportsFinancialTab._asDouble(existing['amount']).toStringAsFixed(2),
  );
  final refCtrl = TextEditingController(
    text: existing?['referenceNumber']?.toString() ?? '',
  );
  DateTime? transferDate;
  final dateRaw = existing?['transferDate']?.toString();
  if (dateRaw != null && dateRaw.isNotEmpty) {
    transferDate = DateTime.tryParse(dateRaw);
  }
  transferDate ??= DateTime.now();
  Uint8List? screenshotBytes;
  String? screenshotFilename;
  var clearScreenshot = false;
  final existingUrl =
      existing == null ? null : controller.screenshotUrlFor(existing);

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text(existing == null ? 'Add transfer' : 'Edit transfer'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Line 1: Amount + Reference number
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                              TextInputFormatter.withFunction(
                                (oldValue, newValue) {
                                  final text = newValue.text;
                                  if (text.isEmpty) return newValue;
                                  if (RegExp(r'^\d+(\.\d{0,2})?$')
                                      .hasMatch(text)) {
                                    return newValue;
                                  }
                                  return oldValue;
                                },
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Amount (₹)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: refCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Reference number',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Line 2: Date + Screenshot
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: transferDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() => transferDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                border: OutlineInputBorder(),
                                isDense: true,
                                suffixIcon: Icon(Icons.calendar_today, size: 18),
                              ),
                              child: Text(
                                DateFormat('yyyy-MM-dd').format(transferDate!),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    try {
                                      final result =
                                          await FilePicker.pickFiles(
                                        type: FileType.image,
                                        allowMultiple: false,
                                        withData: true,
                                      );
                                      if (result == null ||
                                          result.files.isEmpty) {
                                        return;
                                      }
                                      final file = result.files.first;
                                      final bytes =
                                          await _readPickedImageBytes(file);
                                      if (bytes == null || bytes.isEmpty) {
                                        if (ctx.mounted) {
                                          SnackbarHelper.showError(
                                            ctx,
                                            'Could not read the selected image. Please try again.',
                                          );
                                        }
                                        return;
                                      }
                                      setState(() {
                                        screenshotBytes = bytes;
                                        screenshotFilename =
                                            file.name.trim().isEmpty
                                                ? 'screenshot.jpg'
                                                : file.name.trim();
                                        clearScreenshot = false;
                                      });
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        SnackbarHelper.showError(
                                          ctx,
                                          'Failed to pick screenshot: $e',
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.upload_file, size: 18),
                                  label: Text(
                                    screenshotBytes != null ||
                                            (existingUrl != null &&
                                                !clearScreenshot)
                                        ? 'Screenshot'
                                        : 'Screenshot',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              if (screenshotBytes != null ||
                                  (existingUrl != null &&
                                      !clearScreenshot)) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  tooltip: 'View screenshot',
                                  icon: Icon(
                                    Icons.visibility,
                                    color: AppTheme.primaryColor,
                                  ),
                                  onPressed: () {
                                    if (screenshotBytes != null) {
                                      _previewImageBytes(
                                        ctx,
                                        screenshotBytes!,
                                      );
                                    } else if (existingUrl != null) {
                                      _previewImage(ctx, existingUrl);
                                    }
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Remove screenshot',
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.red.shade400,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (screenshotBytes != null) {
                                        screenshotBytes = null;
                                        screenshotFilename = null;
                                      } else {
                                        clearScreenshot = true;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (clearScreenshot &&
                        existingUrl != null &&
                        screenshotBytes == null) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () =>
                              setState(() => clearScreenshot = false),
                          child: const Text('Undo remove screenshot'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: controller.isSaving.value
                    ? null
                    : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              Obx(() {
                final saving = controller.isSaving.value;
                return ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final amount =
                              double.tryParse(amountCtrl.text.trim());
                          if (amount == null || amount <= 0) {
                            SnackbarHelper.showError(
                              ctx,
                              'Enter a valid amount',
                            );
                            return;
                          }
                          final transferId = existing == null
                              ? null
                              : (existing['id'] is int
                                  ? existing['id'] as int
                                  : int.tryParse(
                                      existing['id']?.toString() ?? '',
                                    ));
                          final ok = await controller.saveTransfer(
                            transferId: transferId,
                            amount: amount,
                            referenceNumber: refCtrl.text.trim(),
                            transferDate: transferDate,
                            screenshotBytes: screenshotBytes,
                            screenshotFilename: screenshotFilename,
                            clearScreenshot: clearScreenshot,
                          );
                          if (ok && ctx.mounted) {
                            Navigator.of(ctx).pop();
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                );
              }),
            ],
          );
        },
      );
    },
  );
}

Map<String, String> _authHeaders() {
  final token = StorageService.getString(AppConstants.tokenKey);
  if (token == null || token.isEmpty) return const {};
  return {'Authorization': 'Bearer $token'};
}

Future<Uint8List?> _readPickedImageBytes(PlatformFile file) async {
  final direct = file.bytes;
  if (direct != null && direct.isNotEmpty) return direct;
  try {
    final fromXFile = await file.xFile.readAsBytes();
    if (fromXFile.isNotEmpty) return fromXFile;
  } catch (_) {}
  return null;
}

void _previewImageBytes(BuildContext context, Uint8List bytes) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      child: InteractiveViewer(
        child: Image.memory(bytes),
      ),
    ),
  );
}

void _previewImage(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      child: InteractiveViewer(
        child: Image.network(
          url,
          headers: _authHeaders(),
          errorBuilder: (_, __, ___) => const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Could not load screenshot'),
          ),
        ),
      ),
    ),
  );
}
