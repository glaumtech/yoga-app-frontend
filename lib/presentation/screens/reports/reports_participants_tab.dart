import 'dart:async' show Timer, unawaited;
import 'dart:typed_data';
import 'dart:html' as html show Blob, Url, AnchorElement;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../controllers/reports_participants_tab_controller.dart';
import '../../../data/models/city_model.dart';
import '../../../data/models/school_model.dart';
import '../../../data/models/state_model.dart';
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
        stageIds: tabController.selectedStageIds.isEmpty
            ? null
            : List<int>.from(tabController.selectedStageIds),
        categoryIds: tabController.selectedCategoryIds.isEmpty
            ? null
            : List<int>.from(tabController.selectedCategoryIds),
        groupIds: tabController.selectedGroupIds.isEmpty
            ? null
            : List<int>.from(tabController.selectedGroupIds),
        stateId: tabController.selectedStateId.value,
        cityId: tabController.selectedCityId.value,
        institutionId: tabController.selectedInstitutionId.value,
        genders: tabController.selectedGenders.isEmpty
            ? null
            : List<String>.from(tabController.selectedGenders),
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

      if (tabController.selectedStageIds.length != 1) {
        Get.snackbar(
          'Stage required',
          'Select exactly one stage in Report filters to download Excel.',
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
        );
        return;
      }

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
              context,
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
    BuildContext context,
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Obx(() {
                  final n = controller.activeFilterCount;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (ctx) =>
                              _ParticipantFiltersDialog(controller: controller),
                        );
                      },
                      icon: Badge(
                        isLabelVisible: n > 0,
                        label: Text('$n'),
                        child: const Icon(
                          Icons.tune,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      label: Text(
                        isMobile ? 'Filters' : 'Report filters',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 6),
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
                Obx(() {
                  final stageSelected = controller.selectedStageIds.length == 1;
                  return IconButton(
                    tooltip: stageSelected
                        ? 'Download Participants Excel'
                        : 'Select exactly one stage in Report filters (Excel)',
                    icon: Icon(
                      Icons.download,
                      color: stageSelected
                          ? AppTheme.primaryColor
                          : Colors.grey,
                    ),
                    onPressed: stageSelected ? onDownloadExcel : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Use Report filters for stage, category, group, state, city, institution, and gender.',
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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

class _ParticipantFiltersDialog extends StatefulWidget {
  const _ParticipantFiltersDialog({required this.controller});

  final ReportsParticipantsTabController controller;

  @override
  State<_ParticipantFiltersDialog> createState() =>
      _ParticipantFiltersDialogState();
}

class _ParticipantFiltersDialogState extends State<_ParticipantFiltersDialog> {
  late Set<int> _stages;
  late Set<int> _categories;
  late Set<int> _groups;
  late Set<String> _genders;
  int? _state;
  int? _city;
  int? _institution;
  bool _loadingLists = true;

  /// Refresh hints when async loads finish (institution field is not wrapped in Obx).
  Worker? _filterInstitutionsRxWorker;

  final TextEditingController _stateSearchController = TextEditingController();
  final TextEditingController _citySearchController = TextEditingController();
  final TextEditingController _institutionSearchController =
      TextEditingController();
  final FocusNode _stateFocus = FocusNode();
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _institutionFocus = FocusNode();

  /// Focus drops before ListTile [onTap] runs; panels keyed only on [hasFocus]
  /// disappear and swallow the tap. Keep panels mounted briefly after blur.
  Timer? _stateSuggestionsHideTimer;
  Timer? _citySuggestionsHideTimer;
  Timer? _institutionSuggestionsHideTimer;

  bool _stateSuggestionsVisible = false;
  bool _citySuggestionsVisible = false;
  bool _institutionSuggestionsVisible = false;

  static const Duration _locationSuggestionHideDelay = Duration(
    milliseconds: 220,
  );

  void _scheduleHideStateSuggestions() {
    _stateSuggestionsHideTimer?.cancel();
    _stateSuggestionsHideTimer = Timer(_locationSuggestionHideDelay, () {
      if (!mounted || _stateFocus.hasFocus) return;
      setState(() => _stateSuggestionsVisible = false);
    });
  }

  void _scheduleHideCitySuggestions() {
    _citySuggestionsHideTimer?.cancel();
    _citySuggestionsHideTimer = Timer(_locationSuggestionHideDelay, () {
      if (!mounted || _cityFocus.hasFocus) return;
      setState(() => _citySuggestionsVisible = false);
    });
  }

  void _scheduleHideInstitutionSuggestions() {
    _institutionSuggestionsHideTimer?.cancel();
    _institutionSuggestionsHideTimer = Timer(_locationSuggestionHideDelay, () {
      if (!mounted || _institutionFocus.hasFocus) return;
      setState(() => _institutionSuggestionsVisible = false);
    });
  }

  void _onStateFocusChanged() {
    if (_stateFocus.hasFocus) {
      _stateSuggestionsHideTimer?.cancel();
      setState(() => _stateSuggestionsVisible = true);
    } else {
      _scheduleHideStateSuggestions();
      unawaited(_syncStateFromSearchQuery());
    }
    setState(() {});
  }

  void _onCityFocusChanged() {
    if (_cityFocus.hasFocus) {
      _citySuggestionsHideTimer?.cancel();
      setState(() => _citySuggestionsVisible = true);
    } else {
      _scheduleHideCitySuggestions();
      unawaited(_syncCityFromSearchQuery());
    }
    setState(() {});
  }

  void _onInstitutionFocusChanged() {
    if (_institutionFocus.hasFocus) {
      _institutionSuggestionsHideTimer?.cancel();
      setState(() => _institutionSuggestionsVisible = true);
    } else {
      _scheduleHideInstitutionSuggestions();
      unawaited(_syncInstitutionFromSearchQuery());
    }
    setState(() {});
  }

  /// Ensures the TextField shows programmatic updates (web / nested rebuilds).
  static void _setFilterFieldText(TextEditingController c, String text) {
    c.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// When the typed query matches exactly one state, commit selection and load cities.
  Future<void> _syncStateFromSearchQuery() async {
    final q = _stateSearchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      if (_state != null) {
        setState(() {
          _state = null;
          _city = null;
          _institution = null;
          _citySearchController.clear();
          _institutionSearchController.clear();
        });
        await widget.controller.reloadFilterCitiesForState(null);
        if (mounted) setState(() {});
      }
      return;
    }

    final m = widget.controller.filterStateOptions
        .where((s) => s.stateName.toLowerCase().contains(q))
        .toList();
    if (m.length != 1) return;

    final s = m.first;
    if (_state == s.id &&
        _stateSearchController.text.trim() == s.stateName.trim()) {
      return;
    }

    setState(() {
      _state = s.id;
      _setFilterFieldText(_stateSearchController, s.stateName);
      _city = null;
      _institution = null;
      _citySearchController.clear();
      _institutionSearchController.clear();
    });

    await widget.controller.reloadFilterCitiesForState(s.id);
    await widget.controller.reloadFilterInstitutions(
      stateId: s.id,
      cityId: null,
    );
    if (mounted) setState(() {});
  }

  Future<void> _syncCityFromSearchQuery() async {
    if (_state == null || _state! <= 0) return;
    final q = _citySearchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      if (_city != null) {
        setState(() {
          _city = null;
          _institution = null;
          _institutionSearchController.clear();
        });
        await widget.controller.reloadFilterInstitutions(
          stateId: _state,
          cityId: null,
        );
        if (mounted) setState(() {});
      }
      return;
    }

    final m = widget.controller.filterCityOptions
        .where((c) => c.cityName.toLowerCase().contains(q))
        .toList();
    if (m.length != 1) return;

    final city = m.first;
    if (_city == city.id &&
        _citySearchController.text.trim() == city.cityName.trim()) {
      return;
    }

    setState(() {
      _city = city.id;
      _setFilterFieldText(_citySearchController, city.cityName);
      _institution = null;
      _institutionSearchController.clear();
    });
    await widget.controller.reloadFilterInstitutions(
      stateId: _state,
      cityId: city.id,
    );
    if (mounted) setState(() {});
  }

  Future<void> _syncInstitutionFromSearchQuery() async {
    if (_state == null || _state! <= 0) return;
    final q = _institutionSearchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      if (_institution != null) {
        setState(() => _institution = null);
      }
      return;
    }

    final m = widget.controller.filterInstitutionOptions
        .where((s) => int.tryParse(s.id ?? '') != null)
        .where((s) => s.institutionName.toLowerCase().contains(q))
        .toList();
    if (m.length != 1) return;

    final inst = m.first;
    final id = int.tryParse(inst.id ?? '');
    if (id == null) return;
    if (_institution == id &&
        _institutionSearchController.text.trim() ==
            inst.institutionName.trim()) {
      return;
    }

    setState(() {
      _institution = id;
      _setFilterFieldText(_institutionSearchController, inst.institutionName);
    });
  }

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    _stages = Set<int>.from(c.selectedStageIds);
    _categories = Set<int>.from(c.selectedCategoryIds);
    _groups = Set<int>.from(c.selectedGroupIds);
    _genders = Set<String>.from(c.selectedGenders);
    _state = c.selectedStateId.value;
    _city = c.selectedCityId.value;
    _institution = c.selectedInstitutionId.value;
    _stateFocus.addListener(_onStateFocusChanged);
    _cityFocus.addListener(_onCityFocusChanged);
    _institutionFocus.addListener(_onInstitutionFocusChanged);
    _filterInstitutionsRxWorker = ever(
      widget.controller.filterInstitutionOptions,
      (_) {
        if (mounted) setState(() {});
      },
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loadingLists = true);
    await widget.controller.prefetchFilterListsForDialog();
    if (mounted) {
      _syncSearchLabels();
      setState(() => _loadingLists = false);
    }
  }

  void _syncSearchLabels() {
    final sid = _state;
    if (sid != null) {
      for (final s in widget.controller.filterStateOptions) {
        if (s.id == sid) {
          _setFilterFieldText(_stateSearchController, s.stateName);
          break;
        }
      }
    }
    final cid = _city;
    if (cid != null) {
      for (final c in widget.controller.filterCityOptions) {
        if (c.id == cid) {
          _setFilterFieldText(_citySearchController, c.cityName);
          break;
        }
      }
    }
    final iid = _institution;
    if (iid != null) {
      for (final inst in widget.controller.filterInstitutionOptions) {
        final parsed = int.tryParse(inst.id ?? '');
        if (parsed == iid) {
          _setFilterFieldText(
            _institutionSearchController,
            inst.institutionName,
          );
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _stateSuggestionsHideTimer?.cancel();
    _citySuggestionsHideTimer?.cancel();
    _institutionSuggestionsHideTimer?.cancel();
    _filterInstitutionsRxWorker?.dispose();
    _stateFocus.removeListener(_onStateFocusChanged);
    _cityFocus.removeListener(_onCityFocusChanged);
    _institutionFocus.removeListener(_onInstitutionFocusChanged);
    _stateSearchController.dispose();
    _citySearchController.dispose();
    _institutionSearchController.dispose();
    _stateFocus.dispose();
    _cityFocus.dispose();
    _institutionFocus.dispose();
    super.dispose();
  }

  Iterable<StateModel> _filteredStates() {
    final q = _stateSearchController.text.trim().toLowerCase();
    final all = widget.controller.filterStateOptions;
    if (q.isEmpty) return all.take(80);
    return all.where((s) => s.stateName.toLowerCase().contains(q)).take(100);
  }

  Iterable<CityModel> _filteredCities() {
    final q = _citySearchController.text.trim().toLowerCase();
    final all = widget.controller.filterCityOptions;
    if (q.isEmpty) return all.take(100);
    return all.where((c) => c.cityName.toLowerCase().contains(q)).take(100);
  }

  Iterable<SchoolModel> _filteredInstitutions() {
    final q = _institutionSearchController.text.trim().toLowerCase();
    final all = widget.controller.filterInstitutionOptions.where(
      (s) => int.tryParse(s.id ?? '') != null,
    );
    if (q.isEmpty) return all.take(120);
    return all
        .where((s) => s.institutionName.toLowerCase().contains(q))
        .take(150);
  }

  /// If user typed search text but did not tap a row, resolve a unique match before Apply.
  void _resolveLocationSelectionsBeforeApply() {
    if (_state == null) {
      final q = _stateSearchController.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final m = widget.controller.filterStateOptions
            .where((s) => s.stateName.toLowerCase().contains(q))
            .toList();
        if (m.length == 1) {
          _state = m.first.id;
          _setFilterFieldText(_stateSearchController, m.first.stateName);
        }
      }
    }
    if (_state != null && _city == null) {
      final q = _citySearchController.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final m = widget.controller.filterCityOptions
            .where((c) => c.cityName.toLowerCase().contains(q))
            .toList();
        if (m.length == 1) {
          _city = m.first.id;
          _setFilterFieldText(_citySearchController, m.first.cityName);
        }
      }
    }
    if (_state != null && _institution == null) {
      final q = _institutionSearchController.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final m = widget.controller.filterInstitutionOptions
            .where((s) => int.tryParse(s.id ?? '') != null)
            .where((s) => s.institutionName.toLowerCase().contains(q))
            .toList();
        if (m.length == 1) {
          final id = int.tryParse(m.first.id ?? '');
          if (id != null) {
            _institution = id;
            _setFilterFieldText(
              _institutionSearchController,
              m.first.institutionName,
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 560;
    return AlertDialog(
      title: const Text('Report filters'),
      content: SizedBox(
        width: isMobile ? double.maxFinite : 440,
        child: _loadingLists
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Obx(
                      () => Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _checkboxFilterColumn(
                            title: 'Stage',
                            isMobile: isMobile,
                            options: widget.controller.stageOptions.toList(),
                            selected: _stages,
                            onToggle: (id, on) => setState(() {
                              if (on) {
                                _stages.add(id);
                              } else {
                                _stages.remove(id);
                              }
                            }),
                          ),
                          const SizedBox(height: 10),
                          _checkboxFilterColumn(
                            title: 'Category',
                            isMobile: isMobile,
                            options: widget.controller.categoryOptions.toList(),
                            selected: _categories,
                            onToggle: (id, on) => setState(() {
                              if (on) {
                                _categories.add(id);
                              } else {
                                _categories.remove(id);
                              }
                            }),
                          ),
                          const SizedBox(height: 10),
                          _checkboxFilterColumn(
                            title: 'Group',
                            isMobile: isMobile,
                            options: widget.controller.groupOptions.toList(),
                            selected: _groups,
                            onToggle: (id, on) => setState(() {
                              if (on) {
                                _groups.add(id);
                              } else {
                                _groups.remove(id);
                              }
                            }),
                          ),
                          const SizedBox(height: 10),
                          _genderCheckboxSection(
                            isMobile: isMobile,
                            selected: _genders,
                            onChanged: (g, on) => setState(() {
                              if (on) {
                                _genders.add(g);
                              } else {
                                _genders.remove(g);
                              }
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'State (search)',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      key: const ValueKey('report_filter_state_field'),
                      controller: _stateSearchController,
                      focusNode: _stateFocus,
                      onChanged: (_) {
                        setState(() {});
                        unawaited(_syncStateFromSearchQuery());
                      },
                      decoration: InputDecoration(
                        hintText: 'Type to search states',
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                      ),
                    ),
                    if (_stateSuggestionsVisible)
                      SizedBox(
                        height: 120,
                        child: Material(
                          elevation: 1,
                          borderRadius: BorderRadius.circular(8),
                          child: ListView(
                            primary: false,
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            children: [
                              ListTile(
                                dense: true,
                                title: const Text(
                                  'All states',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                onTap: () async {
                                  _stateSuggestionsHideTimer?.cancel();
                                  setState(() {
                                    _stateSuggestionsVisible = false;
                                    _state = null;
                                    _city = null;
                                    _institution = null;
                                    _stateSearchController.clear();
                                    _citySearchController.clear();
                                    _institutionSearchController.clear();
                                  });
                                  await widget.controller
                                      .reloadFilterCitiesForState(null);
                                  _stateFocus.unfocus();
                                },
                              ),
                              ..._filteredStates().map((s) {
                                return ListTile(
                                  dense: true,
                                  title: Text(s.stateName),
                                  onTap: () async {
                                    _stateSuggestionsHideTimer?.cancel();
                                    setState(() {
                                      _stateSuggestionsVisible = false;
                                      _state = s.id;
                                      _city = null;
                                      _institution = null;
                                      _setFilterFieldText(
                                        _stateSearchController,
                                        s.stateName,
                                      );
                                      _citySearchController.clear();
                                      _institutionSearchController.clear();
                                    });
                                    await widget.controller
                                        .reloadFilterCitiesForState(s.id);
                                    await widget.controller
                                        .reloadFilterInstitutions(
                                          stateId: s.id,
                                          cityId: null,
                                        );
                                    _stateFocus.unfocus();
                                    if (mounted) setState(() {});
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'City (search)',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      key: const ValueKey('report_filter_city_field'),
                      controller: _citySearchController,
                      focusNode: _cityFocus,
                      enabled: _state != null && _state! > 0,
                      onChanged: (_) {
                        setState(() {});
                        unawaited(_syncCityFromSearchQuery());
                      },
                      decoration: InputDecoration(
                        hintText: _state == null
                            ? 'Select a state first'
                            : 'Type to search cities',
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                      ),
                    ),
                    if (_state != null &&
                        _state! > 0 &&
                        _citySuggestionsVisible)
                      SizedBox(
                        height: 120,
                        child: Material(
                          elevation: 1,
                          borderRadius: BorderRadius.circular(8),
                          child: ListView(
                            primary: false,
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            children: [
                              ListTile(
                                dense: true,
                                title: const Text(
                                  'All cities',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                onTap: () async {
                                  _citySuggestionsHideTimer?.cancel();
                                  setState(() {
                                    _citySuggestionsVisible = false;
                                    _city = null;
                                    _institution = null;
                                    _citySearchController.clear();
                                    _institutionSearchController.clear();
                                  });
                                  await widget.controller
                                      .reloadFilterInstitutions(
                                        stateId: _state,
                                        cityId: null,
                                      );
                                  _cityFocus.unfocus();
                                  if (mounted) setState(() {});
                                },
                              ),
                              ..._filteredCities().map((c) {
                                return ListTile(
                                  dense: true,
                                  title: Text(c.cityName),
                                  onTap: () async {
                                    _citySuggestionsHideTimer?.cancel();
                                    setState(() {
                                      _citySuggestionsVisible = false;
                                      _city = c.id;
                                      _institution = null;
                                      _setFilterFieldText(
                                        _citySearchController,
                                        c.cityName,
                                      );
                                      _institutionSearchController.clear();
                                    });
                                    await widget.controller
                                        .reloadFilterInstitutions(
                                          stateId: _state,
                                          cityId: c.id,
                                        );
                                    _cityFocus.unfocus();
                                    if (mounted) setState(() {});
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Institution (search)',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      key: const ValueKey('report_filter_institution_field'),
                      controller: _institutionSearchController,
                      focusNode: _institutionFocus,
                      enabled: _state != null && _state! > 0,
                      onChanged: (_) {
                        setState(() {});
                        unawaited(_syncInstitutionFromSearchQuery());
                      },
                      decoration: InputDecoration(
                        hintText: _state == null
                            ? 'Select a state first'
                            : widget.controller.filterInstitutionOptions.isEmpty
                            ? 'No institutions for this location'
                            : 'Type to search institutions',
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                      ),
                    ),
                    if (_state != null &&
                        _state! > 0 &&
                        widget.controller.filterInstitutionOptions.isNotEmpty &&
                        _institutionSuggestionsVisible)
                      SizedBox(
                        height: 200,
                        child: Material(
                          elevation: 1,
                          borderRadius: BorderRadius.circular(8),
                          child: ListView(
                            primary: false,
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            children: [
                              ListTile(
                                dense: true,
                                title: const Text(
                                  'All institutions',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                onTap: () {
                                  _institutionSuggestionsHideTimer?.cancel();
                                  setState(() {
                                    _institutionSuggestionsVisible = false;
                                    _institution = null;
                                    _institutionSearchController.clear();
                                  });
                                  _institutionFocus.unfocus();
                                },
                              ),
                              ..._filteredInstitutions().map((inst) {
                                final id = int.tryParse(inst.id ?? '')!;
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    inst.institutionName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    _institutionSuggestionsHideTimer?.cancel();
                                    setState(() {
                                      _institutionSuggestionsVisible = false;
                                      _institution = id;
                                      _setFilterFieldText(
                                        _institutionSearchController,
                                        inst.institutionName,
                                      );
                                    });
                                    _institutionFocus.unfocus();
                                  },
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            setState(() {
              _resolveLocationSelectionsBeforeApply();
            });
            widget.controller.applyFilters(
              stageIds: _stages.toList(),
              categoryIds: _categories.toList(),
              groupIds: _groups.toList(),
              genders: _genders.toList(),
              stateId: _state,
              cityId: _city,
              institutionId: _institution,
            );
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// Shared shell for Stage / Category / Group / Gender: title row + soft card body.
Widget _filterSectionCard({
  required String title,
  required bool isMobile,
  required Widget child,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Material(color: Colors.transparent, child: child),
      ),
    ],
  );
}

Widget _horizontalCheckboxChip({
  required bool isMobile,
  required bool value,
  required String label,
  required void Function(bool? v) onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 2),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _checkboxFilterColumn({
  required String title,
  required bool isMobile,
  required List<Map<String, dynamic>> options,
  required Set<int> selected,
  required void Function(int id, bool on) onToggle,
}) {
  return _filterSectionCard(
    title: title,
    isMobile: isMobile,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: options.isEmpty
          ? Text(
              'No options',
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                color: Colors.grey[600],
              ),
            )
          : Wrap(
              spacing: 12,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: options.map((m) {
                final id = (m['id'] as int?) ?? 0;
                final name = (m['name'] ?? '').toString();
                final label = name.isNotEmpty ? name : id.toString();
                return _horizontalCheckboxChip(
                  isMobile: isMobile,
                  value: selected.contains(id),
                  label: label,
                  onChanged: (v) => onToggle(id, v ?? false),
                );
              }).toList(),
            ),
    ),
  );
}

Widget _genderCheckboxSection({
  required bool isMobile,
  required Set<String> selected,
  required void Function(String gender, bool on) onChanged,
}) {
  return _filterSectionCard(
    title: 'Gender',
    isMobile: isMobile,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Wrap(
        spacing: 16,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _horizontalCheckboxChip(
            isMobile: isMobile,
            value: selected.contains('MALE'),
            label: 'Male',
            onChanged: (v) => onChanged('MALE', v ?? false),
          ),
          _horizontalCheckboxChip(
            isMobile: isMobile,
            value: selected.contains('FEMALE'),
            label: 'Female',
            onChanged: (v) => onChanged('FEMALE', v ?? false),
          ),
        ],
      ),
    ),
  );
}
