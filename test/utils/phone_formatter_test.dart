import 'package:flutter_test/flutter_test.dart';

String cleanPhoneForCall(String phone) {
  return phone.replaceAll(RegExp(r'[^0-9+]'), '');
}

String cleanPhoneForWhatsApp(String phone) {
  String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (!cleaned.startsWith('975')) {
    cleaned = '975$cleaned';
  }
  return cleaned;
}

void main() {
  group('Phone Formatter Tests', () {

    test('cleanPhoneForCall removes spaces', () {
      expect(cleanPhoneForCall('+975 17 768 329'), '+97517768329');
    });

    test('cleanPhoneForCall removes dashes', () {
      expect(cleanPhoneForCall('+975-17-768-329'), '+97517768329');
    });

    test('cleanPhoneForWhatsApp adds 975 prefix if missing', () {
      expect(cleanPhoneForWhatsApp('17768329'), '97517768329');
    });

    test('cleanPhoneForWhatsApp keeps 975 if already present', () {
      expect(cleanPhoneForWhatsApp('97517768329'), '97517768329');
    });

    test('cleanPhoneForWhatsApp strips spaces before adding prefix', () {
      expect(cleanPhoneForWhatsApp('+975 17 768 329'), '97517768329');
    });

  });
}