import 'package:flutter/material.dart' show ThemeMode, TimeOfDay;
import 'package:hive_ce/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 14)
class UserSettings extends HiveObject {
  @HiveField(0)
  String currencySymbol;

  /// Stored as int: 0 = system, 1 = light, 2 = dark
  @HiveField(1)
  int themeModeIndex;

  @HiveField(2)
  bool isPinEnabled;

  @HiveField(3)
  bool isBiometricEnabled;

  @HiveField(4)
  bool dailyReminderEnabled;

  /// Hour component of daily reminder time (null if not set)
  @HiveField(5)
  int? dailyReminderHour;

  /// Minute component of daily reminder time (null if not set)
  @HiveField(6)
  int? dailyReminderMinute;

  @HiveField(7)
  bool taskReminderEnabled;

  @HiveField(8)
  int taskReminderMinutesBefore;

  @HiveField(9)
  String? profileName;

  @HiveField(10)
  String? profileAvatarPath;

  UserSettings({
    required this.currencySymbol,
    required this.themeModeIndex,
    required this.isPinEnabled,
    required this.isBiometricEnabled,
    required this.dailyReminderEnabled,
    this.dailyReminderHour,
    this.dailyReminderMinute,
    required this.taskReminderEnabled,
    required this.taskReminderMinutesBefore,
    this.profileName,
    this.profileAvatarPath,
  });

  /// Convenience getter — returns the ThemeMode from stored index
  ThemeMode get themeMode => ThemeMode.values[themeModeIndex];

  /// Convenience setter
  set themeMode(ThemeMode mode) => themeModeIndex = mode.index;

  /// Convenience getter — returns TimeOfDay if both hour and minute are set
  TimeOfDay? get dailyReminderTime {
    if (dailyReminderHour == null || dailyReminderMinute == null) return null;
    return TimeOfDay(hour: dailyReminderHour!, minute: dailyReminderMinute!);
  }

  /// Convenience setter
  set dailyReminderTime(TimeOfDay? time) {
    dailyReminderHour = time?.hour;
    dailyReminderMinute = time?.minute;
  }

  factory UserSettings.defaultSettings() {
    return UserSettings(
      currencySymbol: r'$',
      themeModeIndex: ThemeMode.system.index,
      isPinEnabled: false,
      isBiometricEnabled: false,
      dailyReminderEnabled: true,
      dailyReminderHour: 20,
      dailyReminderMinute: 0,
      taskReminderEnabled: true,
      taskReminderMinutesBefore: 15,
      profileName: 'Productive User',
      profileAvatarPath: null,
    );
  }
}
