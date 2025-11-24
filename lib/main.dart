import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairos/core/app/app.dart';
import 'package:kairos/core/app/app_error.dart';

import 'package:kairos/core/config/firebase_config.dart';
import 'package:kairos/core/providers/core_providers.dart';
import 'package:kairos/core/providers/database_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    final firebaseConfig = FirebaseConfig();
    await firebaseConfig.initialize();
    logger.i('✅ Firebase initialized');

    // Initialize Isar
    final isar = await initializeIsar();
    logger.i('✅ Isar initialized');

    runApp(
      ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(isar),
        ],
        child: const App(),
      ),
    );
  } catch (e, stackTrace) {
    logger.i('❌ Error during initialization: $e');
    logger.i('Stack trace: $stackTrace');
    // Still run the app but with an error screen
    runApp(AppError(e));
  }
} 
