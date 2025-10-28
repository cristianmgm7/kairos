import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blueprint_app/core/config/firebase_config.dart';
import 'package:blueprint_app/core/di/injection.dart';
import 'package:blueprint_app/core/routing/router_provider.dart';
import 'package:blueprint_app/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize dependency injection
    await configureDependencies();
    debugPrint('✅ Dependencies configured');

    // Initialize Firebase
    final firebaseConfig = getIt<FirebaseConfig>();
    await firebaseConfig.initialize();
    debugPrint('✅ Firebase initialized');

    runApp(
      // Wrap with ProviderScope to enable Riverpod
      const ProviderScope(
        child: MyApp(),
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
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
