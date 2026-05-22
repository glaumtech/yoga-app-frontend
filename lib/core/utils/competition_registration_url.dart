import '../../routes/app_routes.dart';

/// Fallback registration URL when API does not return [registrationUrl].
String buildRegistrationShareUrl(String competitionId) {
  final registerPath = AppRoutes.registerCompetitionPath(competitionId);
  final base = Uri.base;
  final origin = '${base.scheme}://${base.authority}';
  final usesHashRouting = base.hasFragment && base.fragment.startsWith('/');
  return usesHashRouting ? '$origin/#$registerPath' : '$origin$registerPath';
}

/// Prefer API [registrationUrl]; fall back to current browser origin.
String registrationShareUrlForCompetition({
  String? registrationUrl,
  required String competitionId,
}) {
  final fromApi = registrationUrl?.trim();
  if (fromApi != null && fromApi.isNotEmpty) {
    return fromApi;
  }
  return buildRegistrationShareUrl(competitionId);
}
