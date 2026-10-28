import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../controllers/reports_organization_tab_controller.dart';

class ReportsOrganizationTab extends StatelessWidget {
  const ReportsOrganizationTab({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = Get.put(
      ReportsOrganizationTabController(),
      permanent: false,
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
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
          child: Text('Select an organization to view the organization report.'),
        );
      }

      final org =
          (report['organization'] as Map?)?.cast<String, dynamic>() ?? {};
      final totals =
          (report['totals'] as Map?)?.cast<String, dynamic>() ?? {};
      final branches = (report['branches'] as List?) ?? const [];
      final competitions = (report['competitions'] as List?) ?? const [];

      final orgName = (org['organizationName'] ?? '').toString();
      final orgCode = (org['organizationCode'] ?? '').toString();
      final phone = (org['phoneNumber'] ?? '').toString().trim();
      final aadhar = (org['aadharNumber'] ?? '').toString().trim();
      final address = (org['address'] ?? '').toString().trim();

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
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMobile) ...[
                      _orgTitleRow(orgName),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _downloadExcelButton(
                          tabController,
                          isMobile: true,
                        ),
                      ),
                      if (orgCode.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _orgCodeLine(orgCode),
                      ],
                      const SizedBox(height: 10),
                      _orgContactBlock(
                        phone: phone,
                        aadhar: aadhar,
                        address: address,
                      ),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _orgTitleRow(orgName),
                                if (orgCode.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  _orgCodeLine(orgCode),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _downloadExcelButton(
                                    tabController,
                                    isMobile: false,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _orgContactBlock(
                                  phone: phone,
                                  aadhar: aadhar,
                                  address: address,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if ((org['paymentModel'] ?? '').toString().isNotEmpty)
                          _chip('Payment', org['paymentModel'].toString()),
                        if ((org['subscriptionModeName'] ?? '')
                            .toString()
                            .isNotEmpty)
                          _chip(
                            'Subscription',
                            org['subscriptionModeName'].toString(),
                          ),
                        if (org['subscriptionExpiresAt'] != null)
                          _chip(
                            'Expires',
                            org['subscriptionExpiresAt'].toString(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _statCard(
                  'Branches',
                  '${totals['branchCount'] ?? 0}',
                  Icons.account_tree_outlined,
                ),
                _statCard(
                  'Competitions',
                  '${totals['competitionCount'] ?? 0}',
                  Icons.emoji_events_outlined,
                ),
                _statCard(
                  'Users',
                  '${totals['userCount'] ?? 0}',
                  Icons.people_outline,
                ),
                if (org['maintenanceFeeAmount'] != null)
                  _statCard(
                    'Maintenance fee',
                    money.format(
                      num.tryParse(org['maintenanceFeeAmount'].toString()) ?? 0,
                    ),
                    Icons.payments_outlined,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionTitle('Branches'),
            const SizedBox(height: 8),
            if (branches.isEmpty)
              _emptyHint('No branches found for this organization.')
            else
              ...branches.map((row) {
                final m = (row as Map).cast<String, dynamic>();
                final name = (m['branchName'] ?? '').toString();
                final location = [
                  m['cityName'],
                  m['stateName'],
                ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.store,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      name.isNotEmpty ? name : 'Branch',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      [
                        if (location.isNotEmpty) location,
                        if ((m['email'] ?? '').toString().isNotEmpty)
                          m['email'].toString(),
                        if ((m['mobileNo'] ?? '').toString().isNotEmpty)
                          m['mobileNo'].toString(),
                        '${m['competitionCount'] ?? 0} competition(s)',
                      ].join(' · '),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }),
            const SizedBox(height: 16),
            _sectionTitle('Competitions'),
            const SizedBox(height: 8),
            if (competitions.isEmpty)
              _emptyHint('No competitions found for this organization.')
            else
              ...competitions.map((row) {
                final m = (row as Map).cast<String, dynamic>();
                final name = (m['competitionName'] ?? '').toString();
                final start = m['eventStartDatetime']?.toString();
                final end = m['eventEndDatetime']?.toString();
                String when = '';
                if (start != null && start.isNotEmpty) {
                  final parsed = DateTime.tryParse(start);
                  when = parsed != null ? dateFmt.format(parsed.toLocal()) : start;
                }
                if (end != null && end.isNotEmpty) {
                  final parsed = DateTime.tryParse(end);
                  final endLabel =
                      parsed != null ? dateFmt.format(parsed.toLocal()) : end;
                  when = when.isEmpty ? endLabel : '$when — $endLabel';
                }
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.flag_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      name.isNotEmpty ? name : 'Competition',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: when.isNotEmpty
                        ? Text(when, maxLines: 2, overflow: TextOverflow.ellipsis)
                        : null,
                  ),
                );
              }),
          ],
        ),
      );
    });
  }

  Widget _orgTitleRow(String orgName) {
    return Row(
      children: [
        Icon(Icons.business, color: AppTheme.primaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            orgName.isNotEmpty ? orgName : 'Organization',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _downloadExcelButton(
    ReportsOrganizationTabController controller, {
    required bool isMobile,
  }) {
    final downloading = controller.isDownloading.value;
    return ElevatedButton.icon(
      onPressed: downloading ? null : controller.downloadExcel,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
        disabledForegroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 14,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: downloading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.download_rounded, size: 18),
      label: Text(isMobile ? 'Excel' : 'Download Excel'),
    );
  }

  Widget _orgCodeLine(String orgCode) {
    return Text(
      'Code: $orgCode',
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _orgContactBlock({
    required String phone,
    required String aadhar,
    required String address,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _orgContactLine(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: phone,
        ),
        const SizedBox(height: 6),
        _orgContactLine(
          icon: Icons.badge_outlined,
          label: 'Aadhar',
          value: aadhar,
        ),
        const SizedBox(height: 6),
        _orgContactLine(
          icon: Icons.location_on_outlined,
          label: 'Address',
          value: address,
        ),
      ],
    );
  }

  Widget _orgContactLine({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final display = value.isNotEmpty ? value : '—';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: display,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: value.isEmpty ? Colors.grey[500] : Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
      side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.25)),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(String message) {
    return Card(
      color: Colors.blueGrey[50],
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
