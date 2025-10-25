import 'package:blueprint_app/core/config/flavor_config.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class FirebaseConfig {
  // TODO(firebase): Initialize Firebase per flavor when adding Firebase integration

  Future<void> initialize() async {
    final flavor = FlavorConfig.instance.flavor;

    // Placeholder for future Firebase initialization
    switch (flavor) {
      case Flavor.dev:
        // await Firebase.initializeApp(options: DefaultFirebaseOptions.dev);
        break;
      case Flavor.staging:
        // await Firebase.initializeApp(options: DefaultFirebaseOptions.staging);
        break;
      case Flavor.prod:
        // await Firebase.initializeApp(options: DefaultFirebaseOptions.prod);
        break;
    }
  }
}
