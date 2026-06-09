import 'package:flutter_test/flutter_test.dart';

bool isValidPrice(String priceText) {
  final price = double.tryParse(priceText);
  return price != null && price > 0;
}

bool isPriceAscending(List<double> prices) {
  for (int i = 1; i < prices.length; i++) {
    if (prices[i] <= prices[i - 1]) return false;
  }
  return true;
}

String? validateEstimatedPrice(String price) {
  if (price.isEmpty) return 'Price cannot be empty';
  final parsed = double.tryParse(price);
  if (parsed == null) return 'Price must be a number';
  if (parsed <= 0) return 'Price must be greater than 0';
  return null;
}

void main() {
  group('Price Validation Tests', () {

    test('isValidPrice returns true for valid price', () {
      expect(isValidPrice('500'), true);
    });

    test('isValidPrice returns false for zero', () {
      expect(isValidPrice('0'), false);
    });

    test('isValidPrice returns false for negative price', () {
      expect(isValidPrice('-100'), false);
    });

    test('isValidPrice returns false for non-numeric', () {
      expect(isValidPrice('abc'), false);
    });

    test('isPriceAscending returns true for ascending prices', () {
      expect(isPriceAscending([500, 700, 800]), true);
    });

    test('isPriceAscending returns false for equal prices', () {
      expect(isPriceAscending([500, 500, 800]), false);
    });

    test('isPriceAscending returns false for descending prices', () {
      expect(isPriceAscending([800, 700, 500]), false);
    });

    test('validateEstimatedPrice returns null for valid price', () {
      expect(validateEstimatedPrice('500'), null);
    });

    test('validateEstimatedPrice returns error for empty price', () {
      expect(validateEstimatedPrice(''), 'Price cannot be empty');
    });

    test('validateEstimatedPrice returns error for zero price', () {
      expect(validateEstimatedPrice('0'), 'Price must be greater than 0');
    });

  });
}