import '../../routes/app_routes.dart';

/// Fallback registration URL when API does not return [registrationUrl].
String buildRegistrationShareUrl(String registrationCode) {
  final registerPath = AppRoutes.registerCompetitionPath(registrationCode);
  final base = Uri.base;
  final origin = '${base.scheme}://${base.authority}';
  final usesHashRouting = base.hasFragment && base.fragment.startsWith('/');
  return usesHashRouting ? '$origin/#$registerPath' : '$origin$registerPath';
}

/// Prefer API [registrationUrl]; fall back to current browser origin + opaque code.
String registrationShareUrlForCompetition({
  String? registrationUrl,
  required String registrationCode,
}) {
  final fromApi = registrationUrl?.trim();
  if (fromApi != null && fromApi.isNotEmpty) {
    return fromApi;
  }
  final code = registrationCode.trim();
  if (code.isEmpty) {
    return '';
  }
  return buildRegistrationShareUrl(code);
}
