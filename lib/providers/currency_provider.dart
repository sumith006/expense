import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Currency state provider
final currencyProvider = StateNotifierProvider<CurrencyNotifier, String>((ref) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<String> {
  CurrencyNotifier() : super('INR') {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getString('currency') ?? 'INR';
    } catch (e) {
      print('Error loading currency: $e');
      state = 'INR';
    }
  }

  Future<void> setCurrency(String newCurrency) async {
    state = newCurrency;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currency', newCurrency);
    } catch (e) {
      print('Error saving currency: $e');
    }
  }
}

// Helper function to get currency symbol
String getCurrencySymbol(String code) {
  switch (code) {
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    case 'INR':
      return '₹';
    case 'JPY':
      return '¥';
    case 'CAD':
      return 'C\$';
    case 'AUD':
      return 'A\$';
    default:
      return '\$';
  }
}

// Helper function to format amount
String formatAmount(double amount, String currencyCode) {
  return '${getCurrencySymbol(currencyCode)}${amount.toStringAsFixed(2)}';
}
