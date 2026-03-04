import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/auth_service.dart';
import '../data/drive_service.dart';
import '../data/database_helper.dart';
import 'backup_serializer.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncService extends ChangeNotifier {
  static final SyncService instance = SyncService._init();
  SyncService._init();

  SyncStatus status = SyncStatus.idle;
  bool get isSyncing => status == SyncStatus.syncing;

  bool isSignedIn = false;
  String? userEmail;
  String? userPhotoUrl;
  int lastSyncTime = 0;
  String? lastAuthError;

  // Drive storage info for UI
  String driveStorageUsed = '—';
  String driveStorageTotal = '—';
  double driveStorageFraction = 0.0;
  List<Map<String, String>> driveBackupFiles = [];

  // Pending unsynced changes count
  int pendingChangesCount = 0;

  // ── Internal guards ────────────────────────────────────────────────────────

  /// Hard lock: prevents two sync operations running at the same time.
  bool _syncLock = false;

  /// Set to true while applying a remote merge so that DB writes made during
  /// the merge do NOT re-trigger another sync (avoids infinite loop).
  bool _isMerging = false;

  /// Debounce timer: sync is only dispatched 30 seconds after the LAST local
  /// write, not on every individual write (avoids API spam).
  Timer? _debounceTimer;

  // ── Public API ─────────────────────────────────────────────────────────────

  void clearError() {
    lastAuthError = null;
    notifyListeners();
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    lastSyncTime = prefs.getInt('lastSyncTime') ?? 0;

    try {
      final account = await AuthService.instance.signInSilently();
      _updateAuthState(account);
      if (account != null) {
        debugPrint('[SyncService] Silent sign-in: ${account.email}');
        await _refreshDriveInfo();
      }
    } catch (e) {
      lastAuthError = e.toString();
      debugPrint('[SyncService] Silent sign-in FAILED: $e');
      notifyListeners();
    }
    await _updatePendingCount();
  }

  Future<void> signIn() async {
    lastAuthError = null;
    try {
      final account = await AuthService.instance.signIn();
      if (account != null) {
        _updateAuthState(account);
        await performTwoWaySync();
      } else {
        throw Exception('Sign-in was cancelled. Please try again.');
      }
    } catch (e) {
      lastAuthError = e.toString();
      debugPrint('[SyncService] Sign-in ERROR: $e');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    _debounceTimer?.cancel();
    await AuthService.instance.signOut();
    lastAuthError = null;
    driveStorageUsed = '—';
    driveStorageTotal = '—';
    driveStorageFraction = 0.0;
    driveBackupFiles = [];
    pendingChangesCount = 0;
    _updateAuthState(null);
  }

  void _updateAuthState(GoogleSignInAccount? account) {
    isSignedIn = account != null;
    userEmail = account?.email;
    userPhotoUrl = account?.photoUrl;
    notifyListeners();
  }

  // ── Debounced auto-sync ────────────────────────────────────────────────────

  /// Called immediately after any DB write.
  ///
  /// • Updates the pending-changes badge right away (no delay).
  /// • Schedules a sync 30 seconds after the LAST local change so that rapid
  ///   edits (e.g. bulk entry creation) produce only ONE sync call instead of
  ///   one per write, preventing Drive API spam and race conditions.
  /// • Does nothing when [_isMerging] is true to prevent sync loops caused by
  ///   the writes that happen while applying a remote merge.
  void triggerAutoSync() {
    // Never count merge writes as "pending local changes".
    if (_isMerging) return;

    _updatePendingCount();
    if (!isSignedIn) return;

    // Cancel any previously scheduled debounced sync and restart the timer.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(seconds: 30),
      () {
        debugPrint('[SyncService] Debounce elapsed — triggering auto-sync.');
        performTwoWaySync();
      },
    );
    debugPrint('[SyncService] Auto-sync debounced (30 s).');
  }

  // ── Core sync ──────────────────────────────────────────────────────────────

  Future<void> _updatePendingCount() async {
    pendingChangesCount =
        await DatabaseHelper.instance.getPendingChangesCount(lastSyncTime);
    notifyListeners();
  }

  Future<void> _refreshDriveInfo() async {
    if (!isSignedIn) return;
    try {
      final info = await DriveService.instance.getDriveStorageInfo();
      driveStorageUsed = info['used'] ?? '—';
      driveStorageTotal = info['total'] ?? '—';
      driveStorageFraction = (info['fraction'] as double?) ?? 0.0;
      driveBackupFiles = await DriveService.instance.listBackupFiles();
      notifyListeners();
    } catch (e) {
      debugPrint('[SyncService] Drive info refresh failed: $e');
    }
  }

  /// Two-way sync: pull remote → smart-merge → push updated local copy.
  ///
  /// Guards:
  ///   • [_syncLock] prevents overlapping sync calls.
  ///   • [_isMerging] silences DB-write triggers while applying remote data.
  Future<void> performTwoWaySync() async {
    if (_syncLock || !isSignedIn) return;
    _syncLock = true;
    _debounceTimer?.cancel(); // No need for the debounce timer any more.

    status = SyncStatus.syncing;
    notifyListeners();

    try {
      // 1. Download the current remote backup.
      final remoteJson = await DriveService.instance.downloadCurrentBackup();

      if (remoteJson != null) {
        // 2. Decode.
        final remoteData = BackupSerializer.decode(remoteJson);

        if (remoteData == null) {
          debugPrint('[SyncService] Remote backup could not be decoded — skipping merge.');
        } else {
          // 3. Validate before touching local data.
          final validation = BackupSerializer.validate(remoteData);
          if (!validation.isValid) {
            debugPrint('[SyncService] Remote backup failed validation: ${validation.message}');
            // Don't throw — just skip the merge and upload our local copy.
          } else {
            // 4. Merge-safe: suppress re-trigger during merge writes.
            _isMerging = true;
            try {
              await DatabaseHelper.instance.mergeRemoteData(remoteData);
              debugPrint('[SyncService] Remote merge applied successfully.');
            } finally {
              _isMerging = false;
            }
          }
        }
      }

      // 5. Push local data with weekly rotation.
      final rawData = await DatabaseHelper.instance.exportAllTables();
      final finalJson = BackupSerializer.encode(rawData);
      await DriveService.instance.uploadWithWeeklyRotation(finalJson);

      // 6. Persist sync timestamp.
      lastSyncTime = DateTime.now().millisecondsSinceEpoch;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastSyncTime', lastSyncTime);

      pendingChangesCount = 0;
      await _refreshDriveInfo();

      status = SyncStatus.success;
      debugPrint('[SyncService] Two-way sync completed successfully.');
    } catch (e) {
      status = SyncStatus.error;
      lastAuthError = e.toString();
      debugPrint('[SyncService] Sync FAILED: $e');
      await _updatePendingCount();
    } finally {
      _syncLock = false;
      _isMerging = false; // Safety reset.
      notifyListeners();

      // Auto-revert status indicator to idle after 3 seconds.
      Future.delayed(const Duration(seconds: 3), () {
        if (status != SyncStatus.syncing) {
          status = SyncStatus.idle;
          notifyListeners();
        }
      });
    }
  }

  // ── Drive restore ──────────────────────────────────────────────────────────

  /// Restores from a named Drive backup using smart merge (never overwrites
  /// newer local data).
  ///
  /// Steps:
  ///   1. Download the requested backup file.
  ///   2. Validate its structure and schema version.
  ///   3. Create a local safety backup of current data before applying.
  ///   4. Apply merge (Last-Write-Wins — newer record always wins).
  Future<void> restoreFromDriveBackup(String fileName) async {
    if (!isSignedIn) return;
    status = SyncStatus.syncing;
    notifyListeners();

    try {
      // 1. Download.
      final json = await DriveService.instance.downloadBackupByName(fileName);
      if (json == null) {
        throw Exception('Could not download "$fileName" from Drive.');
      }

      // 2. Decode + validate.
      final data = BackupSerializer.decode(json);
      if (data == null) {
        throw Exception(
          'The backup file "$fileName" could not be parsed. '
          'It may be corrupted.',
        );
      }

      final validation = BackupSerializer.validate(data);
      if (!validation.isValid) {
        throw Exception('Backup validation failed: ${validation.message}');
      }

      // 3. Safety snapshot of current local data before applying.
      await DatabaseHelper.instance.createSafetyBackup();

      // 4. Merge (suppress sync loop).
      _isMerging = true;
      try {
        await DatabaseHelper.instance.mergeRemoteData(data);
      } finally {
        _isMerging = false;
      }

      status = SyncStatus.success;
      debugPrint('[SyncService] Drive restore from "$fileName" completed.');
    } catch (e) {
      status = SyncStatus.error;
      lastAuthError = e.toString();
      debugPrint('[SyncService] Drive restore FAILED: $e');
    } finally {
      _syncLock = false;
      _isMerging = false;
      notifyListeners();
    }
  }
}
