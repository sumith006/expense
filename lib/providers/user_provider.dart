import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_providers.dart';

final userProvider = StateNotifierProvider<UserNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserNotifier(prefs);
});

class UserNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  UserNotifier(this._prefs) : super('') {
    _loadUserName();
  }

  void _loadUserName() {
    state = _prefs.getString('user_name') ?? '';
  }

  Future<void> setUserName(String name) async {
    state = name;
    await _prefs.setString('user_name', name);
  }
}
