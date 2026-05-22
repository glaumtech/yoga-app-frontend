import 'dart:typed_data';
import 'dart:html' as html show Blob, Url, AnchorElement;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/competition_model.dart';
import '../../../data/repositories/reports_repository.dart';
import '../../controllers/reports_controller.dart';
import '../../widgets/admin_sidebar_layout.dart';
import 'reports_users_tab.dart';
import 'reports_participants_tab.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reports Screen
/// Displays various reports and analytics
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final ReportsController controller;
  final ReportsRepository _printRepository = ReportsRepository();

  @override
  void initState() {
    super.initState();
    controller = Get.put(ReportsController(), permanent: false);
    // Refresh competition list (/competition/list) + report summary on every
    // navigation to Reports (GetX controller may be reused across visits).
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.loadCompetitionsAndMaybeReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isWideWeb = screenWidth >= 1100;

    return AdminSidebarLayout(
      title: 'Reports',
      child: Obx(() {
        final isLoading = controller.isLoading.value;
        final error = controller.errorMessage.value;
        final report = controller.report.value;

        return DefaultTabController(
          length: 4,
          child: Column(
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
                  child: _buildTabs(isMobile),
                ),
              ),
              const SizedBox(height: 0),
              Expanded(
                child: TabBarView(
                  children: [
                    RefreshIndicator(
                      onRefresh: () async =>
                          controller.loadCompetitionsAndMaybeReport(),
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
                    RefreshIndicator(
                      onRefresh: () async =>
                          controller.loadCompetitionsAndMaybeReport(),
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
                    // Users tab (created users list)
                    const ReportsUsersTab(),
                    // Participants scores tab
                    const ReportsParticipantsTab(),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTabs(bool isMobile) {
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
        tabs: [
          Tab(
            height: isMobile ? 30 : 34,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text('Dashboard'),
            ),
          ),
          Tab(
            height: isMobile ? 30 : 34,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text('Prize Winners'),
            ),
          ),
          Tab(
            height: isMobile ? 30 : 34,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text('Users'),
            ),
          ),
          Tab(
            height: isMobile ? 30 : 34,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text('Participants'),
            ),
          ),
        ],
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
        const SizedBox(height: 20),
      ] else ...[
        _buildCategoryCountsSection(report, isMobile),
        const SizedBox(height: 12),
        _buildPrefixAgeSection(report, isMobile),
        const SizedBox(height: 12),
        _buildInstitutionsSection(report, isMobile),
        const SizedBox(height: 20),
      ],
    ];
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

          final dropdown = DropdownButtonFormField<String>(
            value: selectedId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Competition',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: isMobile ? 10 : 12,
              ),
            ),
            items: competitions
                .map(
                  (CompetitionModel c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(
                      c.competitionName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => controller.setSelectedCompetition(v),
          );

          final refreshButton = IconButton(
            tooltip: 'Refresh',
            onPressed: () => controller.loadCompetitionsAndMaybeReport(),
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
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
                _statTile('Total Participants', '$totalParticipants'),
                _statTile('No of Boys', '$boys'),
                _statTile('No of Girls', '$girls'),
                _statTile('Common Category', '$common'),
                _statTile('Special Category', '$special'),
                _statTile('Champions Category', '$champions'),
                _statTile('Online Registration', '$onlineRegistrations'),
                _statTile('Spot Registration', '$spotRegistrations'),
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
                    (e) => Chip(
                      label: Text('${e.key}: ${e.value}'),
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                      side: BorderSide(
                        color: AppTheme.primaryColor.withOpacity(0.25),
                      ),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
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
    final prefixAgeCounts =
        (report['prefixAgeCounts'] as Map?)?.cast<String, dynamic>() ?? {};

    if (prefixAgeCounts.isEmpty) {
      return _buildInfoCard(
        'No Age data found (needs registrationNo + age).',
        icon: Icons.group,
      );
    }

    final prefixKeys = prefixAgeCounts.keys.toList()..sort();

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
            ...prefixKeys.map((prefix) {
              final agesMap =
                  (prefixAgeCounts[prefix] as Map?)?.cast<String, dynamic>() ??
                  {};
              final ageKeys = agesMap.keys.toList()
                ..sort((a, b) {
                  final ai = int.tryParse(a) ?? 0;
                  final bi = int.tryParse(b) ?? 0;
                  return ai.compareTo(bi);
                });

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prefix,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ageKeys
                          .map(
                            (age) =>
                                _miniPill('Age $age', '${agesMap[age] ?? 0}'),
                          )
                          .toList(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildInstitutionsSection(Map<String, dynamic> report, bool isMobile) {
    final institutions =
        (report['institutions'] as Map?)?.cast<String, dynamic>() ?? {};

    final totalInstitutions =
        institutions['totalInstitutionsParticipated'] ?? 0;
    final totalSchools = institutions['totalSchoolsParticipated'] ?? 0;
    final totalColleges = institutions['totalCollegesParticipated'] ?? 0;
    final list =
        (institutions['institutionsByParticipantCount'] as List?)?.cast() ?? [];

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
                _statTile('Total Institutions', '$totalInstitutions'),
                _statTile('Total Schools', '$totalSchools'),
                _statTile('Total Colleges', '$totalColleges'),
              ],
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              _buildInfoCard(
                'No institution list found.',
                icon: Icons.school_outlined,
              )
            else
              Column(
                children: list.take(30).map((row) {
                  final m = (row as Map).cast<String, dynamic>();
                  final name = (m['institutionName'] ?? '').toString();
                  final count = (m['participantCount'] ?? 0).toString();
                  final type = (m['institutionType'] ?? '').toString();

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Text(
                        count,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      name.isNotEmpty ? name : 'Unknown institution',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: type.isNotEmpty ? Text(type) : null,
                  );
                }).toList(),
              ),
            if (list.length > 30) ...[
              const SizedBox(height: 8),
              Text(
                'Showing top 30 institutions (by participants).',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
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

    // Group blocks by stage so mobile UI can use tabs per stage.
    final stageNames =
        blocks
            .map((b) => ((b as Map)['stageName'] ?? '').toString().trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final Map<String, List<Map<String, dynamic>>> blocksByStage = {};
    for (final b in blocks) {
      final m = (b as Map).cast<String, dynamic>();
      final stage = (m['stageName'] ?? '').toString().trim();
      final key = stage.isNotEmpty ? stage : 'Stage';
      blocksByStage.putIfAbsent(key, () => []).add(m);
    }

    // Stable ordering inside each stage: categoryName then stageName then groupName.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('Prize Winners (Category Wise)')),
            IconButton(
              tooltip: 'Print Prize Winners',
              icon: const Icon(Icons.print, color: AppTheme.primaryColor),
              onPressed: _printPrizeWinnersPdf,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (stageNames.length >= 2)
          DefaultTabController(
            length: stageNames.length,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
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
                    tabs: stageNames
                        .map(
                          (s) => Tab(
                            height: isMobile ? 30 : 34,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text('Stage $s'),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 10),
                // In a ListView already; use a fixed height for TabBarView.
                SizedBox(
                  height: isMobile ? 700 : 520,
                  child: TabBarView(
                    children: stageNames.map((stage) {
                      final stageBlocks =
                          blocksByStage[stage]?.cast<Map<String, dynamic>>() ??
                          const <Map<String, dynamic>>[];
                      return ListView(
                        padding: EdgeInsets.zero,
                        children: stageBlocks
                            .map(
                              (block) =>
                                  _buildPrizeWinnersBlock(block, isMobile),
                            )
                            .toList(),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          )
        else
          ...blocksByStage.values
              .expand((list) => list)
              .map((block) => _buildPrizeWinnersBlock(block, isMobile)),
      ],
    );
  }

  Widget _buildPrizeWinnersBlock(Map<String, dynamic> block, bool isMobile) {
    final stageName = (block['stageName'] ?? '').toString();
    final categoryName = (block['categoryName'] ?? '').toString();
    final winners = (block['winners'] as List?)?.cast() ?? [];

    final title =
        '${categoryName.isNotEmpty ? categoryName : 'Category'}'
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

    final bool canSplitBySex =
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
                    prizeName.isNotEmpty ? prizeName : 'Rank',
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
                    ],
                  ),
                ),
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
                const SizedBox(width: 4),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
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
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryColor,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Container(
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
            style: const TextStyle(
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
  }

  Widget _miniPill(String label, String value) {
    return Container(
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
