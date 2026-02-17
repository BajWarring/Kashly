// SERVICE LAYER — backup_service.dart
// Architecture stubs ready for real implementation.

abstract class DatabaseService {
  Future<void> init();
  Future<String> getDatabasePath();
  Future<void> checkpoint();
  Future<void> close();
  Future<void> reopen();
}

abstract class EncryptionService {
  Future<List<int>> encrypt(List<int> plainBytes);
  Future<List<int>> decrypt(List<int> encryptedBytes);
}

class BackupFile {
  final String driveFileId;
  final String name;
  final DateTime createdTime;
  final int sizeBytes;

  const BackupFile({
    required this.driveFileId,
    required this.name,
    required this.createdTime,
    required this.sizeBytes,
  });
}

abstract class CloudStorageService {
  Future<String?> signIn();
  Future<void> signOut();
  Future<String?> getAccountEmail();
  Future<String> uploadBackup(List<int> encryptedBytes, String filename);
  Future<List<int>> downloadBackup(String driveFileId);
  Future<List<BackupFile>> listBackups();
  Future<void> deleteBackup(String driveFileId);
}

class SyncService {
  final DatabaseService _db;
  final EncryptionService _enc;
  final CloudStorageService _cloud;

  static const _maxBackups = 5;

  SyncService({
    required DatabaseService db,
    required EncryptionService enc,
    required CloudStorageService cloud,
  })  : _db = db,
        _enc = enc,
        _cloud = cloud;

  Future<void> runImmediateBackup(
      void Function(String) onStatusUpdate) async {
    // TODO: implement
  }

  Future<void> restoreLatest() async {
    final files = await _cloud.listBackups();
    if (files.isEmpty) throw Exception('No backups found');
    // TODO: implement restore
  }
}
