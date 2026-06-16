enum Environment { dev, qa, prod }

class AppConfig {
  static Environment _environment = Environment.dev;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  static String get baseUrl {
    switch (_environment) {
      case Environment.qa:
        return 'https://ghopon.com/yogatest'; // Update with your QA server URL
      case Environment.prod:
        return 'https://yogacompetition.in/yogaprod'; // Update with your production server URL
      case Environment.dev:
        return 'http://localhost:8080'; // Development server URL
    }
  }

  /// Public Flutter web app URL embedded in jury QR login links.
  static String get webAppUrl {
    switch (_environment) {
      case Environment.qa:
        return 'https://d1fl9gr1w0091l.cloudfront.net';
      case Environment.prod:
        return 'https://yogacompetition.in';
      case Environment.dev:
        return 'http://localhost:60450';
    }
  }

  static Environment get environment => _environment;
}
