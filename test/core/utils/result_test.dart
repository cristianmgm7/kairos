import 'package:flutter_test/flutter_test.dart';
import 'package:blueprint_app/core/errors/failures.dart';
import 'package:blueprint_app/core/utils/result.dart';

void main() {
  group('Result', () {
    test('Success contains data', () {
      const result = Success<int>(42);

      expect(result.isSuccess, true);
      expect(result.isError, false);
      expect(result.dataOrNull, 42);
      expect(result.failureOrNull, null);
    });

    test('Error contains failure', () {
      const failure = ServerFailure(message: 'Server error');
      const result = Error<int>(failure);

      expect(result.isSuccess, false);
      expect(result.isError, true);
      expect(result.dataOrNull, null);
      expect(result.failureOrNull, failure);
    });

    test('when method calls success callback for Success', () {
      const result = Success<int>(42);

      final output = result.when(
        success: (data) => 'Success: $data',
        error: (failure) => 'Error: ${failure.message}',
      );

      expect(output, 'Success: 42');
    });

    test('when method calls error callback for Error', () {
      const failure = ServerFailure(message: 'Server error');
      const result = Error<int>(failure);

      final output = result.when(
        success: (data) => 'Success: $data',
        error: (failure) => 'Error: ${failure.message}',
      );

      expect(output, 'Error: Server error');
    });
  });
}
