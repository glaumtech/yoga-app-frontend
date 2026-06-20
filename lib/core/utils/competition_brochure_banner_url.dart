import '../constants/app_constants.dart';
import '../../data/models/competition_model.dart';

/// URL to show a competition brochure as a banner image in [Image.network].
///
/// Uses `GET /competition/{id}/brochure`, which resolves the stored file path
/// on the server. PDF-only brochures return null so callers show a default banner.
String? competitionBrochureBannerUrl(HomeCompetitionModel c) {
  final filePath = c.brochureFilePath?.trim();
  final brochureUrl = c.brochureUrl?.trim();

  if (!_hasBrochure(filePath, brochureUrl)) {
    return null;
  }

  if (_isPdfOnlyBrochure(filePath, brochureUrl)) {
    return null;
  }

  final id = c.idStr ?? (c.id != null ? '${c.id}' : null);
  if (id != null && id.isNotEmpty) {
    return '${_apiBase()}${EndPoints.competitionBrochure(id)}';
  }

  if (brochureUrl != null &&
      (brochureUrl.startsWith('http://') || brochureUrl.startsWith('https://')) &&
      _isImagePath(brochureUrl)) {
    return brochureUrl;
  }

  return null;
}

String _apiBase() => BaseUrl.baseUrl.replaceAll(RegExp(r'/$'), '');

bool _hasBrochure(String? filePath, String? brochureUrl) {
  return (filePath != null && filePath.isNotEmpty) ||
      (brochureUrl != null && brochureUrl.isNotEmpty);
}

bool _isPdfOnlyBrochure(String? filePath, String? brochureUrl) {
  if (_isImagePath(filePath ?? '') || _isImagePath(brochureUrl ?? '')) {
    return false;
  }
  return _isPdfPath(filePath) || _isPdfPath(brochureUrl);
}

bool _isImagePath(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp');
}

bool _isPdfPath(String? path) {
  if (path == null || path.trim().isEmpty) return false;
  return path.trim().toLowerCase().endsWith('.pdf');
}
