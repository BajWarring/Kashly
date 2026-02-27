import 'package:flutter_test/flutter_test.dart';
import 'package:kashly/services/backup/backup_service.dart';
import 'package:kashly/domain/entities/backup_record.dart';

// Removed unused import:
// - package:kashly/domain/entities/transaction.dart

void main() {
  group('BackupService Tests', () {
    test('BackupRecord status enum has expected values', () {
      expect(BackupStatus.values, containsAll([
        BackupStatus.success,
        BackupStatus.failed,
        BackupStatus.partial,
      ]));
    });

    test('BackupType enum has expected values', () {
      expect(BackupType.values, containsAll([
        BackupType.local,
        BackupType.googleDrive,
      ]));
    });

    test('BackupRecord copyWith preserves unchanged fields', () {
      final record = BackupRecord(
        id: 'test-id',
        type: BackupType.local,
        cashbookIds: ['cb1'],
        transactionCount: 5,
        fileName: 'test.json',
        fileSizeBytes: 1024,
        createdAt: DateTime(2024, 1, 1),
        status: BackupStatus.success,
      );

      final updated = record.copyWith(transactionCount: 10);
      expect(updated.id, equals('test-id'));
      expect(updated.transactionCount, equals(10));
      expect(updated.fileName, equals('test.json'));
    });
  });
}
