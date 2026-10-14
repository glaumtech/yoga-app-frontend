import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

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
      child: Center(
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
      child: Center(
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
    );
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
