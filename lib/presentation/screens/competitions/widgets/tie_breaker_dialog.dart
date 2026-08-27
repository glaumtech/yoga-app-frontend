import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../data/repositories/competition_repository.dart';
import '../../../../data/repositories/participant_repository.dart';

/// Admin dialog: detect prize ties and collect one-asana marks per configured jury.
class TieBreakerDialog extends StatefulWidget {
  const TieBreakerDialog({
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
      builder: (ctx) => TieBreakerDialog(
        competitionId: competitionId,
        categoryId: categoryId,
        categoryName: categoryName,
      ),
    );
  }

  @override
  State<TieBreakerDialog> createState() => _TieBreakerDialogState();
}

class _TieBreakerDialogState extends State<TieBreakerDialog> {
  final _competitionRepo = CompetitionRepository();
  final _participantRepo = ParticipantRepository();

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<Map<String, dynamic>> _groups = [];
  Map<String, dynamic>? _session;

  /// Key: "$juryId-$participantRegistrationId" → controller
  final Map<String, TextEditingController> _scoreControllers = {};

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    for (final c in _scoreControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _loading = true;
      _error = null;
      _session = null;
    });
    final res = await _competitionRepo.fetchTieBreakerGroups(
      competitionId: widget.competitionId,
      categoryId: widget.categoryId,
    );
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _loading = false;
        _error = res.message ?? 'Failed to load tie groups';
        _groups = [];
      });
      return;
    }
    setState(() {
      _loading = false;
      _groups = res.data ?? [];
    });
  }

  Future<void> _startGroup(Map<String, dynamic> group) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final ids = (group['participantRegistrationIds'] as List?)
            ?.map((e) => int.tryParse(e.toString()))
            .whereType<int>()
            .toList() ??
        const <int>[];
    final res = await _competitionRepo.startTieBreaker(
      competitionId: widget.competitionId,
      categoryId: widget.categoryId,
      body: {
        'stageId': group['stageId'],
        'gender': group['gender'],
        'participantRegistrationIds': ids,
        if (group['round'] != null) 'round': group['round'],
      },
    );
    if (!mounted) return;
    if (!res.success || res.data == null) {
      setState(() {
        _submitting = false;
        _error = res.message ?? 'Failed to start tie breaker';
      });
      return;
    }
    _disposeScoreControllers();
    final session = res.data!;
    final juries = (session['juries'] as List?) ?? const [];
    final participants = (session['participants'] as List?) ?? const [];
    for (final j in juries.whereType<Map>()) {
      final juryId = j['juryId'];
      for (final p in participants.whereType<Map>()) {
        final pid = p['participantRegistrationId'];
        if (juryId == null || pid == null) continue;
        _scoreControllers['$juryId-$pid'] = TextEditingController();
      }
    }
    setState(() {
      _submitting = false;
      _session = session;
    });
  }

  void _disposeScoreControllers() {
    for (final c in _scoreControllers.values) {
      c.dispose();
    }
    _scoreControllers.clear();
  }

  Future<void> _submitMarks() async {
    final session = _session;
    if (session == null) return;

    final asanaName = (session['asanaName'] ?? 'TIE BREAKER').toString();
    final categoryId = session['categoryId'] is int
        ? session['categoryId'] as int
        : int.tryParse(session['categoryId']?.toString() ?? '') ??
            widget.categoryId;
    final competitionId = session['competitionId'] is int
        ? session['competitionId'] as int
        : int.tryParse(session['competitionId']?.toString() ?? '') ??
            widget.competitionId;
    final minMarks = session['minimumMarks'] is int
        ? session['minimumMarks'] as int
        : int.tryParse(session['minimumMarks']?.toString() ?? '') ?? 1;
    final maxMarks = session['maximumMarks'] is int
        ? session['maximumMarks'] as int
        : int.tryParse(session['maximumMarks']?.toString() ?? '') ?? 100;

    final juries = (session['juries'] as List?)?.whereType<Map>().toList() ?? [];
    final participants =
        (session['participants'] as List?)?.whereType<Map>().toList() ?? [];

    // Validate all marks entered
    for (final j in juries) {
      final juryId = j['juryId'];
      for (final p in participants) {
        final pid = p['participantRegistrationId'];
        final ctrl = _scoreControllers['$juryId-$pid'];
        final raw = ctrl?.text.trim() ?? '';
        final score = double.tryParse(raw);
        if (score == null) {
          SnackbarHelper.showError(context, 'Enter a mark for every jury and participant');
          return;
        }
        if (score < minMarks || score > maxMarks) {
          SnackbarHelper.showError(
            context,
            'Marks must be between $minMarks and $maxMarks',
          );
          return;
        }
      }
    }

    setState(() => _submitting = true);

    // Submit per participant so different stage/group (common TB) do not clash.
    for (final j in juries) {
      final juryId = int.tryParse(j['juryId']?.toString() ?? '');
      if (juryId == null) continue;

      for (final p in participants) {
        final pid = int.tryParse(p['participantRegistrationId']?.toString() ?? '');
        if (pid == null) continue;
        final stageId = int.tryParse(p['stageId']?.toString() ?? '') ??
            int.tryParse(session['stageId']?.toString() ?? '');
        final groupId = int.tryParse(p['groupId']?.toString() ?? '');
        final score = double.parse(
          _scoreControllers['$juryId-$pid']!.text.trim(),
        );

        final res = await _participantRepo.submitBulkScores(
          competitionId: competitionId,
          juryId: juryId,
          stageId: stageId,
          categoryId: categoryId,
          groupId: groupId,
          participantScores: [
            {
              'participantRegistrationId': pid,
              'asanaScores': [
                {
                  'asanaName': asanaName,
                  'score': score,
                  'isSkipped': false,
                }
              ],
            }
          ],
        );
        if (!res.success) {
          if (mounted) {
            setState(() => _submitting = false);
            SnackbarHelper.showError(
              context,
              res.message ?? 'Failed to submit tie breaker marks',
            );
          }
          return;
        }
      }
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    SnackbarHelper.showSuccess(context, 'Tie breaker marks saved');
    await _loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.balance, color: primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tie Breaker — ${widget.categoryName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _session == null
                    ? 'Prize or upgrade ties with the same total. Start a round so configured juries can award one asana mark. After marks resolve upgrade ties, winners auto-move to the upgrade category.'
                    : 'Enter one mark per jury for each tied participant (${_session!['asanaName'] ?? 'TIE BREAKER'}).',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null && _session == null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _loadGroups, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              else if (_session != null)
                Expanded(child: _buildScoringPanel(primary))
              else if (_groups.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No prize or upgrade ties for this category.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              else
                Expanded(child: _buildGroupsList(primary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_session != null)
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () {
                              _disposeScoreControllers();
                              setState(() => _session = null);
                              _loadGroups();
                            },
                      child: const Text('Back to groups'),
                    ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  if (_session != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submitMarks,
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
                          : const Text('Submit marks'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsList(Color primary) {
    return ListView.separated(
      itemCount: _groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final g = _groups[index];
        final purpose = (g['purpose']?.toString() ?? 'PRIZE').toUpperCase();
        final isUpgrade = purpose == 'UPGRADE';
        final gender = g['gender']?.toString() ?? '';
        final score = g['score'];
        final from = g['prizeFrom'];
        final to = g['prizeTo'];
        final round = g['round'] ?? 1;
        final stage = g['stageName']?.toString();
        final names = ((g['participants'] as List?) ?? const [])
            .whereType<Map>()
            .map((p) => p['participantName']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .join(', ');
        final placeLabel = isUpgrade
            ? (from == to
                ? 'upgrade seat $from'
                : 'upgrade seats $from–$to')
            : (from == to ? 'place $from' : 'places $from–$to');
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isUpgrade ? Colors.teal.shade300 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(10),
            color: isUpgrade ? Colors.teal.shade50 : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  isUpgrade ? 'UPGRADE' : 'PRIZE',
                  if (stage != null && stage.isNotEmpty) stage,
                  gender,
                  'score $score',
                  placeLabel,
                  'round $round',
                ].where((e) => e.toString().trim().isNotEmpty).join(' · '),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                names,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _submitting ? null : () => _startGroup(g),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Start Tie Breaker'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScoringPanel(Color primary) {
    final session = _session!;
    final juries = (session['juries'] as List?)?.whereType<Map>().toList() ?? [];
    final participants =
        (session['participants'] as List?)?.whereType<Map>().toList() ?? [];
    final minMarks = session['minimumMarks'] ?? 1;
    final maxMarks = session['maximumMarks'] ?? 100;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final j in juries) ...[
            Text(
              j['juryName']?.toString() ?? 'Jury ${j['juryId']}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: primary,
              ),
            ),
            const SizedBox(height: 6),
            for (final p in participants) ...[
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      p['participantName']?.toString() ??
                          'Participant ${p['participantRegistrationId']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _scoreControllers[
                          '${j['juryId']}-${p['participantRegistrationId']}'],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Mark',
                        hintText: '$minMarks–$maxMarks',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
