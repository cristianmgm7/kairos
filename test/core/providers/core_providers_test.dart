import 'package:kairos/core/providers/core_providers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

void main() {
  group('Core Providers', () {
    test('loggerProvider creates Logger instance', () {
      final container = ProviderContainer();
      final logger = container.read(loggerProvider);

      expect(logger, isA<Logger>());
      container.dispose();
    });

    test('connectivityProvider creates Connectivity instance', () {
      final container = ProviderContainer();
      final connectivity = container.read(connectivityProvider);

      expect(connectivity, isA<Connectivity>());
      container.dispose();
    });

    test('firebaseAuthProvider creates FirebaseAuth instance', () {
      final container = ProviderContainer();
      final firebaseAuth = container.read(firebaseAuthProvider);

      expect(firebaseAuth, isA<FirebaseAuth>());
      container.dispose();
    });

    test('googleSignInProvider creates GoogleSignIn instance', () {
      final container = ProviderContainer();
      final googleSignIn = container.read(googleSignInProvider);

      expect(googleSignIn, isA<GoogleSignIn>());
      container.dispose();
    });

    test('dioProvider creates Dio instance with proper configuration', () {
      final container = ProviderContainer();
      final dio = container.read(dioProvider);

      expect(dio, isA<Dio>());
      expect(dio.options.baseUrl, isNotEmpty);
      expect(dio.options.connectTimeout, isNotNull);
      expect(dio.options.receiveTimeout, isNotNull);
      container.dispose();
    });

    test('networkInfoProvider creates NetworkInfo instance', () {
      final container = ProviderContainer();
      final networkInfo = container.read(networkInfoProvider);

      expect(networkInfo, isNotNull);
      container.dispose();
    });

    test('apiClientProvider creates ApiClient instance', () {
      final container = ProviderContainer();
      final apiClient = container.read(apiClientProvider);

      expect(apiClient, isNotNull);
      container.dispose();
    });
  });
}
