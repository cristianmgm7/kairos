import 'package:blueprint_app/core/config/firebase_config.dart';
import 'package:blueprint_app/core/config/flavor_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:blueprint_app/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:blueprint_app/features/auth/domain/repositories/auth_repository.dart';

@module
abstract class CoreModule {
  @lazySingleton
  Logger get logger => Logger(
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 5,
          lineLength: 50,
        ),
        level: FlavorConfig.instance.enableLogging ? Level.debug : Level.error,
      );

  @lazySingleton
  Dio get dio {
    final config = FlavorConfig.instance;
    final dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: Duration(milliseconds: config.apiTimeout),
        receiveTimeout: Duration(milliseconds: config.apiTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    if (config.enableLogging) {
      dio.interceptors.add(PrettyDioLogger());
    }

    return dio;
  }

  @lazySingleton
  Connectivity get connectivity => Connectivity();

  @lazySingleton
  FirebaseConfig get firebaseConfig => FirebaseConfig();

  @lazySingleton
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;

  @lazySingleton
  GoogleSignIn get googleSignIn => GoogleSignIn(
        scopes: ['email', 'profile'],
      );

  @lazySingleton
  AuthRepository authRepository(
    FirebaseAuth firebaseAuth,
    GoogleSignIn googleSignIn,
  ) =>
      FirebaseAuthRepository(firebaseAuth, googleSignIn);
}
