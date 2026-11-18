import 'configure_app_url_strategy_stub.dart'
    if (dart.library.html) 'configure_app_url_strategy_web.dart' as impl;

/// Configures Flutter web URL strategy (hash routes for share/QR deep links).
void configureAppUrlStrategy() => impl.configureAppUrlStrategy();
