import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kashly/domain/entities/cashbook.dart';
import 'package:kashly/domain/entities/transaction.dart';
import 'package:kashly/domain/entities/transaction_history.dart';
import 'package:kashly/domain/entities/backup_record.dart';
import 'package:kashly/domain/entities/backup_settings.dart';
import 'package:kashly/core/error/exceptions.dart';
import 'dart:convert';

class LocalDatasource {
  static Database? _db;
  static const String dbName = 'kashly.db';
  static const int _version = 2;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, dbName);
    _db = await openDatabase(
      path,
      version: _version,
      onCreate: _createDb,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  Future _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cashbooks (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        currency TEXT NOT NULL,
        opening_balance REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        auto_backup_enabled INTEGER NOT NULL DEFAULT 0,
        include_attachments INTEGER NOT NULL DEFAULT 0,
        last_backup_at TEXT,
        last_backup_file_id TEXT,
        is_archived INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        cashbook_id TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        remark TEXT NOT NULL DEFAULT '',
        method TEXT NOT NULL DEFAULT '',
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        drive_file_id TEXT,
        drive_file_name TEXT,
        last_synced_at TEXT,
        md5_checksum TEXT,
        version TEXT,
        is_uploaded INTEGER NOT NULL DEFAULT 0,
        is_modified_since_upload INTEGER NOT NULL DEFAULT 0,
        has_attachment INTEGER NOT NULL DEFAULT 0,
        attachment_path TEXT,
        is_reconciled INTEGER NOT NULL DEFAULT 0,
        parent_transaction_id TEXT,
        is_split INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (cashbook_id) REFERENCES cashbooks(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_history (
        id TEXT PRIMARY KEY,
        transaction_id TEXT NOT NULL,
        field_name TEXT NOT NULL,
        old_value TEXT NOT NULL,
        new_value TEXT NOT NULL,
        changed_by TEXT NOT NULL,
        changed_at TEXT NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE backup_records (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        cashbook_ids TEXT NOT NULL,
        transaction_count INTEGER NOT NULL DEFAULT 0,
        file_name TEXT NOT NULL,
        file_size_bytes INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        drive_file_id TEXT,
        status TEXT NOT NULL,
        notes TEXT,
        checksum TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_transactions_cashbook ON transactions(cashbook_id)');
    await db.execute('CREATE INDEX idx_transactions_sync ON transactions(sync_status)');
    await db.execute('CREATE INDEX idx_transactions_uploaded ON transactions(is_uploaded)');
    await db.execute('CREATE INDEX idx_history_transaction ON transaction_history(transaction_id)');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations
  }

  // ─── Cashbooks ────────────────────────────────────────────────────

  Future<void> insertCashbook(Cashbook cashbook) async {
    try {
      final dbClient = await db;
      await dbClient.insert(
        'cashbooks',
        _cashbookToMap(cashbook),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to insert cashbook: $e');
    }
  }

  Future<List<Cashbook>> getCashbooks() async {
    try {
      final dbClient = await db;
      final maps = await dbClient.query('cashbooks', orderBy: 'updated_at DESC');
      return maps.map(_cashbookFromMap).toList();
    } catch (e) {
      throw CacheException('Failed to get cashbooks: $e');
    }
  }

  Future<Cashbook?> getCashbookById(String id) async {
    try {
      final dbClient = await db;
      final maps = await dbClient.query('cashbooks', where: 'id = ?', whereArgs: [id]);
      if (maps.isEmpty) return null;
      return _cashbookFromMap(maps.first);
    } catch (e) {
      throw CacheException('Failed to get cashbook: $e');
    }
  }

  Future<void> updateCashbook(Cashbook cashbook) async {
    try {
      final dbClient = await db;
      await dbClient.update(
        'cashbooks',
        _cashbookToMap(cashbook),
        where: 'id = ?',
        whereArgs: [cashbook.id],
      );
    } catch (e) {
      throw CacheException('Failed to update cashbook: $e');
    }
  }

  Future<void> deleteCashbook(String id) async {
    try {
      final dbClient = await db;
      await dbClient.delete('cashbooks', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw CacheException('Failed to delete cashbook: $e');
    }
  }

  Future<double> getCashbookBalance(String cashbookId) async {
    try {
      final dbClient = await db;
      final cb = await getCashbookById(cashbookId);
      if (cb == null) return 0;

      final inResult = await dbClient.rawQuery(
        "SELECT COALESCE(SUM(amount),0) as total FROM transactions WHERE cashbook_id = ? AND type = 'cashIn'",
        [cashbookId],
      );
      final outResult = await dbClient.rawQuery(
        "SELECT COALESCE(SUM(amount),0) as total FROM transactions WHERE cashbook_id = ? AND type = 'cashOut'",
        [cashbookId],
      );

      final totalIn = (inResult.first['total'] as num).toDouble();
      final totalOut = (outResult.first['total'] as num).toDouble();
      return cb.openingBalance + totalIn - totalOut;
    } catch (e) {
      throw CacheException('Failed to get balance: $e');
    }
  }

  Future<double> getTotalIn(String cashbookId) async {
    final dbClient = await db;
    final result = await dbClient.rawQuery(
      "SELECT COALESCE(SUM(amount),0) as total FROM transactions WHERE cashbook_id = ? AND type = 'cashIn'",
      [cashbookId],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getTotalOut(String cashbookId) async {
    final dbClient = await db;
    final result = await dbClient.rawQuery(
      "SELECT COALESCE(SUM(amount),0) as total FROM transactions WHERE cashbook_id = ? AND type = 'cashOut'",
      [cashbookId],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getReconciledAmount(String cashbookId) async {
    final dbClient = await db;
    final result = await dbClient.rawQuery(
      "SELECT COALESCE(SUM(amount),0) as total FROM transactions WHERE cashbook_id = ? AND is_reconciled = 1",
      [cashbookId],
    );
    return (result.first['total'] as num).toDouble();
  }

  // ─── Transactions ─────────────────────────────────────────────────

  Future<void> insertTransaction(Transaction transaction) async {
    try {
      final dbClient = await db;
      await dbClient.insert(
        'transactions',
        _transactionToMap(transaction),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to insert transaction: $e');
    }
  }

  Future<List<Transaction>> getTransactions(String cashbookId, {int? limit, int? offset}) async {
    try {
      final dbClient = await db;
      final maps = await dbClient.query(
        'transactions',
        where: 'cashbook_id = ?',
        whereArgs: [cashbookId],
        orderBy: 'date DESC, created_at DESC',
        limit: limit,
        offset: offset,
      );
      return maps.map(_transactionFromMap).toList();
    } catch (e) {
      throw CacheException('Failed to get transactions: $e');
    }
  }

  Future<Transaction?> getTransactionById(String id) async {
    try {
      final dbClient = await db;
      final maps = await dbClient.query('transactions', where: 'id = ?', whereArgs: [id]);
      if (maps.isEmpty) return null;
      return _transactionFromMap(maps.first);
    } catch (e) {
      throw CacheException('Failed to get transaction: $e');
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      final dbClient = await db;
      await dbClient.update(
        'transactions',
        _transactionToMap(transaction),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
    } catch (e) {
      throw CacheException('Failed to update transaction: $e');
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final dbClient = await db;
      await dbClient.delete('transactions', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw CacheException('Failed to delete transaction: $e');
    }
  }

  Future<List<Transaction>> getNonUploadedTransactions() async {
    try {
      final dbClient = await db;
      final maps = await dbClient.query(
        'transactions',
        where: 'is_uploaded = 0',
        orderBy: 'date DESC',
      );
      return maps.map(_transactionFromMap).toList();
    } catch (e) {
      throw CacheException('Failed to get non-uploaded transactions: $e');
    }
  }

  Future<List<Transaction>> getModifiedTransactions() async {
    try {
      final dbClient = await db;
      final maps = await dbClient.query(
        'transactions',
        where: 'is_modified_since_upload = 1',
        orderBy: 'date DESC',
      );
      return maps.map(_transactionFromMap).toList();
    } catch (e) {
      throw CacheException('Failed to get modified transactions: $e');
    }
  }

  Future<List<Transaction>> searchTransactions(String cashbookId, String query) async {
    try {
      final dbClient = await db;
      final maps = await dbClient.query(
        'transactions',
        where: 'cashbook_id = ? AND (category LIKE ? OR remark LIKE ? OR method LIKE ?)',
        whereArgs: [cashbookId, '%$query%', '%$query%', '%$query%'],
        orderBy: 'date DESC',
      );
      return maps.map(_transactionFromMap).toList();
    } catch (e) {
      throw CacheException('Failed to search transactions: $e');
    }
  }

  Future<List<Transaction>> getTransactionsByDateRange(
    String cashbookId,
    DateTime from,
    DateTime to,
  ) async {
    try {
      final dbClient = await db;
      final maps = await dbClient.query(
        'transactions',
        where: 'cashbook_id = ? AND date >= ? AND date <= ?',
        whereArgs: [cashbookId, from.toIso8601String(), to.toIso8601String()],
        orderBy: 'date DESC',
      );
      return maps.map(_transactionFromMap).toList();
    } catch (e) {
      throw CacheException('Failed to get transactions by date range: $e');
    }
  }

  Future<List<Transaction>> getConflictTransactions() async {
    try {
      final dbClient = await db;
      final maps = await dbClient.query(
        'transactions',
        where: "sync_status = 'conflict'",
        orderBy: 'date DESC',
      );
      return maps.map(_transactionFromMap).toList();
    } catch (e) {
      throw CacheException('Failed to get conflict transactions: $e');
    }
  }

  // ─── Transaction History ──────────────────────────────────────────

  Future<void> insertHistory(TransactionHistory history) async {
    try {
      final dbClient = await db;
      await dbClient.insert('transaction_history', {
        'id': history.id,
        'transaction_id': history.transactionId,
        'field_name': history.fieldName,
        'old_value': history.oldValue,
        'new_value': history.newValue,
        'changed_by': history.changedBy,
        'changed_at': history.changedAt.toIso8601String(),
      });
    } catch (e) {
      throw CacheException('Failed to insert history: $e');
    }
  }

  Future<List<TransactionHistory>> getHistory(String transactionId) async {
    try {
      final dbClient = await db;
      final maps = await dbClient.query(
        'transaction_history',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
        orderBy: 'changed_at DESC',
      );
      return maps
          .map((m) => TransactionHistory(
                id: m['id'] as String,
                transactionId: m['transaction_id'] as String,
                fieldName: m['field_name'] as String,
                oldValue: m['old_value'] as String,
                newValue: m['new_value'] as String,
                changedBy: m['changed_by'] as String,
                changedAt: DateTime.parse(m['changed_at'] as String),
              ))
          .toList();
    } catch (e) {
      throw CacheException('Failed to get history: $e');
    }
  }

  // ─── Backup Records ───────────────────────────────────────────────

  Future<void> insertBackupRecord(BackupRecord record) async {
    try {
      final dbClient = await db;
      await dbClient.insert('backup_records', {
        'id': record.id,
        'type': record.type.name,
        'cashbook_ids': jsonEncode(record.cashbookIds),
        'transaction_count': record.transactionCount,
        'file_name': record.fileName,
        'file_size_bytes': record.fileSizeBytes,
        'created_at': record.createdAt.toIso8601String(),
        'drive_file_id': record.driveFileId,
        'status': record.status.name,
        'notes': record.notes,
        'checksum': record.checksum,
      });
    } catch (e) {
      throw CacheException('Failed to insert backup record: $e');
    }
  }

  Future<List<BackupRecord>> getBackupHistory({int limit = 50}) async {
    try {
      final dbClient = await db;
      final maps = await dbClient.query(
        'backup_records',
        orderBy: 'created_at DESC',
        limit: limit,
      );
      return maps.map(_backupRecordFromMap).toList();
    } catch (e) {
      throw CacheException('Failed to get backup history: $e');
    }
  }

  Future<BackupRecord?> getLastBackup(String type) async {
    try {
      final dbClient = await db;
      final maps = await dbClient.query(
        'backup_records',
        where: "type = ? AND status = 'success'",
        whereArgs: [type],
        orderBy: 'created_at DESC',
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return _backupRecordFromMap(maps.first);
    } catch (e) {
      throw CacheException('Failed to get last backup: $e');
    }
  }

  // ─── App Settings ─────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    try {
      final dbClient = await db;
      final maps = await dbClient.query('app_settings', where: 'key = ?', whereArgs: [key]);
      if (maps.isEmpty) return null;
      return maps.first['value'] as String?;
    } catch (e) {
      throw CacheException('Failed to get setting: $e');
    }
  }

  Future<void> saveSetting(String key, String value) async {
    try {
      final dbClient = await db;
      await dbClient.insert(
        'app_settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to save setting: $e');
    }
  }

  Future<AppBackupSettings> getBackupSettings() async {
    final json = await getSetting('backup_settings');
    if (json == null) return const AppBackupSettings();
    try {
      return AppBackupSettings.fromJson(jsonDecode(json));
    } catch (_) {
      return const AppBackupSettings();
    }
  }

  Future<void> saveBackupSettings(AppBackupSettings settings) async {
    await saveSetting('backup_settings', jsonEncode(settings.toJson()));
  }

  Future<void> vacuumDb() async {
    final dbClient = await db;
    await dbClient.execute('VACUUM');
  }

  Future<void> close() async {
    final dbClient = await db;
    await dbClient.close();
    _db = null;
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  Map<String, dynamic> _cashbookToMap(Cashbook cb) => {
        'id': cb.id,
        'name': cb.name,
        'currency': cb.currency,
        'opening_balance': cb.openingBalance,
        'created_at': cb.createdAt.toIso8601String(),
        'updated_at': cb.updatedAt.toIso8601String(),
        'sync_status': cb.syncStatus.name,
        'auto_backup_enabled': cb.backupSettings.autoBackupEnabled ? 1 : 0,
        'include_attachments': cb.backupSettings.includeAttachments ? 1 : 0,
        'last_backup_at': cb.backupSettings.lastBackupAt?.toIso8601String(),
        'last_backup_file_id': cb.backupSettings.lastBackupFileId,
        'is_archived': cb.isArchived ? 1 : 0,
      };

  Cashbook _cashbookFromMap(Map<String, dynamic> m) => Cashbook(
        id: m['id'] as String,
        name: m['name'] as String,
        currency: m['currency'] as String,
        openingBalance: (m['opening_balance'] as num).toDouble(),
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
        syncStatus: SyncStatus.values.firstWhere(
          (e) => e.name == m['sync_status'],
          orElse: () => SyncStatus.pending,
        ),
        backupSettings: BackupSettings(
          autoBackupEnabled: m['auto_backup_enabled'] == 1,
          includeAttachments: m['include_attachments'] == 1,
          lastBackupAt: m['last_backup_at'] != null
              ? DateTime.parse(m['last_backup_at'] as String)
              : null,
          lastBackupFileId: m['last_backup_file_id'] as String?,
        ),
        isArchived: m['is_archived'] == 1,
      );

  Map<String, dynamic> _transactionToMap(Transaction tx) => {
        'id': tx.id,
        'cashbook_id': tx.cashbookId,
        'amount': tx.amount,
        'type': tx.type.name,
        'category': tx.category,
        'remark': tx.remark,
        'method': tx.method,
        'date': tx.date.toIso8601String(),
        'created_at': tx.createdAt.toIso8601String(),
        'updated_at': tx.updatedAt.toIso8601String(),
        'sync_status': tx.syncStatus.name,
        'drive_file_id': tx.driveMeta.fileId,
        'drive_file_name': tx.driveMeta.driveFileName,
        'last_synced_at': tx.driveMeta.lastSyncedAt?.toIso8601String(),
        'md5_checksum': tx.driveMeta.md5Checksum,
        'version': tx.driveMeta.version,
        'is_uploaded': tx.driveMeta.isUploaded ? 1 : 0,
        'is_modified_since_upload': tx.driveMeta.isModifiedSinceUpload ? 1 : 0,
        'has_attachment': tx.hasAttachment ? 1 : 0,
        'attachment_path': tx.attachmentPath,
        'is_reconciled': tx.isReconciled ? 1 : 0,
        'parent_transaction_id': tx.parentTransactionId,
        'is_split': tx.isSplit ? 1 : 0,
      };

  Transaction _transactionFromMap(Map<String, dynamic> m) => Transaction(
        id: m['id'] as String,
        cashbookId: m['cashbook_id'] as String,
        amount: (m['amount'] as num).toDouble(),
        type: TransactionType.values.firstWhere(
          (e) => e.name == m['type'],
          orElse: () => TransactionType.cashIn,
        ),
        category: m['category'] as String,
        remark: (m['remark'] as String?) ?? '',
        method: (m['method'] as String?) ?? '',
        date: DateTime.parse(m['date'] as String),
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
        syncStatus: TransactionSyncStatus.values.firstWhere(
          (e) => e.name == m['sync_status'],
          orElse: () => TransactionSyncStatus.pending,
        ),
        driveMeta: DriveMeta(
          fileId: m['drive_file_id'] as String?,
          driveFileName: m['drive_file_name'] as String?,
          lastSyncedAt: m['last_synced_at'] != null
              ? DateTime.parse(m['last_synced_at'] as String)
              : null,
          md5Checksum: m['md5_checksum'] as String?,
          version: m['version'] as String?,
          isUploaded: m['is_uploaded'] == 1,
          isModifiedSinceUpload: m['is_modified_since_upload'] == 1,
        ),
        hasAttachment: m['has_attachment'] == 1,
        attachmentPath: m['attachment_path'] as String?,
        isReconciled: m['is_reconciled'] == 1,
        parentTransactionId: m['parent_transaction_id'] as String?,
        isSplit: m['is_split'] == 1,
      );

  BackupRecord _backupRecordFromMap(Map<String, dynamic> m) => BackupRecord(
        id: m['id'] as String,
        type: BackupType.values.firstWhere(
          (e) => e.name == m['type'],
          orElse: () => BackupType.local,
        ),
        cashbookIds: List<String>.from(jsonDecode(m['cashbook_ids'] as String)),
        transactionCount: m['transaction_count'] as int,
        fileName: m['file_name'] as String,
        fileSizeBytes: m['file_size_bytes'] as int,
        createdAt: DateTime.parse(m['created_at'] as String),
        driveFileId: m['drive_file_id'] as String?,
        status: BackupStatus.values.firstWhere(
          (e) => e.name == m['status'],
          orElse: () => BackupStatus.failed,
        ),
        notes: m['notes'] as String?,
        checksum: m['checksum'] as String?,
      );
}
