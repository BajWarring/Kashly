import 'package:flutter/material.dart';
import 'package:kashly/domain/entities/transaction.dart';
import 'package:kashly/domain/entities/cashbook.dart';

Widget getSyncStatusIcon(String status, {double size = 20}) {
  switch (status) {
    case 'synced':
      return Icon(Icons.check_circle, color: Colors.green, size: size);
    case 'pending_upload':
    case 'pending':
      return Icon(Icons.cloud_upload, color: Colors.orange, size: size);
    case 'modified_since_upload':
      return Icon(Icons.edit_note, color: Colors.amber, size: size);
    case 'upload_failed':
    case 'error':
      return Icon(Icons.cloud_off, color: Colors.red, size: size);
    case 'conflict':
      return Icon(Icons.warning_amber, color: Colors.deepOrange, size: size);
    default:
      return Icon(Icons.help_outline, color: Colors.grey, size: size);
  }
}

Widget getSyncStatusIconFromEnum(TransactionSyncStatus status, {double size = 20}) {
  switch (status) {
    case TransactionSyncStatus.synced:
      return Icon(Icons.check_circle, color: Colors.green, size: size);
    case TransactionSyncStatus.pending:
      return Icon(Icons.cloud_upload, color: Colors.orange, size: size);
    case TransactionSyncStatus.error:
      return Icon(Icons.cloud_off, color: Colors.red, size: size);
    case TransactionSyncStatus.conflict:
      return Icon(Icons.warning_amber, color: Colors.deepOrange, size: size);
  }
}

Widget getCashbookSyncIcon(SyncStatus status, {double size = 20}) {
  switch (status) {
    case SyncStatus.synced:
      return Icon(Icons.check_circle, color: Colors.green, size: size);
    case SyncStatus.pending:
      return Icon(Icons.cloud_upload, color: Colors.orange, size: size);
    case SyncStatus.error:
      return Icon(Icons.cloud_off, color: Colors.red, size: size);
    case SyncStatus.conflict:
      return Icon(Icons.warning_amber, color: Colors.deepOrange, size: size);
  }
}

Widget getDriveFileIcon(String status, {double size = 20}) {
  switch (status) {
    case 'drive_ok':
      return Icon(Icons.drive_file_move, color: Colors.blue, size: size);
    case 'drive_versioned':
      return Icon(Icons.history, color: Colors.teal, size: size);
    case 'drive_missing':
      return Icon(Icons.help_outline, color: Colors.grey, size: size);
    default:
      return Icon(Icons.help_outline, color: Colors.grey, size: size);
  }
}

Color getSyncStatusColor(String status) {
  switch (status) {
    case 'synced':
      return Colors.green;
    case 'pending_upload':
    case 'pending':
      return Colors.orange;
    case 'modified_since_upload':
      return Colors.amber;
    case 'upload_failed':
    case 'error':
      return Colors.red;
    case 'conflict':
      return Colors.deepOrange;
    default:
      return Colors.grey;
  }
}

String getSyncStatusLabel(String status) {
  switch (status) {
    case 'synced':
      return 'Synced';
    case 'pending_upload':
    case 'pending':
      return 'Pending Upload';
    case 'modified_since_upload':
      return 'Modified';
    case 'upload_failed':
    case 'error':
      return 'Upload Failed';
    case 'conflict':
      return 'Conflict';
    default:
      return 'Unknown';
  }
}
