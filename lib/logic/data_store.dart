// DATA STORE — real persistence using shared_preferences.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cashbook.dart';
import '../models/transaction.dart';

class DataStore {
  static const _cashbooksKey = 'cashbooks';
  static const _transactionsKey = 'transactions';

  static DataStore? _instance;
  static DataStore get instance => _instance ??= DataStore._();
  DataStore._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'DataStore.init() must be called before use');
    return _prefs!;
  }

  // ── CashBooks ────────────────────────────────────────────────────────────

  List<CashBook> getCashbooks() {
    final raw = _p.getString(_cashbooksKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => CashBook.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveCashbook(CashBook cashbook) async {
    final list = getCashbooks();
    final idx = list.indexWhere((c) => c.id == cashbook.id);
    if (idx >= 0) {
      list[idx] = cashbook;
    } else {
      list.add(cashbook);
    }
    await _p.setString(_cashbooksKey, jsonEncode(list.map((c) => c.toJson()).toList()));
  }

  Future<void> deleteCashbook(String cashbookId) async {
    final list = getCashbooks()..removeWhere((c) => c.id == cashbookId);
    await _p.setString(_cashbooksKey, jsonEncode(list.map((c) => c.toJson()).toList()));
    final txList = getTransactions(cashbookId: cashbookId);
    for (final tx in txList) {
      await deleteTransaction(tx.id, cashbookId);
    }
  }

  // ── Transactions ─────────────────────────────────────────────────────────

  List<Transaction> getTransactions({String? cashbookId}) {
    final raw = _p.getString(_transactionsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    final all = list.map((e) => Transaction.fromJson(e as Map<String, dynamic>)).toList();
    if (cashbookId == null) return all;
    return all.where((t) => t.cashbookId == cashbookId).toList();
  }

  Future<void> saveTransaction(Transaction transaction) async {
    final all = getTransactions();
    final idx = all.indexWhere((t) => t.id == transaction.id);
    if (idx >= 0) {
      all[idx] = transaction;
    } else {
      all.add(transaction);
    }
    await _p.setString(_transactionsKey, jsonEncode(all.map((t) => t.toJson()).toList()));
    await _recalcCashbook(transaction.cashbookId);
  }

  Future<void> deleteTransaction(String transactionId, String cashbookId) async {
    final all = getTransactions()..removeWhere((t) => t.id == transactionId);
    await _p.setString(_transactionsKey, jsonEncode(all.map((t) => t.toJson()).toList()));
    await _recalcCashbook(cashbookId);
  }

  // Export all data as JSON string (for backup)
  String exportAllDataAsJson() {
    final cashbooks = getCashbooks();
    final transactions = getTransactions();
    return jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'cashbooks': cashbooks.map((c) => c.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
    });
  }

  // Import data from JSON string (for restore)
  Future<void> importFromJson(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final cashbooksJson = data['cashbooks'] as List;
    final transactionsJson = data['transactions'] as List;

    final cashbooks = cashbooksJson
        .map((e) => CashBook.fromJson(e as Map<String, dynamic>))
        .toList();
    final transactions = transactionsJson
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList();

    await _p.setString(_cashbooksKey, jsonEncode(cashbooks.map((c) => c.toJson()).toList()));
    await _p.setString(_transactionsKey, jsonEncode(transactions.map((t) => t.toJson()).toList()));
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<void> _recalcCashbook(String cashbookId) async {
    final txList = getTransactions(cashbookId: cashbookId);
    double totalIn = 0;
    double totalOut = 0;
    for (final tx in txList) {
      if (tx.isCashIn) {
        totalIn += tx.amount;
      } else {
        totalOut += tx.amount;
      }
    }
    final cashbooks = getCashbooks();
    final idx = cashbooks.indexWhere((c) => c.id == cashbookId);
    if (idx >= 0) {
      cashbooks[idx] = cashbooks[idx].copyWith(totalIn: totalIn, totalOut: totalOut);
      await _p.setString(
          _cashbooksKey, jsonEncode(cashbooks.map((c) => c.toJson()).toList()));
    }
  }

  String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      (DateTime.now().microsecond % 1000).toString();
}
