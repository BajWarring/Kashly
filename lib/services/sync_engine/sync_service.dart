import 'dart:math';
import 'package:logger/logger.dart';
import 'package:kashly/services/backup/backup_service.dart';
import 'package:kashly/core/error/exceptions.dart';

enum SyncTrigger {
  addEntry,
  editEntry,
  deleteEntry,
  cashbookUpdate,
  attachmentUpload,
  manual,
}

class SyncService {
  final BackupService _backupService;
  final _logger = Logger();
  bool _isSyncing = false;

  SyncService(this._backupService);

  Future<void> triggerSync(SyncTrigger trigger) async {
    if (_isSyncing) {
      _logger.d('Sync already in progress, skipping trigger: ${trigger.name}');
      return;
    }

    _logger.i('Sync triggered by: ${trigger.name}');
    _isSyncing = true;

    try {
      switch (trigger) {
        case SyncTrigger.addEntry:
        case SyncTrigger.editEntry:
        case SyncTrigger.attachmentUpload:
          await _backupService.incrementalBackup();
          break;
        case SyncTrigger.deleteEntry:
          // Handle delete sync
          await _backupService.incrementalBackup();
          break;
        case SyncTrigger.cashbookUpdate:
          await _backupService.incrementalBackup();
          break;
        case SyncTrigger.manual:
          await _backupService.incrementalBackup();
          break;
      }
    } catch (e) {
      _logger.e('Sync failed for trigger ${trigger.name}: $e');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> detectConflicts() async {
    _logger.i('Detecting conflicts');
    // Compare local checksums with drive metadata
    // Mark conflicted transactions
  }

  Future<void> retryFailed() async {
    _logger.i('Retrying failed sync operations');
    int retries = 0;
    const maxRetries = 5;

    while (retries < maxRetries) {
      try {
        await _backupService.incrementalBackup();
        _logger.i('Retry succeeded on attempt ${retries + 1}');
        break;
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          _logger.e('Max retries ($maxRetries) exceeded');
          throw SyncException('Sync failed after $maxRetries retries: $e');
        }
        final delay = Duration(seconds: pow(2, retries).toInt());
        _logger.w('Retry $retries failed, waiting ${delay.inSeconds}s');
        await Future.delayed(delay);
      }
    }
  }

  Future<void> forceResync() async {
    _logger.i('Force resync triggered');
    // Reset all sync status to pending and re-upload
    await triggerSync(SyncTrigger.manual);
  }

  bool get isSyncing => _isSyncing;
}
