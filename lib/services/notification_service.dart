import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Notification handler callback
typedef NotificationActionCallback = void Function(String actionId, String? payload);

class NotificationService {
  static final NotificationService instance = NotificationService._init();

  // Channel IDs for different notification types
  static const String taskChannelId = 'task_reminders_channel';
  static const String taskChannelName = 'Task Reminders';
  static const String taskChannelDesc = 'Notifications for task due dates and reminders';

  static const String expenseChannelId = 'expense_alerts_channel';
  static const String expenseChannelName = 'Expense Alerts';
  static const String expenseChannelDesc = 'Budget alerts and spending notifications';

  static const String budgetChannelId = 'budget_warnings_channel';
  static const String budgetChannelName = 'Budget Warnings';
  static const String budgetChannelDesc = 'Critical budget alerts';

  static const String summaryChannelId = 'daily_summary_channel';
  static const String summaryChannelName = 'Daily Summary';
  static const String summaryChannelDesc = 'Daily and weekly summaries';

  // Action IDs for notification buttons (Google Tasks style)
  static const String actionComplete = 'action_complete';
  static const String actionReschedule = 'action_reschedule';
  static const String actionSnooze = 'action_snooze';
  static const String actionMarkPaid = 'action_mark_paid';
  static const String actionRescheduleTomorrow = 'reschedule_tomorrow';
  static const String actionRescheduleWeekend = 'reschedule_weekend';
  static const String actionRescheduleNextWeek = 'reschedule_next_week';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  NotificationActionCallback? _actionCallback;

  NotificationService._init();

  Future<void> init({NotificationActionCallback? onActionReceived}) async {
    if (kIsWeb) {
      _log('Notification service disabled on web');
      return;
    }
    if (_initialized) return;

    _actionCallback = onActionReceived;

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTap,
    );

    await _createNotificationChannels();
    await requestPermissions();

    _initialized = true;
    _log('Notification service initialized with all channels');
  }

  Future<void> _configureLocalTimezone() async {
    try {
      tz.setLocalLocation(tz.local);
    } catch (error, stackTrace) {
      _log('Could not resolve local timezone; falling back to UTC.', error, stackTrace);
    }
  }

  Future<void> _createNotificationChannels() async {
    final channels = [
      AndroidNotificationChannel(
        taskChannelId,
        taskChannelName,
        description: taskChannelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        expenseChannelId,
        expenseChannelName,
        description: expenseChannelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        budgetChannelId,
        budgetChannelName,
        description: budgetChannelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        summaryChannelId,
        summaryChannelName,
        description: summaryChannelDesc,
        importance: Importance.low,
        playSound: false,
      ),
    ];

    for (var channel in channels) {
      await _androidImplementation?.createNotificationChannel(channel);
    }
  }

  Future<void> requestPermissions() async {
    final android = _androidImplementation;
    if (android != null) {
      await android.requestNotificationsPermission();
      try {
        await android.requestExactAlarmsPermission();
      } catch (error, stackTrace) {
        _log('Exact alarm permission request unavailable.', error, stackTrace);
      }
    }

    final ios = _notificationsPlugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<bool> areNotificationsEnabled() async {
    return await _androidImplementation?.areNotificationsEnabled() ?? true;
  }

  // ==================== TASK NOTIFICATIONS (Google Tasks Style) ====================

  /// Task due soon notification (30 minutes before)
  Future<void> showTaskDueNotification({
    required int taskId,
    required String taskTitle,
    required DateTime dueDateTime,
  }) async {
    if (kIsWeb) return;
    await _ensureInitialized();

    final scheduledDate = dueDateTime.subtract(const Duration(minutes: 30));
    if (scheduledDate.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      taskChannelId,
      taskChannelName,
      channelDescription: taskChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(actionComplete, '✓ Complete', showsUserInterface: true),
        AndroidNotificationAction(actionReschedule, '📅 Reschedule', showsUserInterface: true),
        AndroidNotificationAction(actionSnooze, '⏰ Snooze', showsUserInterface: true),
      ],
    );

    const iosDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);

    await _notificationsPlugin.zonedSchedule(
      id: taskId,
      title: '⏰ Task Due Soon',
      body: '"$taskTitle" is due at ${_formatTime(dueDateTime)}',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'task_$taskId',
    );

    _log('Scheduled task due notification for task $taskId');
  }

  /// Overdue task notification (with Reschedule button like Google Tasks)
  Future<void> showOverdueTaskNotification({
    required int taskId,
    required String taskTitle,
    required int daysOverdue,
  }) async {
    if (kIsWeb) return;
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      taskChannelId,
      taskChannelName,
      channelDescription: taskChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(actionComplete, '✓ Mark Complete', showsUserInterface: true),
        AndroidNotificationAction(actionReschedule, '📅 Reschedule', showsUserInterface: true),
      ],
    );

    final body = daysOverdue == 1
        ? '"$taskTitle" is overdue by 1 day'
        : '"$taskTitle" is overdue by $daysOverdue days';

    await _notificationsPlugin.show(
      id: taskId,
      title: '⚠️ Task Overdue',
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: 'task_$taskId',
    );

    _log('Showed overdue task notification for task $taskId ($daysOverdue days)');
  }

  /// Quick Reschedule options (like Google Calendar/Tasks)
  Future<void> showRescheduleOptions({
    required int taskId,
    required String taskTitle,
  }) async {
    if (kIsWeb) return;
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      taskChannelId,
      taskChannelName,
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(actionRescheduleTomorrow, 'Tomorrow', showsUserInterface: true),
        AndroidNotificationAction(actionRescheduleWeekend, 'This Weekend', showsUserInterface: true),
        AndroidNotificationAction(actionRescheduleNextWeek, 'Next Week', showsUserInterface: true),
      ],
    );

    await _notificationsPlugin.show(
      id: taskId + 1000, // Unique ID for reschedule notification
      title: 'Reschedule Task',
      body: 'When would you like to reschedule "$taskTitle"?',
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: 'reschedule_$taskId',
    );

    _log('Showed reschedule options for task $taskId');
  }

  // ==================== EXPENSE & BUDGET NOTIFICATIONS ====================

  /// Budget threshold alert (50%, 80%, 100%, 120%)
  Future<void> showBudgetAlert({
    required String categoryName,
    required double spent,
    required double budget,
    required double percentage,
  }) async {
    if (kIsWeb) return;
    await _ensureInitialized();

    String title;
    String body;
    String channelId;
    Importance importance;

    if (percentage >= 120) {
      title = '🚨 Budget Exceeded!';
      body = '$categoryName: ${percentage.toInt()}% used (₹${spent.toStringAsFixed(0)}/₹${budget.toStringAsFixed(0)})';
      channelId = budgetChannelId;
      importance = Importance.max;
    } else if (percentage >= 100) {
      title = '🚨 Budget Exceeded!';
      body = '$categoryName: ${percentage.toInt()}% used (₹${spent.toStringAsFixed(0)}/₹${budget.toStringAsFixed(0)})';
      channelId = budgetChannelId;
      importance = Importance.max;
    } else if (percentage >= 80) {
      title = '⚠️ Budget Warning';
      body = '$categoryName: ${percentage.toInt()}% used. Only ₹${(budget - spent).toStringAsFixed(0)} left';
      channelId = budgetChannelId;
      importance = Importance.high;
    } else {
      title = '📊 Budget Update';
      body = '$categoryName: ${percentage.toInt()}% of budget used (₹${spent.toStringAsFixed(0)}/₹${budget.toStringAsFixed(0)})';
      channelId = expenseChannelId;
      importance = Importance.low;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelId == budgetChannelId ? budgetChannelName : expenseChannelName,
      importance: importance,
      priority: importance == Importance.max ? Priority.max : Priority.high,
    );

    await _notificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: 'budget_$categoryName',
    );

    _log('Showed budget alert for $categoryName: ${percentage.toInt()}%');
  }

  /// Unusual spending detection
  Future<void> showUnusualSpendingAlert({
    required String categoryName,
    required double amount,
    required double averageAmount,
  }) async {
    if (kIsWeb) return;
    await _ensureInitialized();

    final difference = ((amount - averageAmount) / averageAmount * 100).toInt();
    final isHigher = amount > averageAmount;

    const androidDetails = AndroidNotificationDetails(
      expenseChannelId,
      expenseChannelName,
      importance: Importance.high,
    );

    final title = isHigher ? '📈 Unusual Spending Detected' : '📉 Lower Spending This Week';
    final body = isHigher
        ? '$categoryName: ₹${amount.toStringAsFixed(0)} is ${difference}% higher than usual'
        : '$categoryName: ₹${amount.toStringAsFixed(0)} is ${difference.abs()}% lower than usual. Great job!';

    await _notificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: 'unusual_spending',
    );

    _log('Showed unusual spending alert for $categoryName');
  }

  /// Bill due reminder
  Future<void> showBillReminder({
    required int billId,
    required String billName,
    required double amount,
    required DateTime dueDate,
    required int daysBefore,
  }) async {
    if (kIsWeb) return;
    await _ensureInitialized();

    String title;
    String body;
    String actionLabel;

    if (daysBefore == 0) {
      title = '💰 Bill Due Today';
      body = '$billName of ₹${amount.toStringAsFixed(0)} is due today';
      actionLabel = 'Mark Paid';
    } else if (daysBefore == 1) {
      title = '⏰ Bill Due Tomorrow';
      body = '$billName of ₹${amount.toStringAsFixed(0)} is due tomorrow';
      actionLabel = 'Remind Me Later';
    } else {
      title = '📅 Upcoming Bill';
      body = '$billName of ₹${amount.toStringAsFixed(0)} is due in $daysBefore days';
      actionLabel = 'View Details';
    }

    final androidDetails = AndroidNotificationDetails(
      expenseChannelId,
      expenseChannelName,
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(actionMarkPaid, actionLabel, showsUserInterface: true),
        AndroidNotificationAction(actionSnooze, 'Remind later', showsUserInterface: true),
      ],
    );

    final scheduledDate = dueDate.subtract(Duration(days: daysBefore));
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      id: billId + daysBefore,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'bill_$billId',
    );

    _log('Scheduled bill reminder for $billName ($daysBefore days before)');
  }

  // ==================== DAILY/WEEKLY SUMMARIES ====================

  /// Daily task summary (morning - 9:00 AM)
  Future<void> scheduleDailyTaskSummary({
    int hour = 9,
    int minute = 0,
  }) async {
    if (kIsWeb) return;
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      summaryChannelId,
      summaryChannelName,
      importance: Importance.low,
    );

    await _notificationsPlugin.zonedSchedule(
      id: 1000,
      title: '📋 Your Tasks Today',
      body: 'Tap to see tasks due today',
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexact,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_task_summary',
    );

    _log('Scheduled daily task summary at $hour:${minute.toString().padLeft(2, '0')}');
  }

  /// Daily spending summary (evening - 9:00 PM)
  Future<void> scheduleDailySpendingSummary({
    int hour = 21,
    int minute = 0,
  }) async {
    if (kIsWeb) return;
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      summaryChannelId,
      summaryChannelName,
      importance: Importance.low,
    );

    await _notificationsPlugin.zonedSchedule(
      id: 1001,
      title: '💰 Daily Spending',
      body: 'Tap to see spending breakdown',
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexact,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_spending_summary',
    );

    _log('Scheduled daily spending summary at $hour:${minute.toString().padLeft(2, '0')}');
  }

  /// Productivity insight notification
  Future<void> showProductivityInsight({
    required int tasksCompleted,
    required int totalTasks,
  }) async {
    if (kIsWeb) return;
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      summaryChannelId,
      summaryChannelName,
      importance: Importance.low,
    );

    final completionRate = (tasksCompleted / totalTasks * 100).toInt();
    final body = tasksCompleted > 0
        ? 'You completed $tasksCompleted task${tasksCompleted > 1 ? 's' : ''} today ($completionRate%)! 🎉'
        : 'Start completing tasks to track your productivity!';

    await _notificationsPlugin.show(
      id: 1002,
      title: '✨ Great Productivity',
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: 'productivity_insight',
    );

    _log('Showed productivity insight: $tasksCompleted/$totalTasks completed');
  }

  // ==================== NOTIFICATION HANDLERS ====================

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    final actionId = response.actionId;

    _log('Notification tapped - Action: $actionId, Payload: $payload');

    if (payload == null) return;

    // Route to appropriate handler
    if (payload.startsWith('task_')) {
      _handleTaskAction(actionId, payload);
    } else if (payload.startsWith('reschedule_')) {
      _handleRescheduleAction(actionId, payload);
    } else if (payload.startsWith('bill_')) {
      _handleBillAction(actionId, payload);
    } else {
      _actionCallback?.call(actionId ?? 'open', payload);
    }
  }

  void _handleTaskAction(String? actionId, String payload) {
    switch (actionId) {
      case actionComplete:
        _actionCallback?.call('task_complete', payload);
        break;
      case actionReschedule:
        _actionCallback?.call('task_reschedule', payload);
        break;
      case actionSnooze:
        _actionCallback?.call('task_snooze', payload);
        break;
      default:
        _actionCallback?.call('task_open', payload);
    }
  }

  void _handleRescheduleAction(String? actionId, String payload) {
    switch (actionId) {
      case actionRescheduleTomorrow:
        _actionCallback?.call('reschedule_tomorrow', payload);
        break;
      case actionRescheduleWeekend:
        _actionCallback?.call('reschedule_weekend', payload);
        break;
      case actionRescheduleNextWeek:
        _actionCallback?.call('reschedule_next_week', payload);
        break;
      default:
        _actionCallback?.call('reschedule_custom', payload);
    }
  }

  void _handleBillAction(String? actionId, String payload) {
    switch (actionId) {
      case actionMarkPaid:
        _actionCallback?.call('bill_mark_paid', payload);
        break;
      case actionSnooze:
        _actionCallback?.call('bill_snooze', payload);
        break;
      default:
        _actionCallback?.call('bill_open', payload);
    }
  }

  // ==================== UTILITY METHODS ====================

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() {
    return _notificationsPlugin.pendingNotificationRequests();
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidImplementation {
    return _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
  }

  void _log(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'NotificationService',
      error: error,
      stackTrace: stackTrace,
    );
    if (kDebugMode) {
      debugPrint('[NotificationService] $message');
    }
  }
}

@pragma('vm:entry-point')
void _onBackgroundNotificationTap(NotificationResponse response) {
  developer.log(
    'Background notification tapped: ${response.payload ?? 'no payload'}',
    name: 'NotificationService',
  );
}
