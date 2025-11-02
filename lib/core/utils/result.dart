import 'package:kairos/core/errors/failures.dart';
import 'package:equatable/equatable.dart';

sealed class Result<T> extends Equatable {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;

  @override
  List<Object?> get props => [data];
}

class Error<T> extends Result<T> {
  const Error(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

// Extension methods for easier usage
extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;

  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;

  Failure? get failureOrNull =>
      this is Error<T> ? (this as Error<T>).failure : null;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) error,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    } else {
      return error((this as Error<T>).failure);
    }
  }
}
