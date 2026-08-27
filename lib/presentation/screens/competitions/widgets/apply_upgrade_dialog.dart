import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/repositories/competition_repository.dart';

/// Shows eligible upgrade participants with multi-select, then applies only selected.
/// When marks are tied at the upgrade cut, lists those same-score participants for manual pick.
class ApplyUpgradeDialog extends StatefulWidget {
  const ApplyUpgradeDialog({
    super.key,
    required this.competitionId,
    required this.categoryId,
    required this.categoryName,
  });

  final int competitionId;
  final int categoryId;
  final String categoryName;

  static Future<void> show(
    BuildContext context, {
    required int competitionId,
    required int categoryId,
    required String categoryName,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ApplyUpgradeDialog(
        competitionId: competitionId,
        categoryId: categoryId,
        categoryName: categoryName,
      ),
    );
  }

  @override
  State<ApplyUpgradeDialog> createState() => _ApplyUpgradeDialogState();
}

class _ApplyUpgradeDialogState extends State<ApplyUpgradeDialog> {
  final _repo = CompetitionRepository();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String? _statusMessage;
  String? _status;
  String? _upgradeToName;
  bool _scoringComplete = true;
  List<Map<String, dynamic>> _participants = [];
  final Set<int> _selectedIds = {};

  bool get _isTieWaiting => _status == 'WAITING_TIE_BREAKER';

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _loading = true;
      _error = null;
      _selectedIds.clear();
    });
    final res = await _repo.previewCategoryUpgrade(
      competitionId: widget.competitionId,
      categoryId: widget.categoryId,
    );
    if (!mounted) return;
    if (!res.success || res.data == null) {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Failed to load upgrade details';
        _participants = [];
      });
      return;
    }
    final data = res.data!;
    final list = (data['participants'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        <Map<String, dynamic>>[];
    final status = data['status']?.toString();
    final selected = <int>{};
    // On a tie, do not pre-check tied rows — admin must choose.
    // Clear (non-tied) winners stay pre-selected.
    for (final p in list) {
      final id = int.tryParse(p['participantRegistrationId']?.toString() ?? '');
      if (id == null || p['alreadyUpgraded'] == true) continue;
      final tied = p['tiedAtCut'] == true;
      if (status == 'WAITING_TIE_BREAKER' && tied) continue;
      selected.add(id);
    }
    setState(() {
      _loading = false;
      _participants = list;
      _selectedIds.addAll(selected);
      _status = status;
      _statusMessage = data['message']?.toString() ?? res.message;
      _upgradeToName = data['upgradeToCategoryName']?.toString();
      _scoringComplete = data['scoringComplete'] != false;
      _error = null;
    });
  }

  void _setChecked(int id, bool checked, Map<String, dynamic> p) {
    setState(() {
      if (checked) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  Future<void> _apply() async {
    if (_selectedIds.isEmpty) {
      Get.snackbar(
        'Apply Upgrade',
        'Select at least one participant',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFEE2E2),
        colorText: const Color(0xFF991B1B),
      );
      return;
    }
    setState(() => _submitting = true);
    final res = await _repo.applyCategoryUpgrade(
      competitionId: widget.competitionId,
      categoryId: widget.categoryId,
      participantRegistrationIds: _selectedIds.toList(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    final msg = res.message ??
        (res.success ? 'Upgrade applied' : 'Failed to apply upgrade');
    Get.snackbar(
      res.success ? 'Upgrade' : 'Upgrade failed',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor:
          res.success ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
      colorText: res.success ? const Color(0xFF065F46) : const Color(0xFF991B1B),
    );
    if (res.success) {
      Navigator.of(context).pop();
    }
  }

  void _toggleAll(bool select) {
    setState(() {
      _selectedIds.clear();
      if (!select) return;
      for (final p in _participants) {
        if (p['alreadyUpgraded'] == true) continue;
        final id = int.tryParse(p['participantRegistrationId']?.toString() ?? '');
        if (id != null) _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;
    final selectableCount =
        _participants.where((p) => p['alreadyUpgraded'] != true).length;
    final allSelected =
        selectableCount > 0 && _selectedIds.length >= selectableCount;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.arrow_upward, color: primary, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Apply Upgrade',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                _upgradeToName != null && _upgradeToName!.trim().isNotEmpty
                    ? 'From "${widget.categoryName}" → "$_upgradeToName" (no fee). Select who to upgrade.'
                    : 'From "${widget.categoryName}" to the configured next category (no fee). Select who to upgrade.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              if (!_scoringComplete) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: const Text(
                    'Scoring is still incomplete. Showing current top list among scored participants.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
              if (_isTieWaiting) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Text(
                    _statusMessage ??
                        'Tied on marks. Select one or more participants to upgrade, or use Tie Breaker.',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ] else if (_statusMessage != null &&
                  _statusMessage!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _statusMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _loadPreview,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_participants.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      _isTieWaiting
                          ? 'No tied candidates to show yet.'
                          : 'No upgrade candidates yet.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Text(
                      '${_selectedIds.length} selected',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => _toggleAll(!allSelected),
                      child: Text(allSelected ? 'Clear all' : 'Select all'),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _participants.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = _participants[index];
                      final id = int.tryParse(
                            p['participantRegistrationId']?.toString() ?? '',
                          ) ??
                          0;
                      final already = p['alreadyUpgraded'] == true;
                      final tied = p['tiedAtCut'] == true;
                      final name = p['participantName']?.toString() ?? '';
                      final regNo = p['registrationNo']?.toString() ?? '';
                      final gender = p['gender']?.toString() ?? '';
                      final total = p['totalScore'];
                      final tb = p['tieBreakerScore'];
                      final checked = !already && _selectedIds.contains(id);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: already || _submitting
                            ? null
                            : (v) => _setChecked(id, v == true, p),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: already ? Colors.grey : null,
                                ),
                              ),
                            ),
                            if (tied)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFFFCD34D),
                                  ),
                                ),
                                child: const Text(
                                  'TIED',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          [
                            if (regNo.isNotEmpty) regNo,
                            if (gender.isNotEmpty) gender,
                            if (total != null) 'Score $total',
                            if (tb != null &&
                                double.tryParse(tb.toString()) != null &&
                                double.parse(tb.toString()) > 0)
                              'TB $tb',
                            if (p['juryCount'] != null) 'Juries ${p['juryCount']}',
                            if (already) 'Already upgraded',
                          ].join(' · '),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  OutlinedButton(
                    onPressed:
                        _submitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submitting ||
                            _loading ||
                            _selectedIds.isEmpty
                        ? null
                        : _apply,
                    style: ElevatedButton.styleFrom(backgroundColor: primary),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
