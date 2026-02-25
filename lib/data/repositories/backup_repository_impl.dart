import 'package:kashly/domain/repositories/backup_repository.dart';
import 'package:kashly/data/datasources/local_datasource.dart';
import 'package:kashly/domain/entities/backup_record.dart';
import 'package:kashly/domain/entities/backup_settings.dart';
import 'package:kashly/core/error/exceptions.dart';

class BackupRepositoryImpl implements BackupRepository {
  final LocalDatasource localDatasource;

  BackupRepositoryImpl(this.localDatasource);

  @override
  Future<void> insertBackupRecord(BackupRecord record) async {
    try {
      await localDatasource.insertBackupRecord(record);
    } catch (e) {
      throw CacheException('Failed to insert backup record: $e');
    }
  }

  @override
  Future<List<BackupRecord>> getBackupHistory({int limit = 50}) async {
    try {
      return await localDatasource.getBackupHistory(limit: limit);
    } catch (e) {
      throw CacheException('Failed to get backup history: $e');
    }
  }

  @override
  Future<BackupRecord?> getLastBackup(BackupType type) async {
    try {
      return await localDatasource.getLastBackup(type.name);
    } catch (e) {
      throw CacheException('Failed to get last backup: $e');
    }
  }

  @override
  Future<void> deleteBackupRecord(String id) async {
    // Not in datasource yet, would add there
  }

  @override
  Future<AppBackupSettings> getSettings() async {
    try {
      return await localDatasource.getBackupSettings();
    } catch (e) {
      throw CacheException('Failed to get backup settings: $e');
    }
  }

  @override
  Future<void> saveSettings(AppBackupSettings settings) async {
    try {
      await localDatasource.saveBackupSettings(settings);
    } catch (e) {
      throw CacheException('Failed to save backup settings: $e');
    }
  }
}
