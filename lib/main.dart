import 'package:blueprint_app/core/config/firebase_config.dart';
import 'package:blueprint_app/core/providers/database_provider.dart';
import 'package:blueprint_app/core/providers/datum_provider.dart';
import 'package:blueprint_app/core/routing/router_provider.dart';
import 'package:blueprint_app/core/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    final firebaseConfig = FirebaseConfig();
    await firebaseConfig.initialize();
    debugPrint('✅ Firebase initialized');

    // Initialize Isar
    final isar = await initializeIsar();
    debugPrint('✅ Isar initialized');

    // Initialize Firebase Firestore
    final firestore = FirebaseFirestore.instance;
    debugPrint('✅ Firebase Firestore initialized');

    // Initialize Datum
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final datum = await initializeDatum(
      initialUserId: currentUserId,
      isar: isar,
      firestore: firestore,
    );
    debugPrint('✅ Datum initialized');

    runApp(
      ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(isar),
          datumProvider.overrideWithValue(datum),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('❌ Error during initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    // Still run the app but with an error screen
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialization Error',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Blueprint App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
