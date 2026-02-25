import 'package:flutter/material.dart';

Future<bool?> showBackupNowConfirmation(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm Backup'),
      content: const Text('Do you want to backup now?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Backup')),
      ],
    ),
  );
}

Future<bool?> showOverwriteDriveFileConfirmation(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Overwrite File'),
      content: const Text('This will overwrite the existing file on Drive. Proceed?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Overwrite')),
      ],
    ),
  );
}

Future<void> showRestorePreviewModal(BuildContext context, String previewContent) async {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Restore Preview'),
      content: Text(previewContent), // Show sample transactions, etc.
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    ),
  );
}

Future<String?> showConflictResolutionModal(BuildContext context, String diff) async {
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Resolve Conflict'),
      content: Text('Diff: $diff\nChoose resolution:'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, 'local'), child: const Text('Use Local')),
        TextButton(onPressed: () => Navigator.pop(context, 'remote'), child: const Text('Use Remote')),
        TextButton(onPressed: () => Navigator.pop(context, 'merge'), child: const Text('Merge')),
      ],
    ),
  );
}

Future<String?> showEncryptionPasswordPrompt(BuildContext context) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Enter Encryption Password'),
      content: TextField(
        controller: controller,
        obscureText: true,
        decoration: const InputDecoration(hintText: 'Password'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Submit')),
      ],
    ),
  );
}

// Integrate these in features, e.g., in BackupService: if (await showBackupNowConfirmation(context) == true) { ... }
