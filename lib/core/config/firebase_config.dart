import 'package:firebase_core/firebase_core.dart';
import 'package:injectable/injectable.dart';

import 'package:blueprint_app/core/config/firebase_options_dev.dart' as dev;
import 'package:blueprint_app/core/config/firebase_options_prod.dart' as prod;
import 'package:blueprint_app/core/config/firebase_options_staging.dart'
    as staging;
import 'package:blueprint_app/core/config/flavor_config.dart';

@lazySingleton
class FirebaseConfig {
  Future<void> initialize() async {
    final flavor = FlavorConfig.instance.flavor;

    switch (flavor) {
      case Flavor.dev:
        await Firebase.initializeApp(
          options: dev.DefaultFirebaseOptions.currentPlatform,
        );
      case Flavor.staging:
        await Firebase.initializeApp(
          options: staging.DefaultFirebaseOptions.currentPlatform,
        );
      case Flavor.prod:
        await Firebase.initializeApp(
          options: prod.DefaultFirebaseOptions.currentPlatform,
        );
    }
  }
}
