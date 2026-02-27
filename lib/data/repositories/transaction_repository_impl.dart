import 'package:kashly/domain/repositories/transaction_repository.dart';
import 'package:kashly/data/datasources/local_datasource.dart';
import 'package:kashly/domain/entities/transaction.dart';
import 'package:kashly/domain/entities/transaction_history.dart';
import 'package:kashly/core/error/exceptions.dart';
import 'package:kashly/core/utils/utils.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final LocalDatasource localDatasource;

  TransactionRepositoryImpl(this.localDatasource);

  @override
  Future<void> createTransaction(Transaction transaction) async {
    try {
      await localDatasource.insertTransaction(transaction);
    } catch (e) {
      throw CacheException('Failed to create transaction: $e');
    }
  }

  @override
  Future<List<Transaction>> getTransactions(String cashbookId,
      {int? limit, int? offset}) async {
    try {
      return await localDatasource.getTransactions(cashbookId,
          limit: limit, offset: offset);
    } catch (e) {
      throw CacheException('Failed to get transactions: $e');
    }
  }

  @override
  Future<Transaction?> getTransactionById(String id) async {
    try {
      return await localDatasource.getTransactionById(id);
    } catch (e) {
      throw CacheException('Failed to get transaction: $e');
    }
  }

  @override
  Future<void> updateTransaction(Transaction transaction,
      String changedBy) async {
    try {
      final old =
          await localDatasource.getTransactionById(transaction.id);
      if (old != null) {
        await _trackChanges(old, transaction, changedBy);
      }
      await localDatasource.updateTransaction(
        transaction.copyWith(
          updatedAt: DateTime.now(),
          driveMeta: transaction.driveMeta.copyWith(
              isModifiedSinceUpload:
                  transaction.driveMeta.isUploaded),
          syncStatus: TransactionSyncStatus.pending,
        ),
      );
    } catch (e) {
      throw CacheException('Failed to update transaction: $e');
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await localDatasource.deleteTransaction(id);
    } catch (e) {
      throw CacheException('Failed to delete transaction: $e');
    }
  }

  @override
  Future<List<Transaction>> getNonUploadedTransactions() async {
    try {
      return await localDatasource.getNonUploadedTransactions();
    } catch (e) {
      throw CacheException('Failed to get non-uploaded: $e');
    }
  }

  @override
  Future<List<Transaction>> getModifiedSinceUploadTransactions() async {
    try {
      return await localDatasource.getModifiedTransactions();
    } catch (e) {
      throw CacheException('Failed to get modified: $e');
    }
  }

  @override
  Future<void> markAsUploaded(
    String id,
    String fileId,
    String fileName,
    String checksum,
  ) async {
    try {
      final tx = await localDatasource.getTransactionById(id);
      if (tx == null) throw const CacheException('Transaction not found');
      await localDatasource.updateTransaction(
        tx.copyWith(
          syncStatus: TransactionSyncStatus.synced,
          driveMeta: tx.driveMeta.copyWith(
            fileId: fileId,
            driveFileName: fileName,
            md5Checksum: checksum,
            isUploaded: true,
            isModifiedSinceUpload: false,
            lastSyncedAt: DateTime.now(),
          ),
        ),
      );
    } catch (e) {
      throw CacheException('Failed to mark as uploaded: $e');
    }
  }

  @override
  Future<void> markAsModified(String id) async {
    try {
      final tx = await localDatasource.getTransactionById(id);
      if (tx == null) throw const CacheException('Transaction not found');
      await localDatasource.updateTransaction(
        tx.copyWith(
          driveMeta: tx.driveMeta.copyWith(isModifiedSinceUpload: true),
          syncStatus: TransactionSyncStatus.pending,
        ),
      );
    } catch (e) {
      throw CacheException('Failed to mark as modified: $e');
    }
  }

  @override
  Future<List<TransactionHistory>> getHistory(
      String transactionId) async {
    try {
      return await localDatasource.getHistory(transactionId);
    } catch (e) {
      throw CacheException('Failed to get history: $e');
    }
  }

  @override
  Future<List<Transaction>> searchTransactions(
      String cashbookId, String query) async {
    try {
      return await localDatasource.searchTransactions(
          cashbookId, query);
    } catch (e) {
      throw CacheException('Failed to search: $e');
    }
  }

  @override
  Future<List<Transaction>> getTransactionsByDateRange(
    String cashbookId,
    DateTime from,
    DateTime to,
  ) async {
    try {
      return await localDatasource.getTransactionsByDateRange(
          cashbookId, from, to);
    } catch (e) {
      throw CacheException('Failed to get by date range: $e');
    }
  }

  @override
  Future<void> reconcileTransaction(String id, bool reconciled) async {
    try {
      final tx = await localDatasource.getTransactionById(id);
      if (tx == null) throw const CacheException('Transaction not found');
      await localDatasource
          .updateTransaction(tx.copyWith(isReconciled: reconciled));
    } catch (e) {
      throw CacheException('Failed to reconcile: $e');
    }
  }

  @override
  Future<List<Transaction>> getPendingConflicts() async {
    try {
      return await localDatasource.getConflictTransactions();
    } catch (e) {
      throw CacheException('Failed to get conflicts: $e');
    }
  }

  @override
  Future<void> resolveConflict(String id, String resolution) async {
    try {
      final tx = await localDatasource.getTransactionById(id);
      if (tx == null) throw const CacheException('Transaction not found');
      await localDatasource.updateTransaction(
        tx.copyWith(syncStatus: TransactionSyncStatus.synced),
      );
    } catch (e) {
      throw CacheException('Failed to resolve conflict: $e');
    }
  }

  Future<void> _trackChanges(
    Transaction old,
    Transaction updated,
    String changedBy,
  ) async {
    final fields = <String, List<String>>{
      'amount': [
        old.amount.toString(),
        updated.amount.toString()
      ],
      'type': [old.type.name, updated.type.name],
      'category': [old.category, updated.category],
      'remark': [old.remark, updated.remark],
      'method': [old.method, updated.method],
      'date': [
        old.date.toIso8601String(),
        updated.date.toIso8601String()
      ],
    };

    for (final entry in fields.entries) {
      if (entry.value[0] != entry.value[1]) {
        await localDatasource.insertHistory(TransactionHistory(
          id: generateUuid(),
          transactionId: old.id,
          fieldName: entry.key,
          oldValue: entry.value[0],
          newValue: entry.value[1],
          changedBy: changedBy,
          changedAt: DateTime.now(),
        ));
      }
    }
  }
}
