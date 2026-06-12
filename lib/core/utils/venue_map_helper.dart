import 'dart:convert';

import 'package:http/http.dart' as http;

/// Google Maps link and static map preview for a venue address.
class VenueMapHelper {
  VenueMapHelper._();

  static String? googleMapsUrl(String? address) {
    final trimmed = address?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(trimmed)}';
  }

  static Future<String?> staticMapPreviewUrl(String? address) async {
    final trimmed = address?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(trimmed)}&format=json&limit=1',
      );
      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'YogaChamp/1.0 (registration-venue-preview)',
        },
      );
      if (response.statusCode != 200) return null;

      final list = jsonDecode(response.body);
      if (list is! List || list.isEmpty) return null;

      final lat = double.tryParse(list[0]['lat']?.toString() ?? '');
      final lon = double.tryParse(list[0]['lon']?.toString() ?? '');
      if (lat == null || lon == null) return null;

      return 'https://staticmap.openstreetmap.de/staticmap.php'
          '?center=$lat,$lon&zoom=15&size=480x160&markers=$lat,$lon';
    } catch (_) {
      return null;
    }
  }
}
