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

  // Lock to prevent overlapping syncs
  bool _syncLock = false;

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

  // Called immediately after any DB write — no debounce delay
  void triggerAutoSync() {
    _updatePendingCount();
    if (!isSignedIn) return;
    performTwoWaySync();
  }

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

  Future<void> performTwoWaySync() async {
    if (_syncLock || !isSignedIn) return;
    _syncLock = true;

    status = SyncStatus.syncing;
    notifyListeners();

    try {
      // Pull latest remote and merge into local (smart merge, no wipe)
      final remoteJson = await DriveService.instance.downloadCurrentBackup();
      if (remoteJson != null) {
        final remoteData = BackupSerializer.decode(remoteJson);
        if (remoteData != null) {
          await DatabaseHelper.instance.mergeRemoteData(remoteData);
        }
      }

      // Push local data with weekly rotation
      final rawData = await DatabaseHelper.instance.exportAllTables();
      final finalJson = BackupSerializer.encode(rawData);
      await DriveService.instance.uploadWithWeeklyRotation(finalJson);

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
      notifyListeners();
      Future.delayed(const Duration(seconds: 3), () {
        if (status != SyncStatus.syncing) {
          status = SyncStatus.idle;
          notifyListeners();
        }
      });
    }
  }

  // Restore from a named Drive backup — uses smart merge (no wipe)
  Future<void> restoreFromDriveBackup(String fileName) async {
    if (!isSignedIn) return;
    status = SyncStatus.syncing;
    notifyListeners();
    try {
      final json = await DriveService.instance.downloadBackupByName(fileName);
      if (json != null) {
        final data = BackupSerializer.decode(json);
        if (data != null) {
          // Smart merge: only restores records older locally, never deletes new local data
          await DatabaseHelper.instance.mergeRemoteData(data);
        }
      }
      status = SyncStatus.success;
    } catch (e) {
      status = SyncStatus.error;
      lastAuthError = e.toString();
    } finally {
      _syncLock = false;
      notifyListeners();
    }
  }
}
