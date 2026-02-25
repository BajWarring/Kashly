import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashly/domain/entities/backup_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Sections
          ListTile(title: const Text('Account')),
          ExpansionTile(
            title: const Text('Backup and Restore'),
            children: [
              // Summary card
              Card(
                child: Column(
                  children: [
                    const Text('Last Local: date'),
                    const Text('Last Drive: date'),
                    const Text('Next Scheduled: date'),
                    const Text('Storage Used: 100MB'),
                  ],
                ),
              ),
              // Options
              SwitchListTile(title: const Text('Auto Backup'), value: true, onChanged: (v) {}),
              DropdownButton<String>(
                value: 'daily',
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  // Weekly, monthly, custom
                ],
                onChanged: (v) {},
              ),
              // Select drive folder, local path, max backups, include attachments, encrypt, biometric, notify, etc.
              ElevatedButton(onPressed: () {}, child: const Text('Select Drive Folder')),
              // ... Add all options as switches/buttons
              ElevatedButton(onPressed: () {}, child: const Text('Manual Backup Now')),
              ElevatedButton(onPressed: () {}, child: const Text('Manual Restore')),
            ],
          ),
          ListTile(title: const Text('Appearance')),
          ListTile(title: const Text('Currency')),
          ListTile(title: const Text('Notifications')),
          ListTile(title: const Text('Data Management')),
          ExpansionTile(
            title: const Text('Advanced'),
            children: [
              ElevatedButton(onPressed: () {}, child: const Text('Export Debug Logs')),
              ElevatedButton(onPressed: () {}, child: const Text('Force Resync')),
              ElevatedButton(onPressed: () {}, child: const Text('Clear Local Cache')),
              ElevatedButton(onPressed: () {}, child: const Text('SQLite Vacuum')),
              // Developer options: switches for show_sql, simulate_network
            ],
          ),
        ],
      ),
    );
  }
}
