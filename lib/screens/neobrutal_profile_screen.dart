import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/neobrutal_theme.dart';
import '../providers/settings_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/animated_bottom_nav.dart';
import '../widgets/profile_avatar.dart';
import '../services/profile_service.dart';
import '../providers/currency_provider.dart';
import '../providers/user_provider.dart';

class NeoBrutalProfileScreen extends ConsumerWidget {
  const NeoBrutalProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final settings = ref.watch(settingsProvider);
      final userName = ref.watch(userProvider);
      final profileService = ref.watch(profileServiceProvider);
      final currencyCode = ref.watch(currencyProvider);

      return Scaffold(
        backgroundColor: NeoBrutalTheme.background,
        appBar: AppBar(
          automaticallyImplyLeading: false, // Prevent back button if unwanted
          title: Text(
            'PROFILE',
            style: NeoBrutalTheme.textTheme.headlineMedium?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildProfilePhotoSection(context, ref, userName.isNotEmpty ? userName : 'User', profileService),
              const SizedBox(height: 24),
              _buildPersonalDetailsSection(context, ref, profileService, userName),
              const SizedBox(height: 24),
              _buildNotificationSettingsSection(context, ref, profileService),
              const SizedBox(height: 24),
              _buildSection(context, 'PREFERENCES', [
                _buildSettingTile(
                  'THEME MODE',
                  settings.themeMode.name.toUpperCase(),
                  Icons.palette_rounded,
                  NeoBrutalTheme.primary,
                  onTap: () => _showThemeDialog(context, ref, settings.themeMode),
                ),
                _buildSettingTile(
                  'CURRENCY',
                  currencyCode,
                  Icons.monetization_on_rounded,
                  NeoBrutalTheme.secondary,
                  onTap: () => _showCurrencyDialog(context, ref, currencyCode),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSection(context, 'SECURITY', [
                _buildSettingTile(
                  'PIN LOCK',
                  settings.isPinEnabled ? 'ENABLED' : 'DISABLED',
                  Icons.lock_rounded,
                  NeoBrutalTheme.accent,
                  onTap: () => _showPinDialog(context, ref, settings.isPinEnabled),
                ),
                _buildSettingTile(
                  'BIOMETRICS',
                  settings.isBiometricEnabled ? 'ENABLED' : 'DISABLED',
                  Icons.fingerprint_rounded,
                  NeoBrutalTheme.success,
                  onTap: () => _showBiometricDialog(context, ref, settings.isBiometricEnabled),
                ),
              ]),
              const SizedBox(height: 100),
            ],
          ),
        ),
        bottomNavigationBar: AnimatedBottomNav(
          selectedIndex: 4,
          onItemTapped: (index) {},
        ),
      );
    } catch (e, stack) {
      debugPrint('Profile Screen Build Error: $e\n$stack');
      return Scaffold(
        backgroundColor: NeoBrutalTheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Oops! Something went wrong while loading your profile.\n\nError: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }
  }

  // --- UI Widgets ---

  Widget _buildProfilePhotoSection(BuildContext context, WidgetRef ref, String name, ProfileService profileService) {
    return Column(
      children: [
        ProfileAvatar(
          photoPath: profileService.getProfilePhoto(),
          userInitials: _getInitials(name),
          onPhotoSelected: (path) {
            profileService.setProfilePhoto(path);
            ref.invalidate(profileServiceProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile photo updated')),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: NeoBrutalTheme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  String _getInitials(String name) {
    try {
      final cleanName = name.trim();
      if (cleanName.isEmpty) return 'U';
      
      final parts = cleanName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        final f = parts[0];
        final s = parts[1];
        if (f.isNotEmpty && s.isNotEmpty) {
          return (f.substring(0, 1) + s.substring(0, 1)).toUpperCase();
        }
      }
      return cleanName.substring(0, 1).toUpperCase();
    } catch (e) {
      debugPrint('Error getting initials: $e');
      return 'U';
    }
  }

  Widget _buildPersonalDetailsSection(BuildContext context, WidgetRef ref, ProfileService profileService, String currentName) {
    final fullName = profileService.getFullName();
    final phone = profileService.getPhone();
    final dob = profileService.getDateOfBirth();
    final gender = profileService.getGender();

    return _buildSection(context, 'PERSONAL DETAILS', [
      _buildDetailsTile(
        'FULL NAME',
        (fullName != null && fullName.isNotEmpty) ? fullName : (currentName.isNotEmpty ? currentName : 'Not set'),
        Icons.person_rounded,
        NeoBrutalTheme.primary,
        onTap: () => _showEditTextDialog(
          context,
          'Edit Full Name',
          fullName ?? currentName,
          (value) {
            profileService.setFullName(value);
            ref.read(userProvider.notifier).setUserName(value);
            ref.invalidate(profileServiceProvider);
          },
        ),
      ),
      _buildDetailsTile(
        'PHONE NUMBER',
        phone ?? 'Not set',
        Icons.phone_rounded,
        NeoBrutalTheme.secondary,
        onTap: () => _showEditTextDialog(
          context,
          'Edit Phone Number',
          phone ?? '',
          (value) {
            profileService.setPhone(value);
            ref.invalidate(profileServiceProvider);
          },
        ),
      ),
      _buildDetailsTile(
        'DATE OF BIRTH',
        dob ?? 'Not set',
        Icons.calendar_today_rounded,
        NeoBrutalTheme.accent,
        onTap: () => _showDatePickerDialog(context, dob, (value) {
          profileService.setDateOfBirth(value);
          ref.invalidate(profileServiceProvider);
        }),
      ),
      _buildDetailsTile(
        'GENDER',
        gender ?? 'Not set',
        Icons.wc_rounded,
        NeoBrutalTheme.success,
        onTap: () => _showGenderPickerDialog(context, gender, (value) {
          profileService.setGender(value);
          ref.invalidate(profileServiceProvider);
        }),
      ),
    ]);
  }

  Widget _buildNotificationSettingsSection(BuildContext context, WidgetRef ref, ProfileService profileService) {
    return _buildSection(context, 'NOTIFICATIONS', [
      _buildNotificationToggle(
        'PUSH NOTIFICATIONS',
        profileService.getPushNotificationsEnabled(),
        Icons.notifications_rounded,
        NeoBrutalTheme.primary,
        (value) {
          profileService.setPushNotificationsEnabled(value);
          ref.invalidate(profileServiceProvider);
        },
      ),
      _buildNotificationToggle(
        'TASK REMINDERS',
        profileService.getTaskRemindersEnabled(),
        Icons.schedule_rounded,
        NeoBrutalTheme.secondary,
        (value) {
          profileService.setTaskRemindersEnabled(value);
          ref.invalidate(profileServiceProvider);
        },
      ),
      _buildNotificationToggle(
        'BUDGET ALERTS',
        profileService.getBudgetAlertsEnabled(),
        Icons.trending_down_rounded,
        NeoBrutalTheme.accent,
        (value) {
          profileService.setBudgetAlertsEnabled(value);
          ref.invalidate(profileServiceProvider);
        },
      ),
      _buildNotificationToggleWithTime(
        'DAILY SUMMARY',
        profileService.getDailySummaryEnabled(),
        profileService.getDailySummaryTime(),
        Icons.summarize_rounded,
        NeoBrutalTheme.success,
        (enabled) {
          profileService.setDailySummaryEnabled(enabled);
          ref.invalidate(profileServiceProvider);
        },
        (time) {
          profileService.setDailySummaryTime(time);
          ref.invalidate(profileServiceProvider);
        },
        context,
      ),
    ]);
  }

  Widget _buildDetailsTile(
    String title,
    String value,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: NeoBrutalTheme.radiusMedium,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 12),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(
    String title,
    bool value,
    IconData icon,
    Color color,
    Function(bool) onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: NeoBrutalTheme.radiusMedium,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: NeoBrutalTheme.primary,
        activeTrackColor: NeoBrutalTheme.primary.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildNotificationToggleWithTime(
    String title,
    bool enabled,
    String timeValue,
    IconData icon,
    Color color,
    Function(bool) onChanged,
    Function(String) onTimeChanged,
    BuildContext context,
  ) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: NeoBrutalTheme.radiusMedium,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          trailing: Switch(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: NeoBrutalTheme.primary,
            activeTrackColor: NeoBrutalTheme.primary.withValues(alpha: 0.3),
          ),
        ),
        if (enabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: GestureDetector(
              onTap: () => _showTimePickerDialog(context, timeValue, onTimeChanged),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: NeoBrutalTheme.radiusMedium,
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TIME',
                      style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Text(
                          timeValue,
                          style: const TextStyle(color: NeoBrutalTheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time_rounded, color: Colors.white24, size: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showEditTextDialog(BuildContext context, String title, String initialValue, Function(String) onSave) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoBrutalTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.white, letterSpacing: 2)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintStyle: const TextStyle(color: Colors.white30),
            border: OutlineInputBorder(borderRadius: NeoBrutalTheme.radiusMedium),
            enabledBorder: OutlineInputBorder(
              borderRadius: NeoBrutalTheme.radiusMedium,
              borderSide: const BorderSide(color: Colors.white12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white30)),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated')));
            },
            child: const Text('SAVE', style: TextStyle(color: NeoBrutalTheme.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _showDatePickerDialog(BuildContext context, String? currentDate, Function(String) onSave) async {
    final DateTime initialDate = _parseDate(currentDate);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'SELECT DATE OF BIRTH',
      cancelText: 'CANCEL',
      confirmText: 'SAVE',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: NeoBrutalTheme.primary,
            onPrimary: Colors.white,
            surface: NeoBrutalTheme.surface,
            onSurface: Colors.white,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: NeoBrutalTheme.surface,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null && context.mounted) {
      onSave(_formatDate(picked));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Date of birth set to ${_formatDate(picked)}'),
          backgroundColor: NeoBrutalTheme.success.withValues(alpha: 0.85),
        ),
      );
    }
  }

  void _showTimePickerDialog(BuildContext context, String currentTime, Function(String) onSave) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoBrutalTheme.surface,
        title: const Text('SELECT TIME', style: TextStyle(color: Colors.white, letterSpacing: 2)),
        content: SizedBox(
          height: 300,
          child: TimePicker(
            initialTime: _parseTimeString(currentTime),
            onTimeSelected: (hour, minute) {
              Navigator.pop(ctx);
              final timeString = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
              onSave(timeString);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Time updated')));
            },
          ),
        ),
      ),
    );
  }

  void _showGenderPickerDialog(BuildContext context, String? currentGender, Function(String) onSave) {
    final genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoBrutalTheme.surface,
        title: const Text('SELECT GENDER', style: TextStyle(color: Colors.white, letterSpacing: 2)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: genders.map((gender) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                onSave(gender);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gender updated')));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: currentGender == gender ? NeoBrutalTheme.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: NeoBrutalTheme.radiusMedium,
                  border: Border.all(
                    color: currentGender == gender ? NeoBrutalTheme.primary : Colors.white10,
                  ),
                ),
                child: Text(
                  gender.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  DateTime _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == 'Not set') return DateTime.now();
    try {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (_) {}
    return DateTime.now();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  (int, int) _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return (int.parse(parts[0]), int.parse(parts[1]));
      }
    } catch (_) {}
    return (21, 0);
  }


  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: NeoBrutalTheme.surface,
            borderRadius: NeoBrutalTheme.radiusLarge,
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile(String title, String value, IconData icon, Color color, {required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: NeoBrutalTheme.radiusMedium,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 12),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoBrutalTheme.surface,
        title: const Text('SELECT THEME', style: TextStyle(color: Colors.white, letterSpacing: 2)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('Light', ThemeMode.light, currentMode, ctx, ref),
            const SizedBox(height: 12),
            _buildThemeOption('Dark', ThemeMode.dark, currentMode, ctx, ref),
            const SizedBox(height: 12),
            _buildThemeOption('System', ThemeMode.system, currentMode, ctx, ref),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: NeoBrutalTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String label, ThemeMode mode, ThemeMode current, BuildContext ctx, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(settingsProvider.notifier).setThemeMode(mode);
        Navigator.pop(ctx);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: current == mode ? NeoBrutalTheme.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: NeoBrutalTheme.radiusMedium,
          border: Border.all(
            color: current == mode ? NeoBrutalTheme.primary : Colors.white10,
            width: current == mode ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<ThemeMode>(
              value: mode,
              groupValue: current,
              onChanged: (val) {
                if (val != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(val);
                  Navigator.pop(ctx);
                }
              },
              activeColor: NeoBrutalTheme.primary,
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, WidgetRef ref, String currentCurrencyCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoBrutalTheme.surface,
        title: const Text('SELECT CURRENCY', style: TextStyle(color: Colors.white, letterSpacing: 2)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: currencyMap.entries.map((entry) {
              final code = entry.key;
              final name = entry.value;
              final isSelected = currentCurrencyCode == code;
              
              return GestureDetector(
                onTap: () {
                  ref.read(currencyProvider.notifier).setCurrency(code);
                  // Also update the legacy settings provider for broad compatibility
                  ref.read(settingsProvider.notifier).setCurrencySymbol(getCurrencySymbol(code));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Currency set to $code')));
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? NeoBrutalTheme.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                    borderRadius: NeoBrutalTheme.radiusMedium,
                    border: Border.all(
                      color: isSelected ? NeoBrutalTheme.primary : Colors.white10,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: NeoBrutalTheme.primary, size: 20),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: NeoBrutalTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showPinDialog(BuildContext context, WidgetRef ref, bool isEnabled) {
    if (isEnabled) {
      _showVerifyPinDialog(context, ref, onVerified: () {
        ref.read(settingsProvider.notifier).disablePin();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN lock disabled')),
        );
      });
    } else {
      _showSetNewPinDialog(context, ref);
    }
  }

  void _showSetNewPinDialog(BuildContext context, WidgetRef ref) {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoBrutalTheme.surface,
        title: const Text('SET NEW PIN', style: TextStyle(color: Colors.white, letterSpacing: 2)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter 4-6 digit PIN',
                hintStyle: const TextStyle(color: Colors.white30),
                border: OutlineInputBorder(borderRadius: NeoBrutalTheme.radiusMedium),
                enabledBorder: OutlineInputBorder(
                  borderRadius: NeoBrutalTheme.radiusMedium,
                  borderSide: const BorderSide(color: Colors.white12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Confirm PIN',
                hintStyle: const TextStyle(color: Colors.white30),
                border: OutlineInputBorder(borderRadius: NeoBrutalTheme.radiusMedium),
                enabledBorder: OutlineInputBorder(
                  borderRadius: NeoBrutalTheme.radiusMedium,
                  borderSide: const BorderSide(color: Colors.white12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white30)),
          ),
          TextButton(
            onPressed: () {
              if (pinController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN cannot be empty')),
                );
                return;
              }
              if (pinController.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PINs do not match')),
                );
                return;
              }
              if (pinController.text.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN must be at least 4 digits')),
                );
                return;
              }
              
              ref.read(settingsProvider.notifier).setPin(pinController.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN set successfully')),
              );
            },
            child: const Text('SET PIN', style: TextStyle(color: NeoBrutalTheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showVerifyPinDialog(BuildContext context, WidgetRef ref, {required VoidCallback onVerified}) {
    final pinController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NeoBrutalTheme.surface,
        title: const Text('VERIFY PIN', style: TextStyle(color: Colors.white, letterSpacing: 2)),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your PIN',
            hintStyle: const TextStyle(color: Colors.white30),
            border: OutlineInputBorder(borderRadius: NeoBrutalTheme.radiusMedium),
            enabledBorder: OutlineInputBorder(
              borderRadius: NeoBrutalTheme.radiusMedium,
              borderSide: const BorderSide(color: Colors.white12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white30)),
          ),
          TextButton(
            onPressed: () async {
              final isValid = await ref.read(settingsProvider.notifier).verifyPin(pinController.text);
              if (!context.mounted) return;
              
              if (isValid) {
                Navigator.pop(ctx);
                onVerified();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid PIN')),
                );
              }
            },
            child: const Text('VERIFY', style: TextStyle(color: NeoBrutalTheme.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _showBiometricDialog(BuildContext context, WidgetRef ref, bool isEnabled) async {
    if (isEnabled) {
      ref.read(settingsProvider.notifier).updateBiometrics(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Biometric disabled')),
        );
      }
    } else {
      try {
        final localAuth = LocalAuthentication();
        final canCheckBiometrics = await localAuth.canCheckBiometrics;
        
        if (!canCheckBiometrics) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Biometric not available on this device')),
            );
          }
          return;
        }

        final isAuthenticated = await localAuth.authenticate(
          localizedReason: 'Authenticate to enable biometric lock',
        );

        if (!context.mounted) return;
        
        if (isAuthenticated) {
          ref.read(settingsProvider.notifier).updateBiometrics(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric enabled successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error enabling biometric: $e')),
          );
        }
      }
    }
  }
}

class TimePicker extends StatefulWidget {
  final (int, int) initialTime;
  final Function(int hour, int minute) onTimeSelected;

  const TimePicker({
    super.key,
    required this.initialTime,
    required this.onTimeSelected,
  });

  @override
  State<TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour = widget.initialTime.$1;
    _minute = widget.initialTime.$2;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 200, // Fixed height to avoid builder issues
              child: ListView(
                children: List.generate(24, (index) {
                  final isSelected = index == _hour;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _hour = index);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? NeoBrutalTheme.primary.withValues(alpha: 0.3) : Colors.transparent,
                        borderRadius: NeoBrutalTheme.radiusSmall,
                      ),
                      child: Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: TextStyle(
                            color: isSelected ? NeoBrutalTheme.primary : Colors.white60,
                            fontSize: isSelected ? 16 : 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const Text(':', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(
              width: 80,
              height: 200, // Fixed height to avoid builder issues
              child: ListView(
                children: List.generate(60, (index) {
                  final isSelected = index == _minute;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _minute = index);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? NeoBrutalTheme.primary.withValues(alpha: 0.3) : Colors.transparent,
                        borderRadius: NeoBrutalTheme.radiusSmall,
                      ),
                      child: Center(
                        child: Text(
                          index.toString().padLeft(2, '0'),
                          style: TextStyle(
                            color: isSelected ? NeoBrutalTheme.primary : Colors.white60,
                            fontSize: isSelected ? 16 : 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => widget.onTimeSelected(_hour, _minute),
          child: const Text('CONFIRM'),
        ),
      ],
    );
  }
}
