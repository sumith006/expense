import 'package:flutter/material.dart';

class IconHelper {
  // Mapping of string keys to IconData
  static const Map<String, IconData> _iconMap = {
    'fastfood': Icons.fastfood,
    'directions_car': Icons.directions_car,
    'home': Icons.home,
    'flash_on': Icons.flash_on,
    'movie': Icons.movie,
    'local_hospital': Icons.local_hospital,
    'shopping_bag': Icons.shopping_bag,
    'school': Icons.school,
    'shopping_cart': Icons.shopping_cart,
    'category': Icons.category,
    'attach_money': Icons.attach_money,
    'computer': Icons.computer,
    'trending_up': Icons.trending_up,
    'card_giftcard': Icons.card_giftcard,
    'money': Icons.money,
    'work': Icons.work,
    'person': Icons.person,
    'favorite': Icons.favorite,
    'account_balance': Icons.account_balance,
    'assignment': Icons.assignment,
    'flight': Icons.flight,
    'pets': Icons.pets,
    'sports_esports': Icons.sports_esports,
    'build': Icons.build,
    'phone': Icons.phone,
    'wifi': Icons.wifi,
    'coffee': Icons.local_cafe,
    'fitness_center': Icons.fitness_center,
    'payment': Icons.payment,
    'receipt': Icons.receipt,
  };

  static IconData getIcon(String key) {
    return _iconMap[key] ?? Icons.help_outline;
  }

  static String getIconKey(IconData icon) {
    return _iconMap.entries
        .firstWhere((entry) => entry.value == icon, orElse: () => const MapEntry('category', Icons.category))
        .key;
  }

  static List<String> getAvailableIconKeys() {
    return _iconMap.keys.toList();
  }

  // Visual Palette Colors
  static final List<Color> paletteColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];
}
