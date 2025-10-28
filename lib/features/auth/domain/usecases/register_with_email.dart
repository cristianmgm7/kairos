import 'package:blueprint_app/core/utils/result.dart';
import 'package:blueprint_app/features/auth/domain/entities/user_entity.dart';
import 'package:blueprint_app/features/auth/domain/repositories/auth_repository.dart';

class RegisterWithEmail {
  const RegisterWithEmail(this._repository);

  final AuthRepository _repository;

  Future<Result<UserEntity>> call({
    required String email,
    required String password,
  }) =>
      _repository.registerWithEmail(email: email, password: password);
}
