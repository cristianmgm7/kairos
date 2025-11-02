import 'package:kairos/core/utils/result.dart';
import 'package:kairos/features/auth/domain/entities/user_entity.dart';
import 'package:kairos/features/auth/domain/repositories/auth_repository.dart';

class SignInWithEmail {
  const SignInWithEmail(this._repository);

  final AuthRepository _repository;

  Future<Result<UserEntity>> call({
    required String email,
    required String password,
  }) =>
      _repository.signInWithEmail(email: email, password: password);
}
