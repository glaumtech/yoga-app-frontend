import '../constants/app_constants.dart';
import '../../data/models/competition_model.dart';

/// URL to show a competition brochure as a banner image.
///
/// When [HomeCompetitionModel] has an `id`, uses `GET /competition/{id}/brochure`
/// so the banner loads even if the public list omits `brochureUrl` / `brochureFilePath`.
/// [Image.network] [Image.errorBuilder] should handle 404 or non-image bodies (e.g. PDF).
String? competitionBrochureBannerUrl(HomeCompetitionModel c) {
  final raw = c.brochureUrl?.trim();
  final rawPath = c.brochureFilePath?.trim();
  final combined = raw ?? rawPath;

  // Prefer explicit absolute image URLs when the API returns a direct link.
  if (combined != null && combined.isNotEmpty) {
    final lower = combined.toLowerCase();
    if (combined.startsWith('http://') || combined.startsWith('https://')) {
      if (lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png') ||
          lower.endsWith('.webp')) {
        return combined;
      }
    }
  }

  final id = c.idStr ?? (c.id != null ? '${c.id}' : null);
  if (id != null && id.isNotEmpty) {
    final base = BaseUrl.baseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base${EndPoints.competitionBrochure(id)}';
  }

  // No id: resolve relative image paths only.
  if (combined != null && combined.isNotEmpty) {
    final lower = combined.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp')) {
      final base = BaseUrl.baseUrl.replaceAll(RegExp(r'/$'), '');
      final p = combined.startsWith('/') ? combined : '/$combined';
      return '$base$p';
    }
  }
  return null;
}
