import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/competition_model.dart';
import '../../controllers/reports_controller.dart';
import '../../widgets/admin_sidebar_layout.dart';
import 'reports_users_tab.dart';
import 'reports_participants_tab.dart';

/// Reports Screen
/// Displays various reports and analytics
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final ReportsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(ReportsController(), permanent: false);
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

          return Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedId,
                  decoration: InputDecoration(
                    labelText: 'Competition',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: competitions
                      .map(
                        (CompetitionModel c) => DropdownMenuItem<String>(
                          value: c.id,
                          child: Text(
                            c.competitionName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => controller.setSelectedCompetition(v),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => controller.loadCompetitionsAndMaybeReport(),
                icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
              ),
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
        'No prefix/age data found (needs registrationNo + age).',
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
            _sectionTitle('Prefix + Age Counts'),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Prize Winners (Category Wise)'),
        const SizedBox(height: 10),
        ...blocks.map((b) {
          final block = (b as Map).cast<String, dynamic>();
          final stageName = (block['stageName'] ?? '').toString();
          final categoryName = (block['categoryName'] ?? '').toString();
          final groupName = (block['groupName'] ?? '').toString();
          final winners = (block['winners'] as List?)?.cast() ?? [];

          final title =
              '${categoryName.isNotEmpty ? categoryName : 'Category'}'
              '  •  ${stageName.isNotEmpty ? 'Stage $stageName' : 'Stage'}'
              '  •  ${groupName.isNotEmpty ? groupName : 'Group'}';

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                    Column(
                      children: winners.map((w) {
                        final m = (w as Map).cast<String, dynamic>();
                        final prizeName = (m['prizeName'] ?? '').toString();
                        final participantName = (m['participantName'] ?? '')
                            .toString();
                        final regNo = (m['registrationNo'] ?? '').toString();
                        final inst = (m['institutionName'] ?? '').toString();
                        final avg = (m['avgScore'] ?? 0).toString();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
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
                                    Text(
                                      participantName.isNotEmpty
                                          ? participantName
                                          : 'Unknown',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        if (regNo.isNotEmpty) regNo,
                                        if (inst.isNotEmpty) inst,
                                      ].join(' • '),
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
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'AVG',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    avg,
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
                    ),
                ],
              ),
            ),
          );
        }),
      ],
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
