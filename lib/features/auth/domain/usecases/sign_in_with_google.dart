import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/auth/domain/entities/user_entity.dart';
import 'package:kairos/features/auth/domain/repositories/auth_repository.dart';

class SignInWithGoogle {
  const SignInWithGoogle(this._repository);

  final AuthRepository _repository;

  Future<Result<UserEntity>> call() => _repository.signInWithGoogle();
}
