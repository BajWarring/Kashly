import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/theme.dart';
import '../../../../core/data/database_helper.dart';

class LocalBackupRestoreScreen extends StatefulWidget {
  const LocalBackupRestoreScreen({super.key});

  @override
  State<LocalBackupRestoreScreen> createState() => _LocalBackupRestoreScreenState();
}

class _LocalBackupRestoreScreenState extends State<LocalBackupRestoreScreen> {
  bool _isLoading = false;

  void _showToast(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    try {
      final jsonStr = await DatabaseHelper.instance.exportDatabaseJSON();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/Kashly_Manual_Backup.json');
      await file.writeAsString(jsonStr);
      
      await Share.shareXFiles([XFile(file.path)], text: 'Kashly App Backup');
    } catch (e) {
      _showToast('Export failed', danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);
        File file = File(result.files.single.path!);
        String jsonStr = await file.readAsString();
        
        await DatabaseHelper.instance.restoreDatabaseJSON(jsonStr);
        _showToast('Data Successfully Restored!', success);
      }
    } catch (e) {
      _showToast('Import failed. Invalid file.', danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 60),
      children: [
        if (_isLoading)
          const Padding(padding: EdgeInsets.only(bottom: 20), child: Center(child: CircularProgressIndicator(color: accent))),

        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _exportData, borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderCol)),
                  child: const Column(
                    children: [
                      Icon(Icons.download_rounded, color: accent, size: 28), SizedBox(height: 12),
                      Text('Export Data', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                      SizedBox(height: 4), Text('Share JSON File', style: TextStyle(fontSize: 11, color: textMuted)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: _importData, borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderCol)),
                  child: const Column(
                    children: [
                      Icon(Icons.upload_file_rounded, color: textDark, size: 28), SizedBox(height: 12),
                      Text('Import Data', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                      SizedBox(height: 4), Text('Select JSON File', style: TextStyle(fontSize: 11, color: textMuted)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
