import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shared_providers.dart';
import '../providers/settings_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/task_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/budget_provider.dart';
import '../services/backup_service.dart';
import '../database/hive_service.dart';
import '../app/routes.dart';
import '../utils/constants_shared.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // Profile Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            color: isDark ? AppConstants.darkCardColor.withValues(alpha: 0.4) : Colors.white,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, size: 36, color: AppConstants.primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.profileName ?? 'Productive User',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Manage your profile and settings',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
                  icon: const Icon(Icons.edit_outlined, color: AppConstants.primaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Appearance Options
          _buildSectionHeader('APPEARANCE & VISUALS'),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Theme Mode'),
              subtitle: Text(settings.themeMode.name.toUpperCase()),
              trailing: DropdownButton<ThemeMode>(
                value: settings.themeMode,
                underline: const SizedBox.shrink(),
                onChanged: (val) {
                  if (val != null) {
                    settingsNotifier.updateTheme(val);
                  }
                },
                items: ThemeMode.values
                    .map((tm) => DropdownMenuItem<ThemeMode>(
                          value: tm,
                          child: Text(tm.name.toUpperCase()),
                        ))
                    .toList(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on_outlined),
              title: const Text('Currency Symbol'),
              subtitle: const Text('Preferred financial currency mark'),
              trailing: DropdownButton<String>(
                value: settings.currencySymbol,
                underline: const SizedBox.shrink(),
                onChanged: (val) {
                  if (val != null) {
                    settingsNotifier.updateCurrency(val);
                  }
                },
                items: ['\$', '€', '₹', '£', '¥', '₩']
                    .map((symbol) => DropdownMenuItem<String>(
                          value: symbol,
                          child: Text(symbol),
                        ))
                    .toList(),
              ),
            ),
          ]),

          // Security Setup
          _buildSectionHeader('SECURITY & BIO-LOCK'),
          _buildSettingsCard([
            SwitchListTile(
              secondary: const Icon(Icons.lock_outline),
              title: const Text('Enable Passcode Lock'),
              subtitle: const Text('Ask for PIN on app startup'),
              value: settings.isPinEnabled,
              activeThumbColor: AppConstants.primaryColor,
              onChanged: (val) {
                if (val) {
                  _showSetupPinPrompt(context, settingsNotifier);
                } else {
                  settingsNotifier.disablePin();
                }
              },
            ),
            if (settings.isPinEnabled) ...[
              ListTile(
                leading: const Icon(Icons.password),
                title: const Text('Change Security PIN'),
                onTap: () => _showSetupPinPrompt(context, settingsNotifier),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: const Text('Enable Biometrics'),
                subtitle: const Text('Unlock using Fingerprint or FaceID'),
                value: settings.isBiometricEnabled,
                activeThumbColor: AppConstants.primaryColor,
                onChanged: (val) {
                  settingsNotifier.updateBiometrics(val);
                },
              ),
            ]
          ]),

          // Notifications Setup
          _buildSectionHeader('ALERTS & NOTIFICATIONS'),
          _buildSettingsCard([
            SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined),
              title: const Text('Daily Logging Reminders'),
              subtitle: const Text('Remind me to log daily expenses'),
              value: settings.dailyReminderEnabled,
              activeThumbColor: AppConstants.primaryColor,
              onChanged: (val) {
                settingsNotifier.updateDailyReminder(val, settings.dailyReminderTime);
              },
            ),
            if (settings.dailyReminderEnabled)
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Daily Alert Time'),
                subtitle: Text(settings.dailyReminderTime?.format(context) ?? '8:00 PM'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => _selectDailyReminderTime(context, ref),
              ),
            SwitchListTile(
              secondary: const Icon(Icons.checklist),
              title: const Text('Task Reminders'),
              subtitle: const Text('Notify before a task is due'),
              value: settings.taskReminderEnabled,
              activeThumbColor: AppConstants.primaryColor,
              onChanged: (val) {
                settingsNotifier.updateTaskReminder(val, settings.taskReminderMinutesBefore);
              },
            ),
            if (settings.taskReminderEnabled)
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Alert Prior Lead Time'),
                subtitle: const Text('Minutes before due date'),
                trailing: DropdownButton<int>(
                  value: settings.taskReminderMinutesBefore,
                  underline: const SizedBox.shrink(),
                  onChanged: (val) {
                    if (val != null) {
                      settingsNotifier.updateTaskReminder(settings.taskReminderEnabled, val);
                    }
                  },
                  items: [5, 15, 30, 60]
                      .map((mins) => DropdownMenuItem<int>(
                            value: mins,
                            child: Text('$mins Minutes'),
                        ))
                      .toList(),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Notification Test'),
              subtitle: const Text('Verify immediate and scheduled alerts'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.notificationTest,
              ),
            ),
          ]),

          // Data Management
          _buildSectionHeader('DATA MANAGEMENT'),
          _buildSettingsCard([
            ListTile(
              leading: const Icon(Icons.backup_outlined, color: AppConstants.primaryColor),
              title: const Text('Backup Local Data'),
              subtitle: const Text('Export all data to a JSON backup file'),
              onTap: () => _exportDataBackup(context),
            ),
            ListTile(
              leading: const Icon(Icons.restore_outlined, color: AppConstants.secondaryColor),
              title: const Text('Restore Data'),
              subtitle: const Text('Import from a JSON backup file'),
              onTap: () => _restoreDataBackup(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: AppConstants.expenseColor),
              title: const Text('Delete All Local Data', style: TextStyle(color: AppConstants.expenseColor)),
              subtitle: const Text('Wipe database and restore default settings'),
              onTap: () => _clearAllDataPrompt(context, ref),
            ),
          ]),

          // About Section
          _buildSectionHeader('ABOUT'),
          _buildSettingsCard([
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('App Version'),
              trailing: Text('1.0.0 (Build 1)', style: TextStyle(color: Colors.grey)),
            ),
          ]),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: children,
      ),
    );
  }

  // Dialog & Form Triggers
  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    final controller = TextEditingController(text: settings.profileName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter name',
              labelText: 'Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await ref.read(settingsProvider.notifier).updateProfile(controller.text.trim(), null);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showSetupPinPrompt(BuildContext context, SettingsNotifier notifier) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter 4-Digit Security PIN'),
          content: TextField(
            controller: controller,
            maxLength: 4,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Enter PIN',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pin = controller.text;
                if (pin.length == 4) {
                  await notifier.setPin(pin);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN security activated.')),
                    );
                  }
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDailyReminderTime(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: settings.dailyReminderTime ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null) {
      await ref.read(settingsProvider.notifier).updateDailyReminder(settings.dailyReminderEnabled, picked);
    }
  }

  Future<void> _exportDataBackup(BuildContext context) async {
    try {
      final path = await BackupService.instance.exportBackup();
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Data Backup Created'),
            content: Text('Your database was exported successfully to:\n\n$path'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppConstants.expenseColor),
        );
      }
    }
  }

  Future<void> _restoreDataBackup(BuildContext context, WidgetRef ref) async {
    try {
      final success = await BackupService.instance.restoreBackup();
      if (success) {
        // Refresh all providers with the newly restored DB tables
        ref.read(expenseProvider.notifier).refresh();
        ref.read(taskProvider.notifier).refresh();
        ref.read(goalsProvider.notifier).refresh();
        ref.read(recurringProvider.notifier).refresh();
        ref.read(budgetProvider.notifier).refresh();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database restored successfully!'),
              backgroundColor: AppConstants.secondaryColor,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e'), backgroundColor: AppConstants.expenseColor),
        );
      }
    }
  }

  void _clearAllDataPrompt(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Everything?', style: TextStyle(color: AppConstants.expenseColor)),
          content: const Text(
            'This action is permanent and cannot be undone. All your expenses, incomes, budgets, recurring rules, and tasks will be completely wiped from this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await HiveService.instance.clearAllData();
                final prefs = ref.read(sharedPreferencesProvider);
                await prefs.clear();
                await ref.read(settingsProvider.notifier).disablePin();

                // Refresh state reloads
                ref.read(expenseProvider.notifier).refresh();
                ref.read(taskProvider.notifier).refresh();
                ref.read(goalsProvider.notifier).refresh();
                ref.read(recurringProvider.notifier).refresh();
                ref.read(budgetProvider.notifier).refresh();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('App database cleared completely.')),
                  );
                  Navigator.pushReplacementNamed(context, AppRoutes.pinSetup);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.expenseColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset All Data'),
            ),
          ],
        );
      },
    );
  }
}
