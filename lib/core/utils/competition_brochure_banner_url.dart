import '../constants/app_constants.dart';
import '../../data/models/competition_model.dart';

/// Full URL to load a competition brochure as a banner image via
/// `GET /competition/{id}/brochure` when the public list includes brochure metadata.
String? competitionBrochureBannerUrl(HomeCompetitionModel c) {
  final rawBrochure = c.brochureUrl?.trim() ?? '';
  final rawPath = c.brochureFilePath?.trim() ?? '';
  final hasBrochure = rawBrochure.isNotEmpty || rawPath.isNotEmpty;
  if (!hasBrochure) return null;

  final id = c.idStr ?? (c.id != null ? '${c.id}' : null);
  if (id != null && id.isNotEmpty) {
    final base = BaseUrl.baseUrl.replaceAll(RegExp(r'/$'), '');
    return '$base${EndPoints.competitionBrochure(id)}';
  }

  final raw = c.brochureUrl ?? c.brochureFilePath;
  if (raw == null || raw.isEmpty) return null;
  final lower = raw.toLowerCase();
  if (lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp')) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    final base = BaseUrl.baseUrl.replaceAll(RegExp(r'/$'), '');
    final p = raw.startsWith('/') ? raw : '/$raw';
    return '$base$p';
  }
  return null;
}
