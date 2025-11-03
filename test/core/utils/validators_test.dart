import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('isValidEmail', () {
      test('returns true for valid email', () {
        expect(Validators.isValidEmail('test@example.com'), true);
        expect(Validators.isValidEmail('user.name@domain.co.uk'), true);
      });

      test('returns false for invalid email', () {
        expect(Validators.isValidEmail('invalid'), false);
        expect(Validators.isValidEmail('test@'), false);
        expect(Validators.isValidEmail('@example.com'), false);
        expect(Validators.isValidEmail(''), false);
      });
    });

    group('isValidPassword', () {
      test('returns true for valid password', () {
        expect(Validators.isValidPassword('password123'), true);
        expect(Validators.isValidPassword('12345678'), true);
      });

      test('returns false for invalid password', () {
        expect(Validators.isValidPassword('short'), false);
        expect(Validators.isValidPassword(''), false);
      });
    });

    group('isNotEmpty', () {
      test('returns true for non-empty string', () {
        expect(Validators.isNotEmpty('hello'), true);
        expect(Validators.isNotEmpty('  text  '), true);
      });

      test('returns false for empty or null string', () {
        expect(Validators.isNotEmpty(''), false);
        expect(Validators.isNotEmpty('   '), false);
        expect(Validators.isNotEmpty(null), false);
      });
    });
  });
}
