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
  String? _remoteFileId;

  // NEW: exposes the last auth error to the UI
  String? lastAuthError;

  Timer? _debounceTimer;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    lastSyncTime = prefs.getInt('lastSyncTime') ?? 0;
    _remoteFileId = prefs.getString('driveFileId');

    try {
      final account = await AuthService.instance.signInSilently();
      _updateAuthState(account);
      if (account != null) {
        debugPrint('[SyncService] Silent sign-in success: ${account.email}');
      } else {
        debugPrint('[SyncService] Silent sign-in returned null (no previous session).');
      }
    } catch (e) {
      // No longer silently swallowed — now visible in logs and lastAuthError
      lastAuthError = e.toString();
      debugPrint('[SyncService] Silent sign-in FAILED: $e');
      notifyListeners();
    }
  }

  Future<void> signIn() async {
    lastAuthError = null;
    try {
      debugPrint('[SyncService] Starting Google sign-in...');
      final account = await AuthService.instance.signIn();
      if (account != null) {
        debugPrint('[SyncService] Sign-in success: ${account.email}');
        _updateAuthState(account);
        await performTwoWaySync();
      } else {
        // User dismissed the picker — not an error, but should be visible
        debugPrint('[SyncService] Sign-in cancelled by user.');
        throw Exception('Sign-in was cancelled. Please try again.');
      }
    } catch (e) {
      lastAuthError = e.toString();
      debugPrint('[SyncService] Sign-in ERROR: $e');
      notifyListeners();
      rethrow; // Always re-throw so callers can show UI feedback
    }
  }

  Future<void> signOut() async {
    await AuthService.instance.signOut();
    lastAuthError = null;
    _updateAuthState(null);
  }

  void _updateAuthState(GoogleSignInAccount? account) {
    isSignedIn = account != null;
    userEmail = account?.email;
    userPhotoUrl = account?.photoUrl;
    notifyListeners();
  }

  void triggerAutoSync() {
    if (!isSignedIn) return;

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 20), () {
      performTwoWaySync();
    });
  }

  Future<void> performTwoWaySync() async {
    if (isSyncing || !isSignedIn) return;

    status = SyncStatus.syncing;
    notifyListeners();

    try {
      if (_remoteFileId == null) {
        _remoteFileId = await DriveService.instance.getRemoteFileId();
        final prefs = await SharedPreferences.getInstance();
        if (_remoteFileId != null) {
          await prefs.setString('driveFileId', _remoteFileId!);
        }
      }

      if (_remoteFileId != null) {
        final remoteJson = await DriveService.instance.downloadFile(_remoteFileId!);
        if (remoteJson != null) {
          final remoteData = BackupSerializer.decode(remoteJson);
          if (remoteData != null) {
            await DatabaseHelper.instance.mergeRemoteData(remoteData);
          }
        }
      }

      final rawData = await DatabaseHelper.instance.exportAllTables();
      final finalJson = BackupSerializer.encode(rawData);
      await DriveService.instance.uploadFile(finalJson, existingFileId: _remoteFileId);

      lastSyncTime = DateTime.now().millisecondsSinceEpoch;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastSyncTime', lastSyncTime);

      status = SyncStatus.success;
      debugPrint('[SyncService] Two-way sync completed successfully.');
    } catch (e) {
      status = SyncStatus.error;
      lastAuthError = e.toString();
      debugPrint('[SyncService] Sync FAILED: $e');
    } finally {
      notifyListeners();
      Future.delayed(const Duration(seconds: 3), () {
        status = SyncStatus.idle;
        notifyListeners();
      });
    }
  }
}
