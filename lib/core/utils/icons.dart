import 'package:flutter/material.dart';

Icon getSyncStatusIcon(String status) {
  switch (status) {
    case 'synced':
      return const Icon(Icons.check_circle);
    case 'pending_upload':
      return const Icon(Icons.cloud_upload);
    case 'modified_since_upload':
      return const Icon(Icons.edit);
    case 'upload_failed':
      return const Icon(Icons.cloud_off);
    case 'conflict':
      return const Icon(Icons.warning);
    default:
      return const Icon(Icons.help_outline);
  }
}

Icon getDriveFileIcon(String status) {
  switch (status) {
    case 'drive_ok':
      return const Icon(Icons.drive_file_move);
    case 'drive_versioned':
      return const Icon(Icons.history);
    case 'drive_missing':
      return const Icon(Icons.help_outline);
    default:
      return const Icon(Icons.help_outline);
  }
}

// Usage: In UI, e.g., trailing: getSyncStatusIcon(transaction.syncStatus.name)
