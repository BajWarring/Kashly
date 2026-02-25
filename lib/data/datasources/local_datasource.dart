import 'package:sqflite/sqflite.dart'; // Changed to standard sqflite
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kashly/domain/entities/cashbook.dart';
import 'package:kashly/domain/entities/transaction.dart';
import 'package:kashly/core/utils/utils.dart';
 // Import other entities

class LocalDatasource {
  static Database? _db;
  static const String dbName = 'kashly.db';
  static const String password = 'your_encryption_password'; // Use secure storage for prod

  Future<Database> get db async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, dbName);
    _db = await openDatabase(path, password: password, version: 1, onCreate: _createDb); // Works with sqlcipher_flutter_libs
    return _db!;
  }

  Future _createDb(Database db, int version) async {
    // Create tables for all models
    await db.execute('''
      CREATE TABLE cashbooks (
        id TEXT PRIMARY KEY,
        name TEXT,
        currency TEXT,
        opening_balance REAL,
        created_at TEXT,
        updated_at TEXT,
        sync_status TEXT,
        auto_backup_enabled INTEGER,
        include_attachments INTEGER,
        last_backup_at TEXT,
        last_backup_file_id TEXT
      )
    ''');
    // Add tables for transaction, transaction_history, backup_record, etc.
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        cashbook_id TEXT,
        amount REAL,
        type TEXT,
        category TEXT,
        remark TEXT,
        method TEXT,
        date TEXT,
        created_at TEXT,
        updated_at TEXT,
        sync_status TEXT,
        file_id TEXT,
        drive_file_name TEXT,
        last_synced_at TEXT,
        md5_checksum TEXT,
        version TEXT,
        is_uploaded INTEGER,
        is_modified_since_upload INTEGER,
        has_attachment INTEGER,
        is_reconciled INTEGER
      )
    ''');
    // ... Add other tables
  }

  Future<void> insertCashbook(Cashbook cashbook) async {
    final dbClient = await db;
    await dbClient.insert('cashbooks', {
      'id': cashbook.id,
      'name': cashbook.name,
      // ... all fields, convert enums to string, dates to iso
    });
  }

  Future<List<Cashbook>> getCashbooks() async {
    final dbClient = await db;
    final maps = await dbClient.query('cashbooks');
    return maps.map((map) => Cashbook.fromJson(map)).toList();
  }

  // Add CRUD for all models
  // For example, getNonUploadedTransactions() for backup
  Future<List<Transaction>> getNonUploadedTransactions() async {
    final dbClient = await db;
    final maps = await dbClient.query('transactions', where: 'is_uploaded = 0');
    return maps.map((map) => Transaction.fromJson(map)).toList();
  }

  // Vacuum for advanced settings
  Future<void> vacuumDb() async {
    final dbClient = await db;
    await dbClient.execute('VACUUM');
  }

  // Close DB
  Future close() async {
    final dbClient = await db;
    dbClient.close();
  }
}
