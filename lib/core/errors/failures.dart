import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure({
    required this.message,
    this.code,
  });

  final String message;
  final int? code;

  @override
  List<Object?> get props => [message, code];
}

class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.code,
  });
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
  });
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
  });
}

class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.code,
  });
}

class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code,
  });
}

class UserCancelledFailure extends Failure {
  const UserCancelledFailure({
    required super.message,
    super.code,
  });
}
