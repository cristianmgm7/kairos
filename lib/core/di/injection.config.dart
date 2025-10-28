// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;
import 'package:logger/logger.dart' as _i974;

import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../config/firebase_config.dart' as _i119;
import '../network/api_client.dart' as _i557;
import '../network/network_info.dart' as _i932;
import 'core_module.dart' as _i154;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final coreModule = _$CoreModule();
    gh.lazySingleton<_i974.Logger>(() => coreModule.logger);
    gh.lazySingleton<_i361.Dio>(() => coreModule.dio);
    gh.lazySingleton<_i895.Connectivity>(() => coreModule.connectivity);
    gh.lazySingleton<_i119.FirebaseConfig>(() => coreModule.firebaseConfig);
    gh.lazySingleton<_i59.FirebaseAuth>(() => coreModule.firebaseAuth);
    gh.lazySingleton<_i116.GoogleSignIn>(() => coreModule.googleSignIn);
    gh.lazySingleton<_i557.ApiClient>(() => _i557.ApiClient(gh<_i361.Dio>()));
    gh.lazySingleton<_i932.NetworkInfo>(
        () => _i932.NetworkInfoImpl(gh<_i895.Connectivity>()));
    gh.lazySingleton<_i787.AuthRepository>(() => coreModule.authRepository(
          gh<_i59.FirebaseAuth>(),
          gh<_i116.GoogleSignIn>(),
        ));
    return this;
  }
}

class _$CoreModule extends _i154.CoreModule {}
