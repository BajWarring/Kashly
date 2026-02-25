import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kashly/data/datasources/local_datasource.dart';
import 'package:kashly/domain/entities/backup_settings.dart';
import 'package:kashly/domain/entities/transaction.dart';
import 'package:kashly/services/backup/backup_service.dart';

class MockLocalDatasource extends Mock implements LocalDatasource {}

void main() {
  late BackupService service;
  late MockLocalDatasource mockDs;

  setUp(() {
    mockDs = MockLocalDatasource();
    service = BackupService(
      datasource: mockDs,
      getAuthHeaders: () async => {},
    );
  });

  group('BackupService', () {
    test('incrementalBackup returns early when not signed in', () async {
      // No exception should be thrown when headers are empty
      await expectLater(service.incrementalBackup(), completes);
    });

    test('performScheduledBackup skips when auto backup disabled', () async {
      when(() => mockDs.getBackupSettings())
          .thenAnswer((_) async => const AppBackupSettings(autoBackupEnabled: false));
      await service.performScheduledBackup();
      verifyNever(() => mockDs.getNonUploadedTransactions());
    });
  });
}
