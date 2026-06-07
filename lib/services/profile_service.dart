import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const String _profilePhotoKey = 'profile_photo_path';
  static const String _fullNameKey = 'profile_full_name';
  static const String _phoneKey = 'profile_phone';
  static const String _dobKey = 'profile_dob';
  static const String _genderKey = 'profile_gender';
  
  static const String _pushNotificationsKey = 'notif_push_enabled';
  static const String _taskRemindersKey = 'notif_task_reminders_enabled';
  static const String _budgetAlertsKey = 'notif_budget_alerts_enabled';
  static const String _dailySummaryKey = 'notif_daily_summary_enabled';
  static const String _dailySummaryTimeKey = 'notif_daily_summary_time';

  final SharedPreferences _prefs;

  ProfileService(this._prefs);

  // Profile Photo Methods
  Future<void> setProfilePhoto(String path) async {
    await _prefs.setString(_profilePhotoKey, path);
  }

  String? getProfilePhoto() {
    return _prefs.getString(_profilePhotoKey);
  }

  Future<void> clearProfilePhoto() async {
    await _prefs.remove(_profilePhotoKey);
  }

  // Personal Details Methods
  Future<void> setFullName(String name) async {
    await _prefs.setString(_fullNameKey, name);
  }

  String? getFullName() {
    return _prefs.getString(_fullNameKey);
  }

  Future<void> setPhone(String phone) async {
    await _prefs.setString(_phoneKey, phone);
  }

  String? getPhone() {
    return _prefs.getString(_phoneKey);
  }

  Future<void> setDateOfBirth(String dob) async {
    await _prefs.setString(_dobKey, dob);
  }

  String? getDateOfBirth() {
    return _prefs.getString(_dobKey);
  }

  Future<void> setGender(String gender) async {
    await _prefs.setString(_genderKey, gender);
  }

  String? getGender() {
    return _prefs.getString(_genderKey);
  }

  // Notification Settings Methods
  Future<void> setPushNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_pushNotificationsKey, enabled);
  }

  bool getPushNotificationsEnabled() {
    return _prefs.getBool(_pushNotificationsKey) ?? true;
  }

  Future<void> setTaskRemindersEnabled(bool enabled) async {
    await _prefs.setBool(_taskRemindersKey, enabled);
  }

  bool getTaskRemindersEnabled() {
    return _prefs.getBool(_taskRemindersKey) ?? true;
  }

  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    await _prefs.setBool(_budgetAlertsKey, enabled);
  }

  bool getBudgetAlertsEnabled() {
    return _prefs.getBool(_budgetAlertsKey) ?? true;
  }

  Future<void> setDailySummaryEnabled(bool enabled) async {
    await _prefs.setBool(_dailySummaryKey, enabled);
  }

  bool getDailySummaryEnabled() {
    return _prefs.getBool(_dailySummaryKey) ?? true;
  }

  Future<void> setDailySummaryTime(String time) async {
    await _prefs.setString(_dailySummaryTimeKey, time);
  }

  String getDailySummaryTime() {
    return _prefs.getString(_dailySummaryTimeKey) ?? '21:00';
  }
}
