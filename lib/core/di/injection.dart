import 'package:blueprint_app/core/di/injection.config.dart';
import 'package:blueprint_app/core/routing/app_router.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  getIt.init();

  // Manually register AppRouter if not auto-generated
  if (!getIt.isRegistered<AppRouter>()) {
    getIt.registerLazySingleton<AppRouter>(AppRouter.new);
  }
}
