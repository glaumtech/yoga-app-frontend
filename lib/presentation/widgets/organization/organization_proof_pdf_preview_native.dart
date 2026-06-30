import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';

import 'organization_proof_document_utils.dart';

/// Scrollable in-app PDF preview for mobile and desktop.
class OrganizationProofPdfPreview extends StatefulWidget {
  final Uint8List bytes;
  final String? fileName;

  const OrganizationProofPdfPreview({
    super.key,
    required this.bytes,
    this.fileName,
  });

  @override
  State<OrganizationProofPdfPreview> createState() =>
      _OrganizationProofPdfPreviewState();
}

class _OrganizationProofPdfPreviewState extends State<OrganizationProofPdfPreview> {
  PdfController? _controller;
  bool _loading = true;
  bool _failed = false;
  String? _errorMessage;
  late final Uint8List _safeBytes;

  @override
  void initState() {
    super.initState();
    _safeBytes = organizationProofNormalizeBytes(widget.bytes);
    _load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _controller?.dispose();
    _controller = null;

    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
      _errorMessage = null;
    });

    try {
      final doc = await PdfDocument.openData(_safeBytes);
      final controller = PdfController(document: Future.value(doc));
      if (!mounted) {
        controller.dispose();
        await doc.close();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_failed || _controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[500]),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Unable to open PDF',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Retry')),
              if (kIsWeb) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _openPdfInBrowser,
                  child: const Text('Open in new tab'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: PdfView(
          controller: _controller!,
          scrollDirection: Axis.vertical,
          backgroundDecoration: const BoxDecoration(color: Colors.white),
          onDocumentError: (error) {
            if (!mounted) return;
            setState(() {
              _failed = true;
              _errorMessage = error.toString();
              _controller?.dispose();
              _controller = null;
            });
          },
        ),
      ),
    );
  }

  Future<void> _openPdfInBrowser() async {
    final dataUri = Uri.dataFromBytes(_safeBytes, mimeType: 'application/pdf');
    if (await canLaunchUrl(dataUri)) {
      await launchUrl(
        kIsWeb ? dataUri.replace(fragment: 'toolbar=0&navpanes=0&statusbar=0') : dataUri,
        webOnlyWindowName: kIsWeb ? '_blank' : null,
        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
    }
  }
}
