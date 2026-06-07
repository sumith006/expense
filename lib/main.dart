import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'database/hive_service.dart';
import 'providers/shared_providers.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Hive
  await HiveService.instance.init();

  // Initialize local notifications before the first frame.
  await NotificationService.instance.init(
    onActionReceived: _handleNotificationAction,
  );
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ExpenseTaskApp(),
    ),
  );
}

/// Handle notification actions (button taps, reschedule, etc.)
void _handleNotificationAction(String actionId, String? payload) {
  debugPrint('Notification Action: $actionId, Payload: $payload');
  
  // Route notification actions to appropriate handlers
  switch (actionId) {
    case 'task_complete':
      debugPrint('Task completed from notification');
      break;
    case 'task_reschedule':
      debugPrint('Reschedule task from notification');
      break;
    case 'task_snooze':
      debugPrint('Snooze task from notification');
      break;
    case 'reschedule_tomorrow':
      debugPrint('Reschedule to tomorrow');
      break;
    case 'reschedule_weekend':
      debugPrint('Reschedule to weekend');
      break;
    case 'reschedule_next_week':
      debugPrint('Reschedule to next week');
      break;
    case 'bill_mark_paid':
      debugPrint('Mark bill as paid from notification');
      break;
    default:
      debugPrint('Open detail view for payload: $payload');
  }
}
