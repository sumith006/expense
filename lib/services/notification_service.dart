import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

// Notification handler callback
typedef NotificationActionCallback = void Function(String actionId, String? payload);

class NotificationService {
  static final NotificationService instance = NotificationService._init();

  // Channel IDs for different notification types
  static const String taskChannelId = 'task_channel';
  static const String taskChannelName = 'Task Reminders';
  static const String taskChannelDesc = 'Task due reminders and overdue alerts';

  static const String budgetChannelId = 'budget_channel';
  static const String budgetChannelName = 'Budget Alerts';
  static const String budgetChannelDesc = 'Budget threshold alerts';

  static const String summaryChannelId = 'summary_channel';
  static const String summaryChannelName = 'Daily Summary';
  static const String summaryChannelDesc = 'Daily and weekly summaries';

  // Action IDs for notification buttons (Google Tasks style)
  static const String actionComplete = 'COMPLETE_ACTION';
  static const String actionReschedule = 'RESCHEDULE_ACTION';
  static const String actionSnooze = 'SNOOZE_ACTION';
  
  // Reschedule options
  static const String actionRescheduleTomorrow = 'reschedule_tomorrow';
  static const String actionRescheduleWeekend = 'reschedule_weekend';
  static const String actionRescheduleNextWeek = 'reschedule_next_week';
  static const String actionRescheduleCustom = 'reschedule_custom';

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
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (e) {
      _log('Could not set local timezone to Asia/Kolkata, falling back to UTC');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );

    await _createNotificationChannels();
    await requestPermissions();

    _initialized = true;
    _log('Notification service initialized');
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    const AndroidNotificationChannel taskChannel = AndroidNotificationChannel(
      taskChannelId,
      taskChannelName,
      description: taskChannelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await androidPlugin?.createNotificationChannel(taskChannel);

    const AndroidNotificationChannel budgetChannel = AndroidNotificationChannel(
      budgetChannelId,
      budgetChannelName,
      description: budgetChannelDesc,
      importance: Importance.high,
    );
    await androidPlugin?.createNotificationChannel(budgetChannel);

    const AndroidNotificationChannel summaryChannel = AndroidNotificationChannel(
      summaryChannelId,
      summaryChannelName,
      description: summaryChannelDesc,
      importance: Importance.low,
    );
    await androidPlugin?.createNotificationChannel(summaryChannel);
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    final android = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      try {
        await android.requestExactAlarmsPermission();
      } catch (e) {
        _log('Exact alarm permission request failed or unavailable');
      }
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final android = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() {
    return _notificationsPlugin.pendingNotificationRequests();
  }

  Future<void> showTaskDueNotification({
    required int taskId,
    required String taskTitle,
    required DateTime dueDateTime,
  }) async {
    await showTaskDueReminder(taskId: taskId, taskTitle: taskTitle, dueDateTime: dueDateTime);
  }

  Future<void> showTaskDueReminder({
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
      channelDescription: 'Task due soon',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(actionComplete, '✓ Complete', showsUserInterface: true),
        AndroidNotificationAction(actionReschedule, '📅 Reschedule', showsUserInterface: true),
        AndroidNotificationAction(actionSnooze, '⏰ Snooze', showsUserInterface: true),
      ],
    );

    const iosDetails = DarwinNotificationDetails(categoryIdentifier: 'task_category');

    await _notificationsPlugin.zonedSchedule(
      taskId,
      '⏰ Task Due Soon',
      '"$taskTitle" is due at ${_formatTime(dueDateTime)}',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'task_$taskId',
    );
  }

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
      channelDescription: 'Task is overdue',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(actionComplete, '✓ Mark Complete', showsUserInterface: true),
        AndroidNotificationAction(actionReschedule, '📅 Reschedule →', showsUserInterface: true),
      ],
    );

    final String body = daysOverdue == 1
        ? '"$taskTitle" is overdue by 1 day'
        : '"$taskTitle" is overdue by $daysOverdue days';

    await _notificationsPlugin.show(
      taskId + 10000,
      '⚠️ Task Overdue',
      body,
      const NotificationDetails(android: androidDetails),
      payload: 'task_$taskId',
    );
  }

  Future<void> showRescheduleOptions({
    required int taskId,
    required String taskTitle,
  }) async {
    if (kIsWeb) return;
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      taskChannelId,
      taskChannelName,
      channelDescription: 'Reschedule options',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(actionRescheduleTomorrow, 'Tomorrow', showsUserInterface: true),
        AndroidNotificationAction(actionRescheduleWeekend, 'This Weekend', showsUserInterface: true),
        AndroidNotificationAction(actionRescheduleNextWeek, 'Next Week', showsUserInterface: true),
        AndroidNotificationAction(actionRescheduleCustom, 'Custom...', showsUserInterface: true),
      ],
    );

    await _notificationsPlugin.show(
      taskId + 20000,
      'Reschedule Task',
      'When would you like to reschedule "$taskTitle"?',
      const NotificationDetails(android: androidDetails),
      payload: 'reschedule_$taskId',
    );
  }

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

    if (percentage >= 120) {
      title = '🚨 Budget Severely Exceeded!';
      body = '$categoryName: ${percentage.toInt()}% used (\$${spent.toStringAsFixed(0)}/\$${budget.toStringAsFixed(0)})';
    } else if (percentage >= 100) {
      title = '🚨 Budget Exceeded!';
      body = '$categoryName: ${percentage.toInt()}% used (\$${spent.toStringAsFixed(0)}/\$${budget.toStringAsFixed(0)})';
    } else if (percentage >= 80) {
      title = '⚠️ Budget Warning';
      body = '$categoryName: ${percentage.toInt()}% used. Only \$${(budget - spent).toStringAsFixed(0)} left';
    } else {
      title = '📊 Budget Update';
      body = '$categoryName: ${percentage.toInt()}% of budget used';
    }

    const androidDetails = AndroidNotificationDetails(
      budgetChannelId,
      budgetChannelName,
      importance: Importance.high,
      priority: Priority.high,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: 'budget_$categoryName',
    );
  }

  Future<void> scheduleDailyTaskSummary({int hour = 21, int minute = 0}) async {
    if (kIsWeb) return;
    await _ensureInitialized();

    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      summaryChannelId,
      summaryChannelName,
      importance: Importance.low,
      priority: Priority.low,
    );

    await _notificationsPlugin.zonedSchedule(
      3000,
      '📋 Your Tasks Today',
      'Open the app to view your remaining tasks and financial summary.',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexact,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'daily_summary',
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    final actionId = response.actionId;

    _log('Notification tapped - Action: $actionId, Payload: $payload');

    if (payload == null) return;

    if (payload.startsWith('task_')) {
      final taskIdStr = payload.split('_')[1];
      _handleTaskAction(actionId, taskIdStr, payload);
    } else if (payload.startsWith('reschedule_')) {
      final taskIdStr = payload.split('_')[1];
      _handleRescheduleAction(actionId, taskIdStr, payload);
    } else {
      _actionCallback?.call(actionId ?? 'open', payload);
    }
  }

  void _handleTaskAction(String? actionId, String taskId, String payload) {
    switch (actionId) {
      case actionComplete:
        _actionCallback?.call('task_complete', payload);
        break;
      case actionReschedule:
        showRescheduleOptions(taskId: int.parse(taskId), taskTitle: 'Task');
        break;
      case actionSnooze:
        _actionCallback?.call('task_snooze', payload);
        break;
      default:
        _actionCallback?.call('task_open', payload);
    }
  }

  void _handleRescheduleAction(String? actionId, String taskId, String payload) {
    if (actionId != null) {
      _actionCallback?.call(actionId, payload);
    } else {
      _actionCallback?.call('reschedule_custom', payload);
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
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
  developer.log('Background notification tapped: ${response.payload}', name: 'NotificationService');
}
