import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';

import '../../config/app_config.dart';
import '../../routes/app_routes.dart';

/// Public online-participant login URL encoded in the registration QR.
String buildOnlineParticipantLoginUrl(String registrationNo) {
  final path = AppRoutes.participantVideoUploadPath(
    registrationNo: registrationNo,
  );
  final origin = _qrOrigin();
  // This app uses Flutter hash routes on web (`/#/path`).
  return '$origin/#$path';
}

String onlineParticipantLoginUrlFor({
  String? onlineLoginUrl,
  required String registrationNo,
}) {
  final regNo = registrationNo.trim();
  if (regNo.isNotEmpty && kIsWeb) {
    return buildOnlineParticipantLoginUrl(regNo);
  }
  final fromApi = onlineLoginUrl?.trim();
  if (fromApi != null && fromApi.isNotEmpty && !_isUnreachableLocalUrl(fromApi)) {
    return fromApi;
  }
  return buildOnlineParticipantLoginUrl(registrationNo);
}

String _qrOrigin() {
  if (kIsWeb) {
    final base = Uri.base;
    if (base.hasScheme &&
        (base.scheme == 'http' || base.scheme == 'https') &&
        base.host.isNotEmpty) {
      return '${base.scheme}://${base.authority}';
    }
  }
  return AppConfig.webAppUrl.replaceAll(RegExp(r'/+$'), '');
}

/// Backend may still emit localhost:60450 even when Flutter is on another port.
bool _isUnreachableLocalUrl(String url) {
  final parsed = Uri.tryParse(url);
  if (parsed == null) return false;
  if (parsed.host != 'localhost' && parsed.host != '127.0.0.1') {
    return false;
  }
  if (!kIsWeb) return false;
  return parsed.authority != Uri.base.authority;
}

/// Location GoRouter should open on web so QR / pasted hash URLs are not sent to /home.
String flutterWebInitialLocation() {
  final fragment = Uri.base.fragment.trim();
  if (fragment.startsWith('/')) {
    return fragment;
  }
  final path = Uri.base.path;
  if (path.isNotEmpty && path != '/' && !path.endsWith('index.html')) {
    return Uri.base.hasQuery ? '$path?${Uri.base.query}' : path;
  }
  return AppRoutes.home;
}

/// Reads Participant ID from GoRouter (path, query, or hash fragment).
String? registrationNoFromGoRouterState(GoRouterState state) {
  final fromPath = state.pathParameters['registrationNo']?.trim();
  if (fromPath != null && fromPath.isNotEmpty) {
    return Uri.decodeComponent(fromPath);
  }
  return registrationNoFromBrowserUri(state.uri) ??
      registrationNoFromBrowserUri(Uri.base);
}

/// Reads `regNo` from a full URL, hash fragment, or path segment.
String? registrationNoFromBrowserUri(Uri uri) {
  final fromQuery = _firstNonEmpty([
    uri.queryParameters['regNo'],
    uri.queryParameters['registrationNo'],
  ]);
  if (fromQuery != null) return fromQuery;

  final fragment = uri.fragment.trim();
  if (fragment.isNotEmpty) {
    final fragmentUri = Uri.parse(
      fragment.startsWith('/') ? fragment : '/$fragment',
    );
    final fromFragQuery = _firstNonEmpty([
      fragmentUri.queryParameters['regNo'],
      fragmentUri.queryParameters['registrationNo'],
    ]);
    if (fromFragQuery != null) return fromFragQuery;

    final fromFragPath = _registrationNoFromPath(fragmentUri.path);
    if (fromFragPath != null) return fromFragPath;
  }

  return _registrationNoFromPath(uri.path);
}

String? _registrationNoFromPath(String path) {
  final segments = path
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (segments.length >= 3 &&
      segments[0] == 'register' &&
      segments[1] == 'video-upload') {
    final value = Uri.decodeComponent(segments[2]).trim();
    if (value.isNotEmpty && value != 'video-upload') return value;
  }
  return null;
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}
