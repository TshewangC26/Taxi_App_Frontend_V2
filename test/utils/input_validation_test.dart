import 'package:flutter_test/flutter_test.dart';

String? validateEmail(String email) {
  if (email.isEmpty) return 'Please enter your email';
  if (!email.contains('@')) return 'Please enter a valid email';
  return null;
}

String? validatePassword(String password) {
  if (password.isEmpty) return 'Please enter your password';
  if (password.length < 12) return 'Password must be at least 12 characters';
  return null;
}

String? validateName(String name) {
  if (name.trim().isEmpty) return 'Please enter your name';
  return null;
}

String? validateBhutanPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  final local = digits.startsWith('975') ? digits.substring(3) : digits;
  if (local.length != 8) return 'Enter a valid Bhutan number e.g. +975 17 123 456';
  if (!local.startsWith('16') &&
      !local.startsWith('17') &&
      !local.startsWith('77')) {
    return 'Number must start with 16, 17, or 77';
  }
  return null;
}

void main() {
  group('Input Validation Tests', () {

    // Email tests
    test('validateEmail returns null for valid email', () {
      expect(validateEmail('test@email.com'), null);
    });

    test('validateEmail returns error for empty email', () {
      expect(validateEmail(''), 'Please enter your email');
    });

    test('validateEmail returns error for missing @', () {
      expect(validateEmail('invalidemail.com'), 'Please enter a valid email');
    });

    // Password tests
    test('validatePassword returns null for valid password', () {
      expect(validatePassword('mypassword123'), null);
    });

    test('validatePassword returns error for empty password', () {
      expect(validatePassword(''), 'Please enter your password');
    });

    test('validatePassword returns error for short password', () {
      expect(validatePassword('short'), 'Password must be at least 12 characters');
    });

    // Name tests
    test('validateName returns null for valid name', () {
      expect(validateName('Tshering Tashi'), null);
    });

    test('validateName returns error for empty name', () {
      expect(validateName(''), 'Please enter your name');
    });

    test('validateName returns error for whitespace only', () {
      expect(validateName('   '), 'Please enter your name');
    });

    // Bhutan phone tests
    test('validateBhutanPhone returns null for valid 17 number', () {
      expect(validateBhutanPhone('+975 17 768 329'), null);
    });

    test('validateBhutanPhone returns null for valid 77 number', () {
      expect(validateBhutanPhone('+975 77 123 456'), null);
    });

    test('validateBhutanPhone returns error for invalid prefix', () {
      expect(validateBhutanPhone('+975 99 123 456'), 'Number must start with 16, 17, or 77');
    });

    test('validateBhutanPhone returns error for short number', () {
      expect(validateBhutanPhone('+975 17 123'), 'Enter a valid Bhutan number e.g. +975 17 123 456');
    });

  });
}