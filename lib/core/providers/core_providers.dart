import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kairos/core/config/firebase_config.dart';
import 'package:kairos/core/config/flavor_config.dart';
import 'package:kairos/core/services/audio_recorder_service.dart';
import 'package:kairos/core/services/firebase_storage_service.dart';
import 'package:kairos/core/services/image_picker_service.dart';
import 'package:kairos/core/services/media_uploader.dart';
import 'package:logger/logger.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:record/record.dart';

// Export network providers
export 'package:kairos/core/network/api_client.dart';
export 'package:kairos/core/network/network_info.dart';

/// Logger provider - foundational logging service
final loggerProvider = Provider<Logger>((ref) {
  return Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: false,

    ),
    level: FlavorConfig.instance.enableLogging ? Level.debug : Level.error,
  );
});

final logger = ProviderContainer().read(loggerProvider);
/// Connectivity provider - network connectivity monitoring
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// Firebase Auth provider - Firebase authentication instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Google Sign-In provider - Google authentication service
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    scopes: ['email', 'profile'],
  );
});

/// Firebase config provider - Firebase initialization service
final firebaseConfigProvider = Provider<FirebaseConfig>((ref) {
  return FirebaseConfig();
});

/// Firebase Storage provider - Firebase Storage instance
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

/// Firestore provider - Cloud Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Dio provider - HTTP client with logging and configuration
final dioProvider = Provider<Dio>((ref) {
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
});

/// Firebase Storage Service provider - Generalized file upload with processing
final firebaseStorageServiceProvider = Provider<FirebaseStorageService>((ref) {
  final storage = ref.watch(firebaseStorageProvider);
  return FirebaseStorageService(storage);
});

/// Image picker service provider
final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  final picker = ImagePicker();
  return ImagePickerService(picker);
});

/// Audio recorder service provider
final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  final recorder = AudioRecorder();
  return AudioRecorderService(recorder);
});

/// Media uploader provider - Thin utility for Firebase Storage uploads
final mediaUploaderProvider = Provider<MediaUploader>((ref) {
  final storage = ref.watch(firebaseStorageProvider);
  return MediaUploader(storage);
});
