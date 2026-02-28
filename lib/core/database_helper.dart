import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'models/book.dart';
import 'models/edit_log.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kashly_data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Stores the database in the system's hidden document directory
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

    Future _createDB(Database db, int version) async {
    // 1. Cashbooks Table
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

    // 2. Updated Entries Table
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

    // 3. New Edit Logs Table
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
  }


  // --- CRUD Operations for Cashbooks ---

  Future<void> insertBook(Book book) async {
    final db = await instance.database;
    await db.insert('cashbooks', book.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Book>> getAllBooks() async {
    final db = await instance.database;
    final result = await db.query('cashbooks', orderBy: 'timestamp DESC');
    return result.map((map) => Book.fromMap(map)).toList();
  }

  Future<void> updateBook(Book book) async {
    final db = await instance.database;
    await db.update(
      'cashbooks',
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<void> deleteBook(String id) async {
    final db = await instance.database;
    await db.delete(
      'cashbooks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
 // --- CRUD Operations for Entries ---

  // Fetch all entries for a specific cashbook
  Future<List<Entry>> getEntriesForBook(String bookId) async {
    final db = await instance.database;
    final result = await db.query(
      'entries',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'timestamp DESC', // Shows newest entries at the top
    );
    return result.map((map) => Entry.fromMap(map)).toList();
  }

  // Insert a new entry
  Future<void> insertEntry(Entry entry) async {
    final db = await instance.database;
    await db.insert(
      'entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
    
  // --- CRUD Operations for Edit Logs ---

  Future<List<EditLog>> getLogsForEntry(String entryId) async {
    final db = await instance.database;
    final result = await db.query(
      'edit_logs',
      where: 'entryId = ?',
      whereArgs: [entryId],
      orderBy: 'timestamp DESC', // Newest edits first
    );
    return result.map((map) => EditLog.fromMap(map)).toList();
  }

  Future<void> insertEditLog(EditLog log) async {
    final db = await instance.database;
    await db.insert(
      'edit_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
