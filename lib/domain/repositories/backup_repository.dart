import 'package:kashly/domain/entities/backup_record.dart';
import 'package:kashly/domain/entities/backup_settings.dart';

abstract class BackupRepository {
  Future<void> insertBackupRecord(BackupRecord record);
  Future<List<BackupRecord>> getBackupHistory({int limit = 50});
  Future<BackupRecord?> getLastBackup(BackupType type);
  Future<void> deleteBackupRecord(String id);
  Future<AppBackupSettings> getSettings();
  Future<void> saveSettings(AppBackupSettings settings);
}
