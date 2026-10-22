import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/storage_service.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/permission_store.dart';
import '../../../core/constants/app_constants.dart';
import '../../controllers/reports_financial_tab_controller.dart';
import '../../controllers/reports_participants_tab_logic.dart';
import '../../controllers/user_management_controller.dart';

class ReportsFinancialTab extends StatefulWidget {
  const ReportsFinancialTab({super.key});

  @override
  State<ReportsFinancialTab> createState() => _ReportsFinancialTabState();

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String amountRequestStatusLabel(Map<String, dynamic> request) {
    final requestAmt = _asDouble(request['requestAmount']);
    final hasTransfer =
        request['hasTransfer'] == true || request['transferId'] != null;
    final paidAmt = request['paidAmount'] != null
        ? _asDouble(request['paidAmount'])
        : (hasTransfer ? requestAmt : 0);
    if (paidAmt <= 0.009) return 'Pending';
    if (paidAmt + 0.009 < requestAmt) return 'Partially paid';
    return 'Paid';
  }

  static Color amountRequestStatusColor(Map<String, dynamic> request) {
    switch (amountRequestStatusLabel(request)) {
      case 'Partially paid':
        return const Color(0xFFEF6C00);
      case 'Pending':
        return const Color(0xFF616161);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  static String feeTypeLabel(String? raw) {
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
}

class _ReportsFinancialTabState extends State<ReportsFinancialTab> {
  bool _openingPendingTransfer = false;

  bool get _isApplicationAdmin {
    final userController = Get.isRegistered<UserManagementController>()
        ? Get.find<UserManagementController>()
        : null;
    final role = (userController?.currentUser.value?.userTypeName ??
            userController?.currentUser.value?.type ??
            '')
        .trim()
        .toUpperCase();
    return role == 'APPLICATION_ADMIN';
  }

  @override
  Widget build(BuildContext context) {
    final tabController = Get.put(
      ReportsFinancialTabController(),
      permanent: false,
    );
    final permissionStore = Get.isRegistered<PermissionStore>()
        ? Get.find<PermissionStore>()
        : Get.put(PermissionStore());
    final canAddTransfer = permissionStore.has('REPORTS_ADD_CYS_TRANSFER');
    final lockPaidEdits = !_isApplicationAdmin;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isCompact = screenWidth < 900;
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

      _schedulePendingTransferOpen(context, tabController);
      _schedulePendingHighlight(tabController);

      final lines = (report['lines'] as List?) ?? const [];
      final transfers = (report['transfers'] as List?) ?? const [];
      final amountRequests = (report['amountRequests'] as List?) ?? const [];
      final withTotal = ReportsFinancialTab._asDouble(
        report['withTotal'] ?? report['organizerTotal'],
      );
      final feeTotal = ReportsFinancialTab._asDouble(report['feeTotal']);
      final withoutTotal = ReportsFinancialTab._asDouble(
        report['withoutTotal'] ?? report['organizerTotal'],
      );
      final organizerTotal = withoutTotal;
      final transferredTotal =
          ReportsFinancialTab._asDouble(report['transferredTotal']);
      final pending = ReportsFinancialTab._asDouble(report['pending']);

      final defaultFrom =
          report['defaultFromParty']?.toString() ?? 'CYS';
      final defaultTo = report['defaultToParty']?.toString() ??
          report['branchName']?.toString() ??
          report['organizationName']?.toString() ??
          '';
      final transferList = transfers
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final requestList = amountRequests
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      Future<void> openAmountRequest() => _openAmountRequestDialog(
            context,
            tabController,
            defaultFrom: defaultFrom,
            defaultTo: defaultTo,
            defaultTotalAmount: pending > 0 ? pending : 0,
            defaultRequestAmount: pending,
          );

      return RefreshIndicator(
        onRefresh: tabController.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            isMobile ? 12 : 20,
            isMobile ? 12 : 16,
            isMobile ? 12 : 20,
            32,
          ),
          children: [
            _HeaderCard(
              report: report,
              isMobile: isMobile,
              isPrinting: tabController.isPrinting.value,
              onPrint: tabController.isPrinting.value
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
            ),
            const SizedBox(height: 14),
            _KpiOverview(
              withTotal: withTotal,
              feeTotal: feeTotal,
              organizerTotal: organizerTotal,
              transferredTotal: transferredTotal,
              pending: pending,
              money: money,
              isMobile: isMobile,
              isCompact: isCompact,
            ),
            const SizedBox(height: 16),
            _ReportSection(
              title: 'Registration summary',
              subtitle: lines.isEmpty
                  ? 'No category collections yet'
                  : '${lines.length} categor${lines.length == 1 ? 'y' : 'ies'}',
              child: _RegistrationTable(
                lines: lines
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList(),
                withTotal: withTotal,
                feeTotal: feeTotal,
                withoutTotal: withoutTotal,
                money: money,
                isMobile: isMobile,
                forApplicationAdmin: _isApplicationAdmin,
              ),
            ),
            const SizedBox(height: 14),
            _ReportSection(
              title: 'Amount requests',
              subtitle: requestList.isEmpty
                  ? 'No requests yet'
                  : '${requestList.length} request${requestList.length == 1 ? '' : 's'}',
              actions: [
                TextButton.icon(
                  onPressed: tabController.isSaving.value
                      ? null
                      : openAmountRequest,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New request'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
              child: requestList.isEmpty
                  ? _EmptyState(
                      icon: Icons.request_quote_outlined,
                      title: 'No amount requests',
                      message:
                          'Create a request when you need funds released for this competition.',
                      primaryLabel: 'New request',
                      onPrimary: tabController.isSaving.value
                          ? null
                          : openAmountRequest,
                    )
                  : _AmountRequestsTable(
                      requests: requestList,
                      money: money,
                      isMobile: isMobile,
                      isCompact: isCompact,
                      controller: tabController,
                      canAddTransfer: canAddTransfer,
                      lockPaidEdits: lockPaidEdits,
                      defaultFrom: defaultFrom,
                      defaultTo: defaultTo,
                      defaultTotalAmount: pending > 0 ? pending : 0,
                      defaultRequestAmount: pending,
                    ),
            ),
            const SizedBox(height: 14),
            _ReportSection(
              title: 'Transferred from CYS',
              subtitle: transferList.isEmpty
                  ? 'No transfers yet'
                  : '${transferList.length} transfer${transferList.length == 1 ? '' : 's'}',
              actions: [
                OutlinedButton.icon(
                  onPressed: tabController.isSaving.value
                      ? null
                      : openAmountRequest,
                  icon: const Icon(Icons.request_quote_outlined, size: 18),
                  label: Text(isMobile ? 'Request' : 'Amount request'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                    side: BorderSide(color: AppTheme.accentBorder(0.45)),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 14,
                      vertical: 10,
                    ),
                  ),
                ),
                if (canAddTransfer)
                  FilledButton.icon(
                    onPressed: tabController.isSaving.value
                        ? null
                        : () => _openTransferDialog(context, tabController),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(isMobile ? 'Transfer' : 'Add transfer'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 10 : 14,
                        vertical: 10,
                      ),
                    ),
                  ),
              ],
              child: transferList.isEmpty
                  ? _EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No CYS transfers yet',
                      message:
                          'Record a transfer when funds move from CYS, or raise an amount request first.',
                      primaryLabel: canAddTransfer ? 'Add transfer' : null,
                      onPrimary: canAddTransfer && !tabController.isSaving.value
                          ? () => _openTransferDialog(context, tabController)
                          : null,
                      secondaryLabel: 'Amount request',
                      onSecondary: tabController.isSaving.value
                          ? null
                          : openAmountRequest,
                    )
                  : _TransfersTable(
                      transfers: transferList,
                      transferredTotal: transferredTotal,
                      money: money,
                      isMobile: isMobile,
                      isCompact: isCompact,
                      controller: tabController,
                      canEditTransfers: canAddTransfer,
                    ),
            ),
            const SizedBox(height: 14),
            _PendingCard(
              organizerTotal: organizerTotal,
              transferredTotal: transferredTotal,
              pending: pending,
              money: money,
              isMobile: isMobile,
            ),
          ],
        ),
      );
    });
  }

  void _schedulePendingTransferOpen(
    BuildContext context,
    ReportsFinancialTabController tabController,
  ) {
    if (_openingPendingTransfer || tabController.isLoading.value) return;
    final amount =
        tabController.reportsController.pendingTransferPrefillAmount.value;
    if (amount == null) return;
    _openingPendingTransfer = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _openingPendingTransfer = false;
        return;
      }
      final pending =
          tabController.reportsController.pendingTransferPrefillAmount.value;
      final requestId =
          tabController.reportsController.pendingTransferAmountRequestId.value;
      tabController.reportsController.pendingTransferPrefillAmount.value = null;
      tabController.reportsController.pendingTransferAmountRequestId.value =
          null;
      _openingPendingTransfer = false;
      if (pending == null) return;
      _openTransferDialog(
        context,
        tabController,
        prefillAmount: pending,
        amountRequestId: requestId,
      );
    });
  }

  void _schedulePendingHighlight(
    ReportsFinancialTabController tabController,
  ) {
    if (tabController.isLoading.value) return;
    final transferId =
        tabController.reportsController.pendingHighlightTransferId.value;
    if (transferId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending =
          tabController.reportsController.pendingHighlightTransferId.value;
      tabController.reportsController.pendingHighlightTransferId.value = null;
      if (pending != null) {
        tabController.highlightTransfer(pending);
      }
    });
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions.isNotEmpty)
                  Flexible(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: actions,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.accentSoft(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.accent, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textMuted,
              ),
            ),
          ),
          if (primaryLabel != null || secondaryLabel != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (secondaryLabel != null)
                  OutlinedButton(
                    onPressed: onSecondary,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accent,
                      side: BorderSide(color: AppTheme.accentBorder(0.45)),
                    ),
                    child: Text(secondaryLabel!),
                  ),
                if (primaryLabel != null)
                  FilledButton(
                    onPressed: onPrimary,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                    ),
                    child: Text(primaryLabel!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _KpiOverview extends StatelessWidget {
  const _KpiOverview({
    required this.withTotal,
    required this.feeTotal,
    required this.organizerTotal,
    required this.transferredTotal,
    required this.pending,
    required this.money,
    required this.isMobile,
    required this.isCompact,
  });

  final double withTotal;
  final double feeTotal;
  final double organizerTotal;
  final double transferredTotal;
  final double pending;
  final NumberFormat money;
  final bool isMobile;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final pendingTone = pending > 0.009
        ? const Color(0xFFE65100)
        : AppTheme.accent;

    final cards = [
      _KpiTile(
        label: 'Pending balance',
        value: money.format(pending),
        hint: 'Still to receive',
        emphasize: true,
        valueColor: pendingTone,
        bg: pending > 0.009
            ? const Color(0xFFFFF3E0)
            : AppTheme.accentSoft(0.10),
        borderColor: pending > 0.009
            ? const Color(0xFFFFCC80)
            : AppTheme.accentBorder(0.35),
      ),
      _KpiTile(
        label: 'Organizer amount',
        value: money.format(organizerTotal),
        hint: 'Without fee',
      ),
      _KpiTile(
        label: 'Transferred',
        value: money.format(transferredTotal),
        hint: 'From CYS',
      ),
      _KpiTile(
        label: 'Collected',
        value: money.format(withTotal),
        hint: 'Fee ${money.format(feeTotal)}',
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: cards[1]),
              const SizedBox(width: 8),
              Expanded(child: cards[2]),
            ],
          ),
          const SizedBox(height: 8),
          cards[3],
        ],
      );
    }

    if (isCompact) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(flex: 3, child: cards[0]),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: cards[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 10),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(flex: i == 0 ? 3 : 2, child: cards[i]),
        ],
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    this.hint,
    this.emphasize = false,
    this.valueColor,
    this.bg,
    this.borderColor,
  });

  final String label;
  final String value;
  final String? hint;
  final bool emphasize;
  final Color? valueColor;
  final Color? bg;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: emphasize ? 16 : 14,
        vertical: emphasize ? 14 : 12,
      ),
      decoration: BoxDecoration(
        color: bg ?? AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: emphasize ? 12 : 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: emphasize ? 22 : 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.report,
    required this.isMobile,
    this.isPrinting = false,
    this.onPrint,
  });
  final Map<String, dynamic> report;
  final bool isMobile;
  final bool isPrinting;
  final VoidCallback? onPrint;

  @override
  Widget build(BuildContext context) {
    final name = report['competitionName']?.toString() ?? '-';
    final date = report['eventDate']?.toString() ?? '-';
    final year = report['year']?.toString() ?? '-';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 14 : 18,
        isMobile ? 14 : 16,
        12,
        isMobile ? 14 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentSoft(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.insights_outlined,
              color: AppTheme.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(icon: Icons.event_outlined, label: date),
                    _MetaChip(icon: Icons.calendar_today_outlined, label: year),
                  ],
                ),
              ],
            ),
          ),
          if (onPrint != null || isPrinting)
            IconButton(
              tooltip: 'Print financial report',
              onPressed: onPrint,
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.accentSoft(0.10),
                foregroundColor: AppTheme.accent,
              ),
              icon: isPrinting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print_outlined, size: 20),
            ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
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
    this.forApplicationAdmin = false,
  });

  final List<Map<String, dynamic>> lines;
  final double withTotal;
  final double feeTotal;
  final double withoutTotal;
  final NumberFormat money;
  final bool isMobile;
  final bool forApplicationAdmin;

  static const double _tableMinWidth = 980;
  static const double _snoW = 56;
  static const double _participantsW = 100;
  static const double _channelW = 188;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return const Text(
        'No registrations found for this competition.',
        style: TextStyle(
          fontSize: 13,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
      );
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              money.format(value),
              textAlign: TextAlign.right,
              style: cellStyle.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: emphasize ? AppTheme.accent : AppColors.textPrimary,
                fontSize: emphasize ? 13.5 : 13,
              ),
            ),
          ),
        );

    Widget textCell(
      String text, {
      bool bold = false,
      TextAlign align = TextAlign.left,
      Alignment geometry = Alignment.centerLeft,
    }) =>
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Align(
            alignment: geometry,
            child: Text(
              text,
              textAlign: align,
              style: cellStyle.copyWith(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: AppColors.textPrimary,
              ),
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
        final count = ReportsFinancialTab._asDouble(participants);
        var unit = ReportsFinancialTab._asDouble(
          line['unitWithAmount'] ?? line['regAmount'],
        );
        if (unit <= 0 && count > 0) {
          unit = withAmt / count;
        }
        final typeName = ReportsFinancialTab.feeTypeLabel(channel);
        final typeLabel = unit > 0
            ? '$typeName (${_plainAmount(unit)})'
            : typeName;
        return dataRow(
          cells: [
            textCell(
              '${line['sno'] ?? ''}',
              align: TextAlign.center,
              geometry: Alignment.center,
            ),
            textCell(line['categoryName']?.toString() ?? '-'),
            textCell(
              '$participants',
              align: TextAlign.center,
              geometry: Alignment.center,
            ),
            textCell(
              typeLabel,
              align: TextAlign.center,
              geometry: Alignment.center,
            ),
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
          textCell(
            'Total',
            bold: true,
            align: TextAlign.right,
            geometry: Alignment.centerRight,
          ),
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
                            _headerBox(
                              forApplicationAdmin ? 'Registration type' : 'Fee type',
                              width: _channelW,
                              style: headerStyle,
                              borderColor: borderColor,
                            ),
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
                                      forApplicationAdmin ? 'Collection' : 'Amount Details',
                                      textAlign: TextAlign.center,
                                      style: headerStyle.copyWith(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      children: [
                                        _headerBox(
                                          forApplicationAdmin ? 'Collected' : 'With fee',
                                          flex: 1,
                                          style: headerStyle,
                                          borderColor: borderColor,
                                          bottomBorder: false,
                                          align: Alignment.centerRight,
                                        ),
                                        _headerBox(
                                          forApplicationAdmin ? 'Service fee' : 'Fee',
                                          flex: 1,
                                          style: headerStyle,
                                          borderColor: borderColor,
                                          bottomBorder: false,
                                          align: Alignment.centerRight,
                                        ),
                                        _headerBox(
                                          forApplicationAdmin
                                              ? 'Organizer amount'
                                              : 'Without fee',
                                          flex: 1,
                                          style: headerStyle,
                                          borderColor: borderColor,
                                          bottomBorder: false,
                                          rightBorder: false,
                                          align: Alignment.centerRight,
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

  static String _plainAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  Widget _headerBox(
    String text, {
    double? width,
    int? flex,
    required TextStyle style,
    required Color borderColor,
    bool bottomBorder = true,
    bool rightBorder = true,
    Alignment align = Alignment.center,
  }) {
    final child = Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      alignment: align,
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
    required this.isCompact,
    required this.controller,
    this.canEditTransfers = false,
  });

  final List<Map<String, dynamic>> transfers;
  final double transferredTotal;
  final NumberFormat money;
  final bool isMobile;
  final bool isCompact;
  final ReportsFinancialTabController controller;
  final bool canEditTransfers;

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) {
      return const SizedBox.shrink();
    }

    if (isCompact) {
      return Obx(() {
        final highlightedId = controller.highlightedTransferId.value;
        controller.revealHighlightedTransfer();
        return Column(
        children: [
          ...transfers.map((t) {
            final amount = ReportsFinancialTab._asDouble(t['amount']);
            final ref = t['referenceNumber']?.toString() ?? '-';
            final date = t['transferDate']?.toString() ?? '-';
            final url = controller.screenshotUrlFor(t);
            final tid = t['id'] is int
                ? t['id'] as int
                : int.tryParse(t['id']?.toString() ?? '');
            final isHighlighted = tid != null && tid == highlightedId;
            return Container(
              key: tid == null ? null : controller.transferRowKey(tid),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHighlighted
                      ? AppTheme.accent
                      : Colors.grey.shade300,
                  width: isHighlighted ? 2 : 1,
                ),
                color: isHighlighted
                    ? AppTheme.accentSoft(0.18)
                    : Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '#${t['sno'] ?? ''}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      if (isHighlighted) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Linked request',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        money.format(amount),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                          fontSize: isMobile ? 15 : 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Ref: $ref', style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    'Date: $date',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (url != null)
                        TextButton.icon(
                          onPressed: () => _previewImage(context, url),
                          icon: const Icon(Icons.visibility, size: 18),
                          label: const Text('Screenshot'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      if (canEditTransfers) ...[
                        TextButton.icon(
                          onPressed: () => _openTransferDialog(
                            context,
                            controller,
                            existing: t,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryColor,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: tid == null
                              ? null
                              : () async {
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
                                  if (ok) {
                                    await controller.deleteTransfer(tid);
                                  }
                                },
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red.shade400,
                          ),
                          label: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red.shade400),
                          ),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Text(
                'Total: ${money.format(transferredTotal)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.accent,
                ),
              ),
            ),
          ),
        ],
      );
      });
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

    Widget cell(
      Widget child, {
      Alignment align = Alignment.centerLeft,
      Key? key,
    }) =>
        Container(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          alignment: align,
          child: child,
        );

    return Obx(() {
      final highlightedId = controller.highlightedTransferId.value;
      controller.revealHighlightedTransfer();
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
              columnWidths: {
                0: const FixedColumnWidth(56),
                1: const FlexColumnWidth(1.2),
                2: const FlexColumnWidth(1.6),
                3: const FixedColumnWidth(90),
                if (canEditTransfers) 4: const FixedColumnWidth(110),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  children: [
                    header('S.No', align: TextAlign.center),
                    header('Transferred from CYS'),
                    header('Reference number & Date'),
                    header('Screenshot', align: TextAlign.center),
                    if (canEditTransfers)
                      header('Actions', align: TextAlign.center),
                  ],
                ),
                ...transfers.map((t) {
                  final amount = ReportsFinancialTab._asDouble(t['amount']);
                  final ref = t['referenceNumber']?.toString() ?? '-';
                  final date = t['transferDate']?.toString() ?? '-';
                  final url = controller.screenshotUrlFor(t);
                  final tid = t['id'] is int
                      ? t['id'] as int
                      : int.tryParse(t['id']?.toString() ?? '');
                  final isHighlighted = tid != null && tid == highlightedId;
                  return TableRow(
                    decoration: isHighlighted
                        ? BoxDecoration(color: AppTheme.accentSoft(0.22))
                        : null,
                    children: [
                      cell(
                        Text('${t['sno'] ?? ''}', textAlign: TextAlign.center),
                        align: Alignment.center,
                        key: tid == null ? null : controller.transferRowKey(tid),
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
                      if (canEditTransfers)
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
                                  if (ok) {
                                    await controller.deleteTransfer(tid);
                                  }
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
                    if (canEditTransfers) cell(const SizedBox.shrink()),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    });
  }
}

class _AmountRequestsTable extends StatelessWidget {
  const _AmountRequestsTable({
    required this.requests,
    required this.money,
    required this.isMobile,
    required this.isCompact,
    required this.controller,
    required this.canAddTransfer,
    required this.lockPaidEdits,
    required this.defaultFrom,
    required this.defaultTo,
    required this.defaultTotalAmount,
    required this.defaultRequestAmount,
  });

  final List<Map<String, dynamic>> requests;
  final NumberFormat money;
  final bool isMobile;
  final bool isCompact;
  final ReportsFinancialTabController controller;
  final bool canAddTransfer;
  final bool lockPaidEdits;
  final String defaultFrom;
  final String defaultTo;
  final double defaultTotalAmount;
  final double defaultRequestAmount;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const SizedBox.shrink();
    }

    if (isCompact) {
      return Column(
        children: requests.map((r) {
          final total = ReportsFinancialTab._asDouble(r['totalAmount']);
          final requestAmt = ReportsFinancialTab._asDouble(r['requestAmount']);
          final date = r['requestDate']?.toString() ?? '-';
          final rid = r['id'] is int
              ? r['id'] as int
              : int.tryParse(r['id']?.toString() ?? '');
          final linkedTransferId = r['transferId'] is int
              ? r['transferId'] as int
              : int.tryParse(r['transferId']?.toString() ?? '');
          final hasTransfer =
              r['hasTransfer'] == true || linkedTransferId != null;
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#${r['sno'] ?? ''}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      money.format(requestAmt),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                        fontSize: isMobile ? 15 : 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${r['fromParty'] ?? '-'} → ${r['toParty'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Balance: ${money.format(total)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Paid: ${money.format(ReportsFinancialTab._asDouble(r['paidAmount']))}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Date: $date',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    if (canAddTransfer && !hasTransfer)
                      TextButton.icon(
                        onPressed: controller.isSaving.value || rid == null
                            ? null
                            : () => _openTransferDialog(
                                  context,
                                  controller,
                                  prefillAmount:
                                      requestAmt > 0 ? requestAmt : null,
                                  amountRequestId: rid,
                                ),
                        icon: Icon(
                          Icons.add_card_outlined,
                          size: 18,
                          color: AppTheme.accent,
                        ),
                        label: const Text('Add transfer'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accent,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    if (hasTransfer && linkedTransferId != null)
                      TextButton.icon(
                        onPressed: () =>
                            controller.highlightTransfer(linkedTransferId),
                        icon: Icon(
                          Icons.link,
                          size: 18,
                          color: AppTheme.accent,
                        ),
                        label: const Text('View transfer'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accent,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    if (hasTransfer && lockPaidEdits)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          ReportsFinancialTab.amountRequestStatusLabel(r),
                          style: TextStyle(
                            color: ReportsFinancialTab.amountRequestStatusColor(r),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (!hasTransfer || !lockPaidEdits)
                      TextButton.icon(
                      onPressed: controller.isSaving.value
                          ? null
                          : () {
                              if (linkedTransferId != null) {
                                controller.highlightTransfer(linkedTransferId);
                              }
                              _openAmountRequestDialog(
                                context,
                                controller,
                                existing: r,
                                defaultFrom: defaultFrom,
                                defaultTo: defaultTo,
                                defaultTotalAmount: defaultTotalAmount,
                                defaultRequestAmount: defaultRequestAmount,
                              );
                            },
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppTheme.primaryColor,
                      ),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    if (!hasTransfer || !lockPaidEdits)
                      TextButton.icon(
                      onPressed: rid == null || controller.isSaving.value
                          ? null
                          : () async {
                              final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete amount request'),
                                      content: const Text(
                                        'This will remove the amount request from the financial report.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;
                              if (ok) {
                                await controller.deleteAmountRequest(rid);
                              }
                            },
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red.shade400,
                      ),
                      label: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red.shade400),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    final borderColor = Colors.grey.shade300;
    final headerBg = AppTheme.accentSoft(0.18);
    const headerStyle = TextStyle(fontWeight: FontWeight.w800, fontSize: 13);

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
        final minWidth = isMobile ? 940.0 : 1040.0;
        final tableWidth = available < minWidth ? minWidth : available;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Table(
              border: TableBorder.all(color: borderColor),
              columnWidths: {
                0: const FixedColumnWidth(56),
                1: const FlexColumnWidth(1.2),
                2: const FlexColumnWidth(1.2),
                3: const FixedColumnWidth(120),
                4: const FixedColumnWidth(120),
                5: const FixedColumnWidth(120),
                6: const FixedColumnWidth(118),
                7: FixedColumnWidth(canAddTransfer ? 148 : 110),
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
                    header('Actions', align: TextAlign.center),
                  ],
                ),
                ...requests.map((r) {
                  final total = ReportsFinancialTab._asDouble(r['totalAmount']);
                  final requestAmt =
                      ReportsFinancialTab._asDouble(r['requestAmount']);
                  final date = r['requestDate']?.toString() ?? '-';
                  final rid = r['id'] is int
                      ? r['id'] as int
                      : int.tryParse(r['id']?.toString() ?? '');
                  final linkedTransferId = r['transferId'] is int
                      ? r['transferId'] as int
                      : int.tryParse(r['transferId']?.toString() ?? '');
                  final hasTransfer =
                      r['hasTransfer'] == true || linkedTransferId != null;
                  return TableRow(
                    children: [
                      cell(
                        Text('${r['sno'] ?? ''}', textAlign: TextAlign.center),
                        align: Alignment.center,
                      ),
                      cell(Text(r['fromParty']?.toString() ?? '-')),
                      cell(Text(r['toParty']?.toString() ?? '-')),
                      cell(
                        Text(
                          money.format(total),
                          style: const TextStyle(
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        align: Alignment.centerRight,
                      ),
                      cell(
                        Text(
                          money.format(requestAmt),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        align: Alignment.centerRight,
                      ),
                      cell(
                        Text(
                          money.format(
                            ReportsFinancialTab._asDouble(r['paidAmount']),
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        align: Alignment.centerRight,
                      ),
                      cell(
                        Text(
                          date,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: const TextStyle(
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        align: Alignment.center,
                      ),
                      cell(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (canAddTransfer && !hasTransfer)
                              IconButton(
                                tooltip: 'Add transfer',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                icon: Icon(
                                  Icons.add_card_outlined,
                                  color: AppTheme.accent,
                                  size: 20,
                                ),
                                onPressed: controller.isSaving.value ||
                                        rid == null
                                    ? null
                                    : () => _openTransferDialog(
                                          context,
                                          controller,
                                          prefillAmount: requestAmt > 0
                                              ? requestAmt
                                              : null,
                                          amountRequestId: rid,
                                        ),
                              ),
                            if (hasTransfer && linkedTransferId != null)
                              IconButton(
                                tooltip: 'View linked transfer',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                icon: Icon(
                                  Icons.link,
                                  color: AppTheme.accent,
                                  size: 20,
                                ),
                                onPressed: () => controller
                                    .highlightTransfer(linkedTransferId),
                              ),
                            if (hasTransfer && lockPaidEdits)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  ReportsFinancialTab.amountRequestStatusLabel(r),
                                  style: TextStyle(
                                    color: ReportsFinancialTab
                                        .amountRequestStatusColor(r),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (!hasTransfer || !lockPaidEdits)
                              IconButton(
                              tooltip: 'Edit',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              icon: Icon(
                                Icons.edit_outlined,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              onPressed: controller.isSaving.value
                                  ? null
                                  : () {
                                      if (linkedTransferId != null) {
                                        controller.highlightTransfer(
                                          linkedTransferId,
                                        );
                                      }
                                      _openAmountRequestDialog(
                                        context,
                                        controller,
                                        existing: r,
                                        defaultFrom: defaultFrom,
                                        defaultTo: defaultTo,
                                        defaultTotalAmount: defaultTotalAmount,
                                        defaultRequestAmount:
                                            defaultRequestAmount,
                                      );
                                    },
                            ),
                            if (!hasTransfer || !lockPaidEdits)
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
                                color: Colors.red.shade400,
                                size: 20,
                              ),
                              onPressed: rid == null || controller.isSaving.value
                                  ? null
                                  : () async {
                                      final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                'Delete amount request',
                                              ),
                                              content: const Text(
                                                'This will remove the amount request from the financial report.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx)
                                                          .pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx)
                                                          .pop(true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          ) ??
                                          false;
                                      if (ok) {
                                        await controller
                                            .deleteAmountRequest(rid);
                                      }
                                    },
                            ),
                          ],
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
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.organizerTotal,
    required this.transferredTotal,
    required this.pending,
    required this.money,
    this.isMobile = false,
  });

  final double organizerTotal;
  final double transferredTotal;
  final double pending;
  final NumberFormat money;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final hasPending = pending > 0.009;
    final tone = hasPending ? const Color(0xFFE65100) : AppTheme.accent;
    final softBg =
        hasPending ? const Color(0xFFFFF8F1) : AppTheme.accentSoft(0.08);
    final border =
        hasPending ? const Color(0xFFFFCC80) : AppTheme.accentBorder(0.35);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 18),
      decoration: BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pendingLabel(hasPending),
                const SizedBox(height: 8),
                Text(
                  money.format(pending),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: tone,
                  ),
                ),
                const SizedBox(height: 10),
                _formula(money, organizerTotal, transferredTotal),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _pendingLabel(hasPending),
                      const SizedBox(height: 8),
                      _formula(money, organizerTotal, transferredTotal),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  money.format(pending),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: tone,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _pendingLabel(bool hasPending) {
    return Row(
      children: [
        Icon(
          hasPending
              ? Icons.pending_actions_outlined
              : Icons.check_circle_outline,
          size: 18,
          color: hasPending ? const Color(0xFFE65100) : AppTheme.accent,
        ),
        const SizedBox(width: 8),
        Text(
          hasPending ? 'Amount still pending' : 'Fully settled',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _formula(
    NumberFormat money,
    double organizerTotal,
    double transferredTotal,
  ) {
    return Text(
      'Organizer (${money.format(organizerTotal)}) − Transferred (${money.format(transferredTotal)})',
      style: const TextStyle(
        fontSize: 12.5,
        height: 1.35,
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

Future<void> _openAmountRequestDialog(
  BuildContext context,
  ReportsFinancialTabController controller, {
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
        ? defaultTotalAmount.toStringAsFixed(2)
        : ReportsFinancialTab._asDouble(existing['totalAmount'])
            .toStringAsFixed(2),
  );
  final requestCtrl = TextEditingController(
    text: existing == null
        ? defaultRequestAmount.toStringAsFixed(2)
        : ReportsFinancialTab._asDouble(existing['requestAmount'])
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
          if (RegExp(r'^\d+(\.\d{0,2})?$').hasMatch(text)) {
            return newValue;
          }
          return oldValue;
        },
      );

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final labelStyle = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
        letterSpacing: 0.2,
      );
      final valueStyle = TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade900,
      );
      final fieldDecoration = InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.accent, width: 1.5),
        ),
      );

      Widget labeledField({
        required String label,
        required Widget field,
      }) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 6),
            field,
          ],
        );
      }

      return StatefulBuilder(
        builder: (ctx, setState) {
          final screenWidth = MediaQuery.of(ctx).size.width;
          final isNarrow = screenWidth < 600;
          final dialogWidth = isNarrow
              ? (screenWidth - 48).clamp(260.0, 520.0)
              : 520.0;

          Widget fieldPair(Widget left, Widget right) {
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
            insetPadding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 16 : 40,
              vertical: isNarrow ? 24 : 40,
            ),
            title: Text(
              existing == null ? 'Amount request' : 'Edit amount request',
            ),
            content: SizedBox(
              width: dialogWidth,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    fieldPair(
                      labeledField(
                        label: 'From',
                        field: TextField(
                          controller: fromCtrl,
                          style: valueStyle,
                          decoration: fieldDecoration,
                        ),
                      ),
                      labeledField(
                        label: 'To',
                        field: TextField(
                          controller: toCtrl,
                          style: valueStyle,
                          decoration: fieldDecoration,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    fieldPair(
                      labeledField(
                        label: 'Balance amount (₹)',
                        field: TextField(
                          controller: totalCtrl,
                          style: valueStyle,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                            amountFormatter(),
                          ],
                          decoration: fieldDecoration,
                        ),
                      ),
                      labeledField(
                        label: 'Request amount (₹)',
                        field: TextField(
                          controller: requestCtrl,
                          style: valueStyle,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                            amountFormatter(),
                          ],
                          decoration: fieldDecoration,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    labeledField(
                      label: 'Date',
                      field: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: requestDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => requestDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: fieldDecoration.copyWith(
                            suffixIcon: Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(requestDate!),
                            style: valueStyle,
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
                            SnackbarHelper.showError(
                              ctx,
                              'Enter a valid total amount',
                            );
                            return;
                          }
                          final requestAmt =
                              double.tryParse(requestCtrl.text.trim());
                          if (requestAmt == null || requestAmt <= 0) {
                            SnackbarHelper.showError(
                              ctx,
                              'Enter a valid request amount',
                            );
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
                                    onPressed: () =>
                                        Navigator.of(popupCtx).pop(),
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
                          final requestId = existing == null
                              ? null
                              : (existing['id'] is int
                                  ? existing['id'] as int
                                  : int.tryParse(
                                      existing['id']?.toString() ?? '',
                                    ));
                          final ok = await controller.saveAmountRequest(
                            requestId: requestId,
                            fromParty: from,
                            toParty: to,
                            totalAmount: total,
                            requestAmount: requestAmt,
                            requestDate: requestDate,
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

  // Defer dispose until after the dialog route finishes tearing down TextFields.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    fromCtrl.dispose();
    toCtrl.dispose();
    totalCtrl.dispose();
    requestCtrl.dispose();
  });
}

Future<void> _openTransferDialog(
  BuildContext context,
  ReportsFinancialTabController controller, {
  Map<String, dynamic>? existing,
  double? prefillAmount,
  int? amountRequestId,
}) async {
  final amountCtrl = TextEditingController(
    text: existing == null
        ? (prefillAmount != null && prefillAmount > 0
            ? prefillAmount.toStringAsFixed(2)
            : '')
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
      final labelStyle = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
        letterSpacing: 0.2,
      );
      final valueStyle = TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade900,
      );
      final fieldDecoration = InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppTheme.accent, width: 1.5),
        ),
      );

      Widget labeledField({
        required String label,
        required Widget field,
      }) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 6),
            field,
          ],
        );
      }

      return StatefulBuilder(
        builder: (ctx, setState) {
          final screenWidth = MediaQuery.of(ctx).size.width;
          final isNarrow = screenWidth < 600;
          final dialogWidth = isNarrow
              ? (screenWidth - 48).clamp(260.0, 520.0)
              : 520.0;

          Widget fieldPair(Widget left, Widget right) {
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
            insetPadding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 16 : 40,
              vertical: isNarrow ? 24 : 40,
            ),
            title: Text(existing == null ? 'Add transfer' : 'Edit transfer'),
            content: SizedBox(
              width: dialogWidth,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    fieldPair(
                      labeledField(
                        label: 'Amount (₹)',
                        field: TextField(
                          controller: amountCtrl,
                          style: valueStyle,
                          keyboardType:
                              const TextInputType.numberWithOptions(
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
                          decoration: fieldDecoration,
                        ),
                      ),
                      labeledField(
                        label: 'Reference number',
                        field: TextField(
                          controller: refCtrl,
                          style: valueStyle,
                          decoration: fieldDecoration,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    fieldPair(
                      labeledField(
                        label: 'Date',
                        field: InkWell(
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
                          borderRadius: BorderRadius.circular(8),
                          child: InputDecorator(
                            decoration: fieldDecoration.copyWith(
                              suffixIcon: Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            child: Text(
                              DateFormat('yyyy-MM-dd').format(transferDate!),
                              style: valueStyle,
                            ),
                          ),
                        ),
                      ),
                      labeledField(
                        label: 'Screenshot',
                        field: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    final result = await FilePicker.pickFiles(
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
                                icon: const Icon(
                                  Icons.upload_file,
                                  size: 18,
                                ),
                                label: Text(
                                  screenshotBytes != null ||
                                          (existingUrl != null &&
                                              !clearScreenshot)
                                      ? 'Change'
                                      : 'Upload',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.accent,
                                  side: BorderSide(color: AppTheme.accent),
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
                            amountRequestId: existing == null
                                ? amountRequestId
                                : null,
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

  WidgetsBinding.instance.addPostFrameCallback((_) {
    amountCtrl.dispose();
    refCtrl.dispose();
  });
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
