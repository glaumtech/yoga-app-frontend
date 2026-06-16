import 'package:flutter/material.dart';

import '../../core/utils/venue_map_helper.dart';
import '../../data/models/competition_model.dart';
import 'registration_event_venue_card.dart';

/// Highlighted date, time, venue + map preview for competition registration.
class CompetitionVenueHighlightCard extends StatefulWidget {
  final HomeCompetitionModel competition;
  final CompetitionModel? fullCompetition;

  const CompetitionVenueHighlightCard({
    super.key,
    required this.competition,
    this.fullCompetition,
  });

  @override
  State<CompetitionVenueHighlightCard> createState() =>
      _CompetitionVenueHighlightCardState();
}

class _CompetitionVenueHighlightCardState
    extends State<CompetitionVenueHighlightCard> {
  String? _mapPreviewUrl;

  @override
  void initState() {
    super.initState();
    _loadMapPreview();
  }

  @override
  void didUpdateWidget(covariant CompetitionVenueHighlightCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.competition.address != widget.competition.address) {
      _loadMapPreview();
    }
  }

  Future<void> _loadMapPreview() async {
    final url = await VenueMapHelper.staticMapPreviewUrl(
      widget.competition.address,
    );
    if (mounted) setState(() => _mapPreviewUrl = url);
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationEventVenueCard(
      eventDateDisplay: _eventDateDisplay(),
      eventTimeDisplay: _eventTimeDisplay(),
      venueAddress: widget.competition.address,
      venueMapsUrl: VenueMapHelper.googleMapsUrl(widget.competition.address),
      venueMapPreviewUrl: _mapPreviewUrl,
      compact: true,
    );
  }

  String? _eventDateDisplay() {
    final start = widget.fullCompetition?.eventStartDate ??
        _parseDateString(widget.competition.eventStartDate);
    if (start == null) {
      final raw = widget.competition.eventStartDate?.trim();
      return raw != null && raw.isNotEmpty ? raw : null;
    }

    final end = widget.fullCompetition?.eventEndDate ??
        _parseDateString(widget.competition.eventEndDate);
    final startText = _formatDate(start);
    if (end == null || _sameDay(start, end)) return startText;
    return '$startText – ${_formatDate(end)}';
  }

  String? _eventTimeDisplay() {
    final full = widget.fullCompetition;
    final startTime = _formatTime(full?.eventStartTime);
    final endTime = _formatTime(
      full?.eventEndTime ?? widget.competition.eventEndTime,
    );

    if (startTime != null && startTime.isNotEmpty) {
      if (endTime != null && endTime.isNotEmpty) {
        return '$startTime – $endTime';
      }
      return startTime;
    }
    if (endTime != null && endTime.isNotEmpty) return endTime;
    return null;
  }

  String? _formatTime(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final parsed = CompetitionModel.parseTime(trimmed);
    if (parsed != null) {
      return CompetitionModel.formatTimeOfDay(parsed);
    }
    return trimmed;
  }

  DateTime? _parseDateString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
}
