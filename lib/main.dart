import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blueprint_app/core/config/firebase_config.dart';
import 'package:blueprint_app/core/di/injection.dart';
import 'package:blueprint_app/core/routing/router_provider.dart';
import 'package:blueprint_app/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await configureDependencies();

  // Initialize Firebase
  final firebaseConfig = getIt<FirebaseConfig>();
  await firebaseConfig.initialize();

  runApp(
    // Wrap with ProviderScope to enable Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
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
