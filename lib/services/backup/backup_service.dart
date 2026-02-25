import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:kashly/core/di/providers.dart';
import 'package:kashly/domain/entities/backup_record.dart';
import 'package:kashly/data/datasources/local_datasource.dart';
import 'package:kashly/core/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

class BackupService {
  final LocalDatasource localDatasource = LocalDatasource(); // Inject

  Future<void> performScheduledBackup() async {
    // Check settings, network, battery
    if (await _checkConditions()) {
      await fullDbBackup();
      await pruneOldBackups();
      // Notify success/failure
    }
  }

  Future<bool> _checkConditions() async {
    // Implement only wifi, charging, etc.
    return true;
  }

  Future<void> manualBackup() async {
    // Confirmation dialog
    await incrementalBackup();
  }

  Future<void> incrementalBackup() async {
    final nonUploaded = await localDatasource.getNonUploadedTransactions();
    for (var tx in nonUploaded) {
      await _uploadToDrive(tx);
      // Update meta
    }
  }

  Future<void> fullDbBackup() async {
    final dir = await getApplicationDocumentsDirectory();
    final backupFile = File('${dir.path}/kashly_backup.sql');
    // Dump DB to file (use sqflite export)
    // Encrypt if enabled
    final encrypted = _encryptFile(backupFile);
    final checksum = calculateMd5(encrypted);
    await _uploadToDriveFile(encrypted, checksum);
    // Create backup record
    final record = BackupRecord(
      id: 'uuid',
      type: BackupType.google_drive,
      cashbookIds: [],
      transactionCount: 0,
      fileName: 'backup.sql',
      fileSizeBytes: encrypted.lengthSync(),
      createdAt: DateTime.now(),
      status: BackupStatus.success,
    );
    // Insert record
  }

  File _encryptFile(File file) {
    // Use encrypt lib with password
    return file; // Implement
  }

  Future<void> _uploadToDriveFile(File file, String checksum) async {
    final ref = ProviderContainer();
    final headers = await ref.read(authProvider.notifier).getHeaders();
    final client = http.Client();
    final api = drive.DriveApi(client);
    final media = drive.Media(file.openRead(), file.lengthSync());
    final driveFile = drive.File()
      ..name = file.path.split('/').last
      ..mimeType = 'application/sql'
      ..md5Checksum = checksum;
    await api.files.create(driveFile, uploadMedia: media);
    // Versioning if enabled
  }

  Future<void> _uploadToDrive(Transaction tx) async {
    // Per entry upload, with attachments if included
    // Update drive_meta
  }

  Future<void> restoreFromBackup(BackupRecord record) async {
    // Download, decrypt, preview, integrity check, swap DB
  }

  Future<void> pruneOldBackups() async {
    // Keep last 5 versions, auto prune
  }

  // Local backup: export sqlite/json/csv
  Future<void> localBackup() async {
    // Scheduler with workmanager
  }

  // Register background tasks
  void scheduleBackup() {
    Workmanager().registerPeriodicTask(
      "backup_task",
      "scheduled_backup",
      frequency: const Duration(days: 1), // Based on interval
    );
  }
}
