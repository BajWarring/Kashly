import 'package:kashly/services/backup/backup_service.dart';

class SyncService {
  final BackupService backupService = BackupService();

  void triggerSync(String trigger) {
    // Triggers: add_entry, edit_entry, etc.
    switch (trigger) {
      case 'add_entry':
        backupService.incrementalBackup();
        break;
      // Other cases
    }
  }

  Future<void> detectConflicts() async {
    // Compare checksums, versions
    // Auto resolve last_write_wins or manual
  }

  Future<void> retryFailed() async {
    // Exponential backoff, max 5
    int retries = 0;
    while (retries < 5) {
      try {
        await backupService.incrementalBackup();
        break;
      } catch (e) {
        await Future.delayed(Duration(seconds: pow(2, retries).toInt()));
        retries++;
      }
    }
  }

  // Bandwidth limit: throttle uploads
  // Respect preferences
}
