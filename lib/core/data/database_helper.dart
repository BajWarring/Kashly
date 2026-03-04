import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

import '../models/book.dart';
import '../models/entry.dart';
import '../models/edit_log.dart';
import '../models/field_option.dart';
import '../models/custom_field.dart';
import '../application/sync_service.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

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
    
    // Version 3: Introduces Sync Schema (updatedAt, isDeleted)
    return await openDatabase(
      path, 
      version: 3, 
      onCreate: _createDB, 
      onUpgrade: _onUpgrade
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    final tables = ['cashbooks', 'entries', 'edit_logs', 'field_options', 'custom_fields'];
    if (oldVersion < 3) {
      for (String table in tables) {
        try { await db.execute('ALTER TABLE $table ADD COLUMN parentId TEXT'); } catch (_) {}
        try { await db.execute('ALTER TABLE $table ADD COLUMN updatedAt INTEGER DEFAULT 0'); } catch (_) {}
        try { await db.execute('ALTER TABLE $table ADD COLUMN isDeleted INTEGER DEFAULT 0'); } catch (_) {}
      }
    }
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
        icon TEXT NOT NULL, 
        parentId TEXT, 
        updatedAt INTEGER DEFAULT 0, 
        isDeleted INTEGER DEFAULT 0
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
        updatedAt INTEGER DEFAULT 0, 
        isDeleted INTEGER DEFAULT 0,
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
        updatedAt INTEGER DEFAULT 0, 
        isDeleted INTEGER DEFAULT 0,
        FOREIGN KEY (entryId) REFERENCES entries (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE field_options (
        id TEXT PRIMARY KEY, 
        fieldName TEXT NOT NULL, 
        value TEXT NOT NULL, 
        usageCount INTEGER NOT NULL, 
        lastUsed INTEGER NOT NULL, 
        updatedAt INTEGER DEFAULT 0, 
        isDeleted INTEGER DEFAULT 0
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
        updatedAt INTEGER DEFAULT 0, 
        isDeleted INTEGER DEFAULT 0,
        FOREIGN KEY (bookId) REFERENCES cashbooks (id) ON DELETE CASCADE
      )
    ''');
  }

  int get _now => DateTime.now().millisecondsSinceEpoch;

  // ==========================================
  // CASHBOOKS
  // ==========================================
  
  Future<void> insertBook(Book book) async { 
    final db = await instance.database; 
    final map = book.toMap(); 
    map['updatedAt'] = _now; 
    map['isDeleted'] = 0;
    await db.insert('cashbooks', map, conflictAlgorithm: ConflictAlgorithm.replace); 
    SyncService.instance.triggerAutoSync();
  }
  
  Future<List<Book>> getAllBooks() async { 
    final db = await instance.database; 
    final res = await db.query('cashbooks', where: 'isDeleted = 0', orderBy: 'timestamp DESC'); 
    return res.map((m) => Book.fromMap(m)).toList(); 
  }
  
  Future<Book?> getBookById(String id) async { 
    final db = await instance.database; 
    final res = await db.query('cashbooks', where: 'id = ? AND isDeleted = 0', whereArgs: [id]); 
    if (res.isNotEmpty) return Book.fromMap(res.first); 
    return null; 
  }
  
  Future<void> updateBook(Book book) async { 
    final db = await instance.database; 
    final map = book.toMap(); 
    map['updatedAt'] = _now; 
    map['isDeleted'] = 0;
    await db.update('cashbooks', map, where: 'id = ?', whereArgs: [book.id]); 
    SyncService.instance.triggerAutoSync();
  }
  
  Future<void> deleteBook(String id) async { 
    final db = await instance.database; 
    await db.update('entries', {'isDeleted': 1, 'updatedAt': _now}, where: 'bookId = ?', whereArgs: [id]); 
    await db.update('custom_fields', {'isDeleted': 1, 'updatedAt': _now}, where: 'bookId = ?', whereArgs: [id]); 
    await db.update('cashbooks', {'isDeleted': 1, 'updatedAt': _now}, where: 'id = ?', whereArgs: [id]); 
    SyncService.instance.triggerAutoSync();
  }

  // ==========================================
  // ENTRIES
  // ==========================================
  
  Future<List<Entry>> getEntriesForBook(String bookId) async { 
    final db = await instance.database; 
    final res = await db.query('entries', where: 'bookId = ? AND isDeleted = 0', whereArgs: [bookId], orderBy: 'timestamp DESC'); 
    return res.map((m) => Entry.fromMap(m)).toList(); 
  }
  
  Future<Entry?> getEntryById(String id) async { 
    final db = await instance.database; 
    final res = await db.query('entries', where: 'id = ? AND isDeleted = 0', whereArgs: [id]); 
    if (res.isNotEmpty) return Entry.fromMap(res.first); 
    return null; 
  }
  
  Future<void> insertEntry(Entry entry) async { 
    final db = await instance.database; 
    final map = entry.toMap(); 
    map['updatedAt'] = _now; 
    map['isDeleted'] = 0;
    await db.insert('entries', map, conflictAlgorithm: ConflictAlgorithm.replace); 
    SyncService.instance.triggerAutoSync();
  }
  
  Future<void> updateEntry(Entry entry) async { 
    final db = await instance.database; 
    final map = entry.toMap(); 
    map['updatedAt'] = _now; 
    map['isDeleted'] = 0;
    await db.update('entries', map, where: 'id = ?', whereArgs: [entry.id]); 
    SyncService.instance.triggerAutoSync();
  }
  
  Future<void> deleteEntry(String id) async { 
    final db = await instance.database; 
    await db.update('entries', {'isDeleted': 1, 'updatedAt': _now}, where: 'id = ?', whereArgs: [id]); 
    SyncService.instance.triggerAutoSync();
  }
  
  Future<Entry?> getLinkedEntry(String entryId) async { 
    final db = await instance.database; 
    final r1 = await db.query('entries', where: 'linkedEntryId = ? AND isDeleted = 0', whereArgs: [entryId]); 
    if (r1.isNotEmpty) return Entry.fromMap(r1.first); 
    
    final current = await getEntryById(entryId); 
    if (current != null && current.linkedEntryId != null) { 
      final r2 = await db.query('entries', where: 'id = ? AND isDeleted = 0', whereArgs: [current.linkedEntryId]); 
      if (r2.isNotEmpty) return Entry.fromMap(r2.first); 
    } 
    return null; 
  }
  
  Future<List<String>> getRecentRemarks(String bookId, {int limit = 5}) async { 
    final db = await instance.database; 
    final res = await db.rawQuery('SELECT DISTINCT note FROM entries WHERE bookId = ? AND note != "" AND isDeleted = 0 ORDER BY timestamp DESC LIMIT ?', [bookId, limit]); 
    return res.map((row) => row['note'] as String).toList(); 
  }

  // ==========================================
  // EDIT LOGS
  // ==========================================
  
  Future<List<EditLog>> getLogsForEntry(String entryId) async { 
    final db = await instance.database; 
    final res = await db.query('edit_logs', where: 'entryId = ? AND isDeleted = 0', whereArgs: [entryId], orderBy: 'timestamp DESC'); 
    return res.map((m) => EditLog.fromMap(m)).toList(); 
  }
  
  Future<void> insertEditLog(EditLog log) async { 
    final db = await instance.database; 
    final map = log.toMap(); 
    map['updatedAt'] = _now; 
    map['isDeleted'] = 0;
    await db.insert('edit_logs', map, conflictAlgorithm: ConflictAlgorithm.replace); 
    SyncService.instance.triggerAutoSync();
  }

  // ==========================================
  // FIELD OPTIONS (Categories / Payment Methods)
  // ==========================================
  
  Future<List<FieldOption>> getTopOptions(String fieldName, {int limit = 5}) async { 
    final db = await instance.database; 
    final res = await db.query('field_options', where: 'fieldName = ? AND isDeleted = 0', whereArgs: [fieldName], orderBy: 'lastUsed DESC, usageCount DESC', limit: limit); 
    return res.map((m) => FieldOption.fromMap(m)).toList(); 
  }
  
  Future<List<FieldOption>> getAllOptions(String fieldName) async { 
    final db = await instance.database; 
    final res = await db.query('field_options', where: 'fieldName = ? AND isDeleted = 0', whereArgs: [fieldName], orderBy: 'value ASC'); 
    return res.map((m) => FieldOption.fromMap(m)).toList(); 
  }
  
  Future<void> insertOption(FieldOption opt) async { 
    final db = await instance.database; 
    final map = opt.toMap(); 
    map['updatedAt'] = _now; 
    map['isDeleted'] = 0;
    await db.insert('field_options', map, conflictAlgorithm: ConflictAlgorithm.replace); 
    SyncService.instance.triggerAutoSync();
  }
  
  Future<void> updateFieldOption(FieldOption opt) async { 
    final db = await instance.database; 
    final map = opt.toMap(); 
    map['updatedAt'] = _now; 
    map['isDeleted'] = 0;
    await db.update('field_options', map, where: 'id = ?', whereArgs: [opt.id]); 
    SyncService.instance.triggerAutoSync();
  }
  
  Future<void> deleteFieldOption(String id) async { 
    final db = await instance.database; 
    await db.update('field_options', {'isDeleted': 1, 'updatedAt': _now}, where: 'id = ?', whereArgs: [id]); 
    SyncService.instance.triggerAutoSync(); 
  }
  
  Future<void> recordOptionUsage(String fieldName, String value) async { 
    final db = await instance.database; 
    final existing = await db.query('field_options', where: 'fieldName = ? AND value = ? AND isDeleted = 0', whereArgs: [fieldName, value]); 
    if (existing.isNotEmpty) { 
      final opt = FieldOption.fromMap(existing.first); 
      opt.usageCount += 1; 
      opt.lastUsed = _now; 
      await updateFieldOption(opt); 
    } else { 
      await insertOption(FieldOption(id: 'OPT-$_now', fieldName: fieldName, value: value, usageCount: 1, lastUsed: _now)); 
    } 
  }

  // ==========================================
  // CUSTOM FIELDS
  // ==========================================
  
  Future<List<CustomField>> getCustomFieldsForBook(String bookId) async { 
    final db = await instance.database; 
    final res = await db.query('custom_fields', where: 'bookId = ? AND isDeleted = 0', whereArgs: [bookId], orderBy: 'sortOrder ASC'); 
    return res.map((m) => CustomField.fromMap(m)).toList(); 
  }
  
  Future<void> insertCustomField(CustomField field) async { 
    final db = await instance.database; 
    final map = field.toMap(); 
    map['updatedAt'] = _now; 
    map['isDeleted'] = 0;
    await db.insert('custom_fields', map, conflictAlgorithm: ConflictAlgorithm.replace); 
    SyncService.instance.triggerAutoSync();
  }
  
  Future<void> updateCustomField(CustomField field) async { 
    final db = await instance.database; 
    final map = field.toMap(); 
    map['updatedAt'] = _now; 
    map['isDeleted'] = 0;
    await db.update('custom_fields', map, where: 'id = ?', whereArgs: [field.id]); 
    SyncService.instance.triggerAutoSync();
  }
  
  Future<void> deleteCustomField(String id) async { 
    final db = await instance.database; 
    await db.update('custom_fields', {'isDeleted': 1, 'updatedAt': _now}, where: 'id = ?', whereArgs: [id]); 
    SyncService.instance.triggerAutoSync();
  }
  
  Future<void> updateCustomFieldOrders(List<CustomField> fields) async { 
    final db = await instance.database; 
    Batch batch = db.batch(); 
    for (int i = 0; i < fields.length; i++) { 
      fields[i].sortOrder = i; 
      batch.update('custom_fields', {'sortOrder': i, 'updatedAt': _now}, where: 'id = ?', whereArgs: [fields[i].id]); 
    } 
    await batch.commit(noResult: true); 
    SyncService.instance.triggerAutoSync(); 
  }

  // ==========================================
  // SYNC & BACKUP LAYER
  // ==========================================
  
  Future<Map<String, List<Map<String, dynamic>>>> exportAllTables() async {
    final db = await instance.database;
    return {
      'cashbooks': await db.query('cashbooks'),
      'entries': await db.query('entries'),
      'custom_fields': await db.query('custom_fields'),
      'field_options': await db.query('field_options'),
      'edit_logs': await db.query('edit_logs'),
    };
  }

  Future<String> exportDatabaseJSON() async {
    final Map<String, dynamic> exportData = {
      'schemaVersion': 3,
      'lastExported': _now,
      ...await exportAllTables(),
    };
    return jsonEncode(exportData);
  }

  Future<int> getPendingChangesCount(int lastSyncTime) async {
    final db = await instance.database;
    int count = 0;
    final tables = ['cashbooks', 'entries', 'custom_fields', 'field_options', 'edit_logs'];
    for (String t in tables) {
      final res = await db.rawQuery('SELECT COUNT(*) as count FROM $t WHERE updatedAt > ?', [lastSyncTime]);
      count += Sqflite.firstIntValue(res) ?? 0;
    }
    return count;
  }

  Future<void> restoreDatabaseJSON(String jsonString) async {
    final db = await instance.database;
    final data = jsonDecode(jsonString);
    
    await db.transaction((txn) async {
      final tables = ['cashbooks', 'entries', 'custom_fields', 'field_options', 'edit_logs'];
      for (String t in tables) {
        if (data.containsKey(t)) {
          await txn.delete(t); // Wipe clean for pure restore
          for (var record in data[t]) { 
            await txn.insert(t, record); 
          }
        }
      }
    });
    SyncService.instance.triggerAutoSync();
  }

  // Double-Entry CRDT "Last Write Wins" Merge Strategy
  Future<void> mergeRemoteData(Map<String, dynamic> remoteData) async {
    final db = await instance.database;
    final tables = ['cashbooks', 'entries', 'custom_fields', 'field_options', 'edit_logs'];

    await db.transaction((txn) async {
      for (String table in tables) {
        if (!remoteData.containsKey(table)) continue;
        List<dynamic> remoteRecords = remoteData[table];

        final localRecords = await txn.query(table);
        Map<String, Map<String, dynamic>> localMap = { 
          for (var r in localRecords) r['id'].toString(): r 
        };

        for (var remoteItem in remoteRecords) {
          String id = remoteItem['id'].toString();
          
          if (localMap.containsKey(id)) {
            // CASE C: Exists in both. Compare updatedAt
            int localUpdated = (localMap[id]!['updatedAt'] ?? 0) as int;
            int remoteUpdated = (remoteItem['updatedAt'] ?? 0) as int;

            if (remoteUpdated > localUpdated) {
              await txn.update(
                table, 
                Map<String, dynamic>.from(remoteItem), 
                where: 'id = ?', 
                whereArgs: [id]
              );
            }
          } else {
            // CASE B: Exists remote only. Insert locally.
            await txn.insert(table, Map<String, dynamic>.from(remoteItem));
          }
        }
      }
    });
  }
}
