import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('app_icon'),
    );
    await _notifications.initialize(settings);
  }

  Future<void> showNotification(String type, String message) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails('channel_id', 'Channel Name'),
    );
    await _notifications.show(0, type, message, details);
    // Types: backup_success, failure, quota_low, etc.
    // In-app and push
    // Do not disturb hours
  }
}
