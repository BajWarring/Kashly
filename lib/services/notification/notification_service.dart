import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final _logger = Logger();
  bool _initialized = false;

  static const String _channelId = 'kashly_channel';
  static const String _channelName = 'Kashly Notifications';
  static const String _channelDesc = 'Backup and sync status notifications';

  Future<void> init() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notifications.initialize(settings);
    _initialized = true;
  }

  Future<void> showBackupSuccess(String message) async {
    await _show('Backup Successful', message, 'backup_success', importance: Importance.defaultImportance);
  }

  Future<void> showBackupFailure(String message) async {
    await _show('Backup Failed', message, 'backup_failure', importance: Importance.high);
  }

  Future<void> showDriveQuotaLow() async {
    await _show(
      'Drive Storage Low',
      'Your Google Drive storage is running low. Consider freeing up space.',
      'quota_low',
      importance: Importance.high,
    );
  }

  Future<void> showNonUploadedPending(int count) async {
    await _show(
      'Pending Uploads',
      '$count entries are waiting to be synced to Google Drive.',
      'pending',
    );
  }

  Future<void> showConflictDetected(int count) async {
    await _show(
      'Sync Conflicts',
      '$count conflicts need your attention in Backup Center.',
      'conflict',
      importance: Importance.high,
    );
  }

  Future<void> showScheduledBackupStarted() async {
    await _show('Backup Started', 'Scheduled backup is in progress...', 'backup_started');
  }

  Future<void> _show(
    String title,
    String body,
    String tag, {
    Importance importance = Importance.defaultImportance,
  }) async {
    if (!_initialized) await init();
    try {
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: importance,
        priority: Priority.defaultPriority,
        tag: tag,
      );
      const iosDetails = DarwinNotificationDetails();
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      await _notifications.show(
        tag.hashCode,
        title,
        body,
        details,
      );
    } catch (e) {
      _logger.e('Notification error: $e');
    }
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
