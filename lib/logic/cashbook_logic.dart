// LOGIC LAYER - Cashbook Controller
// This file contains all business logic, separate from UI.
// Swap this out for real DB/state management (Riverpod, Bloc, Provider) later.

import '../models/cashbook.dart';
import '../models/transaction.dart';

class CashbookLogic {
  // --- STUB: Replace with real DB calls ---

  static List<CashBook> getSampleCashbooks() {
    return [
      CashBook(
        id: '1',
        name: 'Personal Expenses',
        totalIn: 15000.00,
        totalOut: 9579.50,
        customCategories: ['Rent', 'Gym'],
        customPaymentMethods: ['Wallet'],
      ),
      CashBook(
        id: '2',
        name: 'Business Account',
        totalIn: 52000.00,
        totalOut: 39649.25,
        customCategories: ['Client Payment', 'Project Cost'],
        customPaymentMethods: ['Wire Transfer'],
      ),
      CashBook(
        id: '3',
        name: 'Groceries',
        totalIn: 5000.00,
        totalOut: 5250.00,
        customCategories: [],
        customPaymentMethods: [],
      ),
      CashBook(
        id: '4',
        name: 'Investment Fund',
        totalIn: 50000.00,
        totalOut: 25000.00,
        customCategories: ['Stocks', 'Mutual Funds', 'Crypto'],
        customPaymentMethods: ['Broker Transfer'],
      ),
      CashBook(
        id: '5',
        name: 'Travel Budget',
        totalIn: 10000.00,
        totalOut: 8500.00,
        customCategories: ['Flights', 'Hotels', 'Activities'],
        customPaymentMethods: ['Travel Card'],
      ),
    ];
  }

  static List<Transaction> getSampleTransactions(String cashbookId) {
    final now = DateTime.now();
    return [
      Transaction(
        id: 't1',
        entryType: EntryType.cashIn,
        amount: 5000.00,
        dateTime: now.subtract(const Duration(hours: 2)),
        remarks: 'Monthly salary received',
        category: 'Salary',
        paymentMethod: 'Bank Transfer',
        cashbookId: cashbookId,
      ),
      Transaction(
        id: 't2',
        entryType: EntryType.cashOut,
        amount: 1200.00,
        dateTime: now.subtract(const Duration(hours: 5)),
        remarks: 'Grocery shopping at Big Mart',
        category: 'Food & Drinks',
        paymentMethod: 'UPI',
        cashbookId: cashbookId,
      ),
      Transaction(
        id: 't3',
        entryType: EntryType.cashIn,
        amount: 2500.00,
        dateTime: now.subtract(const Duration(days: 1)),
        remarks: 'Freelance project payment',
        category: 'Business',
        paymentMethod: 'Bank Transfer',
        cashbookId: cashbookId,
      ),
      Transaction(
        id: 't4',
        entryType: EntryType.cashOut,
        amount: 450.00,
        dateTime: now.subtract(const Duration(days: 1, hours: 3)),
        remarks: 'Electricity bill',
        category: 'Bills & Utilities',
        paymentMethod: 'UPI',
        cashbookId: cashbookId,
      ),
      Transaction(
        id: 't5',
        entryType: EntryType.cashOut,
        amount: 850.00,
        dateTime: now.subtract(const Duration(days: 2)),
        remarks: 'Dinner with family',
        category: 'Food & Drinks',
        paymentMethod: 'Card',
        cashbookId: cashbookId,
      ),
      Transaction(
        id: 't6',
        entryType: EntryType.cashIn,
        amount: 7500.00,
        dateTime: now.subtract(const Duration(days: 3)),
        remarks: 'Client advance',
        category: 'Business',
        paymentMethod: 'Cheque',
        cashbookId: cashbookId,
      ),
      Transaction(
        id: 't7',
        entryType: EntryType.cashOut,
        amount: 3500.00,
        dateTime: now.subtract(const Duration(days: 4)),
        remarks: 'Monthly rent',
        category: 'Bills & Utilities',
        paymentMethod: 'Bank Transfer',
        cashbookId: cashbookId,
      ),
      Transaction(
        id: 't8',
        entryType: EntryType.cashOut,
        amount: 299.00,
        dateTime: now.subtract(const Duration(days: 5)),
        remarks: 'Netflix subscription',
        category: 'Entertainment',
        paymentMethod: 'Card',
        cashbookId: cashbookId,
      ),
    ];
  }

  // --- Stubs for future logic ---

  static Future<void> addTransaction(Transaction transaction) async {
    // TODO: Save to local DB (SQLite/Hive)
  }

  static Future<void> updateTransaction(Transaction transaction) async {
    // TODO: Update in local DB
  }

  static Future<void> deleteTransaction(String transactionId) async {
    // TODO: Delete from local DB
  }

  static Future<void> addCashbook(CashBook cashbook) async {
    // TODO: Save to local DB
  }

  static Future<void> deleteCashbook(String cashbookId) async {
    // TODO: Delete from local DB
  }

  static Future<void> updateCashbookOptions({
    required String cashbookId,
    List<String>? customCategories,
    List<String>? customPaymentMethods,
  }) async {
    // TODO: Update in local DB
  }

  static Future<String> exportToCsv(String cashbookId) async {
    // TODO: Generate CSV and return file path
    return '';
  }

  static Future<String> exportToPdf(String cashbookId) async {
    // TODO: Generate PDF and return file path
    return '';
  }
}
