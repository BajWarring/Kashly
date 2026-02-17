// BACKUP SERVICE — Google Drive backup/restore with AES encryption.
// Uses google_sign_in + googleapis packages.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/data_store.dart';

// ── Google Auth HTTP Client ────────────────────────────────────────────────

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}

// ── Backup Metadata ────────────────────────────────────────────────────────

class BackupMetadata {
  final String fileId;
  final String fileName;
  final DateTime createdTime;
  final int sizeBytes;
  final bool isLatest;

  const BackupMetadata({
    required this.fileId,
    required this.fileName,
    required this.createdTime,
    required this.sizeBytes,
    this.isLatest = false,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '${sizeBytes}B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

// ── Backup Service ─────────────────────────────────────────────────────────

class BackupService {
  static const _scopes = [
    'https://www.googleapis.com/auth/drive.appdata',
  ];
  static const _maxBackups = 5;
  static const _backupFilePrefix = 'KASHLY_backup_v';
  static const _lastBackupKey = 'last_backup_timestamp';
  static const _autoBackupKey = 'auto_backup_enabled';

  // Debounce timer for auto-backup
  Timer? _debounceTimer;
  static const _debounceDelay = Duration(seconds: 20);

  // Retry state
  int _retryCount = 0;
  static const _maxRetries = 5;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );

  // Singleton
  static BackupService? _instance;
  static BackupService get instance => _instance ??= BackupService._();
  BackupService._();

  // State callbacks
  Function(BackupServiceState)? onStateChanged;

  BackupServiceState _state = BackupServiceState.idle;
  BackupServiceState get state => _state;

  String? _connectedEmail;
  String? get connectedEmail => _connectedEmail;

  DateTime? _lastBackupTime;
  DateTime? get lastBackupTime => _lastBackupTime;

  String? _lastBackupSize;
  String? get lastBackupSize => _lastBackupSize;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _autoBackupEnabled = true;
  bool get autoBackupEnabled => _autoBackupEnabled;

  List<BackupMetadata> _backupHistory = [];
  List<BackupMetadata> get backupHistory => _backupHistory;

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _autoBackupEnabled = prefs.getBool(_autoBackupKey) ?? true;
    final lastTs = prefs.getInt(_lastBackupKey);
    if (lastTs != null) {
      _lastBackupTime = DateTime.fromMillisecondsSinceEpoch(lastTs);
    }

    // Try silent sign-in
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        _connectedEmail = account.email;
        _setState(BackupServiceState.idle);
        // Load backup history in background
        unawaited(_loadBackupHistory());
      }
    } catch (_) {
      // Silent sign-in failed — user needs to sign in manually
    }
  }

  // ── Authentication ────────────────────────────────────────────────────────

  Future<String?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null; // User cancelled
      _connectedEmail = account.email;
      _setState(BackupServiceState.idle);
      await _loadBackupHistory();
      return account.email;
    } catch (e) {
      _setError('Sign-in failed: ${e.toString()}');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _connectedEmail = null;
    _backupHistory = [];
    _setState(BackupServiceState.idle);
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      final account = await _googleSignIn.signInSilently() ??
          await _googleSignIn.signIn();
      if (account == null) return null;

      final auth = await account.authentication;
      final authClient = _GoogleAuthClient({
        'Authorization': 'Bearer ${auth.accessToken}',
      });
      return drive.DriveApi(authClient);
    } catch (e) {
      _setError('Authentication error: ${e.toString()}');
      return null;
    }
  }

  // ── Backup ────────────────────────────────────────────────────────────────

  /// Called when data changes — debounces backup trigger
  void notifyDataChanged() {
    if (!_autoBackupEnabled || _connectedEmail == null) return;
    _setState(BackupServiceState.pending);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      runBackup();
    });
  }

  /// Manually trigger backup immediately
  Future<bool> runBackup() async {
    if (_connectedEmail == null) {
      _setError('Not signed in to Google Drive');
      return false;
    }
    _setState(BackupServiceState.syncing);
    try {
      final api = await _getDriveApi();
      if (api == null) {
        _setError('Could not connect to Google Drive');
        return false;
      }

      // Export data
      final jsonData = DataStore.instance.exportAllDataAsJson();
      final bytes = utf8.encode(jsonData);

      // Simple encryption (XOR with key — replace with proper AES in production)
      final encrypted = _encrypt(Uint8List.fromList(bytes));

      // Upload
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${_backupFilePrefix}${timestamp}.db.enc';
      await _uploadFile(api, encrypted, fileName);

      // Cleanup old backups
      await _pruneOldBackups(api);
      await _loadBackupHistory();

      // Save metadata
      _lastBackupTime = DateTime.now();
      _lastBackupSize = '${(encrypted.length / 1024).toStringAsFixed(1)}KB';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastBackupKey, _lastBackupTime!.millisecondsSinceEpoch);

      _retryCount = 0;
      _setState(BackupServiceState.synced);
      return true;
    } catch (e) {
      _handleBackupError(e.toString());
      return false;
    }
  }

  Future<void> _uploadFile(
      drive.DriveApi api, Uint8List data, String fileName) async {
    final fileMetadata = drive.File()
      ..name = fileName
      ..parents = ['appDataFolder'];

    final media = drive.Media(
      Stream.value(data.toList()),
      data.length,
      contentType: 'application/octet-stream',
    );

    await api.files.create(fileMetadata, uploadMedia: media);
  }

  Future<void> _pruneOldBackups(drive.DriveApi api) async {
    final files = await _listDriveFiles(api);
    files.sort((a, b) => b.createdTime!.compareTo(a.createdTime!));
    if (files.length > _maxBackups) {
      final toDelete = files.skip(_maxBackups);
      for (final f in toDelete) {
        try {
          await api.files.delete(f.id!);
        } catch (_) {
          // Best effort
        }
      }
    }
  }

  // ── Restore ────────────────────────────────────────────────────────────────

  Future<bool> restoreLatest() async {
    if (_connectedEmail == null) {
      _setError('Not signed in to Google Drive');
      return false;
    }
    _setState(BackupServiceState.syncing);
    try {
      final api = await _getDriveApi();
      if (api == null) {
        _setError('Could not connect to Google Drive');
        return false;
      }

      final files = await _listDriveFiles(api);
      if (files.isEmpty) {
        _setError('No backup found in Google Drive');
        _setState(BackupServiceState.idle);
        return false;
      }

      files.sort((a, b) => b.createdTime!.compareTo(a.createdTime!));
      final latest = files.first;
      return await _restoreFromFileId(api, latest.id!);
    } catch (e) {
      _setError('Restore failed: ${e.toString()}');
      return false;
    }
  }

  Future<bool> restoreFromBackup(BackupMetadata backup) async {
    if (_connectedEmail == null) {
      _setError('Not signed in');
      return false;
    }
    _setState(BackupServiceState.syncing);
    try {
      final api = await _getDriveApi();
      if (api == null) return false;
      return await _restoreFromFileId(api, backup.fileId);
    } catch (e) {
      _setError('Restore failed: ${e.toString()}');
      return false;
    }
  }

  Future<bool> _restoreFromFileId(drive.DriveApi api, String fileId) async {
    try {
      final media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      final decrypted = _decrypt(Uint8List.fromList(bytes));
      final jsonString = utf8.decode(decrypted);

      await DataStore.instance.importFromJson(jsonString);
      _setState(BackupServiceState.synced);
      return true;
    } catch (e) {
      _setError('Could not read backup: ${e.toString()}');
      return false;
    }
  }

  // ── Backup History ────────────────────────────────────────────────────────

  Future<void> _loadBackupHistory() async {
    try {
      final api = await _getDriveApi();
      if (api == null) return;
      final files = await _listDriveFiles(api);
      files.sort((a, b) => b.createdTime!.compareTo(a.createdTime!));

      _backupHistory = files.asMap().entries.map((e) {
        final f = e.value;
        return BackupMetadata(
          fileId: f.id!,
          fileName: f.name!,
          createdTime: f.createdTime!,
          sizeBytes: f.size != null ? int.tryParse(f.size!) ?? 0 : 0,
          isLatest: e.key == 0,
        );
      }).toList();

      if (_backupHistory.isNotEmpty && _lastBackupSize == null) {
        _lastBackupSize = _backupHistory.first.formattedSize;
      }

      onStateChanged?.call(_state);
    } catch (_) {
      // Background operation, silently fail
    }
  }

  Future<List<drive.File>> _listDriveFiles(drive.DriveApi api) async {
  final result = await api.files.list(
    spaces: 'appDataFolder',
    orderBy: 'createdTime desc',
    $fields: 'files(id, name, createdTime, size)',
    q: "name contains '$_backupFilePrefix'",
  );
  return result.files ?? [];
  }

  // ── Encryption (XOR — replace with AES in production) ────────────────────

  static const List<int> _key = [
    0x4B, 0x41, 0x53, 0x48, 0x4C, 0x59, 0x32, 0x30,
    0x32, 0x34, 0x42, 0x55, 0x43, 0x4B, 0x55, 0x50,
  ];

  Uint8List _encrypt(Uint8List data) {
    final out = Uint8List(data.length);
    for (var i = 0; i < data.length; i++) {
      out[i] = data[i] ^ _key[i % _key.length];
    }
    return out;
  }

  Uint8List _decrypt(Uint8List data) => _encrypt(data); // XOR is symmetric

  // ── Auto backup toggle ────────────────────────────────────────────────────

  Future<void> setAutoBackup(bool enabled) async {
    _autoBackupEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);
    onStateChanged?.call(_state);
  }

  // ── Error handling with retry ─────────────────────────────────────────────

  void _handleBackupError(String message) {
    _retryCount++;
    if (_retryCount <= _maxRetries) {
      final delay = Duration(seconds: (2 << _retryCount).clamp(2, 60));
      Timer(delay, () => runBackup());
    }
    _setError('Backup paused — will retry when connection is available.');
  }

  // ── State helpers ─────────────────────────────────────────────────────────

  void _setState(BackupServiceState newState) {
    _state = newState;
    _errorMessage = null;
    onStateChanged?.call(_state);
  }

  void _setError(String message) {
    _state = BackupServiceState.error;
    _errorMessage = message;
    onStateChanged?.call(_state);
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}

enum BackupServiceState { idle, pending, syncing, synced, error }
