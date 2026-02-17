// LOGIC LAYER — thin wrapper over DataStore.

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

  /// Updates a transaction and records edit history automatically.
  static Future<Transaction> editTransaction({
    required Transaction original,
    required EntryType entryType,
    required double amount,
    required DateTime dateTime,
    required String category,
    required String paymentMethod,
    String? remarks,
  }) async {
    final changes = <FieldChange>[];

    if (original.entryType != entryType) {
      changes.add(FieldChange(
        fieldName: 'Entry Type',
        before: original.isCashIn ? 'Cash In' : 'Cash Out',
        after: entryType == EntryType.cashIn ? 'Cash In' : 'Cash Out',
      ));
    }
    if (original.amount != amount) {
      changes.add(FieldChange(
        fieldName: 'Amount',
        before: '₹${original.amount.toStringAsFixed(2)}',
        after: '₹${amount.toStringAsFixed(2)}',
      ));
    }
    if (original.dateTime != dateTime) {
      changes.add(FieldChange(
        fieldName: 'Date & Time',
        before: _fmtDateTime(original.dateTime),
        after: _fmtDateTime(dateTime),
      ));
    }
    if (original.category != category) {
      changes.add(FieldChange(
        fieldName: 'Category',
        before: original.category,
        after: category,
      ));
    }
    if (original.paymentMethod != paymentMethod) {
      changes.add(FieldChange(
        fieldName: 'Payment Method',
        before: original.paymentMethod,
        after: paymentMethod,
      ));
    }
    final oldRemarks = original.remarks ?? '';
    final newRemarks = remarks ?? '';
    if (oldRemarks != newRemarks) {
      changes.add(FieldChange(
        fieldName: 'Remarks',
        before: oldRemarks.isEmpty ? '(none)' : oldRemarks,
        after: newRemarks.isEmpty ? '(none)' : newRemarks,
      ));
    }

    // Build new edit history
    List<EditLog> newHistory = List.from(original.editHistory);
    if (changes.isNotEmpty) {
      newHistory.add(EditLog(
        id: DataStore.instance.generateId(),
        editedAt: DateTime.now(),
        changes: changes,
      ));
    }

    final updated = original.copyWith(
      entryType: entryType,
      amount: amount,
      dateTime: dateTime,
      category: category,
      paymentMethod: paymentMethod,
      remarks: remarks,
      editHistory: newHistory,
    );

    await _db.saveTransaction(updated);
    return updated;
  }

  static Future<void> updateTransaction(Transaction transaction) =>
      _db.saveTransaction(transaction);

  static Future<void> deleteTransaction(
          String transactionId, String cashbookId) =>
      _db.deleteTransaction(transactionId, cashbookId);

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _fmtDateTime(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}, $h:$min $period';
  }
}
