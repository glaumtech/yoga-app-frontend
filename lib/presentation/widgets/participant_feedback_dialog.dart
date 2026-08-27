import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/storage_service.dart';
import '../../data/models/participant_feedback_model.dart';
import '../../data/repositories/participant_feedback_repository.dart';
import 'form_label_with_hint.dart';
import 'primary_button.dart';

Future<bool?> showParticipantFeedbackDialog(
  BuildContext context, {
  ParticipantFeedbackModel? existing,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _ParticipantFeedbackDialog(existing: existing),
  );
}

class _ParticipantFeedbackDialog extends StatefulWidget {
  final ParticipantFeedbackModel? existing;

  const _ParticipantFeedbackDialog({this.existing});

  @override
  State<_ParticipantFeedbackDialog> createState() =>
      _ParticipantFeedbackDialogState();
}

class _ParticipantFeedbackDialogState extends State<_ParticipantFeedbackDialog> {
  final _repository = ParticipantFeedbackRepository();
  final _reviewController = TextEditingController();

  bool _isPublic = false;
  bool _isSaving = false;
  bool _clearImage = false;
  bool _loadingExistingImage = false;
  String? _error;
  String? _pickedFileName;
  Uint8List? _pickedBytes;
  Uint8List? _existingImageBytes;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _reviewController.text = existing.reviewText;
      _isPublic = existing.isPublic;
      if (existing.hasImage && existing.id != null) {
        _loadExistingImage(existing.id!);
      }
    }
  }

  Future<void> _loadExistingImage(int feedbackId) async {
    setState(() => _loadingExistingImage = true);
    try {
      final token = StorageService.getString(
        AppConstants.participantVideoTokenKey,
      );
      final uri = Uri.parse(
        BaseUrl.baseUrl + EndPoints.participantFeedbackImage('$feedbackId'),
      );
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.get(uri, headers: headers);
      if (!mounted) return;
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.bodyBytes.isNotEmpty) {
        setState(() => _existingImageBytes = response.bodyBytes);
      }
    } catch (_) {
      // Preview is optional; save still works without it.
    } finally {
      if (mounted) setState(() => _loadingExistingImage = false);
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null || file.bytes!.isEmpty) {
      setState(() => _error = 'Could not read the selected image.');
      return;
    }
    if (file.bytes!.length > 10 * 1024 * 1024) {
      setState(() => _error = 'Image must be 10 MB or smaller.');
      return;
    }
    setState(() {
      _error = null;
      _pickedBytes = file.bytes;
      _pickedFileName = file.name;
      _clearImage = false;
      _existingImageBytes = null;
    });
  }

  void _removeImage() {
    setState(() {
      _pickedBytes = null;
      _pickedFileName = null;
      _existingImageBytes = null;
      _clearImage = widget.existing?.hasImage == true;
    });
  }

  Future<void> _save() async {
    final text = _reviewController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Please enter your review.');
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final response = await _repository.save(
      reviewText: text,
      isPublic: _isPublic,
      imageBytes: _pickedBytes,
      imageFileName: _pickedFileName,
      clearImage: _clearImage,
    );
    if (!mounted) return;
    if (!response.success) {
      setState(() {
        _isSaving = false;
        _error = response.message ?? 'Failed to save feedback.';
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final dialogWidth = width < 520 ? width - 32.0 : 480.0;
    final hasImagePreview =
        _pickedBytes != null || _existingImageBytes != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'Feedback',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          IconButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const FormLabelWithHint(label: 'Review'),
              TextFormField(
                controller: _reviewController,
                maxLines: 5,
                maxLength: 4000,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const FormLabelWithHint(label: 'Image (optional)'),
              const SizedBox(height: 6),
              if (_loadingExistingImage)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_pickedBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    _pickedBytes!,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                )
              else if (_existingImageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    _existingImageBytes!,
                    height: 140,
                    fit: BoxFit.cover,
                  ),
                ),
              if (hasImagePreview) const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickImage,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: Text(
                      hasImagePreview ? 'Change image' : 'Upload image',
                    ),
                  ),
                  if (hasImagePreview) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _isSaving ? null : _removeImage,
                      child: const Text('Remove'),
                    ),
                  ],
                ],
              ),
              if (_pickedFileName != null) ...[
                const SizedBox(height: 4),
                Text(
                  _pickedFileName!,
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _isPublic,
                onChanged: _isSaving
                    ? null
                    : (value) => setState(() => _isPublic = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Make review public'),
                subtitle: Text(
                  'If enabled, this review is shown on the public participants page.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        PrimaryButton(
          text: 'Save',
          width: 110,
          height: 40,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _save,
        ),
      ],
    );
  }
}
