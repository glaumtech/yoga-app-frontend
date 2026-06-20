import '../../routes/app_routes.dart';

/// Fallback participant list URL when API does not return [participantsUrl].
String buildParticipantsShareUrl(
  String competitionId, {
  String? competitionName,
}) {
  final path = AppRoutes.publicCompetitionParticipantsPath(
    competitionId,
    competitionName: competitionName,
    isPastCompetition: true,
  );
  final base = Uri.base;
  final origin = '${base.scheme}://${base.authority}';
  final usesHashRouting = base.hasFragment && base.fragment.startsWith('/');
  return usesHashRouting ? '$origin/#$path' : '$origin$path';
}

/// Prefer API [participantsUrl]; fall back to current browser origin.
String participantsShareUrlForCompetition({
  String? participantsUrl,
  required String competitionId,
  String? competitionName,
}) {
  final fromApi = participantsUrl?.trim();
  if (fromApi != null && fromApi.isNotEmpty) {
    return fromApi;
  }
  return buildParticipantsShareUrl(
    competitionId,
    competitionName: competitionName,
  );
}
