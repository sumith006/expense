import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';
import 'shared_providers.dart';

// Provider for ProfileService
final profileServiceProvider = Provider<ProfileService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProfileService(prefs);
});
