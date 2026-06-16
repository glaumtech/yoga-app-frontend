import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

/// Highlighted event date, time, venue with optional map preview and Maps link.
class RegistrationEventVenueCard extends StatelessWidget {
  final String? competitionName;
  final String? eventDateDisplay;
  final String? eventTimeDisplay;
  final String? venueAddress;
  final String? venueMapsUrl;
  final String? venueMapPreviewUrl;
  final bool combineDateAndTime;
  final bool stackDateAndTime;
  final bool compact;

  const RegistrationEventVenueCard({
    super.key,
    this.competitionName,
    this.eventDateDisplay,
    this.eventTimeDisplay,
    this.venueAddress,
    this.venueMapsUrl,
    this.venueMapPreviewUrl,
    this.combineDateAndTime = false,
    this.stackDateAndTime = false,
    this.compact = false,
  });

  bool get _hasContent =>
      _hasText(competitionName) ||
      _hasText(eventDateDisplay) ||
      _hasText(eventTimeDisplay) ||
      _hasText(venueAddress);

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  Future<void> _openMaps(BuildContext context) async {
    final url = venueMapsUrl?.trim();
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasContent) return const SizedBox.shrink();

    final padding = compact ? 10.0 : 14.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF9A825), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event schedule & venue',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colors.orange.shade900,
            ),
          ),
          if (_hasText(competitionName)) ...[
            const SizedBox(height: 10),
            Text(
              competitionName!.trim(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
          if (stackDateAndTime &&
              (_hasText(eventDateDisplay) || _hasText(eventTimeDisplay)))
            _stackedDateTimeRow()
          else if (combineDateAndTime &&
              (_hasText(eventDateDisplay) || _hasText(eventTimeDisplay)))
            _row(
              Icons.event_outlined,
              'Date & time',
              [
                if (_hasText(eventDateDisplay)) eventDateDisplay!.trim(),
                if (_hasText(eventTimeDisplay)) eventTimeDisplay!.trim(),
              ].join(' · '),
            )
          else ...[
            if (_hasText(eventDateDisplay))
              _row(Icons.calendar_today_outlined, 'Date', eventDateDisplay!),
            if (_hasText(eventTimeDisplay))
              _row(Icons.schedule_outlined, 'Time', eventTimeDisplay!),
          ],
          if (_hasText(venueAddress))
            _row(Icons.location_on_outlined, 'Venue', venueAddress!),
          if (_hasText(venueMapPreviewUrl)) ...[
            SizedBox(height: compact ? 6 : 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                venueMapPreviewUrl!,
                height: compact ? 120 : 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    height: 160,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (_hasText(venueMapsUrl)) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: () => _openMaps(context),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Open venue in Google Maps'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stackedDateTimeRow() {
    return Padding(
      padding: EdgeInsets.only(top: compact ? 5 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.event_outlined, size: 18, color: Colors.brown.shade700),
          const SizedBox(width: 8),
          Text(
            'Date & time',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.brown.shade700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasText(eventDateDisplay))
                  Text(
                    eventDateDisplay!.trim(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                if (_hasText(eventTimeDisplay))
                  Padding(
                    padding: EdgeInsets.only(top: _hasText(eventDateDisplay) ? 2 : 0),
                    child: Text(
                      eventTimeDisplay!.trim(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(top: compact ? 5 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.brown.shade700),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.brown.shade700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value.trim(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
