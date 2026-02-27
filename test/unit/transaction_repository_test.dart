import 'package:flutter_test/flutter_test.dart';
import 'package:kashly/domain/entities/transaction.dart';
import 'package:kashly/domain/repositories/transaction_repository.dart';

// Removed unused import:
// - package:kashly/domain/entities/transaction_history.dart

void main() {
  group('Transaction Entity Tests', () {
    test('Transaction copyWith preserves unchanged fields', () {
      final now = DateTime(2024, 6, 1);
      final tx = Transaction(
        id: 'tx-1',
        cashbookId: 'cb-1',
        amount: 100.0,
        type: TransactionType.cashIn,
        category: 'Salary',
        remark: 'Monthly salary',
        method: 'Bank Transfer',
        date: now,
        createdAt: now,
        updatedAt: now,
        syncStatus: TransactionSyncStatus.pending,
        driveMeta: const DriveMeta(),
      );

      final updated = tx.copyWith(amount: 200.0);
      expect(updated.id, equals('tx-1'));
      expect(updated.amount, equals(200.0));
      expect(updated.category, equals('Salary'));
    });

    test('DriveMeta defaults are correct', () {
      const meta = DriveMeta();
      expect(meta.isUploaded, isFalse);
      expect(meta.isModifiedSinceUpload, isFalse);
      expect(meta.fileId, isNull);
    });

    test('Transaction toJson / fromJson round-trips correctly', () {
      final now = DateTime(2024, 6, 1, 12, 0, 0);
      final tx = Transaction(
        id: 'tx-round',
        cashbookId: 'cb-round',
        amount: 42.5,
        type: TransactionType.cashOut,
        category: 'Food & Dining',
        remark: 'Lunch',
        method: 'Cash',
        date: now,
        createdAt: now,
        updatedAt: now,
        syncStatus: TransactionSyncStatus.synced,
        driveMeta: const DriveMeta(),
      );

      final json = tx.toJson();
      final restored = Transaction.fromJson(json);
      expect(restored.id, equals(tx.id));
      expect(restored.amount, equals(tx.amount));
      expect(restored.type, equals(tx.type));
    });

    test('TransactionSyncStatus enum has expected values', () {
      expect(TransactionSyncStatus.values, containsAll([
        TransactionSyncStatus.synced,
        TransactionSyncStatus.pending,
        TransactionSyncStatus.error,
        TransactionSyncStatus.conflict,
      ]));
    });
  });
}
