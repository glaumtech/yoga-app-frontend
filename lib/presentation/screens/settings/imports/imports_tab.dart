import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'dart:io' as io;
import 'dart:async';

import '../../../../data/models/competition_model.dart';
import '../../../../data/repositories/competition_repository.dart';
import '../../../../data/repositories/participant_repository.dart';

class SettingsImportsTab extends StatefulWidget {
  const SettingsImportsTab({super.key});

  @override
  State<SettingsImportsTab> createState() => _SettingsImportsTabState();
}

class _SettingsImportsTabState extends State<SettingsImportsTab> {
  final _participantRepository = ParticipantRepository();
  final _competitionRepository = CompetitionRepository();

  bool _isCompetitionsLoading = false;
  List<CompetitionModel> _competitions = const [];
  CompetitionModel? _selectedCompetition;

  Uint8List? _fileBytes;
  String? _fileName;
  String? _filePath;
  PlatformFile? _pickedFile;

  bool _isImporting = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _loadCompetitions();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCompetitions() async {
    setState(() {
      _isCompetitionsLoading = true;
    });

    final res = await _competitionRepository.getAllCompetitions(
      page: 0,
      limit: 200,
      sortBy: 'createdAt',
      order: 'desc',
    );

    if (!mounted) return;

    if (res.success && res.data != null) {
      final list = res.data!.competitions;
      setState(() {
        _competitions = list;
        _selectedCompetition = (_selectedCompetition != null)
            ? list.firstWhereOrNull((c) => c.id == _selectedCompetition!.id)
            : (list.isNotEmpty ? list.first : null);
        _isCompetitionsLoading = false;
      });
    } else {
      setState(() {
        _competitions = const [];
        _selectedCompetition = null;
        _isCompetitionsLoading = false;
      });
      Get.snackbar(
        'Error',
        res.message ?? 'Could not load competitions',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _pickExcel() async {
    final res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls'],
      // On mobile/desktop we prefer reading bytes from `path` to avoid
      // platform-specific cases where `bytes` is empty/incorrect.
      withData: kIsWeb,
      withReadStream: !kIsWeb,
    );

    if (!mounted) return;
    if (res == null || res.files.isEmpty) return;

    final f = res.files.first;
    if ((kIsWeb && f.bytes == null) || (!kIsWeb && f.path == null) || f.name.isEmpty) {
      Get.snackbar(
        'Error',
        'Could not read the selected file. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _fileBytes = kIsWeb ? f.bytes : null;
      _fileName = f.name;
      _filePath = f.path;
      _pickedFile = f;
      _result = null;
    });
  }

  Future<void> _import() async {
    final selectedIdStr = _selectedCompetition?.id?.toString();
    final competitionId = int.tryParse((selectedIdStr ?? '').trim());
    if (competitionId == null || competitionId <= 0) {
      Get.snackbar(
        'Select competition',
        'Please select a competition.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if ((_fileBytes == null && _filePath == null && _pickedFile?.readStream == null) || _fileName == null) {
      Get.snackbar(
        'No file selected',
        'Please choose an Excel file (.xlsx/.xls).',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Uint8List bytes;
    try {
      if (kIsWeb) {
        bytes = (_fileBytes ?? Uint8List(0));
      } else if (_pickedFile?.readStream != null) {
        bytes = await _readAllBytes(_pickedFile!.readStream!);
      } else if (_filePath != null && _filePath!.isNotEmpty) {
        bytes = await io.File(_filePath!).readAsBytes();
      } else {
        bytes = Uint8List(0);
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Could not read the file bytes. Please reselect the Excel file.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (bytes.isEmpty) {
      Get.snackbar(
        'Error',
        'Selected file is empty. Please choose a valid Excel file.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _isImporting = true;
      _result = null;
    });

    final res = await _participantRepository.importParticipantRegistrationsExcel(
      competitionId: competitionId,
      filename: _fileName!,
      bytes: kIsWeb ? bytes : null,
      filePath: !kIsWeb ? _filePath : null,
    );

    if (!mounted) return;
    setState(() {
      _isImporting = false;
      _result = res.data;
    });

    if (res.success) {
      Get.snackbar(
        'Import complete',
        res.message ?? 'Participant registrations imported',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Import failed',
        res.message ?? 'Unable to import',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<Uint8List> _readAllBytes(Stream<List<int>> stream) async {
    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
    }
    return Uint8List.fromList(chunks);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Imports',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final canRow = !isMobile && constraints.maxWidth >= 720;

                final competitionPicker = _buildCompetitionPicker();
                final chooseExcelBtn = ElevatedButton.icon(
                  onPressed: _isImporting ? null : _pickExcel,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Choose Excel'),
                );
                final fileNameText = Text(
                  _fileName ?? 'No file selected',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                );

                if (canRow) {
                  return Row(
                    children: [
                      SizedBox(width: 360, child: competitionPicker),
                      const SizedBox(width: 12),
                      chooseExcelBtn,
                      const SizedBox(width: 12),
                      Expanded(child: fileNameText),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    competitionPicker,
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        chooseExcelBtn,
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: fileNameText,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: _isImporting ? null : _import,
                child: _isImporting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Import'),
              ),
            ),
            const SizedBox(height: 16),
            if (_result != null) _buildResult(context, _result!),
          ],
        ),
      ),
    );
  }

  Widget _buildCompetitionPicker() {
    final items = _competitions
        .where((c) => (c.id ?? '').toString().trim().isNotEmpty)
        .map(
          (c) => DropdownMenuItem<CompetitionModel>(
            value: c,
            child: Text(
              '${c.competitionName} (ID: ${c.id})',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList();

    return DropdownButtonFormField<CompetitionModel>(
      isExpanded: true,
      initialValue: _selectedCompetition,
      items: items,
      onChanged: _isImporting
          ? null
          : (v) {
              setState(() {
                _selectedCompetition = v;
                _result = null;
              });
            },
      decoration: InputDecoration(
        labelText: 'Competition',
        border: const OutlineInputBorder(),
        suffixIcon: _isCompetitionsLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                tooltip: 'Refresh',
                onPressed: _isImporting ? null : _loadCompetitions,
                icon: const Icon(Icons.refresh),
              ),
      ),
    );
  }

  Widget _buildResult(BuildContext context, Map<String, dynamic> data) {
    final summary = (data['summary'] is Map<String, dynamic>)
        ? (data['summary'] as Map<String, dynamic>)
        : <String, dynamic>{};
    final errors = (data['errors'] is List) ? (data['errors'] as List) : const [];
    final skipped =
        (data['skippedDuplicates'] is List) ? (data['skippedDuplicates'] as List) : const [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _chip('Total', '${summary['totalRows'] ?? '-'}'),
                _chip('Imported', '${summary['importedCount'] ?? '-'}'),
                _chip('Duplicates', '${summary['skippedDuplicateCount'] ?? '-'}'),
                _chip('Invalid', '${summary['skippedInvalidCount'] ?? '-'}'),
              ],
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              title: Text('Skipped duplicates (${skipped.length})'),
              children: skipped
                  .take(50)
                  .map(
                    (e) => ListTile(
                      dense: true,
                      title: Text(
                        'Row ${e is Map ? e['rowNumber'] : '-'}',
                      ),
                      subtitle: Text(
                        e is Map ? (e['participantName']?.toString() ?? '') : e.toString(),
                      ),
                    ),
                  )
                  .toList(),
            ),
            ExpansionTile(
              title: Text('Errors (${errors.length})'),
              children: errors
                  .take(50)
                  .map(
                    (e) => ListTile(
                      dense: true,
                      title: Text(
                        'Row ${e is Map ? e['rowNumber'] : '-'}',
                      ),
                      subtitle: Text(
                        e is Map ? (e['reason']?.toString() ?? '') : e.toString(),
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

  Widget _chip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
    );
  }
}

