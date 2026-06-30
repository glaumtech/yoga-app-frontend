// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import 'organization_proof_document_utils.dart';

/// Read-only PDF open params for the browser viewer (hides annotate/edit toolbar).
const String organizationProofPdfViewerFragment = '#toolbar=0&navpanes=0&statusbar=0';

/// Browser PDF preview using an embed + blob URL (read-only, no edit toolbar).
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
  String? _viewType;
  String? _blobUrl;
  late final Uint8List _safeBytes;

  @override
  void initState() {
    super.initState();
    _safeBytes = organizationProofNormalizeBytes(widget.bytes);
    _registerView();
  }

  @override
  void dispose() {
    _revokeBlobUrl();
    super.dispose();
  }

  void _revokeBlobUrl() {
    final url = _blobUrl;
    if (url != null) {
      html.Url.revokeObjectUrl(url);
      _blobUrl = null;
    }
  }

  void _registerView() {
    _revokeBlobUrl();
    final blob = html.Blob([_safeBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    _blobUrl = url;
    final viewType =
        'org-proof-pdf-${identityHashCode(_safeBytes)}-${url.hashCode}';

    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      return html.EmbedElement()
        ..type = 'application/pdf'
        ..src = '$url$organizationProofPdfViewerFragment'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
    });

    setState(() {
      _viewType = viewType;
    });
  }

  void _openInNewTab() {
    final url = _blobUrl;
    if (url == null) return;
    html.window.open('$url$organizationProofPdfViewerFragment', '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final viewType = _viewType;
    if (viewType == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: ColoredBox(
            color: Colors.grey.shade200,
            child: HtmlElementView(viewType: viewType),
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: Material(
            color: Colors.white,
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _openInNewTab,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Open in new tab',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
