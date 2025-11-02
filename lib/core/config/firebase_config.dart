import 'package:kairos/core/config/firebase_options_dev.dart' as dev;
import 'package:kairos/core/config/firebase_options_prod.dart' as prod;
import 'package:kairos/core/config/firebase_options_staging.dart' as staging;
import 'package:kairos/core/config/flavor_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  Future<void> initialize() async {
    try {
      final flavor = FlavorConfig.instance.flavor;

      debugPrint('🔥 Initializing Firebase for flavor: $flavor');

      // Use native platform configuration files on mobile to avoid crashes
      // when Dart options are placeholders or not configured.
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.android)) {
        await Firebase.initializeApp();
        debugPrint('✅ Firebase initialized successfully (plist/json)');
        return;
      }

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

      debugPrint('✅ Firebase initialized successfully');
    } on FirebaseException catch (e) {
      debugPrint('❌ Firebase initialization failed: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ Firebase initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
