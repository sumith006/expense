import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// Map of currency codes to names
final Map<String, String> currencyMap = {
  'USD': 'US Dollar (\$)',
  'EUR': 'Euro (€)',
  'GBP': 'British Pound (£)',
  'INR': 'Indian Rupee (₹)',
  'JPY': 'Japanese Yen (¥)',
  'CAD': 'Canadian Dollar (C\$)',
  'AUD': 'Australian Dollar (A\$)',
};
