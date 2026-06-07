import '../services/notification_service.dart';
import '../models/task.dart';

class NotificationHelper {
  static final NotificationService _service = NotificationService.instance;

  /// Schedule a task reminder using the new NotificationService API
  static Future<void> scheduleTaskReminder(Task task, int minutesBefore) async {
    if (task.status == TaskStatus.completed ||
        task.dueDate.isBefore(DateTime.now())) {
      return;
    }

    // Use the new showTaskDueNotification method
    await _service.showTaskDueNotification(
      taskId: task.id.hashCode,
      taskTitle: task.title,
      dueDateTime: task.dueDate,
    );
  }

  /// Cancel a task reminder
  static Future<void> cancelTaskReminder(String taskId) async {
    await _service.cancelNotification(taskId.hashCode);
  }

  /// Trigger a budget warning using the new NotificationService API
  static Future<void> triggerBudgetWarning(
    double percentage,
    double budgetAmount,
  ) async {
    // Use the new showBudgetAlert method
    await _service.showBudgetAlert(
      categoryName: 'Overall Budget',
      spent: (budgetAmount * percentage / 100),
      budget: budgetAmount,
      percentage: percentage,
    );
  }
}
