// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/venue_map_helper.dart';

/// Google Maps iframe embed for Flutter web.
class VenueMapPreview extends StatefulWidget {
  final String address;
  final double height;
  final BorderRadius borderRadius;

  const VenueMapPreview({
    super.key,
    required this.address,
    this.height = 200,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  @override
  State<VenueMapPreview> createState() => _VenueMapPreviewState();
}

class _VenueMapPreviewState extends State<VenueMapPreview> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _registerView();
  }

  @override
  void didUpdateWidget(covariant VenueMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.address != widget.address) {
      _registerView();
    }
  }

  void _registerView() {
    final embedUrl = VenueMapHelper.googleMapsEmbedUrl(widget.address) ?? '';
    _viewType = 'google-map-${embedUrl.hashCode}';

    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = embedUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true
        ..referrerPolicy = 'no-referrer-when-downgrade';
      return iframe;
    });
  }

  Future<void> _openGoogleMaps() async {
    final url = VenueMapHelper.googleMapsUrl(widget.address);
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final embedUrl = VenueMapHelper.googleMapsEmbedUrl(widget.address);
    if (embedUrl == null || embedUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            HtmlElementView(viewType: _viewType),
            Positioned(
              right: 8,
              bottom: 8,
              child: Material(
                color: Colors.white,
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _openGoogleMaps,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_new, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Open in Maps',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
