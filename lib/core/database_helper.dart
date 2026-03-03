import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'models/book.dart';
import 'models/entry.dart';
import 'models/edit_log.dart';
import 'models/field_option.dart';
import 'models/custom_field.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Persists Tip Dialog state during the app session
  static bool hideLinkTip = false;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kashly_data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cashbooks (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        balance REAL NOT NULL,
        createdAt INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        currency TEXT NOT NULL,
        icon TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE entries (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        type TEXT NOT NULL, 
        amount REAL NOT NULL,
        note TEXT,
        category TEXT NOT NULL,
        paymentMethod TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        linkedEntryId TEXT,
        customFields TEXT,
        FOREIGN KEY (bookId) REFERENCES cashbooks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE edit_logs (
        id TEXT PRIMARY KEY,
        entryId TEXT NOT NULL,
        field TEXT NOT NULL,
        oldValue TEXT NOT NULL,
        newValue TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (entryId) REFERENCES entries (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE field_options (
        id TEXT PRIMARY KEY,
        fieldName TEXT NOT NULL,
        value TEXT NOT NULL,
        usageCount INTEGER NOT NULL,
        lastUsed INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_fields (
        id TEXT PRIMARY KEY,
        bookId TEXT NOT NULL,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        options TEXT,
        sortOrder INTEGER NOT NULL,
        FOREIGN KEY (bookId) REFERENCES cashbooks (id) ON DELETE CASCADE
      )
    ''');
  }

  // ==========================================
  // CASHBOOKS
  // ==========================================
  Future<void> insertBook(Book book) async {
    final db = await instance.database;
    await db.insert('cashbooks', book.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Book>> getAllBooks() async {
    final db = await instance.database;
    final result = await db.query('cashbooks', orderBy: 'timestamp DESC');
    return result.map((map) => Book.fromMap(map)).toList();
  }

  Future<Book?> getBookById(String id) async {
    final db = await instance.database;
    final result = await db.query('cashbooks', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return Book.fromMap(result.first);
    return null;
  }

  Future<void> updateBook(Book book) async {
    final db = await instance.database;
    await db.update('cashbooks', book.toMap(), where: 'id = ?', whereArgs: [book.id]);
  }

  Future<void> deleteBook(String id) async {
    final db = await instance.database;
    // Safely cascade delete everything inside the book
    await db.delete('entries', where: 'bookId = ?', whereArgs: [id]);
    await db.delete('custom_fields', where: 'bookId = ?', whereArgs: [id]);
    await db.delete('cashbooks', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // ENTRIES & DOUBLE ENTRY LINKING LOGIC
  // ==========================================
  Future<List<Entry>> getEntriesForBook(String bookId) async {
    final db = await instance.database;
    final result = await db.query('entries', where: 'bookId = ?', whereArgs: [bookId], orderBy: 'timestamp DESC');
    return result.map((map) => Entry.fromMap(map)).toList();
  }

  Future<Entry?> getEntryById(String id) async {
    final db = await instance.database;
    final result = await db.query('entries', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return Entry.fromMap(result.first);
    return null;
  }

  Future<void> insertEntry(Entry entry) async {
    final db = await instance.database;
    await db.insert('entries', entry.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateEntry(Entry entry) async {
    final db = await instance.database;
    await db.update('entries', entry.toMap(), where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<void> deleteEntry(String id) async {
    final db = await instance.database;
    await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  // Finds the opposite side of a Transfer to keep them synchronized
  Future<Entry?> getLinkedEntry(String entryId) async {
    final db = await instance.database;
    
    final r1 = await db.query('entries', where: 'linkedEntryId = ?', whereArgs: [entryId]);
    if (r1.isNotEmpty) return Entry.fromMap(r1.first);
    
    final current = await getEntryById(entryId);
    if (current != null && current.linkedEntryId != null) {
      final r2 = await db.query('entries', where: 'id = ?', whereArgs: [current.linkedEntryId]);
      if (r2.isNotEmpty) return Entry.fromMap(r2.first);
    }
    
    return null;
  }

  // ==========================================
  // LOGS & SUGGESTIONS
  // ==========================================
  Future<List<EditLog>> getLogsForEntry(String entryId) async {
    final db = await instance.database;
    final result = await db.query('edit_logs', where: 'entryId = ?', whereArgs: [entryId], orderBy: 'timestamp DESC');
    return result.map((map) => EditLog.fromMap(map)).toList();
  }

  Future<void> insertEditLog(EditLog log) async {
    final db = await instance.database;
    await db.insert('edit_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<String>> getRecentRemarks(String bookId, {int limit = 5}) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT note FROM entries WHERE bookId = ? AND note != "" ORDER BY timestamp DESC LIMIT ?', 
      [bookId, limit]
    );
    return result.map((row) => row['note'] as String).toList();
  }

  // ==========================================
  // FIELD OPTIONS
  // ==========================================
  Future<List<FieldOption>> getTopOptions(String fieldName, {int limit = 5}) async {
    final db = await instance.database;
    final result = await db.query('field_options', where: 'fieldName = ?', whereArgs: [fieldName], orderBy: 'lastUsed DESC, usageCount DESC', limit: limit);
    return result.map((map) => FieldOption.fromMap(map)).toList();
  }

  Future<List<FieldOption>> getAllOptions(String fieldName) async {
    final db = await instance.database;
    final result = await db.query('field_options', where: 'fieldName = ?', whereArgs: [fieldName], orderBy: 'value ASC');
    return result.map((map) => FieldOption.fromMap(map)).toList();
  }

  Future<void> insertOption(FieldOption option) async {
    final db = await instance.database;
    await db.insert('field_options', option.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateFieldOption(FieldOption option) async {
    final db = await instance.database;
    await db.update('field_options', option.toMap(), where: 'id = ?', whereArgs: [option.id]);
  }

  Future<void> deleteFieldOption(String id) async {
    final db = await instance.database;
    await db.delete('field_options', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> recordOptionUsage(String fieldName, String value) async {
    final db = await instance.database;
    final existing = await db.query('field_options', where: 'fieldName = ? AND value = ?', whereArgs: [fieldName, value]);
    
    if (existing.isNotEmpty) {
      final opt = FieldOption.fromMap(existing.first);
      opt.usageCount += 1;
      opt.lastUsed = DateTime.now().millisecondsSinceEpoch;
      await updateFieldOption(opt);
    } else {
      await insertOption(FieldOption(
        id: 'OPT-${DateTime.now().millisecondsSinceEpoch}',
        fieldName: fieldName,
        value: value,
        usageCount: 1,
        lastUsed: DateTime.now().millisecondsSinceEpoch
      ));
    }
  }

  // ==========================================
  // CUSTOM FIELDS
  // ==========================================
  Future<List<CustomField>> getCustomFieldsForBook(String bookId) async {
    final db = await instance.database;
    final result = await db.query('custom_fields', where: 'bookId = ?', whereArgs: [bookId], orderBy: 'sortOrder ASC');
    return result.map((map) => CustomField.fromMap(map)).toList();
  }

  Future<void> insertCustomField(CustomField field) async {
    final db = await instance.database;
    await db.insert('custom_fields', field.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCustomField(CustomField field) async {
    final db = await instance.database;
    await db.update('custom_fields', field.toMap(), where: 'id = ?', whereArgs: [field.id]);
  }

  Future<void> deleteCustomField(String id) async {
    final db = await instance.database;
    await db.delete('custom_fields', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateCustomFieldOrders(List<CustomField> fields) async {
    final db = await instance.database;
    Batch batch = db.batch();
    for (int i = 0; i < fields.length; i++) {
      fields[i].sortOrder = i;
      batch.update('custom_fields', fields[i].toMap(), where: 'id = ?', whereArgs: [fields[i].id]);
    }
    await batch.commit(noResult: true);
  }
}
