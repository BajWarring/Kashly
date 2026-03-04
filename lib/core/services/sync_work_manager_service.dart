import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../application/backup_serializer.dart';
import '../data/auth_service.dart';
import '../data/database_helper.dart';
import '../data/drive_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      return await BackgroundSyncExecutor.execute();
    } catch (e) {
      debugPrint('[WorkManager] Unhandled error in "$taskName": $e');
      return false;
    }
  });
}

// ─── Self-contained sync executor ─────────────────────────────────────────
//
// Does NOT use SyncService — that singleton lives in the foreground isolate
// and is unavailable here. All operations go directly through the underlying
// service classes, which are safe to re-initialise in any isolate.

class BackgroundSyncExecutor {
  static Future<bool> execute() async {
    // ── 1. Silent sign-in ──────────────────────────────────────────────────
    final account = await AuthService.instance.signInSilently();
    if (account == null) {
      debugPrint('[BGSync] Not authenticated — skipping sync (no retry).');
      // Return true: auth issues require user interaction, not background retries.
      return true;
    }
    debugPrint('[BGSync] Authenticated as ${account.email}');

    try {
      // ── 2. Download remote backup ────────────────────────────────────────
      final remoteJson = await DriveService.instance.downloadCurrentBackup();

      // ── 3. Validate + merge ──────────────────────────────────────────────
      if (remoteJson != null) {
        final remoteData = BackupSerializer.decode(remoteJson);

        if (remoteData == null) {
          debugPrint('[BGSync] Remote backup unparseable — uploading local only.');
        } else {
          final validation = BackupSerializer.validate(remoteData);

          if (!validation.isValid) {
            // Invalid schema → abort without retry; persist error for the UI.
            debugPrint('[BGSync] Schema validation failed: ${validation.message}');
            await _persistError('Background sync aborted — ${validation.message}');
            return true; // Don't retry; let the user decide.
          }

          await DatabaseHelper.instance.mergeRemoteData(remoteData);
          debugPrint('[BGSync] Remote merge applied successfully.');
        }
      }

      // ── 4. Upload merged local snapshot ─────────────────────────────────
      final rawData = await DatabaseHelper.instance.exportAllTables();
      final finalJson = BackupSerializer.encode(rawData);
      await DriveService.instance.uploadWithWeeklyRotation(finalJson);
      debugPrint('[BGSync] Upload complete.');

      // ── 5. Persist sync timestamp ────────────────────────────────────────
      final now = DateTime.now().millisecondsSinceEpoch;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastSyncTime', now);
      await prefs.remove(_bgErrorKey); // Clear any previous persisted error.

      debugPrint('[BGSync] Sync completed at $now.');
      return true; // ✓ Success — WorkManager marks task SUCCEEDED.

    } on SocketException catch (e) {
      // Transient network error — tell WorkManager to retry.
      debugPrint('[BGSync] Network error (will retry): $e');
      return false;

    } catch (e) {
      debugPrint('[BGSync] Unexpected error: $e');
      await _persistError(e.toString());
      return false; // Retry with exponential back-off.
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static const String _bgErrorKey = 'bg_sync_error';

  /// Stores an error string in SharedPreferences so [SyncService.initialize]
  /// can surface it in the UI on the next app launch.
  static Future<void> _persistError(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bgErrorKey, message);
  }

  /// Called by [SyncService.initialize] to check whether a background task
  /// left an error that should be shown to the user.
  static Future<String?> consumePersistedError() async {
    final prefs = await SharedPreferences.getInstance();
    final error = prefs.getString(_bgErrorKey);
    if (error != null) await prefs.remove(_bgErrorKey);
    return error;
  }
}
