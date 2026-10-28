part of 'bulk_registration_screen.dart';

Future<void> _showBulkImportDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => const _BulkRegistrationImportDialog(),
  );
}

class _BulkRegistrationImportDialog extends StatefulWidget {
  const _BulkRegistrationImportDialog();

  @override
  State<_BulkRegistrationImportDialog> createState() =>
      _BulkRegistrationImportDialogState();
}

class _BulkRegistrationImportDialogState
    extends State<_BulkRegistrationImportDialog> {
  final ParticipantController _participantController =
      Get.find<ParticipantController>();
  final CompetitionController _competitionController =
      Get.find<CompetitionController>();

  String? _competitionId;
  bool _downloading = false;
  bool _importing = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final current = _participantController.selectedEventId.value;
    if (current.isNotEmpty) {
      _competitionId = current;
    }
  }

  CompetitionModel? get _selectedCompetition {
    final id = _competitionId;
    if (id == null || id.isEmpty) return null;
    return _competitionController.competitions.firstWhereOrNull(
      (competition) => competition.id == id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _competitionController.competitions.length;
      _competitionController.isLoadingRegistrationCompetition.value;
      return _buildDialog(context);
    });
  }

  Widget _buildDialog(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Import',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text(
                'Download the test template',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose the competition and download the template. Sex, category, and group are dropdowns filled from that competition, using the same labels as the registration form. Enter each participant, then import the file here. Add each photo on the registration table after import.',
                style: TextStyle(fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 16),
              _fieldLabel('COMPETITION'),
              DropdownButtonFormField<String>(
                value: _competitionController.competitions.any(
                  (item) => item.id == _competitionId,
                )
                    ? _competitionId
                    : null,
                isExpanded: true,
                menuMaxHeight: 320,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select competition',
                ),
                items: _competitionController.competitions
                    .where((item) => item.id != null && item.id!.isNotEmpty)
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(
                          item.competitionName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null || value == _competitionId) return;
                  setState(() {
                    _competitionId = value;
                    _formError = null;
                  });
                },
              ),
              if (_formError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _formError!,
                  style: TextStyle(color: Colors.red[700], fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _downloading ? null : _downloadTemplate,
                  icon: _downloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  label: const Text('Download template'),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Import filled template',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'Use the dropdowns for sex, category, and group. Keep the competition lines unchanged. Date of birth uses dd/MM/yyyy.',
                style: TextStyle(fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: _importing ? null : _importTemplate,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  icon: _importing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: const Text('Import to bulk registration'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Future<void> _downloadTemplate() async {
    final competition = _selectedCompetition;
    if (competition == null || competition.id == null) {
      setState(() => _formError = 'Select a competition');
      return;
    }

    setState(() {
      _formError = null;
      _downloading = true;
    });
    await _competitionController.ensureCompetitionLoadedForRegistration(
      competition.id!,
    );
    if (!mounted) return;
    final loaded =
        _competitionController.competitions.firstWhereOrNull(
          (item) => item.id == competition.id,
        ) ??
        competition;
    final options = buildRegistrationCategoryOptions(
      configs: loaded.categoryConfigs,
      categoryNames: loaded.categories,
      competitionMode: loaded.competitionMode,
    );
    final categories = <String>[];
    for (final option in options) {
      final label = option.displayLabel;
      if (!categories.any(
        (name) => name.toLowerCase() == label.toLowerCase(),
      )) {
        categories.add(label);
      }
    }
    final groups = <String>[];
    for (final entry in groupStageEntriesForBulk(
      loaded,
      _competitionController,
    )) {
      final label = bulkGroupStageLabel(entry.groupName, entry.stageName);
      if (!groups.any((name) => name.toLowerCase() == label.toLowerCase())) {
        groups.add(label);
      }
    }
    await _participantController.downloadBulkRegistrationTemplate(
      BulkRegistrationTemplateSelection(
        competitionId: loaded.id ?? competition.id!,
        competitionName: loaded.competitionName,
      ),
      sexes: bulkSexOptions(loaded),
      categories: categories,
      groups: groups,
    );
    if (!mounted) return;
    setState(() => _downloading = false);
  }

  Future<void> _importTemplate() async {
    setState(() => _importing = true);
    final imported = await _participantController
        .importBulkRegistrationTemplateFile();
    if (!mounted) return;
    setState(() => _importing = false);
    if (imported) Navigator.of(context).pop();
  }
}
