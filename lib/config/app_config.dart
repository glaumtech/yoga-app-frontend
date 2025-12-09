enum Environment { dev, qa, prod }

class AppConfig {
  static Environment _environment = Environment.dev;

  static void setEnvironment(Environment env) {
    _environment = env;
  }

  static String get baseUrl {
    switch (_environment) {
      case Environment.qa:
        return 'https://ghopon.com/school'; // Update with your QA server URL
      case Environment.prod:
        return 'https://ghopon.com/school'; // Update with your production server URL
      case Environment.dev:
        return 'http://localhost:8083'; // Development server URL
    }
  }

  static Environment get environment => _environment;
}
