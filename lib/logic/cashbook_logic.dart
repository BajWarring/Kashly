// LOGIC LAYER — thin wrapper over DataStore.
// All dummy/sample data removed. Everything is real and persisted.

import '../models/cashbook.dart';
import '../models/transaction.dart';
import 'data_store.dart';

class CashbookLogic {
  static DataStore get _db => DataStore.instance;

  // ── CashBooks ────────────────────────────────────────────────────────────

  static List<CashBook> getCashbooks() => _db.getCashbooks();

  static Future<CashBook> addCashbook(String name) async {
    final cb = CashBook(id: _db.generateId(), name: name);
    await _db.saveCashbook(cb);
    return cb;
  }

  static Future<void> deleteCashbook(String cashbookId) =>
      _db.deleteCashbook(cashbookId);

  static Future<void> updateCashbookOptions({
    required String cashbookId,
    List<String>? customCategories,
    List<String>? customPaymentMethods,
  }) async {
    final list = _db.getCashbooks();
    final idx = list.indexWhere((c) => c.id == cashbookId);
    if (idx < 0) return;
    final updated = list[idx].copyWith(
      customCategories: customCategories,
      customPaymentMethods: customPaymentMethods,
    );
    await _db.saveCashbook(updated);
  }

  // ── Transactions ─────────────────────────────────────────────────────────

  static List<Transaction> getTransactions(String cashbookId) =>
      _db.getTransactions(cashbookId: cashbookId);

  static Future<Transaction> addTransaction({
    required String cashbookId,
    required EntryType entryType,
    required double amount,
    required DateTime dateTime,
    required String category,
    required String paymentMethod,
    String? remarks,
  }) async {
    final tx = Transaction(
      id: _db.generateId(),
      cashbookId: cashbookId,
      entryType: entryType,
      amount: amount,
      dateTime: dateTime,
      category: category,
      paymentMethod: paymentMethod,
      remarks: remarks,
    );
    await _db.saveTransaction(tx);
    return tx;
  }

  static Future<void> updateTransaction(Transaction transaction) =>
      _db.saveTransaction(transaction);

  static Future<void> deleteTransaction(
          String transactionId, String cashbookId) =>
      _db.deleteTransaction(transactionId, cashbookId);
}
