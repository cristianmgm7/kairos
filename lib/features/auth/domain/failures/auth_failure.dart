import 'package:blueprint_app/core/errors/failures.dart';

class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });

  factory AuthFailure.invalidCredentials() => const AuthFailure(
        message: 'Invalid email or password',
        code: 401,
      );

  factory AuthFailure.userNotFound() => const AuthFailure(
        message: 'User not found',
        code: 404,
      );

  factory AuthFailure.emailInUse() => const AuthFailure(
        message: 'Email already in use',
        code: 409,
      );

  factory AuthFailure.weakPassword() => const AuthFailure(
        message: 'Password is too weak',
        code: 400,
      );

  factory AuthFailure.cancelled() => const AuthFailure(
        message: 'Sign-in was cancelled',
        code: 499,
      );

  factory AuthFailure.network() => const AuthFailure(
        message: 'Network error occurred',
        code: 503,
      );

  factory AuthFailure.unknown(String message) => AuthFailure(
        message: message,
        code: 500,
      );
}
