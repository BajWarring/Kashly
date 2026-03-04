import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Note: To strictly decouple, UI changes to DB will trigger SyncService from the outside, not inside here.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();
  
  int get _now => DateTime.now().millisecondsSinceEpoch;

  Future<Database> get database async {
    if (_database != null) return _database!;
    Directory docsDir = await getApplicationDocumentsDirectory();
    _database = await openDatabase(join(docsDir.path, 'kashly_data.db'), version: 3, onCreate: _createDB);
    return _database!;
  }

  Future _createDB(Database db, int version) async {
    // schema includes updatedAt and isDeleted for CRDT sync
    await db.execute('''CREATE TABLE cashbooks (id TEXT PRIMARY KEY, name TEXT NOT NULL, description TEXT, balance REAL NOT NULL, createdAt INTEGER NOT NULL, timestamp INTEGER NOT NULL, currency TEXT NOT NULL, icon TEXT NOT NULL, updatedAt INTEGER DEFAULT 0, isDeleted INTEGER DEFAULT 0)''');
    await db.execute('''CREATE TABLE entries (id TEXT PRIMARY KEY, bookId TEXT NOT NULL, type TEXT NOT NULL, amount REAL NOT NULL, note TEXT, category TEXT NOT NULL, paymentMethod TEXT NOT NULL, timestamp INTEGER NOT NULL, linkedEntryId TEXT, customFields TEXT, updatedAt INTEGER DEFAULT 0, isDeleted INTEGER DEFAULT 0)''');
  }

  // --- CRUD ---
  Future<void> insertData(String table, Map<String, dynamic> data) async {
    final db = await instance.database;
    data['updatedAt'] = _now; data['isDeleted'] = 0;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> softDelete(String table, String id) async {
    final db = await instance.database;
    await db.update(table, {'isDeleted': 1, 'updatedAt': _now}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> fetchActive(String table) async {
    final db = await instance.database;
    return await db.query(table, where: 'isDeleted = 0');
  }

  Future<Map<String, List<Map<String, dynamic>>>> exportAllTables() async {
    final db = await instance.database;
    return {
      'cashbooks': await db.query('cashbooks'),
      'entries': await db.query('entries'),
    };
  }

  // --- TRUE TWO-WAY MERGE (CASE C) ---
  Future<void> mergeRemoteData(Map<String, dynamic> remoteData) async {
    final db = await instance.database;
    final tables = ['cashbooks', 'entries'];

    await db.transaction((txn) async {
      for (String table in tables) {
        if (!remoteData.containsKey(table)) continue;
        List<dynamic> remoteRecords = remoteData[table];

        final localRecords = await txn.query(table);
        Map<String, Map<String, dynamic>> localMap = { for (var r in localRecords) r['id'].toString(): r };

        for (var remoteItem in remoteRecords) {
          String id = remoteItem['id'].toString();
          
          if (localMap.containsKey(id)) {
            int localUpdated = (localMap[id]!['updatedAt'] ?? 0) as int;
            int remoteUpdated = (remoteItem['updatedAt'] ?? 0) as int;
            
            // Last Write Wins
            if (remoteUpdated > localUpdated) {
              await txn.update(table, Map<String, dynamic>.from(remoteItem), where: 'id = ?', whereArgs: [id]);
            }
          } else {
            // Exists remotely, missing locally -> Insert
            await txn.insert(table, Map<String, dynamic>.from(remoteItem));
          }
        }
      }
    });
  }
}
