import 'package:flutter_test/flutter_test.dart';
import 'package:expense/utils/currency_formatter.dart';

void main() {
  test('formats with dollar symbol', () {
    final formatted = CurrencyFormatter.format(1234.5, r'$');
    expect(formatted, r'$1,234.50');
  });

  test('formats with euro symbol', () {
    final formatted = CurrencyFormatter.format(9876.54, '€');
    expect(formatted, '€9,876.54');
  });

  test('formats with rupee symbol', () {
    final formatted = CurrencyFormatter.format(5000, '₹');
    // Locale-independent formatting may place symbol before amount
    expect(formatted.contains('5000') || formatted.contains('5,000'), isTrue);
    expect(formatted.startsWith('₹') || formatted.endsWith('₹'), isTrue);
  });
}
