import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Match backend `app.frontend.use-hash-routing=true` so pasted/QR links like
/// `http://host/#/register/competition/{code}` open correctly in a new tab.
void configureAppUrlStrategy() {
  setUrlStrategy(HashUrlStrategy());
}
