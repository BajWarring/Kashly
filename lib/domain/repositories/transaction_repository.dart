import 'package:kashly/domain/entities/transaction.dart';
import 'package:kashly/domain/entities/transaction_history.dart';

abstract class TransactionRepository {
  Future<void> createTransaction(Transaction transaction);
  Future<List<Transaction>> getTransactions(String cashbookId, {int? limit, int? offset});
  Future<Transaction?> getTransactionById(String id);
  Future<void> updateTransaction(Transaction transaction, String changedBy);
  Future<void> deleteTransaction(String id);
  Future<List<Transaction>> getNonUploadedTransactions();
  Future<List<Transaction>> getModifiedSinceUploadTransactions();
  Future<void> markAsUploaded(String id, String fileId, String fileName, String checksum);
  Future<void> markAsModified(String id);
  Future<List<TransactionHistory>> getHistory(String transactionId);
  Future<List<Transaction>> searchTransactions(String cashbookId, String query);
  Future<List<Transaction>> getTransactionsByDateRange(String cashbookId, DateTime from, DateTime to);
  Future<void> reconcileTransaction(String id, bool reconciled);
  Future<List<Transaction>> getPendingConflicts();
  Future<void> resolveConflict(String id, String resolution);
}
