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
  String? userPhotoUrl; // NEW: Added to store the Google Profile Picture
  int lastSyncTime = 0;
  String? _remoteFileId;

  Timer? _debounceTimer;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    lastSyncTime = prefs.getInt('lastSyncTime') ?? 0;
    _remoteFileId = prefs.getString('driveFileId');
    
    final account = await AuthService.instance.signInSilently();
    _updateAuthState(account);
  }

  Future<void> signIn() async {
    final account = await AuthService.instance.signIn();
    _updateAuthState(account);
    if (isSignedIn) await performTwoWaySync();
  }

  Future<void> signOut() async {
    await AuthService.instance.signOut();
    _updateAuthState(null);
  }

  void _updateAuthState(GoogleSignInAccount? account) {
    isSignedIn = account != null;
    userEmail = account?.email;
    userPhotoUrl = account?.photoUrl; // Captures the profile picture
    notifyListeners(); // This instantly triggers UI rebuilds
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
        if (_remoteFileId != null) await prefs.setString('driveFileId', _remoteFileId!);
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
    } catch (e) {
      status = SyncStatus.error;
    } finally {
      notifyListeners();
      Future.delayed(const Duration(seconds: 3), () {
        status = SyncStatus.idle;
        notifyListeners();
      });
    }
  }
}
