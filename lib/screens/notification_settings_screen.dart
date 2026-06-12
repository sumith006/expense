import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  late SharedPreferences _prefs;
  bool _isLoading = true;

  // Task Notifications
  bool _taskRemindersEnabled = true;
  int _taskReminderMinutesBefore = 30;

  // Budget Alerts
  bool _budgetAlertsEnabled = true;
  bool _budgetAlert50 = false;
  bool _budgetAlert80 = true;
  bool _budgetAlert100 = true;
  bool _budgetAlert120 = true;

  // Bill Reminders
  bool _billRemindersEnabled = true;
  bool _billReminder3Days = true;
  bool _billReminder1Day = true;
  bool _billReminderDueDate = true;

  // Daily Summaries
  bool _dailySummaryEnabled = true;
  TimeOfDay _taskSummaryTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _spendingSummaryTime = const TimeOfDay(hour: 21, minute: 0);

  // Other
  bool _unusualSpendingAlerts = true;
  bool _productivityInsights = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    setState(() {
      // Task Notifications
      _taskRemindersEnabled = _prefs.getBool('task_reminders_enabled') ?? true;
      _taskReminderMinutesBefore =
          _prefs.getInt('task_reminder_minutes_before') ?? 30;

      // Budget Alerts
      _budgetAlertsEnabled = _prefs.getBool('budget_alerts_enabled') ?? true;
      _budgetAlert50 = _prefs.getBool('budget_alert_50') ?? false;
      _budgetAlert80 = _prefs.getBool('budget_alert_80') ?? true;
      _budgetAlert100 = _prefs.getBool('budget_alert_100') ?? true;
      _budgetAlert120 = _prefs.getBool('budget_alert_120') ?? true;

      // Bill Reminders
      _billRemindersEnabled = _prefs.getBool('bill_reminders_enabled') ?? true;
      _billReminder3Days = _prefs.getBool('bill_reminder_3_days') ?? true;
      _billReminder1Day = _prefs.getBool('bill_reminder_1_day') ?? true;
      _billReminderDueDate = _prefs.getBool('bill_reminder_due_date') ?? true;

      // Daily Summaries
      _dailySummaryEnabled = _prefs.getBool('daily_summary_enabled') ?? true;
      final taskTime = _prefs.getString('task_summary_time') ?? '09:00';
      final spendingTime = _prefs.getString('spending_summary_time') ?? '21:00';
      _taskSummaryTime = _parseTimeOfDay(taskTime);
      _spendingSummaryTime = _parseTimeOfDay(spendingTime);

      // Other
      _unusualSpendingAlerts =
          _prefs.getBool('unusual_spending_alerts') ?? true;
      _productivityInsights = _prefs.getBool('productivity_insights') ?? true;

      _isLoading = false;
    });
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is String) {
      await _prefs.setString(key, value);
    }
  }

  Future<void> _showTimePicker() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _taskSummaryTime,
    );
    if (time != null) {
      setState(() => _taskSummaryTime = time);
      await _saveSetting('task_summary_time', _formatTimeOfDay(time));
      await NotificationService.instance.scheduleDailyTaskSummary(
        hour: time.hour,
        minute: time.minute,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task summary time updated')),
        );
      }
    }
  }

  Future<void> _showSpendingTimePicker() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _spendingSummaryTime,
    );
    if (time != null) {
      setState(() => _spendingSummaryTime = time);
      await _saveSetting('spending_summary_time', _formatTimeOfDay(time));
      await NotificationService.instance.scheduleDailySpendingSummary(
        hour: time.hour,
        minute: time.minute,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Spending summary time updated')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // ─── Task Notifications ───────────────────────────────────────────
          _buildSectionHeader('📋 Task Notifications'),
          SwitchListTile(
            title: const Text('Task Reminders'),
            subtitle: const Text('Get notified when tasks are due'),
            value: _taskRemindersEnabled,
            onChanged: (value) async {
              setState(() => _taskRemindersEnabled = value);
              await _saveSetting('task_reminders_enabled', value);
            },
          ),
          if (_taskRemindersEnabled)
            ListTile(
              title: const Text('Reminder Before'),
              subtitle: Text('$_taskReminderMinutesBefore minutes before due time'),
              trailing: DropdownButton<int>(
                value: _taskReminderMinutesBefore,
                items: const [
                  DropdownMenuItem(value: 15, child: Text('15 min')),
                  DropdownMenuItem(value: 30, child: Text('30 min')),
                  DropdownMenuItem(value: 60, child: Text('1 hour')),
                  DropdownMenuItem(value: 120, child: Text('2 hours')),
                  DropdownMenuItem(value: 1440, child: Text('1 day')),
                ],
                onChanged: (value) async {
                  if (value != null) {
                    setState(() => _taskReminderMinutesBefore = value);
                    await _saveSetting('task_reminder_minutes_before', value);
                  }
                },
              ),
            ),
          SwitchListTile(
            title: const Text('Overdue Task Alerts'),
            subtitle: const Text('Daily alerts for overdue tasks'),
            value: _taskRemindersEnabled,
            onChanged: _taskRemindersEnabled
                ? (value) async {
                    setState(() => _taskRemindersEnabled = value);
                    await _saveSetting('task_reminders_enabled', value);
                  }
                : null,
          ),
          const Divider(),

          // ─── Budget Alerts ────────────────────────────────────────────────
          _buildSectionHeader('💰 Budget Alerts'),
          SwitchListTile(
            title: const Text('Budget Alerts'),
            subtitle: const Text('Get notified about spending limits'),
            value: _budgetAlertsEnabled,
            onChanged: (value) async {
              setState(() => _budgetAlertsEnabled = value);
              await _saveSetting('budget_alerts_enabled', value);
            },
          ),
          if (_budgetAlertsEnabled) ...[
            CheckboxListTile(
              title: const Text('Alert at 50% budget'),
              subtitle: const Text('Informational alert'),
              value: _budgetAlert50,
              onChanged: (value) async {
                setState(() => _budgetAlert50 = value ?? false);
                await _saveSetting('budget_alert_50', value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('Alert at 80% budget'),
              subtitle: const Text('Warning alert'),
              value: _budgetAlert80,
              onChanged: (value) async {
                setState(() => _budgetAlert80 = value ?? false);
                await _saveSetting('budget_alert_80', value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('Alert at 100% budget'),
              subtitle: const Text('Critical alert - budget exceeded'),
              value: _budgetAlert100,
              onChanged: (value) async {
                setState(() => _budgetAlert100 = value ?? false);
                await _saveSetting('budget_alert_100', value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('Alert at 120% budget'),
              subtitle: const Text('Emergency alert - significantly over budget'),
              value: _budgetAlert120,
              onChanged: (value) async {
                setState(() => _budgetAlert120 = value ?? false);
                await _saveSetting('budget_alert_120', value ?? false);
              },
            ),
          ],
          SwitchListTile(
            title: const Text('Unusual Spending Alerts'),
            subtitle: const Text('Alert when spending deviates from average'),
            value: _unusualSpendingAlerts,
            onChanged: (value) async {
              setState(() => _unusualSpendingAlerts = value);
              await _saveSetting('unusual_spending_alerts', value);
            },
          ),
          const Divider(),

          // ─── Bill Reminders ───────────────────────────────────────────────
          _buildSectionHeader('📅 Bill Reminders'),
          SwitchListTile(
            title: const Text('Bill Reminders'),
            subtitle: const Text('Get notified about upcoming bills'),
            value: _billRemindersEnabled,
            onChanged: (value) async {
              setState(() => _billRemindersEnabled = value);
              await _saveSetting('bill_reminders_enabled', value);
            },
          ),
          if (_billRemindersEnabled) ...[
            CheckboxListTile(
              title: const Text('3 Days Before'),
              value: _billReminder3Days,
              onChanged: (value) async {
                setState(() => _billReminder3Days = value ?? false);
                await _saveSetting('bill_reminder_3_days', value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('1 Day Before'),
              value: _billReminder1Day,
              onChanged: (value) async {
                setState(() => _billReminder1Day = value ?? false);
                await _saveSetting('bill_reminder_1_day', value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('On Due Date'),
              value: _billReminderDueDate,
              onChanged: (value) async {
                setState(() => _billReminderDueDate = value ?? false);
                await _saveSetting('bill_reminder_due_date', value ?? false);
              },
            ),
          ],
          const Divider(),

          // ─── Daily Summaries ──────────────────────────────────────────────
          _buildSectionHeader('📊 Daily Summaries'),
          SwitchListTile(
            title: const Text('Daily Summaries'),
            subtitle: const Text('Morning task summary and evening spending summary'),
            value: _dailySummaryEnabled,
            onChanged: (value) async {
              setState(() => _dailySummaryEnabled = value);
              await _saveSetting('daily_summary_enabled', value);
              if (value) {
                await NotificationService.instance.scheduleDailyTaskSummary(
                  hour: _taskSummaryTime.hour,
                  minute: _taskSummaryTime.minute,
                );
                await NotificationService.instance.scheduleDailySpendingSummary(
                  hour: _spendingSummaryTime.hour,
                  minute: _spendingSummaryTime.minute,
                );
              }
            },
          ),
          if (_dailySummaryEnabled) ...[
            ListTile(
              title: const Text('Morning Task Summary'),
              subtitle: Text('Daily at ${_formatTimeOfDay(_taskSummaryTime)}'),
              trailing: const Icon(Icons.access_time),
              onTap: _showTimePicker,
            ),
            ListTile(
              title: const Text('Evening Spending Summary'),
              subtitle: Text('Daily at ${_formatTimeOfDay(_spendingSummaryTime)}'),
              trailing: const Icon(Icons.access_time),
              onTap: _showSpendingTimePicker,
            ),
          ],
          SwitchListTile(
            title: const Text('Productivity Insights'),
            subtitle: const Text('Celebrate completed tasks and progress'),
            value: _productivityInsights,
            onChanged: (value) async {
              setState(() => _productivityInsights = value);
              await _saveSetting('productivity_insights', value);
            },
          ),
          const Divider(),

          // ─── Actions ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Test Notification'),
                  onPressed: () async {
                    await NotificationService.instance.showBudgetAlert(
                      categoryName: 'Food',
                      spent: 800,
                      budget: 1000,
                      percentage: 80,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Test notification sent')),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear All Notifications'),
                  onPressed: () async {
                    await NotificationService.instance.cancelAllNotifications();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All notifications cleared')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
      ),
    );
  }
}
