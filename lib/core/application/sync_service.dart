import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/auth_service.dart';
import '../data/drive_service.dart';
import '../data/database_helper.dart';
import '../services/sync_scheduler.dart';
import '../services/sync_work_manager_service.dart';
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

  /// Hard lock: prevents two foreground sync operations running in parallel.
  bool _syncLock = false;

  /// True while applying a remote merge so that DB writes made during the
  /// merge do NOT re-trigger another sync (prevents infinite loops).
  bool _isMerging = false;

  /// Debounce timer: foreground sync fires 30 s after the LAST local write
  /// rather than on every individual write (avoids redundant API calls while
  /// the user is actively entering data).
  Timer? _debounceTimer;

  // ── Public API ─────────────────────────────────────────────────────────────

  void clearError() {
    lastAuthError = null;
    notifyListeners();
  }

  /// Called once at app launch (e.g. from [BackupManagerScreen.initState]).
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    lastSyncTime = prefs.getInt('lastSyncTime') ?? 0;

    // Surface any error persisted by a WorkManager background task so the
    // UI can inform the user on the next app open.
    final bgError = await BackgroundSyncExecutor.consumePersistedError();
    if (bgError != null) {
      lastAuthError = 'Background sync error: $bgError';
    }

    try {
      final account = await AuthService.instance.signInSilently();
      _updateAuthState(account);
      if (account != null) {
        debugPrint('[SyncService] Silent sign-in: ${account.email}');
        // Re-register the periodic task on every launch so it survives
        // device reboots and task cancellations (ExistingWorkPolicy.keep
        // makes this a no-op if already scheduled).
        await SyncScheduler.schedulePeriodic();
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
        // Activate background sync as soon as the user signs in.
        await SyncScheduler.schedulePeriodic();
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
    // Stop all background tasks — they would fail without valid credentials.
    await SyncScheduler.cancelAll();
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

  // ── Auto-sync: debounced foreground + immediate background ─────────────────
  //
  // Called immediately after every DB write. Two things happen:
  //
  //   1. A WorkManager one-time task is registered right now.
  //      If the user closes the app before the 30 s timer fires, WorkManager
  //      will still run the sync in the background (even after a reboot).
  //
  //   2. A 30 s debounce timer resets on each call. A burst of writes
  //      (e.g. bulk entry creation) produces only ONE foreground sync
  //      rather than one per write.
  //
  // When the foreground sync succeeds it cancels the WorkManager one-time
  // task so the background job doesn't duplicate the upload.
  //
  // [_isMerging] prevents DB writes caused by applying a remote merge from
  // triggering a new sync — breaking the infinite loop.

  void triggerAutoSync() {
    if (_isMerging) return;

    _updatePendingCount();
    if (!isSignedIn) return;

    // ── Immediate WorkManager safety net ─────────────────────────────────────
    SyncScheduler.scheduleOneTime();

    // ── 30-second foreground debounce ────────────────────────────────────────
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(seconds: 30),
      () {
        debugPrint('[SyncService] Debounce elapsed — triggering foreground sync.');
        performTwoWaySync();
      },
    );
    debugPrint('[SyncService] Auto-sync: BG task queued; debounce reset (30 s).');
  }

  // ── Core two-way sync ──────────────────────────────────────────────────────

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

  /// Foreground two-way sync: pull remote → validate → merge → push.
  ///
  /// On success, cancels the pending WorkManager one-time task to prevent a
  /// redundant background upload moments later.
  Future<void> performTwoWaySync() async {
    if (_syncLock || !isSignedIn) return;
    _syncLock = true;
    _debounceTimer?.cancel();

    status = SyncStatus.syncing;
    notifyListeners();

    try {
      // 1. Download.
      final remoteJson = await DriveService.instance.downloadCurrentBackup();

      if (remoteJson != null) {
        // 2. Decode.
        final remoteData = BackupSerializer.decode(remoteJson);

        if (remoteData == null) {
          debugPrint('[SyncService] Remote backup unparseable — skipping merge.');
        } else {
          // 3. Validate.
          final validation = BackupSerializer.validate(remoteData);
          if (!validation.isValid) {
            debugPrint('[SyncService] Remote backup invalid: ${validation.message}');
            // Skip merge but still push local data below.
          } else {
            // 4. Merge — silence re-triggers during merge writes.
            _isMerging = true;
            try {
              await DatabaseHelper.instance.mergeRemoteData(remoteData);
              debugPrint('[SyncService] Remote merge applied.');
            } finally {
              _isMerging = false;
            }
          }
        }
      }

      // 5. Push updated local snapshot.
      final rawData = await DatabaseHelper.instance.exportAllTables();
      final finalJson = BackupSerializer.encode(rawData);
      await DriveService.instance.uploadWithWeeklyRotation(finalJson);

      // 6. Persist sync timestamp.
      lastSyncTime = DateTime.now().millisecondsSinceEpoch;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastSyncTime', lastSyncTime);

      // 7. Cancel the background one-time task — foreground beat it to it.
      await SyncScheduler.cancelOneTime();

      pendingChangesCount = 0;
      await _refreshDriveInfo();

      status = SyncStatus.success;
      debugPrint('[SyncService] Foreground sync completed successfully.');
    } catch (e) {
      status = SyncStatus.error;
      lastAuthError = e.toString();
      debugPrint('[SyncService] Foreground sync FAILED: $e');
      await _updatePendingCount();
      // The WorkManager one-time task stays queued and will retry in background.
    } finally {
      _syncLock = false;
      _isMerging = false; // Safety reset.
      notifyListeners();

      Future.delayed(const Duration(seconds: 3), () {
        if (status != SyncStatus.syncing) {
          status = SyncStatus.idle;
          notifyListeners();
        }
      });
    }
  }

  // ── Drive restore ──────────────────────────────────────────────────────────

  /// Restores from a named Drive backup using smart merge.
  ///
  /// Flow: download → validate → safety snapshot → merge.
  Future<void> restoreFromDriveBackup(String fileName) async {
    if (!isSignedIn) return;
    status = SyncStatus.syncing;
    notifyListeners();

    try {
      final json = await DriveService.instance.downloadBackupByName(fileName);
      if (json == null) {
        throw Exception('Could not download "$fileName" from Drive.');
      }

      final data = BackupSerializer.decode(json);
      if (data == null) {
        throw Exception(
            'Backup file "$fileName" could not be parsed — may be corrupted.');
      }

      final validation = BackupSerializer.validate(data);
      if (!validation.isValid) {
        throw Exception('Backup validation failed:\n${validation.message}');
      }

      await DatabaseHelper.instance.createSafetyBackup();

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
