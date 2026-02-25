import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashly/core/di/providers.dart';
import 'package:kashly/ux_and_ui_elements/dialogs.dart'; // Integrated dialogs
import 'package:kashly/core/utils/icons.dart'; // Integrated icons
import 'package:kashly/reports/backup_report.dart'; // Integrated reports
import 'package:kashly/domain/entities/backup_record.dart'; // Assume fetch backups

class BackupCenterScreen extends ConsumerWidget {
  const BackupCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backups = <BackupRecord>[]; // Assume fetched

    return Scaffold(
      appBar: AppBar(title: const Text('Backup Center')),
      body: ListView(
        children: [
          // Drive status banner
          Card(child: Row(children: [const Text('Drive Connected'), getDriveFileIcon('drive_ok')])),
          // Local storage usage bar
          LinearProgressIndicator(value: 0.5), // Calculate usage
          // Non uploaded entries list
          ExpansionTile(
            title: const Text('Non Uploaded Entries'),
            children: [
              // Summary counts
              const Text('Pending: 5'),
              // Group by cashbook
              ListView.builder(
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return ListTile(title: const Text('Entry'), trailing: getSyncStatusIcon('pending_upload'));
                },
              ),
              // Batch actions: upload selected, update, ignore, mark local
              Row(
                children: [
                  ElevatedButton(onPressed: () async {
                    if (await showOverwriteDriveFileConfirmation(context) == true) {
                      // Upload
                    }
                  }, child: const Text('Upload Selected')), // Use dialog
                  // Other buttons
                ],
              ),
            ],
          ),
          // Backup history timeline
          ListView.builder(
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return ListTile(title: const Text('Backup at date'), trailing: getSyncStatusIcon('synced'));
            },
          ),
          // Quick backup buttons
          ElevatedButton(onPressed: () async {
            if (await showBackupNowConfirmation(context) == true) {
              ref.read(backupServiceProvider).manualBackup();
            }
          }, child: const Text('Backup Now')), // Use dialog
          // Conflict resolution queue
          ExpansionTile(
            title: const Text('Conflicts'),
            children: [
              // List conflicts with preview diff UI, merge
              ListTile(
                title: const Text('Conflict 1'),
                trailing: ElevatedButton(onPressed: () async {
                  final resolution = await showConflictResolutionModal(context, 'Diff example');
                  if (resolution != null) {
                    // Resolve based on choice
                  }
                }, child: const Text('Resolve')), // Use modal
              ),
            ],
          ),
          // Drive file actions: open, share, download, delete
          // Add report buttons
          ElevatedButton(onPressed: () async {
            await generateBackupReportPdf(backups);
            // Show success
          }, child: const Text('Generate PDF Report')),
          ElevatedButton(onPressed: () async {
            await exportBackupManifest(backups);
            // Show success
          }, child: const Text('Export Manifest CSV')),
        ],
      ),
    );
  }
}
