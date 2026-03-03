import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import 'backup_models.dart';
import 'backup_file_tile.dart';

class LocalBackupRestoreScreen extends StatefulWidget {
  const LocalBackupRestoreScreen({super.key});

  @override
  State<LocalBackupRestoreScreen> createState() => _LocalBackupRestoreScreenState();
}

class _LocalBackupRestoreScreenState extends State<LocalBackupRestoreScreen> {
  List<BackupFile> localBackups = [
    BackupFile('Manual_Export_01Mar.zip', '01 Mar 2026, 09:15 AM', '4.1 MB', false),
    BackupFile('Archive_Jan2026.zip', '31 Jan 2026, 05:00 PM', '12.5 MB', false),
  ];

  void _triggerLocalExport() async {
    _showToast('Generating local archive...', textDark);
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    setState(() {
      localBackups.insert(0, BackupFile('Manual_Export_JustNow.zip', 'Just now', '4.3 MB', false));
    });
    _showToast('Saved to device /Downloads folder.', success);
  }

  void _showToast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 60),
      children: [
        // Action Controls
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _triggerLocalExport,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderCol)),
                  child: const Column(
                    children: [
                      Icon(Icons.download_rounded, color: accent, size: 28),
                      SizedBox(height: 12),
                      Text('Export Data', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                      SizedBox(height: 4),
                      Text('Save to device', style: TextStyle(fontSize: 11, color: textMuted)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () {
                  _showToast('Opening File Explorer...', textDark);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderCol)),
                  child: const Column(
                    children: [
                      Icon(Icons.upload_file_rounded, color: textDark, size: 28),
                      SizedBox(height: 12),
                      Text('Import Data', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                      SizedBox(height: 4),
                      Text('Select .zip file', style: TextStyle(fontSize: 11, color: textMuted)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Local Directory
        const Text('LOCAL ARCHIVES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: textLight, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderCol)),
          child: Column(
            children: localBackups.map((file) => BackupFileTile(file: file, isLast: file == localBackups.last)).toList(),
          ),
        )
      ],
    );
  }
}
