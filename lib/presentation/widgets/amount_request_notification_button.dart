import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/permission_store.dart';
import '../../routes/app_routes.dart';
import '../controllers/amount_request_notification_controller.dart';
import '../controllers/reports_controller.dart';

class AmountRequestNotificationButton extends StatefulWidget {
  const AmountRequestNotificationButton({super.key});

  @override
  State<AmountRequestNotificationButton> createState() =>
      _AmountRequestNotificationButtonState();
}

class _AmountRequestNotificationButtonState
    extends State<AmountRequestNotificationButton> {
  bool _didInitialLoad = false;

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<AmountRequestNotificationController>()
        ? Get.find<AmountRequestNotificationController>()
        : Get.put(AmountRequestNotificationController(), permanent: true);
    final permissionStore = Get.isRegistered<PermissionStore>()
        ? Get.find<PermissionStore>()
        : Get.put(PermissionStore());

    return Obx(() {
      final canShow =
          permissionStore.has('SHOW_AMOUNT_REQUEST_NOTIFICATIONS');
      if (!canShow) {
        return const SizedBox.shrink();
      }
      if (!_didInitialLoad) {
        _didInitialLoad = true;
        Future.microtask(controller.load);
      }
      final canAddTransfer = permissionStore.has('REPORTS_ADD_CYS_TRANSFER');
      final count = controller.count;
      return IconButton(
        tooltip: 'Amount request notifications',
        onPressed: () async {
          await controller.load();
          if (!context.mounted) return;
          await _openNotificationsSheet(
            context,
            controller: controller,
            canAddTransfer: canAddTransfer,
          );
        },
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text(count > 99 ? '99+' : '$count'),
          child: const Icon(Icons.notifications_outlined, color: Colors.white),
        ),
      );
    });
  }

  Future<void> _openNotificationsSheet(
    BuildContext context, {
    required AmountRequestNotificationController controller,
    required bool canAddTransfer,
  }) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isPhone = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final sheetHeightFactor = isPhone ? 0.88 : (isTablet ? 0.75 : 0.65);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      constraints: BoxConstraints(
        maxWidth: isPhone ? double.infinity : 560,
        maxHeight: media.size.height * sheetHeightFactor,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewPadding.bottom;
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset > 0 ? 4 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isPhone ? 14 : 16,
                    12,
                    4,
                    8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Amount requests',
                          style: Theme.of(sheetContext)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: controller.load,
                        icon: const Icon(Icons.refresh),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.requests.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.errorMessage.value.isNotEmpty &&
                        controller.requests.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            controller.errorMessage.value,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    if (controller.requests.isEmpty) {
                      return const Center(
                        child: Text('No amount requests yet.'),
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        isPhone ? 12 : 16,
                        12,
                        isPhone ? 12 : 16,
                        16,
                      ),
                      itemCount: controller.requests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = controller.requests[index];
                        return _NotificationRequestCard(
                          item: item,
                          controller: controller,
                          canAddTransfer: canAddTransfer,
                          isPhone: isPhone,
                          onView: (competitionId, requestId, transferId) async {
                            final ok = await controller.markViewed(
                              competitionId: competitionId,
                              requestId: requestId,
                            );
                            if (!ok || !sheetContext.mounted || !mounted) {
                              return;
                            }
                            Navigator.of(sheetContext).pop();
                            _openFinancialReport(
                              context,
                              competitionId.toString(),
                              highlightTransferId: transferId,
                            );
                          },
                          onAddTransfer: (
                            competitionId,
                            requestId,
                            transferAmount,
                          ) async {
                            // Viewing/acting from notification; transfer save
                            // will also mark viewed when linked on the backend.
                            await controller.markViewed(
                              competitionId: competitionId,
                              requestId: requestId,
                            );
                            if (!sheetContext.mounted || !mounted) return;
                            Navigator.of(sheetContext).pop();
                            _openFinancialReport(
                              context,
                              competitionId.toString(),
                              transferPrefillAmount: transferAmount > 0
                                  ? transferAmount
                                  : null,
                              amountRequestId: requestId,
                            );
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFinancialReport(
    BuildContext context,
    String competitionId, {
    double? transferPrefillAmount,
    int? amountRequestId,
    int? highlightTransferId,
  }) {
    final reportsController = Get.isRegistered<ReportsController>()
        ? Get.find<ReportsController>()
        : Get.put(ReportsController(), permanent: false);
    reportsController.openFinancialReport(
      competitionId,
      transferPrefillAmount: transferPrefillAmount,
      amountRequestId: amountRequestId,
      highlightTransferId: highlightTransferId,
    );
    context.go(AppRoutes.reports);
  }
}

class _NotificationRequestCard extends StatelessWidget {
  const _NotificationRequestCard({
    required this.item,
    required this.controller,
    required this.canAddTransfer,
    required this.isPhone,
    required this.onView,
    required this.onAddTransfer,
  });

  final Map<String, dynamic> item;
  final AmountRequestNotificationController controller;
  final bool canAddTransfer;
  final bool isPhone;
  final Future<void> Function(
    int competitionId,
    int requestId,
    int? transferId,
  ) onView;
  final Future<void> Function(
    int competitionId,
    int requestId,
    double transferAmount,
  ) onAddTransfer;

  @override
  Widget build(BuildContext context) {
    final competitionName =
        item['competitionName']?.toString() ?? 'Competition';
    final from = item['fromParty']?.toString() ?? '-';
    final to = item['toParty']?.toString() ?? '-';
    final date = item['requestDate']?.toString() ?? '-';
    final requestAmount = controller.formatMoney(item['requestAmount']);
    final totalAmount = controller.formatMoney(item['totalAmount']);
    final competitionId = int.tryParse(item['competitionId']?.toString() ?? '');
    final requestIdRaw = item['id'];
    final requestId = requestIdRaw is int
        ? requestIdRaw
        : int.tryParse(requestIdRaw?.toString() ?? '');
    final linkedTransferId = item['transferId'] is int
        ? item['transferId'] as int
        : int.tryParse(item['transferId']?.toString() ?? '');
    final hasTransfer =
        item['hasTransfer'] == true || linkedTransferId != null;
    final transferAmount = item['requestAmount'] is num
        ? (item['requestAmount'] as num).toDouble()
        : double.tryParse(item['requestAmount']?.toString() ?? '') ?? 0;

    final viewButton = OutlinedButton.icon(
      onPressed: competitionId == null || requestId == null
          ? null
          : () {
              final cid = competitionId;
              final rid = requestId;
              onView(cid, rid, linkedTransferId);
            },
      icon: const Icon(Icons.visibility_outlined, size: 18),
      label: const Text('View'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryColor,
        visualDensity: VisualDensity.compact,
        minimumSize: Size(isPhone ? double.infinity : 0, 40),
      ),
    );
    final transferButton = ElevatedButton.icon(
      onPressed: competitionId == null || requestId == null
          ? null
          : () {
              final cid = competitionId;
              final rid = requestId;
              onAddTransfer(cid, rid, transferAmount);
            },
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add transfer'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        visualDensity: VisualDensity.compact,
        minimumSize: Size(isPhone ? double.infinity : 0, 40),
      ),
    );

    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              competitionName,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: isPhone ? 14 : 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$from → $to',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: isPhone ? 12.5 : 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Request $requestAmount of $totalAmount',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: isPhone ? 12.5 : 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Date: $date',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            if (isPhone) ...[
              viewButton,
              if (canAddTransfer && !hasTransfer) ...[
                const SizedBox(height: 8),
                transferButton,
              ],
            ] else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  viewButton,
                  if (canAddTransfer && !hasTransfer) transferButton,
                ],
              ),
          ],
        ),
      ),
    );
  }
}
