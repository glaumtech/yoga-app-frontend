import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdfx/pdfx.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../controllers/competition_controller.dart';
import 'organization_proof_document_utils.dart';
import 'organization_proof_pdf_preview.dart';
const int organizationProofMaxPdfBytes = 10 * 1024 * 1024;
const String organizationProofUploadNotes =
    'Upload official e-PAN and e-AADHAR PDF files (max 10 MB each). '
    'Password-protected PDFs are not accepted — save an unlocked copy first.';
const String organizationBankDetailsNote =
    'This can be changed only before the transaction starts. '
    'Once the transaction has started, it cannot be changed.';
const String organizationProofPasswordProtectedMessage =
    'This PDF is password-protected. Password-protected e-PAN and e-AADHAR '
    'files cannot be uploaded. Open the PDF on your device, save or print it '
    'as an unlocked PDF (without password), then upload again.';

String formatOrganizationProofPickError(Object error) {
  final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  if (raw.contains('ArrayBuffer') || raw.contains('detached')) {
    return 'Could not read the selected PDF. Please choose the file again.';
  }
  return raw;
}

void notifyOrganizationProofUploadError(String message) {
  final isPasswordProtected = message == organizationProofPasswordProtectedMessage;
  SnackbarHelper.show(
    title: isPasswordProtected ? 'Password-protected PDF' : 'Upload failed',
    message: message,
    backgroundColor: const Color(0xFFD32F2F),
    duration: Duration(seconds: isPasswordProtected ? 8 : 5),
  );
}

void handleOrganizationProofPickFailure(Object error) {
  final message = formatOrganizationProofPickError(error);
  notifyOrganizationProofUploadError(message);
}

bool organizationProofBytesLookLikePdf(Uint8List bytes, {String? fileName}) {
  return CompetitionController.brochureBytesLookLikePdf(bytes);
}

bool organizationProofBytesLookLikeImage(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return true;
  }
  if (bytes.length >= 4 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return true;
  }
  return false;
}


bool organizationProofPdfContainsEncryptMarker(Uint8List bytes) {
  const encryptMarker = '/Encrypt';
  final marker = encryptMarker.codeUnits;
  if (bytes.length < marker.length) return false;

  final limit = bytes.length - marker.length;
  for (var i = 0; i <= limit; i++) {
    var found = true;
    for (var j = 0; j < marker.length; j++) {
      if (bytes[i + j] != marker[j]) {
        found = false;
        break;
      }
    }
    if (found) return true;
  }
  return false;
}

Future<bool> organizationProofPdfIsPasswordProtected(Uint8List bytes) async {
  if (organizationProofPdfContainsEncryptMarker(bytes)) {
    return true;
  }

  // pdfx can detach web ArrayBuffers; rely on /Encrypt marker only on web.
  if (kIsWeb) {
    return false;
  }

  try {
    final doc = await PdfDocument.openData(bytes);
    await doc.close();
    return false;
  } catch (e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('password') ||
        msg.contains('encrypted') ||
        msg.contains('encrypt') ||
        msg.contains('security handler');
  }
}

Future<void> assertOrganizationProofPdfUploadable({
  required Uint8List bytes,
  required String documentLabel,
}) async {
  if (await organizationProofPdfIsPasswordProtected(bytes)) {
    throw Exception(organizationProofPasswordProtectedMessage);
  }
}

Future<({Uint8List bytes, String fileName})?> pickOrganizationProofPdf({
  required String documentLabel,
}) async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
    allowMultiple: false,
    withData: kIsWeb,
  );
  if (result == null || result.files.isEmpty) return null;

  final picked = result.files.first;
  final fileName = picked.name.trim();
  if (fileName.isEmpty) {
    throw Exception('Invalid file name');
  }
  if (!fileName.toLowerCase().endsWith('.pdf')) {
    throw Exception('$documentLabel must be a PDF file');
  }

  Uint8List bytes;
  try {
    bytes = await organizationProofReadPickedPdfBytes(picked);
  } catch (e) {
    throw Exception(
      'Could not read the selected PDF. Please choose the file again.',
    );
  }
  if (bytes.isEmpty) {
    throw Exception('Unable to read $documentLabel file');
  }
  if (bytes.length > organizationProofMaxPdfBytes) {
    throw Exception('$documentLabel PDF must be 10 MB or smaller');
  }
  if (!organizationProofBytesLookLikePdf(bytes, fileName: fileName)) {
    throw Exception('$documentLabel must be a valid PDF file');
  }

  await assertOrganizationProofPdfUploadable(
    bytes: bytes,
    documentLabel: documentLabel,
  );

  return (bytes: bytes, fileName: fileName);
}

Widget buildOrganizationProofUploadErrorBanner(String message) {
  final text = message.trim();
  if (text.isEmpty) return const SizedBox.shrink();

  final isPasswordProtected = text == organizationProofPasswordProtectedMessage;
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red.shade700,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPasswordProtected
                    ? 'Password-protected PDF not allowed'
                    : 'Upload error',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Compact upload + view control group for e-PAN / e-AADHAR PDFs.
class OrganizationProofDocumentActions extends StatelessWidget {
  final Rx<Uint8List?> documentBytes;
  final RxString fileName;
  final bool busy;
  final VoidCallback onPick;
  final String previewTitle;

  const OrganizationProofDocumentActions({
    super.key,
    required this.documentBytes,
    required this.fileName,
    required this.busy,
    required this.onPick,
    required this.previewTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasDocument = documentBytes.value != null;
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasDocument
                ? AppTheme.primaryColor.withValues(alpha: 0.4)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionIcon(
              icon: Icons.upload_file_outlined,
              enabled: !busy,
              active: hasDocument,
              tooltip: hasDocument
                  ? 'Change $previewTitle'
                  : 'Upload $previewTitle',
              onTap: busy ? null : onPick,
            ),
            if (hasDocument) ...[
              Container(
                width: 1,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: Colors.grey.shade300,
              ),
              _ActionIcon(
                icon: Icons.visibility_outlined,
                enabled: !busy,
                active: true,
                tooltip: 'View $previewTitle',
                onTap: busy
                    ? null
                    : () => showOrganizationProofDocumentPreview(
                          context,
                          organizationProofNormalizeBytes(documentBytes.value!),
                          title: previewTitle,
                          fileName: fileName.value,
                        ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool active;
  final String tooltip;
  final VoidCallback? onTap;

  const _ActionIcon({
    required this.icon,
    required this.enabled,
    required this.active,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? Colors.grey.shade400
        : active
            ? AppTheme.primaryColor
            : AppTheme.primaryColor.withValues(alpha: 0.85);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

void showOrganizationProofDocumentPreview(
  BuildContext context,
  Uint8List bytes, {
  String title = 'Preview',
  String? fileName,
}) {
  final dialogHeight = MediaQuery.of(context).size.height * 0.88;
  final dialogWidth = MediaQuery.of(context).size.width * 0.9;

  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: dialogWidth.clamp(320, 900),
        height: dialogHeight.clamp(400, 900),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _OrganizationProofPreviewContent(
                  bytes: bytes,
                  fileName: fileName,
                  title: title,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OrganizationProofPreviewContent extends StatefulWidget {
  final Uint8List bytes;
  final String? fileName;
  final String title;

  const _OrganizationProofPreviewContent({
    required this.bytes,
    this.fileName,
    required this.title,
  });

  @override
  State<_OrganizationProofPreviewContent> createState() =>
      _OrganizationProofPreviewContentState();
}

class _OrganizationProofPreviewContentState
    extends State<_OrganizationProofPreviewContent> {
  late final Uint8List _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = organizationProofNormalizeBytes(widget.bytes);
  }

  @override
  Widget build(BuildContext context) {
    if (CompetitionController.brochureBytesLookLikeJson(_bytes)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[500]),
              const SizedBox(height: 12),
              Text(
                'Document could not be loaded from the server. '
                'Please upload the ${widget.title} PDF again.',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final isPdf = organizationProofBytesLookLikePdf(
      _bytes,
      fileName: widget.fileName,
    );

    if (isPdf) {
      if (organizationProofPdfContainsEncryptMarker(_bytes)) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 48, color: Colors.grey[500]),
                const SizedBox(height: 12),
                Text(
                  organizationProofPasswordProtectedMessage,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return OrganizationProofPdfPreview(
        bytes: _bytes,
        fileName: widget.fileName,
      );
    }

    if (organizationProofBytesLookLikeImage(_bytes)) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Center(
          child: Image.memory(
            _bytes,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              size: 64,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 12),
            Text(
              'Unable to preview ${widget.title}. '
              'Please upload a valid unlocked PDF file.',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
/// Proof details with grouped e-PAN / e-AADHAR blocks.
class OrganizationProofDetailsLayout extends StatelessWidget {
  final Widget panField;
  final Widget aadharField;
  final Rx<Uint8List?> panDocumentBytes;
  final RxString panDocumentFileName;
  final Rx<Uint8List?> aadharDocumentBytes;
  final RxString aadharDocumentFileName;
  final bool busy;
  final VoidCallback onPickPan;
  final VoidCallback onPickAadhar;

  const OrganizationProofDetailsLayout({
    super.key,
    required this.panField,
    required this.aadharField,
    required this.panDocumentBytes,
    required this.panDocumentFileName,
    required this.aadharDocumentBytes,
    required this.aadharDocumentFileName,
    required this.busy,
    required this.onPickPan,
    required this.onPickAadhar,
  });

  Widget _proofBlock({
    required String title,
    required Widget field,
    required List<Widget> actions,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, innerConstraints) {
              final inline = innerConstraints.maxWidth >= 420;
              if (inline) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: field),
                    const SizedBox(width: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: actions,
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  field,
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: actions,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _panBlock() {
    return _proofBlock(
      title: 'e-PAN',
      field: panField,
      actions: [
        OrganizationProofDocumentActions(
          documentBytes: panDocumentBytes,
          fileName: panDocumentFileName,
          busy: busy,
          onPick: onPickPan,
          previewTitle: 'e-PAN',
        ),
      ],
    );
  }

  Widget _aadharBlock() {
    return _proofBlock(
      title: 'e-AADHAR',
      field: aadharField,
      actions: [
        OrganizationProofDocumentActions(
          documentBytes: aadharDocumentBytes,
          fileName: aadharDocumentFileName,
          busy: busy,
          onPick: onPickAadhar,
          previewTitle: 'e-AADHAR',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _panBlock()),
              const SizedBox(width: 16),
              Expanded(child: _aadharBlock()),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _panBlock(),
            const SizedBox(height: 12),
            _aadharBlock(),
          ],
        );
      },
    );
  }
}

String? validatePanNumber(String? value, {bool required = true}) {
  final v = value?.trim().toUpperCase() ?? '';
  if (v.isEmpty) {
    return required ? 'PAN number is required' : null;
  }
  final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
  if (!panRegex.hasMatch(v)) {
    return 'Enter a valid PAN (e.g. ABCDE1234F)';
  }
  return null;
}

String? validateAadharNumber(String? value, {bool required = true}) {
  final v = value?.trim().replaceAll(' ', '') ?? '';
  if (v.isEmpty) {
    return required ? 'Aadhar number is required' : null;
  }
  if (!RegExp(r'^\d{12}$').hasMatch(v)) {
    return 'Enter a valid 12-digit Aadhar number';
  }
  return null;
}

String? validateIfsc(String? value, {bool required = true}) {
  final v = value?.trim().toUpperCase() ?? '';
  if (v.isEmpty) {
    return required ? 'IFSC number is required' : null;
  }
  if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(v)) {
    return 'Enter a valid IFSC code';
  }
  return null;
}

String? validateGstNumber(String? value, {bool required = false}) {
  final v = value?.trim().toUpperCase() ?? '';
  if (v.isEmpty) {
    return required ? 'GST number is required' : null;
  }
  final gstRegex = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
  );
  if (!gstRegex.hasMatch(v)) {
    return 'Enter a valid 15-character GSTIN';
  }
  return null;
}

String? validateRequiredField(String? value, {required String fieldName}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  return null;
}
