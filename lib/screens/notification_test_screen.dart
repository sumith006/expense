import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../utils/constants_shared.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final NotificationService _notifications = NotificationService.instance;

  bool _areEnabled = false;
  int _pendingCount = 0;
  String _pendingIds = 'None';

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final enabled = await _notifications.areNotificationsEnabled();
    final pending = await _notifications.getPendingNotifications();
    if (!mounted) return;

    setState(() {
      _areEnabled = enabled;
      _pendingCount = pending.length;
      _pendingIds = pending.isEmpty
          ? 'None'
          : pending.map((notification) => notification.id).join(', ');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Test')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _areEnabled
                        ? 'Notifications enabled'
                        : 'Notifications disabled',
                    style: TextStyle(
                      color: _areEnabled
                          ? AppConstants.secondaryColor
                          : AppConstants.expenseColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Pending: $_pendingCount ($_pendingIds)'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showImmediateNotification,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Show Immediate Notification'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _scheduleTenSecondNotification,
            icon: const Icon(Icons.timer_outlined),
            label: const Text('Schedule in 10 Seconds'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _refreshStatus,
            icon: const Icon(Icons.pending_actions_outlined),
            label: const Text('Refresh Pending'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _cancelAll,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel All Notifications'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImmediateNotification() async {
    // Test with a budget alert notification
    await _notifications.showBudgetAlert(
      categoryName: 'Test Category',
      spent: 800,
      budget: 1000,
      percentage: 80,
    );
    await _refreshStatus();
  }

  Future<void> _scheduleTenSecondNotification() async {
    // Test with a task due notification scheduled for 10 seconds from now
    final dueDateTime = DateTime.now().add(const Duration(seconds: 10));
    await _notifications.showTaskDueNotification(
      taskId: 2,
      taskTitle: 'Test Task',
      dueDateTime: dueDateTime,
    );
    await _refreshStatus();
  }

  Future<void> _cancelAll() async {
    await _notifications.cancelAllNotifications();
    await _refreshStatus();
  }
}
