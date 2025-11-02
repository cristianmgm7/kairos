import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Flavor {
  dev,
  staging,
  prod,
}

class FlavorConfig {
  FlavorConfig._({
    required this.flavor,
    required this.name,
    required this.apiBaseUrl,
    required this.apiTimeout,
    required this.enableLogging,
  });

  static FlavorConfig? _instance;

  final Flavor flavor;
  final String name;
  final String apiBaseUrl;
  final int apiTimeout;
  final bool enableLogging;

  static FlavorConfig get instance {
    if (_instance == null) {
      throw StateError(
        'FlavorConfig not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  static Future<void> initialize(Flavor flavor) async {
    // Load appropriate .env file
    switch (flavor) {
      case Flavor.dev:
        await dotenv.load(fileName: '.env.dev');
      case Flavor.staging:
        await dotenv.load(fileName: '.env.staging');
      case Flavor.prod:
        await dotenv.load(fileName: '.env.prod');
    }

    _instance = FlavorConfig._(
      flavor: flavor,
      name: dotenv.env['APP_NAME'] ?? 'Blueprint',
      apiBaseUrl: dotenv.env['API_BASE_URL'] ?? '',
      apiTimeout: int.parse(dotenv.env['API_TIMEOUT'] ?? '30000'),
      enableLogging: dotenv.env['ENABLE_LOGGING'] == 'true',
    );
  }

  bool get isDev => flavor == Flavor.dev;
  bool get isStaging => flavor == Flavor.staging;
  bool get isProd => flavor == Flavor.prod;
}
