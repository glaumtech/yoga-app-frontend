import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../controllers/amount_config_controller.dart';
import '../../../widgets/pinned_scroll_views.dart';

class AmountConfigTab extends StatefulWidget {
  const AmountConfigTab({super.key});

  @override
  State<AmountConfigTab> createState() => _AmountConfigTabState();
}

class _AmountConfigTabState extends State<AmountConfigTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Get.put(AmountConfigController(), permanent: false);
  }

  @override
  void dispose() {
    if (Get.isRegistered<AmountConfigController>()) {
      Get.delete<AmountConfigController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Obx(() {
      final controller = Get.find<AmountConfigController>();
      if (controller.isLoading.value &&
          controller.asanasFeeController.text.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return RefreshIndicator(
        onRefresh: controller.loadSettings,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildInnerTabs(isMobile),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _AmountSubTab(isMobile: isMobile),
                    _FeesSubTab(isMobile: isMobile),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInnerTabs(bool isMobile) {
    final bg = Colors.grey[100]!;
    final radius = BorderRadius.circular(12);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 10),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TabBar(
        isScrollable: true,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[800],
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: isMobile ? 12 : 13,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: isMobile ? 12 : 13,
        ),
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: radius,
        ),
        tabs: [
          Tab(
            height: isMobile ? 30 : 34,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text('Amount'),
            ),
          ),
          Tab(
            height: isMobile ? 30 : 34,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text('Fees (gateway, platform)'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountSubTab extends StatelessWidget {
  const _AmountSubTab({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AmountConfigController>();

    return PinnedVerticalScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Obx(
                () => _sectionCard(
              context: context,
              isMobile: isMobile,
              title: 'AMOUNT',
              subtitle:
                  'These amounts apply when creating an On Demand competition. '
                  'Asanas and Challenge are additive (both formats = sum of both fees).',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller.asanasFeeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'ASANAS FEE',
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.challengeFeeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'CHALLENGE FEE',
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Fees include gateway & platform charges',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      controller.extraFeeIncludedForCompetition.value
                          ? 'Quoted Asanas/Challenge amounts are charged as-is (no extra %).'
                          : 'Gateway and platform % will be added on top at checkout.',
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                    value: controller.extraFeeIncludedForCompetition.value,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (v) =>
                        controller.extraFeeIncludedForCompetition.value = v,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: controller.isSaving.value
                          ? null
                          : controller.saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(140, 42),
                      ),
                      child: controller.isSaving.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('SAVE'),
                    ),
                  ),
                ],
              ),
            ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _AmountHistoryTable(kind: _HistoryKind.amount),
        ],
      ),
    );
  }
}

class _FeesSubTab extends StatelessWidget {
  const _FeesSubTab({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AmountConfigController>();

    return PinnedVerticalScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Obx(
                () => _sectionCard(
              context: context,
              isMobile: isMobile,
              title: 'FEES (GATEWAY, PLATFORM)',
              subtitle:
                  'Percentages added at checkout when fees are not already '
                  'included in the Asanas/Challenge amounts.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller.gatewayPercentController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'GATEWAY FEE %',
                      suffixText: '%',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.platformPercentController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'PLATFORM FEE %',
                      suffixText: '%',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: controller.isSaving.value
                          ? null
                          : controller.saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(140, 42),
                      ),
                      child: controller.isSaving.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('SAVE'),
                    ),
                  ),
                ],
              ),
            ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _AmountHistoryTable(kind: _HistoryKind.fees),
        ],
      ),
    );
  }
}

enum _HistoryKind { amount, fees }

class _AmountHistoryTable extends StatelessWidget {
  const _AmountHistoryTable({required this.kind});

  final _HistoryKind kind;

  static final DateFormat _whenFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static const _amountColumns = <String>[
    'Date',
    'Changed by',
    'Asanas fee',
    'Challenge fee',
    'Fees included',
  ];

  static const _feeColumns = <String>[
    'Date',
    'Changed by',
    'Gateway %',
    'Platform %',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AmountConfigController>();

    return Obx(() {
      final entries = _relevant(controller.history.toList());
      final loading = controller.isHistoryLoading.value && entries.isEmpty;
      final error = controller.historyError.value;

      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'HISTORY',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                    ),
              ),
              const SizedBox(height: 12),
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (error.isNotEmpty && entries.isEmpty)
                Column(
                  children: [
                    Text(error, style: TextStyle(color: Colors.red[700])),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: controller.loadHistory,
                      child: const Text('RETRY'),
                    ),
                  ],
                )
              else if (entries.isEmpty)
                Text(
                  'No amount changes yet.',
                  style: TextStyle(color: Colors.grey[700]),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final minWidth = kind == _HistoryKind.amount ? 720.0 : 640.0;
                    final width = constraints.maxWidth < minWidth
                        ? minWidth
                        : constraints.maxWidth;
                    return ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.stylus,
                          PointerDeviceKind.trackpad,
                        },
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: width,
                          child: _table(entries),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );
    });
  }

  List<AmountConfigHistoryEntry> _relevant(
    List<AmountConfigHistoryEntry> entries,
  ) {
    final visible = <AmountConfigHistoryEntry>[];
    for (final entry in entries) {
      if (visible.isEmpty || _differs(visible.last, entry)) {
        visible.add(entry);
      }
    }
    return visible;
  }

  bool _differs(AmountConfigHistoryEntry newer, AmountConfigHistoryEntry older) {
    if (kind == _HistoryKind.amount) {
      return !_same(newer.asanasFee, older.asanasFee) ||
          !_same(newer.challengeFee, older.challengeFee) ||
          newer.extraFeeIncluded != older.extraFeeIncluded;
    }
    return !_same(newer.gatewayPercent, older.gatewayPercent) ||
        !_same(newer.platformPercent, older.platformPercent);
  }

  Widget _table(List<AmountConfigHistoryEntry> entries) {
    final columns = kind == _HistoryKind.amount ? _amountColumns : _feeColumns;
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: kind == _HistoryKind.amount
          ? const {
              0: FlexColumnWidth(2.3),
              1: FlexColumnWidth(1.7),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1.3),
              4: FlexColumnWidth(1.3),
            }
          : const {
              0: FlexColumnWidth(2.2),
              1: FlexColumnWidth(1.8),
              2: FlexColumnWidth(1.2),
              3: FlexColumnWidth(1.2),
            },
      children: [
        TableRow(
          decoration: BoxDecoration(color: AppTheme.primaryColor),
          children: [
            for (final label in columns) _cell(label, header: true),
          ],
        ),
        for (var i = 0; i < entries.length; i++)
          _dataRow(
            entry: entries[i],
            older: i + 1 < entries.length ? entries[i + 1] : null,
            shaded: i.isOdd,
          ),
      ],
    );
  }

  TableRow _dataRow({
    required AmountConfigHistoryEntry entry,
    required AmountConfigHistoryEntry? older,
    required bool shaded,
  }) {
    final name = entry.changedByName?.trim();
    final by = (name != null && name.isNotEmpty) ? name : '—';
    final when = entry.changedAt != null
        ? _whenFormat.format(entry.changedAt!)
        : '—';

    return TableRow(
      decoration: BoxDecoration(
        color: shaded ? Colors.grey.shade50 : Colors.white,
      ),
      children: kind == _HistoryKind.amount
          ? [
              _cell(when),
              _cell(by),
              _cell(
                _money(entry.asanasFee),
                changed:
                    older != null && !_same(entry.asanasFee, older.asanasFee),
              ),
              _cell(
                _money(entry.challengeFee),
                changed: older != null &&
                    !_same(entry.challengeFee, older.challengeFee),
              ),
              _cell(
                entry.extraFeeIncluded ? 'Yes' : 'No',
                changed: older != null &&
                    entry.extraFeeIncluded != older.extraFeeIncluded,
              ),
            ]
          : [
              _cell(when),
              _cell(by),
              _cell(
                _percent(entry.gatewayPercent),
                changed: older != null &&
                    !_same(entry.gatewayPercent, older.gatewayPercent),
              ),
              _cell(
                _percent(entry.platformPercent),
                changed: older != null &&
                    !_same(entry.platformPercent, older.platformPercent),
              ),
            ],
    );
  }

  Widget _cell(String text, {bool header = false, bool changed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          color: header
              ? Colors.white
              : (changed ? AppTheme.primaryColor : Colors.black87),
          fontWeight: header || changed ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  static bool _same(double a, double b) => (a - b).abs() < 0.001;

  static String _money(double value) {
    if (value == value.roundToDouble()) {
      return '₹${value.toStringAsFixed(0)}';
    }
    return '₹${value.toStringAsFixed(2)}';
  }

  static String _percent(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toStringAsFixed(0)}%';
    }
    return '${value.toStringAsFixed(2)}%';
  }
}

Widget _sectionCard({
  required BuildContext context,
  required bool isMobile,
  required String title,
  required String subtitle,
  required Widget child,
}) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 16,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                  height: 1.35,
                ),
          ),
          SizedBox(height: isMobile ? 16 : 20),
          child,
        ],
      ),
    ),
  );
}
