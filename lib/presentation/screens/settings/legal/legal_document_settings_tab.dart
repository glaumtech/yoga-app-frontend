import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../data/repositories/legal_document_repository.dart';

class LegalDocumentSettingsTab extends StatefulWidget {
  const LegalDocumentSettingsTab({super.key, required this.docType});

  final String docType;

  @override
  State<LegalDocumentSettingsTab> createState() =>
      _LegalDocumentSettingsTabState();
}

class _LegalDocumentSettingsTabState extends State<LegalDocumentSettingsTab>
    with AutomaticKeepAliveClientMixin {
  final LegalDocumentRepository _repository = LegalDocumentRepository();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final resp = await _repository.getLegalDocument(widget.docType);
    if (!mounted) return;
    if (!resp.success || resp.data == null) {
      setState(() {
        _loading = false;
        _error = resp.message ?? 'Failed to load document';
      });
      return;
    }
    final data = resp.data!;
    _titleController.text = data['title']?.toString() ?? '';
    final paragraphs = (data['paragraphs'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toList() ??
        const <String>[];
    _bodyController.text = paragraphs.join('\n\n');
    setState(() {
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final paragraphs = _bodyController.text
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (paragraphs.isEmpty) {
      SnackbarHelper.showErrorMessage('Add at least one paragraph');
      return;
    }
    setState(() => _saving = true);
    final resp = await _repository.updateLegalDocument(
      docType: widget.docType,
      title: _titleController.text.trim(),
      paragraphs: paragraphs,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!resp.success) {
      SnackbarHelper.showErrorMessage(
        resp.message ?? 'Failed to save document',
      );
      return;
    }
    SnackbarHelper.showSuccessMessage('Document saved');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        children: [
          Text(
            widget.docType == 'privacy'
                ? 'Edit Privacy Policy shown on the public legal page.'
                : 'Edit Terms and Conditions shown on the public legal page.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Title is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bodyController,
            minLines: 12,
            maxLines: 24,
            decoration: const InputDecoration(
              labelText: 'Content',
              alignLabelWithHint: true,
              helperText: 'Separate paragraphs with a blank line.',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Content is required' : null,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving…' : 'Save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
