import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../controllers/reports_amount_request_tab_controller.dart';

class ReportsAmountRequestTab extends StatelessWidget {
  const ReportsAmountRequestTab({super.key});

  static double asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool isPaid(Map<String, dynamic> request) {
    if (request['hasTransfer'] == true) return true;
    final transferId = request['transferId'];
    if (transferId == null) return false;
    if (transferId is num) return true;
    return int.tryParse(transferId.toString()) != null;
  }

  /// PENDING, PARTIAL, or PAID.
  /// Partially paid only when the paid amount is below the request amount.
  static String paymentStatus(Map<String, dynamic> request) {
    final requestAmt = asDouble(request['requestAmount']);
    final paidAmt = paidAmount(request);
    if (paidAmt <= 0.009) return 'PENDING';
    if (paidAmt + 0.009 < requestAmt) return 'PARTIAL';
    return 'PAID';
  }

  static double paidAmount(Map<String, dynamic> request) {
    if (request.containsKey('paidAmount') && request['paidAmount'] != null) {
      return asDouble(request['paidAmount']);
    }
    return isPaid(request) ? asDouble(request['requestAmount']) : 0;
  }

  @override
  Widget build(BuildContext context) {
    final tabController = Get.put(
      ReportsAmountRequestTabController(),
      permanent: false,
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isCompact = screenWidth < 900;
    final money = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Obx(() {
      if (tabController.competitionId == null) {
        return const Center(
          child: Text('Select a competition to manage amount requests.'),
        );
      }
      if (tabController.isLoading.value && tabController.data.value == null) {
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

      final report = tabController.data.value ?? const <String, dynamic>{};
      final requests = ((report['amountRequests'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final organizerTotal = asDouble(report['organizerTotal']);
      final pending = asDouble(report['pending']);
      final detailLines = ((report['lines'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final defaultFrom = (report['defaultFromParty'] ?? 'CYS').toString();
      final defaultTo = (report['defaultToParty'] ?? '').toString();

      void openCreate() {
        _openAmountRequestDialog(
          context,
          tabController,
          defaultFrom: defaultFrom,
          defaultTo: defaultTo,
          defaultTotalAmount: pending > 0 ? pending : 0,
          defaultRequestAmount: pending > 0 ? pending : 0,
        );
      }

      return RefreshIndicator(
        onRefresh: tabController.load,
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
              money: money,
              organizerTotal: organizerTotal,
              pending: pending,
              requestCount: requests.length,
              saving: tabController.isSaving.value,
              onNewRequest: openCreate,
            ),
            if (detailLines.isNotEmpty) ...[
              const SizedBox(height: 14),
              _CategoryAmountDetails(
                lines: detailLines,
                money: money,
                organizerTotal: organizerTotal,
              ),
            ],
            const SizedBox(height: 14),
            if (requests.isEmpty)
              _EmptyState(onNewRequest: tabController.isSaving.value
                  ? null
                  : openCreate)
            else
              _RequestTable(
                requests: requests,
                money: money,
                isCompact: isCompact,
                controller: tabController,
                defaultFrom: defaultFrom,
                defaultTo: defaultTo,
                defaultTotalAmount: pending > 0 ? pending : 0,
                defaultRequestAmount: pending > 0 ? pending : 0,
              ),
          ],
        ),
      );
    });
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.isMobile,
    required this.money,
    required this.organizerTotal,
    required this.pending,
    required this.requestCount,
    required this.saving,
    required this.onNewRequest,
  });

  final bool isMobile;
  final NumberFormat money;
  final double organizerTotal;
  final double pending;
  final int requestCount;
  final bool saving;
  final VoidCallback onNewRequest;

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
                  'Organizer amount request',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : onNewRequest,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New request'),
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
              'Raise a request for this competition. Application Admin sees it and records the payment. After it is paid, you cannot edit or delete it.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatChip(
                  label: 'Organizer amount',
                  value: money.format(organizerTotal),
                ),
                _StatChip(
                  label: 'Still pending',
                  value: money.format(pending),
                  emphasize: pending > 0.009,
                ),
                _StatChip(
                  label: 'Requests',
                  value: '$requestCount',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final color = emphasize ? const Color(0xFFE65100) : AppTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: emphasize ? const Color(0xFFFFF8F1) : AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryAmountDetails extends StatelessWidget {
  const _CategoryAmountDetails({
    required this.lines,
    required this.money,
    required this.organizerTotal,
  });

  final List<Map<String, dynamic>> lines;
  final NumberFormat money;
  final double organizerTotal;

  static String _feeTypeLabel(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'EARLY_BIRD':
        return 'Early Bird';
      case 'BULK_DISCOUNT':
        return 'Group discount';
      case 'SPOT':
        return 'Spot';
      case 'NORMAL':
      case 'ONLINE':
        return 'Online';
      default:
        return raw == null || raw.trim().isEmpty ? 'Online' : raw.trim();
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Map<String, dynamic>>>{};
    final order = <String>[];
    for (final line in lines) {
      final name = (line['categoryName']?.toString().trim().isNotEmpty == true)
          ? line['categoryName'].toString().trim()
          : 'Category';
      if (!groups.containsKey(name)) {
        groups[name] = [];
        order.add(name);
      }
      groups[name]!.add(line);
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Amount details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Organizer amount split by category.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < order.length; i++) ...[
              if (i > 0) Divider(height: 28, color: Colors.grey.shade300),
              _CategoryBlock(
                categoryName: order[i],
                lines: groups[order[i]]!,
                money: money,
              ),
            ],
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Organizer amount',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    money.format(organizerTotal),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({
    required this.categoryName,
    required this.lines,
    required this.money,
  });

  final String categoryName;
  final List<Map<String, dynamic>> lines;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final categoryTotal = lines.fold<double>(
      0,
      (sum, line) =>
          sum + ReportsAmountRequestTab.asDouble(line['withoutTotal']),
    );
    final participants = lines.fold<int>(
      0,
      (sum, line) =>
          sum + (ReportsAmountRequestTab.asDouble(line['participants']).round()),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                categoryName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '$participants participant${participants == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(width: 12),
            Text(
              money.format(categoryTotal),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2.2),
            1: FlexColumnWidth(1.2),
            2: FlexColumnWidth(1.6),
            3: FlexColumnWidth(1.6),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              children: [
                _cell('Fee type', header: true),
                _cell('Participants', header: true, align: TextAlign.center),
                _cell('Rate', header: true, align: TextAlign.right),
                _cell('Amount', header: true, align: TextAlign.right),
              ],
            ),
            ...lines.map((line) {
              final count =
                  ReportsAmountRequestTab.asDouble(line['participants']).round();
              final rate = ReportsAmountRequestTab.asDouble(
                line['unitWithoutAmount'] ?? line['regAmount'],
              );
              final amount = ReportsAmountRequestTab.asDouble(
                line['withoutTotal'],
              );
              return TableRow(
                children: [
                  _cell(_CategoryAmountDetails._feeTypeLabel(
                    line['channel']?.toString(),
                  )),
                  _cell('$count', align: TextAlign.center),
                  _cell(money.format(rate), align: TextAlign.right),
                  _cell(
                    money.format(amount),
                    align: TextAlign.right,
                    bold: true,
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _cell(
    String text, {
    bool header = false,
    bool bold = false,
    TextAlign align = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: header ? 11.5 : 13,
          fontWeight: header || bold ? FontWeight.w800 : FontWeight.w600,
          color: header ? Colors.grey.shade800 : Colors.black87,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNewRequest});

  final VoidCallback? onNewRequest;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.request_quote_outlined, size: 36, color: Colors.grey.shade500),
          const SizedBox(height: 10),
          const Text(
            'No amount requests',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a request when you need funds released for this competition.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onNewRequest,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New request'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestTable extends StatelessWidget {
  const _RequestTable({
    required this.requests,
    required this.money,
    required this.isCompact,
    required this.controller,
    required this.defaultFrom,
    required this.defaultTo,
    required this.defaultTotalAmount,
    required this.defaultRequestAmount,
  });

  final List<Map<String, dynamic>> requests;
  final NumberFormat money;
  final bool isCompact;
  final ReportsAmountRequestTabController controller;
  final String defaultFrom;
  final String defaultTo;
  final double defaultTotalAmount;
  final double defaultRequestAmount;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Column(
        children: requests.map((request) {
          return _RequestCard(
            request: request,
            money: money,
            controller: controller,
            defaultFrom: defaultFrom,
            defaultTo: defaultTo,
            defaultTotalAmount: defaultTotalAmount,
            defaultRequestAmount: defaultRequestAmount,
          );
        }).toList(),
      );
    }

    final borderColor = Colors.grey.shade300;
    final headerBg = AppTheme.primaryColor.withValues(alpha: 0.12);
    const headerStyle = TextStyle(fontWeight: FontWeight.w800, fontSize: 13);

    Widget header(String text, {TextAlign align = TextAlign.left}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          color: headerBg,
          alignment: align == TextAlign.center
              ? Alignment.center
              : (align == TextAlign.right
                  ? Alignment.centerRight
                  : Alignment.centerLeft),
          child: Text(text, textAlign: align, style: headerStyle),
        );

    Widget cell(Widget child, {Alignment align = Alignment.centerLeft}) =>
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          alignment: align,
          child: child,
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;
          final tableWidth = available < 1120 ? 1120.0 : available;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Table(
                border: TableBorder.all(color: borderColor),
                columnWidths: const {
                  0: FixedColumnWidth(56),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(1.2),
                  3: FixedColumnWidth(120),
                  4: FixedColumnWidth(130),
                  5: FixedColumnWidth(130),
                  6: FixedColumnWidth(118),
                  7: FixedColumnWidth(124),
                  8: FixedColumnWidth(96),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    children: [
                      header('S.No', align: TextAlign.center),
                      header('From'),
                      header('To'),
                      header('Balance amount', align: TextAlign.right),
                      header('Request amount', align: TextAlign.right),
                      header('Paid amount', align: TextAlign.right),
                      header('Date', align: TextAlign.center),
                      header('Status', align: TextAlign.center),
                      header('Actions', align: TextAlign.center),
                    ],
                  ),
                  ...requests.map((request) {
                    final paid = ReportsAmountRequestTab.isPaid(request);
                    final rid = _requestId(request);
                    return TableRow(
                      children: [
                        cell(
                          Text('${request['sno'] ?? ''}',
                              textAlign: TextAlign.center),
                          align: Alignment.center,
                        ),
                        cell(Text(request['fromParty']?.toString() ?? '-')),
                        cell(Text(request['toParty']?.toString() ?? '-')),
                        cell(
                          Text(money.format(
                              ReportsAmountRequestTab.asDouble(
                                  request['totalAmount']))),
                          align: Alignment.centerRight,
                        ),
                        cell(
                          Text(
                            money.format(ReportsAmountRequestTab.asDouble(
                                request['requestAmount'])),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          align: Alignment.centerRight,
                        ),
                        cell(
                          Text(
                            money.format(
                              ReportsAmountRequestTab.paidAmount(request),
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          align: Alignment.centerRight,
                        ),
                        cell(
                          Text(request['requestDate']?.toString() ?? '-'),
                          align: Alignment.center,
                        ),
                        cell(
                          _StatusChip(
                            status: ReportsAmountRequestTab.paymentStatus(
                              request,
                            ),
                          ),
                          align: Alignment.center,
                        ),
                        cell(
                          _RequestActions(
                            paid: paid,
                            iconOnly: true,
                            requestId: rid,
                            controller: controller,
                            onEdit: () => _openAmountRequestDialog(
                              context,
                              controller,
                              existing: request,
                              defaultFrom: defaultFrom,
                              defaultTo: defaultTo,
                              defaultTotalAmount: defaultTotalAmount,
                              defaultRequestAmount: defaultRequestAmount,
                            ),
                          ),
                          align: Alignment.center,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.money,
    required this.controller,
    required this.defaultFrom,
    required this.defaultTo,
    required this.defaultTotalAmount,
    required this.defaultRequestAmount,
  });

  final Map<String, dynamic> request;
  final NumberFormat money;
  final ReportsAmountRequestTabController controller;
  final String defaultFrom;
  final String defaultTo;
  final double defaultTotalAmount;
  final double defaultRequestAmount;

  @override
  Widget build(BuildContext context) {
    final paid = ReportsAmountRequestTab.isPaid(request);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#${request['sno'] ?? ''}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(
                status: ReportsAmountRequestTab.paymentStatus(request),
              ),
              const Spacer(),
              Text(
                money.format(ReportsAmountRequestTab.asDouble(
                    request['requestAmount'])),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${request['fromParty'] ?? '-'} → ${request['toParty'] ?? '-'}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Balance: ${money.format(ReportsAmountRequestTab.asDouble(request['totalAmount']))}',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
          ),
          Text(
            'Paid: ${money.format(ReportsAmountRequestTab.paidAmount(request))}',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
          ),
          Text(
            'Date: ${request['requestDate'] ?? '-'}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          _RequestActions(
            paid: paid,
            requestId: _requestId(request),
            controller: controller,
            onEdit: () => _openAmountRequestDialog(
              context,
              controller,
              existing: request,
              defaultFrom: defaultFrom,
              defaultTo: defaultTo,
              defaultTotalAmount: defaultTotalAmount,
              defaultRequestAmount: defaultRequestAmount,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final Color bg;
    final String label;
    switch (status) {
      case 'PAID':
        color = const Color(0xFF2E7D32);
        bg = const Color(0xFFE8F5E9);
        label = 'Paid';
        break;
      case 'PARTIAL':
        color = const Color(0xFFEF6C00);
        bg = const Color(0xFFFFF3E0);
        label = 'Partially paid';
        break;
      default:
        color = const Color(0xFF616161);
        bg = const Color(0xFFF5F5F5);
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RequestActions extends StatelessWidget {
  const _RequestActions({
    required this.paid,
    required this.requestId,
    required this.controller,
    required this.onEdit,
    this.iconOnly = false,
  });

  final bool paid;
  final int? requestId;
  final ReportsAmountRequestTabController controller;
  final VoidCallback onEdit;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    if (paid) {
      return Text(
        'Locked',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Obx(() {
      final saving = controller.isSaving.value;
      if (iconOnly) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Edit',
              onPressed: saving ? null : onEdit,
              icon: Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: saving || requestId == null
                  ? null
                  : () => _confirmDelete(context),
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red.shade400,
              ),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: saving ? null : onEdit,
            icon: Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor),
            label: const Text('Edit'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              visualDensity: VisualDensity.compact,
            ),
          ),
          TextButton.icon(
            onPressed: saving || requestId == null
                ? null
                : () => _confirmDelete(context),
            icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
            label: Text('Delete', style: TextStyle(color: Colors.red.shade400)),
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ],
      );
    });
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final id = requestId;
    if (id == null) return;
    final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete amount request'),
            content: const Text(
              'This removes the request. Application Admin will no longer see it.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) {
      await controller.deleteAmountRequest(id);
    }
  }
}

int? _requestId(Map<String, dynamic> request) {
  final id = request['id'];
  if (id is int) return id;
  return int.tryParse(id?.toString() ?? '');
}

const _dialogValueStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w700,
  color: Color(0xFF1F2933),
);

InputDecoration _dialogInput({String? prefix}) {
  const borderColor = Color(0xFFE4E7EB);
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: const Color(0xFFF7F8F8),
    prefixText: prefix == null ? null : '$prefix ',
    prefixStyle: _dialogValueStyle,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.6),
    ),
  );
}

class _DialogField extends StatelessWidget {
  const _DialogField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _DialogCategoryBreakdown extends StatelessWidget {
  const _DialogCategoryBreakdown({
    required this.lines,
    required this.money,
  });

  final List<Map<String, dynamic>> lines;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Map<String, dynamic>>>{};
    final order = <String>[];
    for (final line in lines) {
      final name = (line['categoryName']?.toString().trim().isNotEmpty == true)
          ? line['categoryName'].toString().trim()
          : 'Category';
      groups.putIfAbsent(name, () {
        order.add(name);
        return [];
      }).add(line);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'By category',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          for (final name in order) ...[
            _DialogCategoryGroup(
              name: name,
              lines: groups[name]!,
              money: money,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _DialogCategoryGroup extends StatelessWidget {
  const _DialogCategoryGroup({
    required this.name,
    required this.lines,
    required this.money,
  });

  final String name;
  final List<Map<String, dynamic>> lines;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final total = lines.fold<double>(
      0,
      (sum, line) =>
          sum + ReportsAmountRequestTab.asDouble(line['withoutTotal']),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                money.format(total),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppTheme.primaryColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _CategoryAmountDetails._feeTypeLabel(
                        line['channel']?.toString(),
                      ),
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  Text(
                    '${ReportsAmountRequestTab.asDouble(line['participants']).round()}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 88,
                    child: Text(
                      money.format(
                        ReportsAmountRequestTab.asDouble(line['withoutTotal']),
                      ),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> _openAmountRequestDialog(
  BuildContext context,
  ReportsAmountRequestTabController controller, {
  Map<String, dynamic>? existing,
  String defaultFrom = 'CYS',
  String defaultTo = '',
  double defaultTotalAmount = 0,
  double defaultRequestAmount = 0,
}) async {
  final fromCtrl = TextEditingController(
    text: existing?['fromParty']?.toString() ?? defaultFrom,
  );
  final toCtrl = TextEditingController(
    text: existing?['toParty']?.toString() ?? defaultTo,
  );
  final totalCtrl = TextEditingController(
    text: existing == null
        ? (defaultTotalAmount > 0 ? defaultTotalAmount.toStringAsFixed(2) : '')
        : ReportsAmountRequestTab.asDouble(existing['totalAmount'])
            .toStringAsFixed(2),
  );
  final requestCtrl = TextEditingController(
    text: existing == null
        ? (defaultRequestAmount > 0
            ? defaultRequestAmount.toStringAsFixed(2)
            : '')
        : ReportsAmountRequestTab.asDouble(existing['requestAmount'])
            .toStringAsFixed(2),
  );
  DateTime? requestDate;
  final dateRaw = existing?['requestDate']?.toString();
  if (dateRaw != null && dateRaw.isNotEmpty) {
    requestDate = DateTime.tryParse(dateRaw);
  }
  requestDate ??= DateTime.now();

  TextInputFormatter amountFormatter() => TextInputFormatter.withFunction(
        (oldValue, newValue) {
          final text = newValue.text;
          if (text.isEmpty) return newValue;
          if (RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(text)) return newValue;
          return oldValue;
        },
      );

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final lines = ((controller.data.value?['lines'] as List?) ?? const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          final money = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
          final screenWidth = MediaQuery.of(ctx).size.width;
          final isNarrow = screenWidth < 640;
          final dialogWidth = isNarrow
              ? (screenWidth - 48).clamp(280.0, 560.0)
              : 560.0;

          Future<void> save() async {
            final from = fromCtrl.text.trim();
            final to = toCtrl.text.trim();
            if (from.isEmpty) {
              SnackbarHelper.showError(ctx, 'Enter From');
              return;
            }
            if (to.isEmpty) {
              SnackbarHelper.showError(ctx, 'Enter To');
              return;
            }
            final total = double.tryParse(totalCtrl.text.trim());
            if (total == null || total < 0) {
              SnackbarHelper.showError(ctx, 'Enter a valid total amount');
              return;
            }
            final requestAmt = double.tryParse(requestCtrl.text.trim());
            if (requestAmt == null || requestAmt <= 0) {
              SnackbarHelper.showError(ctx, 'Enter a valid request amount');
              return;
            }
            if (requestAmt > total + 0.009) {
              await showDialog<void>(
                context: ctx,
                builder: (popupCtx) => AlertDialog(
                  title: const Text(
                    'Amount request',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  content: const Text(
                    'Request amount cannot be greater than the balance amount.',
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.of(popupCtx).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
              return;
            }
            final ok = await controller.saveAmountRequest(
              requestId: existing == null ? null : _requestId(existing),
              fromParty: from,
              toParty: to,
              totalAmount: total,
              requestAmount: requestAmt,
              requestDate: requestDate,
            );
            if (ok && ctx.mounted) Navigator.of(ctx).pop();
          }

          Widget pair(Widget left, Widget right) {
            if (isNarrow) {
              return Column(
                children: [
                  left,
                  const SizedBox(height: 14),
                  right,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: left),
                const SizedBox(width: 12),
                Expanded(child: right),
              ],
            );
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        existing == null
                            ? 'Amount request'
                            : 'Edit amount request',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ask for this competition amount to be released.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    pair(
                      _DialogField(
                        label: 'From',
                        child: TextField(
                          controller: fromCtrl,
                          style: _dialogValueStyle,
                          decoration: _dialogInput(),
                        ),
                      ),
                      _DialogField(
                        label: 'To',
                        child: TextField(
                          controller: toCtrl,
                          style: _dialogValueStyle,
                          decoration: _dialogInput(),
                        ),
                      ),
                    ),
                    if (lines.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _DialogCategoryBreakdown(lines: lines, money: money),
                    ],
                    const SizedBox(height: 16),
                    pair(
                      _DialogField(
                        label: 'Balance amount',
                        child: TextField(
                          controller: totalCtrl,
                          style: _dialogValueStyle,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                            amountFormatter(),
                          ],
                          decoration: _dialogInput(prefix: '₹'),
                        ),
                      ),
                      _DialogField(
                        label: 'Request amount',
                        child: TextField(
                          controller: requestCtrl,
                          style: _dialogValueStyle,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                            amountFormatter(),
                          ],
                          decoration: _dialogInput(prefix: '₹'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DialogField(
                      label: 'Date',
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: requestDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => requestDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: _dialogInput().copyWith(
                            suffixIcon: Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          child: Text(
                            DateFormat('d MMM yyyy').format(requestDate!),
                            style: _dialogValueStyle,
                          ),
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
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade800,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: const Text('Cancel'),
              ),
              Obx(() {
                final saving = controller.isSaving.value;
                return FilledButton(
                  onPressed: saving ? null : save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                  ),
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

  WidgetsBinding.instance.addPostFrameCallback((_) {
    fromCtrl.dispose();
    toCtrl.dispose();
    totalCtrl.dispose();
    requestCtrl.dispose();
  });
}
