import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashly/core/di/providers.dart';

class BackupCenterScreen extends ConsumerWidget {
  const BackupCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup Center')),
      body: ListView(
        children: [
          // Drive status banner
          Card(child: const Padding(padding: EdgeInsets.all(8), child: Text('Drive Connected'))),
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
                  return ListTile(title: const Text('Entry'));
                },
              ),
              // Batch actions: upload selected, update, ignore, mark local
              Row(
                children: [
                  ElevatedButton(onPressed: () {}, child: const Text('Upload Selected')),
                  // Other buttons
                ],
              ),
            ],
          ),
          // Backup history timeline
          ListView.builder(
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return ListTile(title: const Text('Backup at date'));
            },
          ),
          // Quick backup buttons
          ElevatedButton(onPressed: ref.read(backupServiceProvider).manualBackup, child: const Text('Backup Now')),
          // Conflict resolution queue
          ExpansionTile(
            title: const Text('Conflicts'),
            children: [
              // List conflicts with preview diff UI, merge
              ListTile(title: const Text('Conflict 1'), trailing: ElevatedButton(onPressed: () {}, child: const Text('Resolve'))),
            ],
          ),
          // Drive file actions: open, share, download, delete
        ],
      ),
    );
  }
}
