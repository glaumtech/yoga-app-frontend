import 'dart:typed_data';
import 'dart:html' as html show Blob, Url, AnchorElement;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/permission_store.dart';
import '../../../data/models/competition_model.dart';
import '../../../data/repositories/reports_repository.dart';
import '../../controllers/reports_controller.dart';
import '../../widgets/admin_sidebar_layout.dart';
import '../../widgets/searchable_dropdown_field.dart';
import '../../controllers/reports_participants_list_preset.dart';
import 'reports_users_tab.dart';
import 'reports_participants_tab.dart';
import 'reports_registered_participants_tab.dart';
import 'reports_financial_tab.dart';
import 'reports_registered_participants_popup.dart';
import 'reports_institutions_details_popup.dart';
import 'reports_masters_details_popup.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reports Screen
/// Displays various reports and analytics
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportTabItem {
  const _ReportTabItem({
    required this.id,
    required this.label,
    this.requiredKey,
    required this.child,
  });

  final String id;
  final String label;
  final String? requiredKey;
  final Widget child;
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  late final ReportsController controller;
  final ReportsRepository _printRepository = ReportsRepository();
  TabController? _tabController;
  List<_ReportTabItem> _visibleTabs = const [];
  String? _pendingReportTabId;
  Worker? _tabNavWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ReportsController(), permanent: false);
    _tabNavWorker = ever<String?>(controller.navigateToReportTabId, (tabId) {
      if (tabId == null || !mounted) return;
      _pendingReportTabId = tabId;
      controller.navigateToReportTabId.value = null;
      _schedulePendingTabNavigation();
    });
    // Refresh competition list (/competition/list) + report summary on every
    // navigation to Reports (GetX controller may be reused across visits).
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.loadCompetitionsAndMaybeReport();
    });
  }

  @override
  void dispose() {
    _tabNavWorker?.dispose();
    _tabController?.dispose();
    _tabController = null;
    super.dispose();
  }

  void _ensureTabController(int length) {
    if (length <= 0) return;
    final previousIndex = _tabController?.index ?? 0;
    if (_tabController != null && _tabController!.length == length) return;

    // Keep the old controller alive until after this frame so TabBar/TabBarView
    // do not touch a disposed controller mid-rebuild.
    final oldController = _tabController;
    _tabController = TabController(
      length: length,
      vsync: this,
      initialIndex: previousIndex.clamp(0, length - 1),
    );
    if (oldController != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        oldController.dispose();
      });
    }
  }

  void _schedulePendingTabNavigation() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyPendingTabNavigation();
    });
  }

  void _applyPendingTabNavigation() {
    final tabId = _pendingReportTabId;
    final tabController = _tabController;
    if (tabId == null || tabController == null) return;
    final index = _visibleTabs.indexWhere((t) => t.id == tabId);
    if (index >= 0 && index < tabController.length) {
      tabController.animateTo(index);
      _pendingReportTabId = null;
    }
  }

  List<_ReportTabItem> _buildAllReportTabs({
    required bool isLoading,
    required String error,
    required Map<String, dynamic>? report,
    required bool isMobile,
    required bool isWideWeb,
  }) {
    return [
      _ReportTabItem(
        id: 'dashboard',
        label: 'Dashboard',
        child: RefreshIndicator(
          onRefresh: () async => controller.loadCompetitionsAndMaybeReport(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 12 : 5),
            children: [
              if (isLoading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ] else if (error.isNotEmpty) ...[
                _buildErrorCard(error),
              ] else if (report == null) ...[
                _buildInfoCard(
                  'Select a competition to view reports.',
                  icon: Icons.info_outline,
                ),
              ] else ...[
                ..._buildDashboardTab(
                  report,
                  isMobile: isMobile,
                  isWideWeb: isWideWeb,
                ),
              ],
            ],
          ),
        ),
      ),
      _ReportTabItem(
        id: ReportsController.registeredParticipantsReportTabId,
        label: 'Registered participants',
        requiredKey: 'REPORTS_REGISTERED_PARTICIPANTS',
        child: const ReportsRegisteredParticipantsTab(),
      ),
      _ReportTabItem(
        id: 'prize_winners',
        label: 'Prize Winners',
        child: RefreshIndicator(
          onRefresh: () async => controller.loadCompetitionsAndMaybeReport(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            children: [
              if (isLoading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ] else if (error.isNotEmpty) ...[
                _buildErrorCard(error),
              ] else if (report == null) ...[
                _buildInfoCard(
                  'Select a competition to view reports.',
                  icon: Icons.info_outline,
                ),
              ] else ...[
                _buildPrizeWinnersSection(report, isMobile),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
      _ReportTabItem(
        id: 'users',
        label: 'Users',
        child: const ReportsUsersTab(),
      ),
      _ReportTabItem(
        id: 'scores',
        label: 'Score of participants',
        child: const ReportsParticipantsTab(),
      ),
      _ReportTabItem(
        id: 'financial',
        label: 'Financial report',
        child: const ReportsFinancialTab(),
      ),
    ];
  }

  List<_ReportTabItem> _visibleReportTabs(
    PermissionStore permissionStore, {
    required bool isLoading,
    required String error,
    required Map<String, dynamic>? report,
    required bool isMobile,
    required bool isWideWeb,
  }) {
    return _buildAllReportTabs(
      isLoading: isLoading,
      error: error,
      report: report,
      isMobile: isMobile,
      isWideWeb: isWideWeb,
    ).where((tab) {
      final key = tab.requiredKey;
      if (key == null || key.isEmpty) return true;
      return permissionStore.has(key);
    }).toList();
  }

  void _openRegisteredParticipants(ReportsParticipantsListPreset preset) {
    final competitionId = controller.selectedCompetitionId.value;
    if (competitionId == null || competitionId.isEmpty) {
      Get.snackbar(
        'Competition required',
        'Select a competition first.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }
    ReportsRegisteredParticipantsPopup.show(
      context,
      competitionId: competitionId,
      preset: preset,
    );
  }

  void _openInstitutionsDetails({
    required String title,
    required InstitutionsListKind kind,
    required List<Map<String, dynamic>> institutions,
  }) {
    final competitionId = controller.selectedCompetitionId.value;
    if (competitionId == null || competitionId.isEmpty) {
      Get.snackbar(
        'Competition required',
        'Select a competition first.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    String? competitionName;
    for (final c in controller.competitions) {
      if (c.id == competitionId) {
        competitionName = c.competitionName;
        break;
      }
    }
    ReportsInstitutionsDetailsPopup.show(
      context,
      title: title,
      kind: kind,
      institutions: institutions,
      competitionId: competitionId,
      competitionName: competitionName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isWideWeb = screenWidth >= 1100;

    final permissionStore = Get.isRegistered<PermissionStore>()
        ? Get.find<PermissionStore>()
        : Get.put(PermissionStore());

    return AdminSidebarLayout(
      title: 'Reports',
      child: Obx(() {
        final isLoading = controller.isLoading.value;
        final error = controller.errorMessage.value;
        final report = controller.report.value;
        // Touch reactive permission keys so tab visibility updates after login.
        permissionStore.keys.length;

        final tabs = _visibleReportTabs(
          permissionStore,
          isLoading: isLoading,
          error: error,
          report: report,
          isMobile: isMobile,
          isWideWeb: isWideWeb,
        );
        _visibleTabs = tabs;

        if (tabs.isEmpty) {
          return Center(
            child: Text(
              'No reports access for your role.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        }

        _ensureTabController(tabs.length);
        _schedulePendingTabNavigation();
        final tabController = _tabController!;

        return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 12 : 16,
                  isMobile ? 5 : 5,
                  isMobile ? 12 : 16,
                  0,
                ),
                child: _buildCompetitionSelector(isMobile),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildTabs(isMobile, tabs, tabController),
                ),
              ),
              const SizedBox(height: 0),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: tabs.map((t) => t.child).toList(),
                ),
              ),
            ],
        );
      }),
    );
  }

  Widget _buildTabs(
    bool isMobile,
    List<_ReportTabItem> tabs,
    TabController tabController,
  ) {
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
        controller: tabController,
        isScrollable: true,
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 8),
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
        tabs: tabs
            .map(
              (tab) => Tab(
                height: isMobile ? 30 : 34,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text(tab.label),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  List<Widget> _buildDashboardTab(
    Map<String, dynamic> report, {
    required bool isMobile,
    required bool isWideWeb,
  }) {
    final sectionsRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildCategoryCountsSection(report, isMobile)),
        const SizedBox(width: 12),
        Expanded(child: _buildPrefixAgeSection(report, isMobile)),
        const SizedBox(width: 12),
        Expanded(child: _buildInstitutionsSection(report, isMobile)),
      ],
    );

    return [
      _buildTotalsSection(report, isMobile),
      const SizedBox(height: 12),
      if (isWideWeb) ...[
        sectionsRow,
        const SizedBox(height: 12),
        _buildBestSchoolAndTopMastersRow(report, isMobile),
        const SizedBox(height: 20),
      ] else ...[
        _buildCategoryCountsSection(report, isMobile),
        const SizedBox(height: 12),
        _buildPrefixAgeSection(report, isMobile),
        const SizedBox(height: 12),
        _buildInstitutionsSection(report, isMobile),
        const SizedBox(height: 12),
        _buildBestSchoolAwardSection(report, isMobile),
        const SizedBox(height: 12),
        _buildTopMastersSection(report, isMobile),
        const SizedBox(height: 20),
      ],
    ];
  }

  Widget _buildBestSchoolAndTopMastersRow(
    Map<String, dynamic> report,
    bool isMobile,
  ) {
    final institutions =
        (report['institutions'] as Map?)?.cast<String, dynamic>() ?? {};
    final threshold = (institutions['bestSchoolAwardMinParticipants'] as num?)
        ?.toInt();
    final showBestSchool = threshold != null && threshold > 0;

    if (!showBestSchool) {
      return _buildTopMastersSection(report, isMobile);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildBestSchoolAwardSection(report, isMobile)),
        const SizedBox(width: 12),
        Expanded(child: _buildTopMastersSection(report, isMobile)),
      ],
    );
  }

  Widget _buildCompetitionSelector(bool isMobile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Obx(() {
          final competitions = controller.competitions;
          final selectedId = controller.selectedCompetitionId.value;

          final dropdown = SearchableDropdownField(
            items: competitions
                .where((c) => (c.id ?? '').isNotEmpty)
                .map(
                  (CompetitionModel c) => SearchableDropdownItem(
                    value: c.id!,
                    label: c.competitionName,
                  ),
                )
                .toList(),
            selectedValue: selectedId,
            labelText: 'Competition',
            hintText: 'Select competition',
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: isMobile ? 10 : 12,
            ),
            onChanged: (v) => controller.setSelectedCompetition(v),
          );

          final refreshButton = IconButton(
            tooltip: 'Refresh',
            onPressed: () => controller.loadCompetitionsAndMaybeReport(),
            icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: BoxConstraints(
              minWidth: isMobile ? 36 : 40,
              minHeight: isMobile ? 36 : 40,
            ),
          );

          if (isMobile) {
            return Row(
              children: [
                Expanded(child: dropdown),
                const SizedBox(width: 8),
                refreshButton,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: dropdown),
              const SizedBox(width: 12),
              refreshButton,
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTotalsSection(Map<String, dynamic> report, bool isMobile) {
    final totals = (report['totals'] as Map?)?.cast<String, dynamic>() ?? {};
    final categoryCounts =
        (report['categoryCounts'] as Map?)?.cast<String, dynamic>() ?? {};

    final totalParticipants = totals['totalParticipants'] ?? 0;
    final boys = totals['boys'] ?? 0;
    final girls = totals['girls'] ?? 0;
    final onlineRegistrations = totals['onlineRegistrations'] ?? 0;
    final spotRegistrations = totals['spotRegistrations'] ?? 0;

    final common = categoryCounts['COMMON'] ?? 0;
    final special = categoryCounts['SPECIAL'] ?? 0;
    final champions = categoryCounts['CHAMPIONS'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Participants Summary'),
            const SizedBox(height: 10),
            Wrap(
              runSpacing: 10,
              spacing: 10,
              children: [
                _statTile(
                  'Total Participants',
                  '$totalParticipants',
                  onTap: () => _openRegisteredParticipants(
                    ReportsParticipantsListPreset.all,
                  ),
                ),
                _statTile(
                  'No of Boys',
                  '$boys',
                  onTap: () => _openRegisteredParticipants(
                    ReportsParticipantsListPreset.boys(),
                  ),
                ),
                _statTile(
                  'No of Girls',
                  '$girls',
                  onTap: () => _openRegisteredParticipants(
                    ReportsParticipantsListPreset.girls(),
                  ),
                ),
                _statTile(
                  'Common Category',
                  '$common',
                  onTap: () => _openRegisteredParticipants(
                    ReportsParticipantsListPreset.categoryType('COMMON'),
                  ),
                ),
                _statTile(
                  'Special Category',
                  '$special',
                  onTap: () => _openRegisteredParticipants(
                    ReportsParticipantsListPreset.categoryType('SPECIAL'),
                  ),
                ),
                _statTile(
                  'Champions Category',
                  '$champions',
                  onTap: () => _openRegisteredParticipants(
                    ReportsParticipantsListPreset.categoryType('CHAMPIONS'),
                  ),
                ),
                _statTile(
                  'Online Registration',
                  '$onlineRegistrations',
                  onTap: () => _openRegisteredParticipants(
                    ReportsParticipantsListPreset.onlineRegistration(),
                  ),
                ),
                _statTile(
                  'Spot Registration',
                  '$spotRegistrations',
                  onTap: () => _openRegisteredParticipants(
                    ReportsParticipantsListPreset.spotRegistration(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCountsSection(
    Map<String, dynamic> report,
    bool isMobile,
  ) {
    final categoryCounts =
        (report['categoryCounts'] as Map?)?.cast<String, dynamic>() ?? {};

    if (categoryCounts.isEmpty) {
      return _buildInfoCard('No category data found.', icon: Icons.category);
    }

    final entries = categoryCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Category Wise Participants'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entries
                  .map(
                    (e) => ActionChip(
                      label: Text('${e.key}: ${e.value}'),
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                      side: BorderSide(
                        color: AppTheme.primaryColor.withOpacity(0.25),
                      ),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      onPressed: () => _openRegisteredParticipants(
                        ReportsParticipantsListPreset.categoryType(e.key),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrefixAgeSection(Map<String, dynamic> report, bool isMobile) {
    final raw =
        (report['prefixAgeCounts'] as Map?)?.cast<String, dynamic>() ?? {};

    if (raw.isEmpty) {
      return _buildInfoCard(
        'No Age data found (needs registrationNo + age).',
        icon: Icons.group,
      );
    }

    // Prefer nested shape: category -> prefix -> ages.
    // Fall back to legacy flat shape: prefix -> ages.
    final byCategory = _groupPrefixAgeCountsByCategory(raw);
    if (byCategory.isEmpty) {
      return _buildInfoCard(
        'No Age data found (needs registrationNo + age).',
        icon: Icons.group,
      );
    }

    final categoryKeys = byCategory.keys.toList()
      ..sort(_compareCategoryTypeKeys);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Age wise Participants'),
            const SizedBox(height: 10),
            ...categoryKeys.map((categoryKey) {
              final prefixMap = byCategory[categoryKey]!;
              final prefixKeys = prefixMap.keys.toList()..sort();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _categoryTypeDisplayName(categoryKey),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...prefixKeys.map((prefix) {
                      final agesMap = prefixMap[prefix]!;
                      final ageKeys = agesMap.keys.toList()
                        ..sort((a, b) {
                          final ai = int.tryParse(a) ?? 0;
                          final bi = int.tryParse(b) ?? 0;
                          return ai.compareTo(bi);
                        });

                      return Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prefix,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ageKeys
                                  .map(
                                    (age) => _miniPill(
                                      'Age $age',
                                      '${agesMap[age] ?? 0}',
                                      onTap: () {
                                        final ageInt = int.tryParse(age);
                                        if (ageInt == null) return;
                                        _openRegisteredParticipants(
                                          ReportsParticipantsListPreset
                                              .prefixAndAge(
                                            prefix: prefix,
                                            age: ageInt,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Normalizes report payload to: category -> prefix -> age -> count.
  Map<String, Map<String, Map<String, dynamic>>>
  _groupPrefixAgeCountsByCategory(Map<String, dynamic> raw) {
    if (raw.isEmpty) return {};

    final firstValue = raw.values.first;
    final nested =
        firstValue is Map &&
        firstValue.isNotEmpty &&
        firstValue.values.first is Map;

    if (nested) {
      final out = <String, Map<String, Map<String, dynamic>>>{};
      for (final entry in raw.entries) {
        final prefixMap =
            (entry.value as Map?)?.cast<String, dynamic>() ?? {};
        if (prefixMap.isEmpty) continue;
        final prefixes = <String, Map<String, dynamic>>{};
        for (final p in prefixMap.entries) {
          final ages = (p.value as Map?)?.cast<String, dynamic>() ?? {};
          if (ages.isEmpty) continue;
          prefixes[p.key] = ages;
        }
        if (prefixes.isNotEmpty) {
          out[entry.key.toUpperCase()] = prefixes;
        }
      }
      return out;
    }

    // Legacy flat: prefix -> ages. Infer category from registration prefix letter.
    final out = <String, Map<String, Map<String, dynamic>>>{};
    for (final entry in raw.entries) {
      final prefix = entry.key;
      final ages = (entry.value as Map?)?.cast<String, dynamic>() ?? {};
      if (ages.isEmpty) continue;
      final category = _categoryTypeFromRegistrationPrefix(prefix);
      out.putIfAbsent(category, () => {})[prefix] = ages;
    }
    return out;
  }

  String _categoryTypeFromRegistrationPrefix(String prefix) {
    if (prefix.isEmpty) return 'UNKNOWN';
    switch (prefix[0].toUpperCase()) {
      case 'C':
        return 'COMMON';
      case 'S':
        return 'SPECIAL';
      case 'H':
        return 'CHAMPIONS';
      default:
        return 'UNKNOWN';
    }
  }

  String _categoryTypeDisplayName(String key) {
    switch (key.toUpperCase()) {
      case 'COMMON':
        return 'Common';
      case 'SPECIAL':
        return 'Special';
      case 'CHAMPIONS':
        return 'Champions';
      case 'UNKNOWN':
        return 'Other';
      default:
        if (key.isEmpty) return key;
        return key[0].toUpperCase() + key.substring(1).toLowerCase();
    }
  }

  int _compareCategoryTypeKeys(String a, String b) {
    const order = ['COMMON', 'SPECIAL', 'CHAMPIONS'];
    final ai = order.indexOf(a.toUpperCase());
    final bi = order.indexOf(b.toUpperCase());
    if (ai >= 0 || bi >= 0) {
      if (ai < 0) return 1;
      if (bi < 0) return -1;
      return ai.compareTo(bi);
    }
    return a.compareTo(b);
  }

  Widget _buildBestSchoolAwardSection(
    Map<String, dynamic> report,
    bool isMobile,
  ) {
    final institutions =
        (report['institutions'] as Map?)?.cast<String, dynamic>() ?? {};
    final threshold = (institutions['bestSchoolAwardMinParticipants'] as num?)
        ?.toInt();
    final awards =
        (institutions['bestSchoolAwards'] as List?)?.cast() ?? const [];

    if (threshold == null || threshold <= 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Best School Award'),
            const SizedBox(height: 6),
            Text(
              'Schools with above $threshold participants',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            if (awards.isEmpty)
              _buildInfoCard(
                'No schools have reached the Best School Award threshold yet.',
                icon: Icons.emoji_events_outlined,
              )
            else
              Column(
                children: awards.map((row) {
                  final m = (row as Map).cast<String, dynamic>();
                  final name = (m['institutionName'] ?? '').toString();
                  final count = (m['participantCount'] ?? 0).toString();
                  final institutionId = (m['institutionId'] as num?)?.toInt();

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onTap: institutionId != null
                        ? () => _openRegisteredParticipants(
                            ReportsParticipantsListPreset.institution(
                              institutionId,
                              institutionName:
                                  name.isNotEmpty ? name : null,
                            ),
                          )
                        : null,
                    leading: CircleAvatar(
                      backgroundColor:
                          AppTheme.primaryColor.withOpacity(0.12),
                      child: Icon(
                        Icons.emoji_events,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      name.isNotEmpty ? name : 'Unknown institution',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      '$count participants',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMastersSection(
    Map<String, dynamic> report,
    bool isMobile,
  ) {
    final masters = (report['topMasters'] as List?)
            ?.map((row) => (row as Map).cast<String, dynamic>())
            .toList() ??
        const <Map<String, dynamic>>[];
    final totalMasters = masters.length;
    final topMaster = masters.isNotEmpty ? masters.first : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Top Master's Report"),
            const SizedBox(height: 6),
            // Text(
            //   'Yoga masters who brought the most students (by teacher name & cell)',
            //   style: TextStyle(
            //     fontSize: 12,
            //     color: Colors.grey[700],
            //     fontWeight: FontWeight.w600,
            //   ),
            // ),
            const SizedBox(height: 10),
            if (masters.isEmpty)
              _buildInfoCard(
                'No yoga teacher data available yet.',
                icon: Icons.person_outline,
              )
            else
              Wrap(
                runSpacing: 10,
                spacing: 10,
                children: [
                  _statTile(
                    'Total Masters',
                    '$totalMasters',
                    onTap: () => _openTopMastersDetails(
                      title: 'All Masters',
                      masters: masters,
                    ),
                  ),
                  _buildTopMasterSummaryTile(
                    topMaster!,
                    onTap: () {
                      final name =
                          (topMaster['yogaTeacherName'] ?? '').toString().trim();
                      _openTopMastersDetails(
                        title: name.isNotEmpty
                            ? "$name's Details"
                            : "Top Master's Details",
                        masters: [topMaster],
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopMasterSummaryTile(
    Map<String, dynamic> topMaster, {
    VoidCallback? onTap,
  }) {
    final name = (topMaster['yogaTeacherName'] ?? '').toString().trim();
    final cell = (topMaster['yogaTeacherCell'] ?? '').toString().trim();
    final participantCount =
        (topMaster['participantCount'] as num?)?.toInt() ?? 0;
    final institutionCount =
        (topMaster['institutionCount'] as num?)?.toInt() ?? 0;

    final tile = Container(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 360),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name.isNotEmpty ? name : 'Unknown master',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          if (cell.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              cell,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '$institutionCount institution${institutionCount == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '·',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              Text(
                '$participantCount participant${participantCount == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Top Master',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );

    if (onTap == null) return tile;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: tile,
        ),
      ),
    );
  }

  void _openTopMastersDetails({
    required String title,
    required List<Map<String, dynamic>> masters,
  }) {
    final competitionId = controller.selectedCompetitionId.value;
    if (competitionId == null || competitionId.isEmpty) {
      Get.snackbar(
        'Competition required',
        'Select a competition first.',
        backgroundColor: Colors.orange.shade800,
        colorText: Colors.white,
      );
      return;
    }

    String? competitionName;
    for (final c in controller.competitions) {
      if (c.id == competitionId) {
        competitionName = c.competitionName;
        break;
      }
    }

    ReportsMastersDetailsPopup.show(
      context,
      title: title,
      masters: masters,
      competitionId: competitionId,
      competitionName: competitionName,
    );
  }

  Widget _buildInstitutionsSection(
    Map<String, dynamic> report,
    bool isMobile,
  ) {
    final institutions =
        (report['institutions'] as Map?)?.cast<String, dynamic>() ?? {};

    final totalInstitutions =
        institutions['totalInstitutionsParticipated'] ?? 0;
    final totalSchools = institutions['totalSchoolsParticipated'] ?? 0;
    final totalColleges = institutions['totalCollegesParticipated'] ?? 0;
    final totalYogaCenters =
        institutions['totalYogaCentersParticipated'] ?? 0;
    final rawList =
        (institutions['institutionsByParticipantCount'] as List?)?.cast() ??
            [];
    final list = rawList
        .map((row) => (row as Map).cast<String, dynamic>())
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Institutions Participated'),
            const SizedBox(height: 10),
            Wrap(
              runSpacing: 10,
              spacing: 10,
              children: [
                _statTile(
                  'Total Institutions',
                  '$totalInstitutions',
                  onTap: () => _openInstitutionsDetails(
                    title: 'Total Institutions',
                    kind: InstitutionsListKind.all,
                    institutions: list,
                  ),
                ),
                _statTile(
                  'Total Schools',
                  '$totalSchools',
                  onTap: () => _openInstitutionsDetails(
                    title: 'Total Schools',
                    kind: InstitutionsListKind.schools,
                    institutions: list,
                  ),
                ),
                _statTile(
                  'Total Colleges',
                  '$totalColleges',
                  onTap: () => _openInstitutionsDetails(
                    title: 'Total Colleges',
                    kind: InstitutionsListKind.colleges,
                    institutions: list,
                  ),
                ),
                _statTile(
                  'Total Yoga Centers',
                  '$totalYogaCenters',
                  onTap: () => _openInstitutionsDetails(
                    title: 'Total Yoga Centers',
                    kind: InstitutionsListKind.yogaCenters,
                    institutions: list,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeWinnersSection(Map<String, dynamic> report, bool isMobile) {
    final blocks = (report['prizeWinners'] as List?)?.cast() ?? [];

    if (blocks.isEmpty) {
      return _buildInfoCard(
        'No prize winners data yet (needs jury scores submitted).',
        icon: Icons.emoji_events_outlined,
      );
    }

    final allBlocks = blocks
        .map((b) => (b as Map).cast<String, dynamic>())
        .toList();
    final onlineBlocks = allBlocks
        .where((b) => _prizeWinnerMode(b) == 'ONLINE')
        .toList();
    final offlineBlocks = allBlocks
        .where((b) => _prizeWinnerMode(b) != 'ONLINE')
        .toList();
    final showModeTabs = onlineBlocks.isNotEmpty && offlineBlocks.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('Prize Winners (Category Wise)')),
            IconButton(
              tooltip: 'Print Prize Winners',
              icon: Icon(Icons.print, color: AppTheme.primaryColor),
              onPressed: _printPrizeWinnersPdf,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (showModeTabs)
          DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _prizeWinnersTabBar(
                  isMobile: isMobile,
                  labels: const ['Online', 'Offline'],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: isMobile ? 760 : 580,
                  child: TabBarView(
                    children: [
                      _buildPrizeWinnersModePane(
                        onlineBlocks,
                        isMobile,
                        bounded: true,
                      ),
                      _buildPrizeWinnersModePane(
                        offlineBlocks,
                        isMobile,
                        bounded: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          _buildPrizeWinnersModePane(
            onlineBlocks.isNotEmpty ? onlineBlocks : offlineBlocks,
            isMobile,
            bounded: false,
          ),
      ],
    );
  }

  String _prizeWinnerMode(Map<String, dynamic> block) {
    final raw = (block['mode'] ?? block['competitionMode'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    return raw == 'ONLINE' ? 'ONLINE' : 'OFFLINE';
  }

  Widget _prizeWinnersTabBar({
    required bool isMobile,
    required List<String> labels,
  }) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TabBar(
        isScrollable: true,
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 12,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[800],
        labelStyle: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: isMobile ? 12 : 13,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: isMobile ? 12 : 13,
        ),
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        tabs: labels
            .map(
              (label) => Tab(
                height: isMobile ? 30 : 34,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(label),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPrizeWinnersModePane(
    List<Map<String, dynamic>> blocks,
    bool isMobile, {
    required bool bounded,
  }) {
    if (blocks.isEmpty) {
      return _buildInfoCard(
        'No prize winners for this mode yet.',
        icon: Icons.emoji_events_outlined,
      );
    }

    final stageNames = blocks
        .map((b) => (b['stageName'] ?? '').toString().trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final Map<String, List<Map<String, dynamic>>> blocksByStage = {};
    for (final m in blocks) {
      final stage = (m['stageName'] ?? '').toString().trim();
      final key = stage.isNotEmpty ? stage : 'Stage';
      blocksByStage.putIfAbsent(key, () => []).add(m);
    }

    for (final e in blocksByStage.entries) {
      e.value.sort((a, b) {
        final ac = (a['categoryName'] ?? '').toString();
        final bc = (b['categoryName'] ?? '').toString();
        final as = (a['stageName'] ?? '').toString();
        final bs = (b['stageName'] ?? '').toString();
        final ag = (a['groupName'] ?? '').toString();
        final bg = (b['groupName'] ?? '').toString();
        final c = ac.toLowerCase().compareTo(bc.toLowerCase());
        if (c != 0) return c;
        final s = as.toLowerCase().compareTo(bs.toLowerCase());
        if (s != 0) return s;
        return ag.toLowerCase().compareTo(bg.toLowerCase());
      });
    }

    Widget stageView(String stage) {
      final stageBlocks = blocksByStage[stage] ?? const <Map<String, dynamic>>[];
      return ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: !bounded,
        physics: bounded
            ? null
            : const NeverScrollableScrollPhysics(),
        children: stageBlocks
            .map((block) => _buildPrizeWinnersBlock(block, isMobile))
            .toList(),
      );
    }

    if (stageNames.length >= 2) {
      final tabs = DefaultTabController(
        length: stageNames.length,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _prizeWinnersTabBar(
              isMobile: isMobile,
              labels: stageNames.map((s) => 'Stage $s').toList(),
            ),
            const SizedBox(height: 10),
            if (bounded)
              Expanded(
                child: TabBarView(
                  children: stageNames.map(stageView).toList(),
                ),
              )
            else
              SizedBox(
                height: isMobile ? 700 : 520,
                child: TabBarView(
                  children: stageNames.map(stageView).toList(),
                ),
              ),
          ],
        ),
      );
      return tabs;
    }

    final allBlocks = blocksByStage.values.expand((list) => list).toList();
    if (bounded) {
      return ListView(
        padding: EdgeInsets.zero,
        children: allBlocks
            .map((block) => _buildPrizeWinnersBlock(block, isMobile))
            .toList(),
      );
    }
    return Column(
      children: allBlocks
          .map((block) => _buildPrizeWinnersBlock(block, isMobile))
          .toList(),
    );
  }

  Widget _buildPrizeWinnersBlock(Map<String, dynamic> block, bool isMobile) {
    final stageName = (block['stageName'] ?? '').toString();
    final categoryName = (block['categoryName'] ?? '').toString();
    final modeLabel =
        _prizeWinnerMode(block) == 'ONLINE' ? 'Online' : 'Offline';
    final winners = (block['winners'] as List?)?.cast() ?? [];

    final title =
        '${categoryName.isNotEmpty ? categoryName : 'Category'}'
        '  •  $modeLabel'
        '  •  ${stageName.isNotEmpty ? 'Stage $stageName' : 'Stage'}';

    String _normSex(dynamic v) {
      final s = (v ?? '').toString().trim().toUpperCase();
      if (s.isEmpty) return '';
      if (s == 'MALE' || s == 'M' || s == 'BOY' || s == 'B') return 'MALE';
      if (s == 'FEMALE' || s == 'F' || s == 'GIRL' || s == 'G') {
        return 'FEMALE';
      }
      if (s.startsWith('MALE')) return 'MALE';
      if (s.startsWith('FEMALE')) return 'FEMALE';
      return '';
    }

    final maleWinners = winners.where((w) {
      final m = (w as Map).cast<String, dynamic>();
      return _normSex(m['sex'] ?? m['gender']) == 'MALE';
    }).toList();

    final femaleWinners = winners.where((w) {
      final m = (w as Map).cast<String, dynamic>();
      return _normSex(m['sex'] ?? m['gender']) == 'FEMALE';
    }).toList();

    final prizesCommon = block['prizesCommon'] == true;
    // Common prizes = one overall list (do not split into BOYS / GIRLS).
    final bool canSplitBySex =
        !prizesCommon &&
        winners.isNotEmpty &&
        (maleWinners.isNotEmpty || femaleWinners.isNotEmpty);

    Widget _renderWinners(List<dynamic> list) {
      return Column(
        children: list.map((w) {
          final m = (w as Map).cast<String, dynamic>();
          final prizeName = (m['prizeName'] ?? '').toString();
          final participantName = (m['participantName'] ?? '').toString();
          final regNo = (m['registrationNo'] ?? '').toString();
          final stageIdNum = (block['stageId'] as num?)?.toInt();
          final categoryIdNum = (block['categoryId'] as num?)?.toInt();
          final participantRegIdNum = (m['participantRegistrationId'] as num?)
              ?.toInt();
          final prizeRankNum = (m['prizeRank'] as num?)?.toInt();
          final inst = (m['institutionName'] ?? '').toString();
          final winnerGroupName = (m['groupName'] ?? '').toString();
          final totalScore = (m['totalScore'] ?? m['avgScore'] ?? 0).toString();
          final gradeName = (m['gradeName'] ?? '').toString().trim();
          final pendingTieBreaker = m['pendingTieBreaker'] == true;
          final prizeTied = m['prizeTied'] == true;
          final tbScore = m['tieBreakerScore'];
          final awardIsGrade =
              m['awardIsGrade'] == true ||
              (block['scoringMethod'] ?? '')
                  .toString()
                  .toUpperCase()
                  .contains('GRAD');
          // Prefer short grade letter on badge when backend sends "Grade A".
          final badgeLabel = () {
            if (awardIsGrade && gradeName.isNotEmpty) return gradeName;
            if (prizeName.isNotEmpty) return prizeName;
            return 'Rank';
          }();
          final awardLabel = awardIsGrade ? 'GRADE' : 'PRIZE';
          final awardValue = () {
            if (awardIsGrade) {
              if (gradeName.isNotEmpty) return gradeName;
              if (prizeName.isNotEmpty) {
                final p = prizeName.trim();
                final lower = p.toLowerCase();
                if (lower.startsWith('grade ')) {
                  return p.substring(6).trim();
                }
                return p;
              }
              return badgeLabel;
            }
            if (prizeName.isNotEmpty) return prizeName;
            return badgeLabel;
          }();

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            participantName.isNotEmpty
                                ? participantName
                                : 'Unknown',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (regNo.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              regNo,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (winnerGroupName.isNotEmpty || inst.isNotEmpty)
                        Text(
                          [
                            if (winnerGroupName.isNotEmpty) winnerGroupName,
                            if (inst.isNotEmpty) inst,
                          ].join(' - '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (pendingTieBreaker)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Same total — complete Tie Breaker to set 1st / 2nd',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        )
                      else if (prizeTied)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Tied on total marks',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        )
                      else if (tbScore is num && tbScore > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'TB: $tbScore',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          totalScore,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          awardLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          awardValue,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(width: isMobile ? 20 : 28),
                IconButton(
                  tooltip: 'Download certificate',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: Icon(
                    Icons.workspace_premium_outlined,
                    color: AppTheme.primaryColor,
                    size: isMobile ? 22 : 24,
                  ),
                  onPressed: () async {
                    final cid = int.tryParse(
                      controller.selectedCompetitionId.value ?? '',
                    );
                    if (cid == null ||
                        stageIdNum == null ||
                        categoryIdNum == null ||
                        participantRegIdNum == null) {
                      Get.snackbar(
                        'Error',
                        'Cannot download certificate: missing data',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                      return;
                    }
                    await _downloadPrizeWinnerCertificate(
                      competitionId: cid,
                      stageId: stageIdNum,
                      categoryId: categoryIdNum,
                      participantRegistrationId: participantRegIdNum,
                      prizeRank: prizeRankNum,
                      regNoForFilename: regNo,
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: isMobile ? 18 : 20,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: isMobile ? 13 : 14,
                    ),
                  ),
                ),
                Text(
                  '${winners.length} winner${winners.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (winners.isEmpty)
              _buildInfoCard(
                'No winners found for this block.',
                icon: Icons.emoji_events_outlined,
              )
            else
              canSplitBySex
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (maleWinners.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'BOYS',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.grey[800],
                                fontSize: 12,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          _renderWinners(maleWinners),
                          if (femaleWinners.isNotEmpty)
                            const SizedBox(height: 6),
                        ],
                        if (femaleWinners.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'GIRLS',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.grey[800],
                                fontSize: 12,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          _renderWinners(femaleWinners),
                        ],
                      ],
                    )
                  : _renderWinners(winners),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadPdf(Uint8List bytes, String filename) async {
    if (bytes.isEmpty) return;

    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: blobUrl)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(blobUrl);
      return;
    }

    final dataUri = Uri.dataFromBytes(bytes, mimeType: 'application/pdf');
    if (await canLaunchUrl(dataUri)) {
      await launchUrl(dataUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _printPrizeWinnersPdf() async {
    final competitionId = int.tryParse(
      controller.selectedCompetitionId.value ?? '',
    );
    if (competitionId == null) return;

    final resp = await _printRepository.getCompetitionPrizeWinnersPrintPdf(
      competitionId,
    );

    if (!resp.success || resp.data == null) {
      Get.snackbar(
        'Error',
        resp.message ?? 'Failed to generate Prize Winners PDF',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    await _downloadPdf(resp.data!, 'prize_winners_$competitionId.pdf');
  }

  Future<void> _downloadPrizeWinnerCertificate({
    required int competitionId,
    required int stageId,
    required int categoryId,
    required int participantRegistrationId,
    int? prizeRank,
    required String regNoForFilename,
  }) async {
    final resp = await _printRepository.getPrizeWinnerCertificatePdf(
      competitionId,
      stageId: stageId,
      categoryId: categoryId,
      participantRegistrationId: participantRegistrationId,
      prizeRank: prizeRank,
    );

    if (!resp.success || resp.data == null) {
      Get.snackbar(
        'Error',
        resp.message ?? 'Failed to generate certificate',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final safe = regNoForFilename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final suffix = safe.isNotEmpty
        ? safe
        : participantRegistrationId.toString();
    await _downloadPdf(
      resp.data!,
      'prize_certificate_${competitionId}_$suffix.pdf',
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _statTile(String label, String value, {VoidCallback? onTap}) {
    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );

    if (onTap == null) return tile;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: tile,
        ),
      ),
    );
  }

  Widget _miniPill(String label, String value, {VoidCallback? onTap}) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );

    if (onTap == null) return pill;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: pill,
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      elevation: 2,
      color: Colors.red[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.red[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String message, {required IconData icon}) {
    return Card(
      elevation: 2,
      color: Colors.blueGrey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.blueGrey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
