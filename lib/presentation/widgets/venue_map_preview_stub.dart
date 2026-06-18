import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/venue_map_helper.dart';

/// Interactive map preview for venue addresses on mobile/desktop.
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
  String? _previewUrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  @override
  void didUpdateWidget(covariant VenueMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.address != widget.address) {
      _loadPreview();
    }
  }

  Future<void> _loadPreview() async {
    setState(() => _loading = true);
    final url = await VenueMapHelper.staticMapPreviewUrl(widget.address);
    if (!mounted) return;
    setState(() {
      _previewUrl = url;
      _loading = false;
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
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Material(
          color: Colors.grey.shade100,
          child: InkWell(
            onTap: _openGoogleMaps,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_loading)
                  const Center(child: CircularProgressIndicator(strokeWidth: 2))
                else if (_previewUrl != null)
                  Image.network(
                    _previewUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                else
                  _placeholder(),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: Colors.black.withValues(alpha: 0.55),
                    child: Row(
                      children: [
                        const Icon(Icons.map_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Open in Google Maps',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Icon(Icons.open_in_new, color: Colors.white.withValues(alpha: 0.9), size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.primaryColor.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on, size: 40, color: AppTheme.primaryColor.withValues(alpha: 0.7)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.address,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
