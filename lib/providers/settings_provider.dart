import 'package:flutter/material.dart' show ThemeMode, TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:hive_ce/hive.dart';
import 'dart:convert';
import '../models/user_settings.dart';
import '../database/boxes.dart';
import 'shared_providers.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final secure = ref.watch(secureStorageProvider);
  return SettingsNotifier(prefs, secure);
});

class SettingsNotifier extends StateNotifier<UserSettings> {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  SettingsNotifier(this._prefs, this._secure) : super(UserSettings.defaultSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final currency = _prefs.getString('currency_symbol') ?? r'$';
    final themeIndex = _prefs.getInt('theme_mode') ?? ThemeMode.system.index;
    final pinEnabled = _prefs.getBool('is_pin_enabled') ?? false;
    final bioEnabled = _prefs.getBool('is_biometric_enabled') ?? false;
    final dailyEnabled = _prefs.getBool('daily_reminder_enabled') ?? true;
    final dailyHour = _prefs.getInt('daily_reminder_hour') ?? 20;
    final dailyMinute = _prefs.getInt('daily_reminder_minute') ?? 0;
    final taskEnabled = _prefs.getBool('task_reminder_enabled') ?? true;
    final taskMin = _prefs.getInt('task_reminder_minutes_before') ?? 15;
    final name = _prefs.getString('profile_name') ?? 'Productive User';
    final avatar = _prefs.getString('profile_avatar_path');

    state = UserSettings(
      currencySymbol: currency,
      themeModeIndex: themeIndex,
      isPinEnabled: pinEnabled,
      isBiometricEnabled: bioEnabled,
      dailyReminderEnabled: dailyEnabled,
      dailyReminderHour: dailyHour,
      dailyReminderMinute: dailyMinute,
      taskReminderEnabled: taskEnabled,
      taskReminderMinutesBefore: taskMin,
      profileName: name,
      profileAvatarPath: avatar,
    );
  }

  Future<void> updateCurrency(String symbol) async {
    await _prefs.setString('currency_symbol', symbol);
    state = UserSettings(
      currencySymbol: symbol,
      themeModeIndex: state.themeModeIndex,
      isPinEnabled: state.isPinEnabled,
      isBiometricEnabled: state.isBiometricEnabled,
      dailyReminderEnabled: state.dailyReminderEnabled,
      dailyReminderHour: state.dailyReminderHour,
      dailyReminderMinute: state.dailyReminderMinute,
      taskReminderEnabled: state.taskReminderEnabled,
      taskReminderMinutesBefore: state.taskReminderMinutesBefore,
      profileName: state.profileName,
      profileAvatarPath: state.profileAvatarPath,
    );
  }

  Future<void> updateTheme(ThemeMode mode) async {
    await _prefs.setInt('theme_mode', mode.index);
    state = UserSettings(
      currencySymbol: state.currencySymbol,
      themeModeIndex: mode.index,
      isPinEnabled: state.isPinEnabled,
      isBiometricEnabled: state.isBiometricEnabled,
      dailyReminderEnabled: state.dailyReminderEnabled,
      dailyReminderHour: state.dailyReminderHour,
      dailyReminderMinute: state.dailyReminderMinute,
      taskReminderEnabled: state.taskReminderEnabled,
      taskReminderMinutesBefore: state.taskReminderMinutesBefore,
      profileName: state.profileName,
      profileAvatarPath: state.profileAvatarPath,
    );
  }

  Future<void> setPin(String pin) async {
    final hashedPin = sha256.convert(utf8.encode(pin)).toString();
    await _secure.write(key: 'user_pin', value: hashedPin);
    await _prefs.setBool('is_pin_enabled', true);
    
    state = UserSettings(
      currencySymbol: state.currencySymbol,
      themeModeIndex: state.themeModeIndex,
      isPinEnabled: true,
      isBiometricEnabled: state.isBiometricEnabled,
      dailyReminderEnabled: state.dailyReminderEnabled,
      dailyReminderHour: state.dailyReminderHour,
      dailyReminderMinute: state.dailyReminderMinute,
      taskReminderEnabled: state.taskReminderEnabled,
      taskReminderMinutesBefore: state.taskReminderMinutesBefore,
      profileName: state.profileName,
      profileAvatarPath: state.profileAvatarPath,
    );
  }

  Future<void> disablePin() async {
    await _secure.delete(key: 'user_pin');
    await _prefs.setBool('is_pin_enabled', false);
    await _prefs.setBool('is_biometric_enabled', false);
    
    state = UserSettings(
      currencySymbol: state.currencySymbol,
      themeModeIndex: state.themeModeIndex,
      isPinEnabled: false,
      isBiometricEnabled: false,
      dailyReminderEnabled: state.dailyReminderEnabled,
      dailyReminderHour: state.dailyReminderHour,
      dailyReminderMinute: state.dailyReminderMinute,
      taskReminderEnabled: state.taskReminderEnabled,
      taskReminderMinutesBefore: state.taskReminderMinutesBefore,
      profileName: state.profileName,
      profileAvatarPath: state.profileAvatarPath,
    );
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await _secure.read(key: 'user_pin');
    if (storedHash == null) return false;
    final inputHash = sha256.convert(utf8.encode(pin)).toString();
    return storedHash == inputHash;
  }

  Future<void> updateBiometrics(bool enabled) async {
    await _prefs.setBool('is_biometric_enabled', enabled);
    state = UserSettings(
      currencySymbol: state.currencySymbol,
      themeModeIndex: state.themeModeIndex,
      isPinEnabled: state.isPinEnabled,
      isBiometricEnabled: enabled,
      dailyReminderEnabled: state.dailyReminderEnabled,
      dailyReminderHour: state.dailyReminderHour,
      dailyReminderMinute: state.dailyReminderMinute,
      taskReminderEnabled: state.taskReminderEnabled,
      taskReminderMinutesBefore: state.taskReminderMinutesBefore,
      profileName: state.profileName,
      profileAvatarPath: state.profileAvatarPath,
    );
  }

  Future<void> updateDailyReminder(bool enabled, TimeOfDay? time) async {
    await _prefs.setBool('daily_reminder_enabled', enabled);
    final hour = time?.hour ?? state.dailyReminderHour;
    final minute = time?.minute ?? state.dailyReminderMinute;
    if (time != null) {
      await _prefs.setInt('daily_reminder_hour', time.hour);
      await _prefs.setInt('daily_reminder_minute', time.minute);
    }
    state = UserSettings(
      currencySymbol: state.currencySymbol,
      themeModeIndex: state.themeModeIndex,
      isPinEnabled: state.isPinEnabled,
      isBiometricEnabled: state.isBiometricEnabled,
      dailyReminderEnabled: enabled,
      dailyReminderHour: hour,
      dailyReminderMinute: minute,
      taskReminderEnabled: state.taskReminderEnabled,
      taskReminderMinutesBefore: state.taskReminderMinutesBefore,
      profileName: state.profileName,
      profileAvatarPath: state.profileAvatarPath,
    );
  }

  Future<void> updateTaskReminder(bool enabled, int minutesBefore) async {
    await _prefs.setBool('task_reminder_enabled', enabled);
    await _prefs.setInt('task_reminder_minutes_before', minutesBefore);
    state = UserSettings(
      currencySymbol: state.currencySymbol,
      themeModeIndex: state.themeModeIndex,
      isPinEnabled: state.isPinEnabled,
      isBiometricEnabled: state.isBiometricEnabled,
      dailyReminderEnabled: state.dailyReminderEnabled,
      dailyReminderHour: state.dailyReminderHour,
      dailyReminderMinute: state.dailyReminderMinute,
      taskReminderEnabled: enabled,
      taskReminderMinutesBefore: minutesBefore,
      profileName: state.profileName,
      profileAvatarPath: state.profileAvatarPath,
    );
  }

  Future<void> updateProfile(String name, String? avatarPath) async {
    await _prefs.setString('profile_name', name);
    if (avatarPath != null) {
      await _prefs.setString('profile_avatar_path', avatarPath);
    } else {
      await _prefs.remove('profile_avatar_path');
    }
    state = UserSettings(
      currencySymbol: state.currencySymbol,
      themeModeIndex: state.themeModeIndex,
      isPinEnabled: state.isPinEnabled,
      isBiometricEnabled: state.isBiometricEnabled,
      dailyReminderEnabled: state.dailyReminderEnabled,
      dailyReminderHour: state.dailyReminderHour,
      dailyReminderMinute: state.dailyReminderMinute,
      taskReminderEnabled: state.taskReminderEnabled,
      taskReminderMinutesBefore: state.taskReminderMinutesBefore,
      profileName: name,
      profileAvatarPath: avatarPath ?? state.profileAvatarPath,
    );
  }

  Future<void> updateProfileName(String name) async {
    await _prefs.setString('profile_name', name);
    state = UserSettings(
      currencySymbol: state.currencySymbol,
      themeModeIndex: state.themeModeIndex,
      isPinEnabled: state.isPinEnabled,
      isBiometricEnabled: state.isBiometricEnabled,
      dailyReminderEnabled: state.dailyReminderEnabled,
      dailyReminderHour: state.dailyReminderHour,
      dailyReminderMinute: state.dailyReminderMinute,
      taskReminderEnabled: state.taskReminderEnabled,
      taskReminderMinutesBefore: state.taskReminderMinutesBefore,
      profileName: name,
      profileAvatarPath: state.profileAvatarPath,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setInt('theme_mode', mode.index);
    state = UserSettings(
      currencySymbol: state.currencySymbol,
      themeModeIndex: mode.index,
      isPinEnabled: state.isPinEnabled,
      isBiometricEnabled: state.isBiometricEnabled,
      dailyReminderEnabled: state.dailyReminderEnabled,
      dailyReminderHour: state.dailyReminderHour,
      dailyReminderMinute: state.dailyReminderMinute,
      taskReminderEnabled: state.taskReminderEnabled,
      taskReminderMinutesBefore: state.taskReminderMinutesBefore,
      profileName: state.profileName,
      profileAvatarPath: state.profileAvatarPath,
    );
  }

  Future<void> setCurrencySymbol(String symbol) async {
    await _prefs.setString('currency_symbol', symbol);
    state = UserSettings(
      currencySymbol: symbol,
      themeModeIndex: state.themeModeIndex,
      isPinEnabled: state.isPinEnabled,
      isBiometricEnabled: state.isBiometricEnabled,
      dailyReminderEnabled: state.dailyReminderEnabled,
      dailyReminderHour: state.dailyReminderHour,
      dailyReminderMinute: state.dailyReminderMinute,
      taskReminderEnabled: state.taskReminderEnabled,
      taskReminderMinutesBefore: state.taskReminderMinutesBefore,
      profileName: state.profileName,
      profileAvatarPath: state.profileAvatarPath,
    );
  }

  Future<void> clearAllData() async {
    // Clear all Hive boxes
    final expensesBox = Hive.box(Boxes.expenses);
    final incomesBox = Hive.box(Boxes.incomes);
    final tasksBox = Hive.box(Boxes.tasks);
    final categoriesBox = Hive.box(Boxes.categories);
    final budgetsBox = Hive.box(Boxes.budgets);
    final goalsBox = Hive.box(Boxes.goals);
    final recurringBox = Hive.box(Boxes.recurring);

    await expensesBox.clear();
    await incomesBox.clear();
    await tasksBox.clear();
    await categoriesBox.clear();
    await budgetsBox.clear();
    await goalsBox.clear();
    await recurringBox.clear();

    // Reset settings to defaults
    await _prefs.clear();
    await _secure.deleteAll();

    state = UserSettings.defaultSettings();
  }
}
