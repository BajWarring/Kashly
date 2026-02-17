// SERVICE LAYER — backup_service.dart
// Architecture stubs ready for real implementation.
// Each layer is independently replaceable.

// ══════════════════════════════════════════════════════════════════════════════
// DATABASE LAYER
// Real impl: use sqflite package
// ══════════════════════════════════════════════════════════════════════════════

abstract class DatabaseService {
  /// Initialize SQLite database
  Future<void> init();

  /// Get the path to the SQLite .db file (for snapshotting)
  Future<String> getDatabasePath();

  /// Checkpoint WAL to ensure all writes are committed before snapshot
  Future<void> checkpoint();

  /// Close database connection (before snapshot copy)
  Future<void> close();

  /// Re-open database (after restore)
  Future<void> reopen();
}

class DatabaseServiceImpl implements DatabaseService {
  // TODO: inject sqflite Database instance

  @override
  Future<void> init() async {
    // final db = await openDatabase('cashbook.db', version: 1, onCreate: _onCreate);
  }

  @override
  Future<String> getDatabasePath() async {
    // final dir = await getDatabasesPath();
    // return join(dir, 'cashbook.db');
    return '/data/data/com.example.cashbook/databases/cashbook.db';
  }

  @override
  Future<void> checkpoint() async {
    // db.rawQuery('PRAGMA wal_checkpoint(FULL)');
  }

  @override
  Future<void> close() async {
    // await db.close();
  }

  @override
  Future<void> reopen() async {
    // db = await openDatabase(...);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ENCRYPTION SERVICE
// Real impl: use encrypt package (AES-256-GCM)
// ══════════════════════════════════════════════════════════════════════════════

abstract class EncryptionService {
  /// Encrypt raw bytes, returns encrypted bytes
  Future<List<int>> encrypt(List<int> plainBytes);

  /// Decrypt encrypted bytes, returns plain bytes
  Future<List<int>> decrypt(List<int> encryptedBytes);
}

class EncryptionServiceImpl implements EncryptionService {
  // TODO: derive key from user PIN or secure storage (flutter_secure_storage)
  // final _key = Key.fromSecureRandom(32);
  // final _iv = IV.fromSecureRandom(16);

  @override
  Future<List<int>> encrypt(List<int> plainBytes) async {
    // final encrypter = Encrypter(AES(_key, mode: AESMode.gcm));
    // final encrypted = encrypter.encryptBytes(plainBytes, iv: _iv);
    // return [..._iv.bytes, ...encrypted.bytes]; // prepend IV
    return plainBytes; // stub
  }

  @override
  Future<List<int>> decrypt(List<int> encryptedBytes) async {
    // final iv = IV(Uint8List.fromList(encryptedBytes.take(16).toList()));
    // final payload = encryptedBytes.skip(16).toList();
    // final encrypter = Encrypter(AES(_key, mode: AESMode.gcm));
    // return encrypter.decryptBytes(Encrypted(Uint8List.fromList(payload)), iv: iv);
    return encryptedBytes; // stub
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CLOUD STORAGE SERVICE
// Real impl: use googleapis package (Drive API v3)
// ══════════════════════════════════════════════════════════════════════════════

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
  /// Sign in to Google account
  Future<String?> signIn();

  /// Sign out
  Future<void> signOut();

  /// Get signed-in account email
  Future<String?> getAccountEmail();

  /// Upload encrypted backup, returns Drive file ID
  Future<String> uploadBackup(List<int> encryptedBytes, String filename);

  /// Download backup by Drive file ID
  Future<List<int>> downloadBackup(String driveFileId);

  /// List all backups in Drive folder (sorted newest first)
  Future<List<BackupFile>> listBackups();

  /// Delete a backup by Drive file ID
  Future<void> deleteBackup(String driveFileId);
}

class GoogleDriveService implements CloudStorageService {
  // TODO: inject google_sign_in + googleapis DriveApi
  static const _folderName = 'CashBookBackups';

  @override
  Future<String?> signIn() async {
    // final account = await GoogleSignIn(scopes: [DriveApi.driveFileScope]).signIn();
    // return account?.email;
    return 'user@gmail.com'; // stub
  }

  @override
  Future<void> signOut() async {
    // await _googleSignIn.signOut();
  }

  @override
  Future<String?> getAccountEmail() async {
    // return _googleSignIn.currentUser?.email;
    return 'user@gmail.com'; // stub
  }

  @override
  Future<String> uploadBackup(List<int> encryptedBytes, String filename) async {
    // final media = Media(Stream.value(encryptedBytes), encryptedBytes.length);
    // final file = File()..name = filename..parents = [await _getOrCreateFolder()];
    // final result = await _driveApi.files.create(file, uploadMedia: media);
    // return result.id!;
    return 'stub_file_id_${DateTime.now().millisecondsSinceEpoch}'; // stub
  }

  @override
  Future<List<int>> downloadBackup(String driveFileId) async {
    // final media = await _driveApi.files.get(driveFileId, downloadOptions: DownloadOptions.fullMedia) as Media;
    // return await media.stream.expand((e) => e).toList();
    return []; // stub
  }

  @override
  Future<List<BackupFile>> listBackups() async {
    // final result = await _driveApi.files.list(q: "'$_folderId' in parents", orderBy: 'createdTime desc');
    // return result.files!.map((f) => BackupFile(...)).toList();
    return []; // stub
  }

  @override
  Future<void> deleteBackup(String driveFileId) async {
    // await _driveApi.files.delete(driveFileId);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SYNC SERVICE (orchestrates everything)
// Debounce timer + retry logic
// ══════════════════════════════════════════════════════════════════════════════

class SyncService {
  final DatabaseService _db;
  final EncryptionService _enc;
  final CloudStorageService _cloud;

  static const _debounceSeconds = 20;
  static const _maxBackups = 5;

  DateTime? _lastDebounce;

  SyncService({
    required DatabaseService db,
    required EncryptionService enc,
    required CloudStorageService cloud,
  })  : _db = db,
        _enc = enc,
        _cloud = cloud;

  /// Call this after every data mutation
  Future<void> onDataChanged(void Function(String) onStatusUpdate) async {
    _lastDebounce = DateTime.now();
    onStatusUpdate('pending');

    await Future.delayed(const Duration(seconds: _debounceSeconds), () async {
      // If more changes happened during debounce, skip this run
      final elapsed = DateTime.now().difference(_lastDebounce!).inSeconds;
      if (elapsed < _debounceSeconds) return;

      await _runBackupWithRetry(onStatusUpdate);
    });
  }

  Future<void> runImmediateBackup(void Function(String) onStatusUpdate) async {
    await _runBackupWithRetry(onStatusUpdate);
  }

  Future<void> _runBackupWithRetry(void Function(String) onStatusUpdate,
      {int attempt = 1}) async {
    try {
      onStatusUpdate('syncing');

      // 1. Checkpoint SQLite WAL
      await _db.checkpoint();

      // 2. Read .db file bytes
      final dbPath = await _db.getDatabasePath();
      // final bytes = await File(dbPath).readAsBytes(); // real impl

      // 3. Encrypt
      // final encrypted = await _enc.encrypt(bytes);
      final encrypted = <int>[]; // stub

      // 4. Generate timestamped filename
      final ts = DateTime.now().millisecondsSinceEpoch;
      final filename = 'cashbook_backup_v$ts.db.enc';

      // 5. Upload to Google Drive
      await _cloud.uploadBackup(encrypted, filename);

      // 6. Prune old backups (keep latest _maxBackups)
      final all = await _cloud.listBackups();
      if (all.length > _maxBackups) {
        final toDelete = all.skip(_maxBackups).toList();
        for (final f in toDelete) {
          await _cloud.deleteBackup(f.driveFileId);
        }
      }

      onStatusUpdate('synced');
    } catch (e) {
      if (attempt <= 5) {
        // Exponential backoff: 2^attempt seconds
        final delay = Duration(seconds: (2 << attempt).clamp(2, 60));
        await Future.delayed(delay,
            () => _runBackupWithRetry(onStatusUpdate, attempt: attempt + 1));
      } else {
        onStatusUpdate('error');
      }
    }
  }

  Future<void> restoreLatest() async {
    final files = await _cloud.listBackups();
    if (files.isEmpty) throw Exception('No backups found');

    final latest = files.first;
    final encrypted = await _cloud.downloadBackup(latest.driveFileId);
    final decrypted = await _enc.decrypt(encrypted);

    // Replace local db file
    // await _db.close();
    // await File(await _db.getDatabasePath()).writeAsBytes(decrypted);
    // await _db.reopen();
  }
}
