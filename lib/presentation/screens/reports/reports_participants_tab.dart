import 'dart:typed_data';
import 'dart:html' as html show Blob, Url, AnchorElement;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../controllers/reports_participants_tab_controller.dart';
import '../../../data/repositories/reports_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportsParticipantsTab extends StatelessWidget {
  const ReportsParticipantsTab({super.key});

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

  Future<void> _downloadExcel(Uint8List bytes, String filename) async {
    if (bytes.isEmpty) return;

    const excelMime =
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

    if (kIsWeb) {
      final blob = html.Blob([bytes], excelMime);
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: blobUrl)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(blobUrl);
      return;
    }

    final dataUri = Uri.dataFromBytes(bytes, mimeType: excelMime);
    if (await canLaunchUrl(dataUri)) {
      await launchUrl(dataUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabController = Get.put(
      ReportsParticipantsTabController(),
      permanent: false,
    );

    Future<void> _printParticipants() async {
      final repo = ReportsRepository();
      final competitionId = int.tryParse(
        tabController.reportsController.selectedCompetitionId.value ?? '',
      );
      if (competitionId == null) return;

      final resp = await repo.getCompetitionParticipantsPrintPdf(
        competitionId,
        stageId: tabController.selectedStageId.value,
        categoryId: tabController.selectedCategoryId.value,
        groupId: tabController.selectedGroupId.value,
      );

      if (!resp.success || resp.data == null) {
        Get.snackbar(
          'Error',
          resp.message ?? 'Failed to generate Participants PDF',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await _downloadPdf(resp.data!, 'participants_$competitionId.pdf');
    }

    Future<void> _downloadParticipantsExcel() async {
      final competitionId = int.tryParse(
        tabController.reportsController.selectedCompetitionId.value ?? '',
      );
      if (competitionId == null) return;

      final resp = await tabController.getParticipantsScoresExcel();

      if (!resp.success || resp.data == null) {
        Get.snackbar(
          'Error',
          resp.message ?? 'Failed to generate Participants Excel',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      await _downloadExcel(resp.data!, 'participants_$competitionId.xlsx');
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Obx(() {
      if (tabController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (tabController.errorMessage.value.isNotEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 12),
                Text(
                  tabController.errorMessage.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[700]),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: tabController.refresh,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      final payload = tabController.data.value;
      final blocks = (payload?['blocks'] as List?)?.cast() ?? const [];
      final query = tabController.participantSearchQuery.value
          .trim()
          .toLowerCase();
      final visibleBlocks = query.isEmpty
          ? blocks
          : blocks.where((b) {
              final block = (b as Map).cast<String, dynamic>();
              final participants =
                  (block['participants'] as List?)?.cast() ?? const [];
              return participants.any((p) {
                final m = (p as Map).cast<String, dynamic>();
                final name = (m['participantName'] ?? '')
                    .toString()
                    .toLowerCase();
                return name.contains(query);
              });
            }).toList();

      return RefreshIndicator(
        onRefresh: tabController.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          children: [
            _buildFilters(
              tabController,
              isMobile,
              onPrint: _printParticipants,
              onDownloadExcel: _downloadParticipantsExcel,
            ),
            const SizedBox(height: 12),
            if (payload == null)
              _infoCard('Select a competition to view participant scores.')
            else if (blocks.isEmpty)
              _infoCard('No participant scores found yet.')
            else if (visibleBlocks.isEmpty)
              _infoCard('No participants match your search.')
            else ...[
              ...visibleBlocks.map((b) {
                final block = (b as Map).cast<String, dynamic>();
                final stageName = (block['stageName'] ?? '').toString();
                final categoryName = (block['categoryName'] ?? '').toString();
                final groupName = (block['groupName'] ?? '').toString();
                final participants =
                    (block['participants'] as List?)?.cast() ?? const [];

                final filteredParticipants = participants.where((p) {
                  final m = (p as Map).cast<String, dynamic>();
                  final name = (m['participantName'] ?? '')
                      .toString()
                      .toLowerCase();
                  if (query.isEmpty) return true;
                  return name.contains(query);
                }).toList();

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
                              '${filteredParticipants.length} participant${filteredParticipants.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (filteredParticipants.isEmpty)
                          _infoCard(
                            'No scored participants found for this block.',
                          )
                        else
                          ...filteredParticipants.map((p) {
                            final m = (p as Map).cast<String, dynamic>();
                            return _participantCard(m, isMobile);
                          }).toList(),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildFilters(
    ReportsParticipantsTabController controller,
    bool isMobile, {
    required VoidCallback onPrint,
    required VoidCallback onDownloadExcel,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 10 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: AppTheme.primaryColor,
                  size: isMobile ? 18 : 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Filters',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    controller.clearFilters();
                    await controller.refresh();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(0, 0),
                  ),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: controller.setParticipantSearchQuery,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppTheme.primaryColor,
                      ),
                      hintText: 'Search participant name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Print Participants',
                  icon: const Icon(Icons.print, color: AppTheme.primaryColor),
                  onPressed: onPrint,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Download Participants Excel',
                  icon: const Icon(
                    Icons.download,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: onDownloadExcel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            isMobile
                ? Column(
                    children: [
                      _dropdown(
                        label: 'Stage',
                        value: controller.selectedStageId.value,
                        items: controller.stageOptions,
                        onChanged: (v) => controller.setStage(v),
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 8),
                      _dropdown(
                        label: 'Category',
                        value: controller.selectedCategoryId.value,
                        items: controller.categoryOptions,
                        onChanged: (v) => controller.setCategory(v),
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 8),
                      _dropdown(
                        label: 'Group',
                        value: controller.selectedGroupId.value,
                        items: controller.groupOptions,
                        onChanged: (v) => controller.setGroup(v),
                        isMobile: isMobile,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _dropdown(
                          label: 'Stage',
                          value: controller.selectedStageId.value,
                          items: controller.stageOptions,
                          onChanged: (v) => controller.setStage(v),
                          isMobile: isMobile,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dropdown(
                          label: 'Category',
                          value: controller.selectedCategoryId.value,
                          items: controller.categoryOptions,
                          onChanged: (v) => controller.setCategory(v),
                          isMobile: isMobile,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dropdown(
                          label: 'Group',
                          value: controller.selectedGroupId.value,
                          items: controller.groupOptions,
                          onChanged: (v) => controller.setGroup(v),
                          isMobile: isMobile,
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required int? value,
    required List<Map<String, dynamic>> items,
    required void Function(int?) onChanged,
    required bool isMobile,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: isMobile ? 12 : 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey[700],
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isMobile ? 10 : 12,
        ),
      ),
      items: [
        const DropdownMenuItem<int>(value: null, child: Text('All')),
        ...items.map((m) {
          final id = (m['id'] as int?) ?? 0;
          final name = (m['name'] ?? '').toString();
          return DropdownMenuItem<int>(
            value: id,
            child: Text(
              name.isNotEmpty ? name : id.toString(),
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ],
      onChanged: onChanged,
    );
  }

  Widget _participantCard(Map<String, dynamic> p, bool isMobile) {
    final name = (p['participantName'] ?? '').toString();
    final regNo = (p['registrationNo'] ?? '').toString();
    final inst = (p['institutionName'] ?? '').toString();
    final juryCount = (p['juryCount'] ?? 0).toString();
    final avgTotal =
        (double.tryParse((p['avgGrandTotal'] ?? 0).toString()) ?? 0.0)
            .toStringAsFixed(2);
    final juryScores = (p['juryScores'] as List?)?.cast() ?? const [];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 14,
            vertical: isMobile ? 6 : 8,
          ),
          childrenPadding: EdgeInsets.fromLTRB(
            isMobile ? 12 : 14,
            0,
            isMobile ? 12 : 14,
            isMobile ? 12 : 14,
          ),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : 'Unknown participant',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: isMobile ? 13 : 14,
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
                    'AVG TOTAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    avgTotal,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    'Juries: $juryCount',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            if (juryScores.isEmpty)
              Text(
                'No jury scores.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              ...juryScores.map((js) {
                final m = (js as Map).cast<String, dynamic>();
                final juryId = (m['juryId'] ?? '').toString();
                final juryName = (m['juryName'] ?? '').toString().trim();
                final juryLabel = juryName.isNotEmpty ? juryName : juryId;
                final total =
                    (double.tryParse((m['grandTotal'] ?? 0).toString()) ?? 0.0)
                        .toStringAsFixed(2);
                final asanaScores =
                    (m['asanaScores'] as Map?)?.cast<String, dynamic>() ?? {};

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              juryLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Total: $total',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final entry in asanaScores.entries)
                            _pill(entry.key, (entry.value ?? 0).toString()),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _infoCard(String message) {
    return Card(
      elevation: 2,
      color: Colors.blueGrey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.primaryColor),
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
