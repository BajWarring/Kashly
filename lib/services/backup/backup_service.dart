import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import 'package:kashly/domain/entities/backup_record.dart';
import 'package:kashly/domain/entities/transaction.dart';
import 'package:kashly/data/datasources/local_datasource.dart';
import 'package:kashly/core/error/exceptions.dart';
import 'package:kashly/core/utils/utils.dart';
import 'package:kashly/ux_and_ui_elements/dialogs.dart';

class BackupService {
  final LocalDatasource datasource;
  final Future<Map<String, String>> Function() getAuthHeaders;
  final _logger = Logger();
  final _uuid = const Uuid();

  BackupService({
    required this.datasource,
    required this.getAuthHeaders,
  });

  Future<void> performScheduledBackup() async {
    final settings = await datasource.getBackupSettings();
    if (!settings.autoBackupEnabled) return;
    await incrementalBackup();
  }

  Future<void> manualBackup([BuildContext? context]) async {
    if (context != null && context.mounted) {
      final confirmed = await showBackupNowConfirmation(context);
      if (confirmed != true) return;
    }
    await incrementalBackup();
  }

  Future<void> incrementalBackup() async {
    final headers = await getAuthHeaders();
    if (headers.isEmpty) {
      _logger.w('Not signed in – skipping Drive backup');
      return;
    }

    final nonUploaded = await datasource.getNonUploadedTransactions();
    final modified = await datasource.getModifiedTransactions();
    final toProcess = <Transaction>{...nonUploaded, ...modified};
    if (toProcess.isEmpty) return;

    int success = 0, failed = 0;
    final cashbookIds = <String>{};

    for (final tx in toProcess) {
      try {
        final fileId = await _uploadToDrive(tx, headers);
        await datasource.updateTransaction(tx.copyWith(
          syncStatus: TransactionSyncStatus.synced,
          driveMeta: tx.driveMeta.copyWith(
            fileId: fileId,
            isUploaded: true,
            isModifiedSinceUpload: false,
            lastSyncedAt: DateTime.now(),
            version: '${(int.tryParse(tx.driveMeta.version ?? '0') ?? 0) + 1}',
          ),
        ));
        cashbookIds.add(tx.cashbookId);
        success++;
      } catch (e) {
        _logger.e('Upload failed for ${tx.id}: $e');
        await datasource.updateTransaction(tx.copyWith(syncStatus: TransactionSyncStatus.error));
        failed++;
      }
    }

    await datasource.insertBackupRecord(BackupRecord(
      id: _uuid.v4(),
      type: BackupType.googleDrive,
      cashbookIds: cashbookIds.toList(),
      transactionCount: success,
      fileName: 'incremental_${DateTime.now().millisecondsSinceEpoch}.json',
      fileSizeBytes: success * 512,
      createdAt: DateTime.now(),
      status: failed == 0
          ? BackupStatus.success
          : (success > 0 ? BackupStatus.partial : BackupStatus.failed),
      notes: failed > 0 ? '$failed failed' : null,
    ));
  }

  Future<File> fullDbBackup() async {
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/kashly_backup_$ts.json');

    final cashbooks = await datasource.getCashbooks();
    final allTx = <Transaction>[];
    for (final cb in cashbooks) {
      allTx.addAll(await datasource.getTransactions(cb.id));
    }

    await file.writeAsString(
      '{"version":"1","cashbooks":${cashbooks.length},"transactions":${allTx.length},'
      '"exported_at":"${DateTime.now().toIso8601String()}"}',
    );
    final checksum = calculateMd5(file);

    await datasource.insertBackupRecord(BackupRecord(
      id: _uuid.v4(),
      type: BackupType.local,
      cashbookIds: cashbooks.map((c) => c.id).toList(),
      transactionCount: allTx.length,
      fileName: file.path.split('/').last,
      fileSizeBytes: file.lengthSync(),
      createdAt: DateTime.now(),
      status: BackupStatus.success,
      checksum: checksum,
    ));

    return file;
  }

  Future<void> restoreFromBackup(BackupRecord record, BuildContext context) async {
    final settings = await datasource.getBackupSettings();
    if (settings.encryptionEnabled && context.mounted) {
      final pw = await showEncryptionPasswordPrompt(context);
      if (pw == null) return;
    }
    if (context.mounted) {
      await showRestorePreviewModal(
        context,
        'Backup: ${record.fileName}\nDate: ${record.createdAt}\n'
        'Transactions: ${record.transactionCount}\nStatus: ${record.status.name}',
      );
    }
  }

  Future<String> _uploadToDrive(Transaction tx, Map<String, String> headers) async {
    final client = _AuthClient(headers);
    final api = drive.DriveApi(client);
    final bytes = tx.toJson().toString().codeUnits;
    final fileName = 'kashly_tx_${tx.id}.json';

    if (tx.driveMeta.fileId != null && tx.driveMeta.fileId!.isNotEmpty) {
      final res = await api.files.update(
        drive.File()..name = fileName,
        tx.driveMeta.fileId!,
        uploadMedia: drive.Media(Stream.fromIterable([bytes]), bytes.length),
      );
      return res.id ?? tx.driveMeta.fileId!;
    } else {
      final res = await api.files.create(
        drive.File()
          ..name = fileName
          ..mimeType = 'application/json'
          ..appProperties = {'kashly_tx_id': tx.id},
        uploadMedia: drive.Media(Stream.fromIterable([bytes]), bytes.length),
      );
      return res.id ?? '';
    }
  }

  void scheduleBackup({Duration frequency = const Duration(days: 1)}) {
    Workmanager().registerPeriodicTask(
      'kashly_backup_task',
      'scheduled_backup',
      frequency: frequency,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  void cancelScheduledBackup() {
    Workmanager().cancelByUniqueName('kashly_backup_task');
  }

  Future<void> pruneOldBackups() async {}
}

class _AuthClient extends http.BaseClient {
  final Map<String, String> _h;
  final http.Client _inner = http.Client();
  _AuthClient(this._h);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_h);
    return _inner.send(request);
  }
}
