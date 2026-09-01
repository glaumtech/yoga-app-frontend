import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/competition_model.dart';
import '../../../../data/repositories/competition_repository.dart';
import '../../../../data/repositories/jury_scoring_repository.dart';
import '../../../controllers/reports_controller.dart';
import '../../../controllers/reports_participants_tab_controller.dart';

import '../../../widgets/pinned_scroll_views.dart';

enum _ResetDataStep { competitions, tableSelection }

enum _ResetTableType { scoring }

class ResetScoringDataTab extends StatefulWidget {
  const ResetScoringDataTab({super.key});

  @override
  State<ResetScoringDataTab> createState() => _ResetScoringDataTabState();
}

class _ResetScoringDataTabState extends State<ResetScoringDataTab> {
  final _competitionRepository = CompetitionRepository();
  final _juryScoringRepository = JuryScoringRepository();

  bool _isLoadingCompetitions = false;
  bool _isDeleting = false;
  List<CompetitionModel> _competitions = const [];
  final Set<String> _selectedCompetitionIds = <String>{};
  String _searchQuery = '';
  _ResetDataStep _currentStep = _ResetDataStep.competitions;
  final Set<_ResetTableType> _selectedTables = <_ResetTableType>{};

  @override
  void initState() {
    super.initState();
    _loadCompetitions();
  }

  Future<void> _loadCompetitions() async {
    setState(() => _isLoadingCompetitions = true);

    final response = await _competitionRepository.getAllCompetitions(
      page: 0,
      limit: 200,
      sortBy: 'createdAt',
      order: 'desc',
    );

    if (!mounted) return;

    if (response.success && response.data != null) {
      setState(() {
        _competitions = response.data!.competitions;
        _selectedCompetitionIds.removeWhere(
          (id) => !_competitions.any((c) => c.id == id),
        );
        _isLoadingCompetitions = false;
      });
    } else {
      setState(() {
        _competitions = const [];
        _selectedCompetitionIds.clear();
        _isLoadingCompetitions = false;
      });
      Get.snackbar(
        'Error',
        response.message ?? 'Could not load competitions',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  List<CompetitionModel> get _filteredCompetitions {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _competitions;
    return _competitions
        .where((c) => c.competitionName.toLowerCase().contains(query))
        .toList();
  }

  List<CompetitionModel> get _selectedCompetitions => _competitions
      .where((c) => c.id != null && _selectedCompetitionIds.contains(c.id))
      .toList();

  void _toggleSelection(String competitionId, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedCompetitionIds.add(competitionId);
      } else {
        _selectedCompetitionIds.remove(competitionId);
      }
    });
  }

  void _toggleSelectAllFiltered(bool? selected) {
    setState(() {
      if (selected == true) {
        for (final competition in _filteredCompetitions) {
          final id = competition.id;
          if (id != null && id.isNotEmpty) {
            _selectedCompetitionIds.add(id);
          }
        }
      } else {
        for (final competition in _filteredCompetitions) {
          final id = competition.id;
          if (id != null) {
            _selectedCompetitionIds.remove(id);
          }
        }
      }
    });
  }

  void _goToTableSelection() {
    if (_selectedCompetitionIds.isEmpty) {
      Get.snackbar(
        'Select competitions',
        'Please select at least one competition.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    setState(() {
      _currentStep = _ResetDataStep.tableSelection;
      _selectedTables.clear();
    });
  }

  void _goBackToCompetitions() {
    setState(() {
      _currentStep = _ResetDataStep.competitions;
      _selectedTables.clear();
    });
  }

  void _toggleTableSelection(_ResetTableType table, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedTables.add(table);
      } else {
        _selectedTables.remove(table);
      }
    });
  }

  Future<void> _confirmAndReset() async {
    if (_selectedCompetitionIds.isEmpty) {
      Get.snackbar(
        'Select competitions',
        'Please select at least one competition.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    if (!_selectedTables.contains(_ResetTableType.scoring)) {
      Get.snackbar(
        'Select table',
        'Please select the Scoring table to reset.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm reset'),
        content: const Text(
          'Are you sure you want to delete all scoring data for the selected competitions? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    final competitionIds = _selectedCompetitionIds
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .where((id) => id > 0)
        .toList();

    final response = await _juryScoringRepository.resetCompetitionScoringData(
      competitionIds: competitionIds,
    );

    if (!mounted) return;

    setState(() {
      _isDeleting = false;
      if (response.success) {
        _selectedCompetitionIds.clear();
        _selectedTables.clear();
        _currentStep = _ResetDataStep.competitions;
      }
    });

    if (response.success) {
      await _refreshScoringLists();
      await _showResultDialog(
        title: response.data?.hasDeletedData == true ? 'Success' : 'Completed',
        message: response.message ??
            'Scoring data for the selected competitions has been deleted successfully.',
        isError: false,
      );
    } else {
      await _showResultDialog(
        title: 'Error',
        message: response.message ?? 'Failed to delete scoring data',
        isError: true,
      );
    }
  }

  Future<void> _showResultDialog({
    required String title,
    required String message,
    required bool isError,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          color: isError ? Colors.red : Colors.green,
          size: 32,
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshScoringLists() async {
    if (Get.isRegistered<ReportsController>()) {
      await Get.find<ReportsController>().loadCompetitionsAndMaybeReport();
    }
    if (Get.isRegistered<ReportsParticipantsTabController>()) {
      await Get.find<ReportsParticipantsTabController>().refresh();
    }
  }

  Widget _buildStepIndicator() {
    final isCompetitionStep = _currentStep == _ResetDataStep.competitions;
    return Row(
      children: [
        _buildStepChip(
          stepNumber: 1,
          label: 'Competitions',
          isActive: isCompetitionStep,
          isCompleted: !isCompetitionStep,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.chevron_right, color: Colors.grey[500], size: 20),
        ),
        _buildStepChip(
          stepNumber: 2,
          label: 'Table selection',
          isActive: !isCompetitionStep,
          isCompleted: false,
        ),
      ],
    );
  }

  Widget _buildStepChip({
    required int stepNumber,
    required String label,
    required bool isActive,
    required bool isCompleted,
  }) {
    final color = isActive || isCompleted
        ? AppTheme.primaryColor
        : Colors.grey[500];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive || isCompleted
              ? AppTheme.primaryColor
              : Colors.grey[300],
          child: Text(
            '$stepNumber',
            style: TextStyle(
              color: isActive || isCompleted ? Colors.white : Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCompetitionSelectionStep(bool isMobile) {
    final filtered = _filteredCompetitions;
    final allFilteredSelected = filtered.isNotEmpty &&
        filtered.every(
          (c) => c.id != null && _selectedCompetitionIds.contains(c.id),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Search competitions',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            isDense: true,
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 12),
        if (_isLoadingCompetitions)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_competitions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No competitions available.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          )
        else ...[
          Row(
            children: [
              Checkbox(
                value: allFilteredSelected,
                tristate: true,
                onChanged: _isDeleting ? null : _toggleSelectAllFiltered,
              ),
              Expanded(
                child: Text(
                  'Select all (${filtered.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                '${_selectedCompetitionIds.length} selected',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final competition = filtered[index];
                final id = competition.id ?? '';
                final isSelected = _selectedCompetitionIds.contains(id);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: _isDeleting
                      ? null
                      : (value) => _toggleSelection(id, value),
                  title: Text(
                    competition.competitionName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Starts: ${competition.eventStartDate.toLocal().toString().split(' ').first}',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            onPressed: _isDeleting ||
                    _isLoadingCompetitions ||
                    _selectedCompetitionIds.isEmpty
                ? null
                : _goToTableSelection,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: 12,
              ),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continue to table selection'),
          ),
        ),
      ],
    );
  }

  Widget _buildTableSelectionStep(bool isMobile) {
    final selectedCompetitions = _selectedCompetitions;
    final scoringSelected = _selectedTables.contains(_ResetTableType.scoring);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          color: AppTheme.primaryColor.withValues(alpha: 0.06),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected competitions (${selectedCompetitions.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                ...selectedCompetitions.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${c.competitionName}'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Select table to reset',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose which data table should be reset for the selected competitions.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          child: CheckboxListTile(
            value: scoringSelected,
            onChanged: _isDeleting
                ? null
                : (value) => _toggleTableSelection(_ResetTableType.scoring, value),
            title: const Text(
              'Scoring Reset',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Deletes jury scoring records only (participant scores and asana scores). '
              'Competition, participant, and other master data remain unchanged.',
            ),
            secondary: Icon(Icons.table_chart, color: AppTheme.primaryColor),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: _isDeleting ? null : _goBackToCompetitions,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
            if (scoringSelected)
              ElevatedButton.icon(
                onPressed: _isDeleting ? null : _confirmAndReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: 12,
                  ),
                ),
                icon: _isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.restart_alt),
                label: Text(_isDeleting ? 'Resetting...' : 'Reset Data'),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return PinnedVerticalScrollView(
      padding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset Data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Select competitions, choose the scoring table, then reset data. '
              'Only scoring records are removed; master data is not affected.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 16),
            _buildStepIndicator(),
            const SizedBox(height: 20),
            if (_currentStep == _ResetDataStep.competitions)
              _buildCompetitionSelectionStep(isMobile)
            else
              _buildTableSelectionStep(isMobile),
          ],
        ),
      ),
    );
  }
}
