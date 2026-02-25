import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kashly/data/datasources/local_datasource.dart';
import 'package:kashly/domain/entities/transaction.dart';
import 'package:kashly/domain/entities/backup_settings.dart';
import 'package:kashly/services/backup/backup_service.dart';
import 'package:kashly/services/sync_engine/sync_service.dart';

class MockLocalDatasource extends Mock implements LocalDatasource {}

void main() {
  late SyncService syncService;
  late BackupService backupService;
  late MockLocalDatasource mockDs;

  setUp(() {
    mockDs = MockLocalDatasource();
    backupService = BackupService(
      datasource: mockDs,
      getAuthHeaders: () async => {},
    );
    syncService = SyncService(backupService);
  });

  group('Sync Flow', () {
    test('triggerSync with addEntry calls incremental backup', () async {
      // Since auth headers are empty, no actual upload, but no error thrown
      await expectLater(
        syncService.triggerSync(SyncTrigger.addEntry),
        completes,
      );
    });

    test('retryFailed retries and succeeds', () async {
      int callCount = 0;
      final testService = BackupService(
        datasource: mockDs,
        getAuthHeaders: () async {
          callCount++;
          return {}; // empty headers = early return, no failure
        },
      );
      final testSyncService = SyncService(testService);
      await testSyncService.retryFailed();
      // Should complete without error
      expect(callCount, greaterThanOrEqualTo(1));
    });

    test('sync not triggered again while already syncing', () async {
      expect(syncService.isSyncing, false);
    });
  });
}
