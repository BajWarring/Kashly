import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme.dart';
import '../../../../core/data/database_helper.dart';

class LocalBackupRestoreScreen extends StatefulWidget {
  const LocalBackupRestoreScreen({super.key});

  @override
  State<LocalBackupRestoreScreen> createState() => _LocalBackupRestoreScreenState();
}

class _LocalBackupRestoreScreenState extends State<LocalBackupRestoreScreen> {
  bool _isLoading = false;
  List<File> _localBackups = [];
  final String _kashlyDirPath = '/storage/emulated/0/Kashly';

  @override
  void initState() {
    super.initState();
    _loadLocalFiles();
  }

  void _showToast(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 11+ uses manageExternalStorage, Android 10 and below uses storage
      if (await Permission.manageExternalStorage.isGranted || await Permission.storage.isGranted) {
        return true;
      }
      
      final statusManage = await Permission.manageExternalStorage.request();
      if (statusManage.isGranted) return true;

      final statusStorage = await Permission.storage.request();
      if (statusStorage.isGranted) return true;
      
      return false;
    }
    return true; // iOS fallback
  }

  Future<void> _loadLocalFiles() async {
    setState(() => _isLoading = true);
    try {
      if (!await _requestPermissions()) {
        _showToast('Storage permission denied', danger);
        return;
      }

      final dir = Directory(_kashlyDirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final List<File> files = dir.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();

      // Sort files by newest first
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      setState(() => _localBackups = files);
    } catch (e) {
      debugPrint("Error loading files: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    try {
      if (!await _requestPermissions()) throw Exception('Permission denied');

      final jsonStr = await DatabaseHelper.instance.exportDatabaseJSON();
      final dir = Directory(_kashlyDirPath);
      if (!await dir.exists()) await dir.create(recursive: true);
      
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/Kashly_Backup_$dateStr.json');
      
      await file.writeAsString(jsonStr);
      _showToast('Backup saved to /Kashly folder!', success);
      await _loadLocalFiles(); // Refresh the list immediately
    } catch (e) {
      _showToast('Export failed. Check permissions.', danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importDataExternal() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        await _restoreFromFile(file);
      }
    } catch (e) {
      _showToast('Import failed. Invalid file.', danger);
    }
  }

  Future<void> _restoreFromFile(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup?', style: TextStyle(color: danger, fontWeight: FontWeight.bold)),
        content: Text('This will overwrite your current app database with the data inside:\n\n${file.path.split('/').last}\n\nAre you sure you want to proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: danger),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Restore', style: TextStyle(color: Colors.white))
          )
        ],
      )
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      String jsonStr = await file.readAsString();
      await DatabaseHelper.instance.restoreDatabaseJSON(jsonStr);
      _showToast('Database Successfully Restored!', success);
    } catch (e) {
      _showToast('Corrupted JSON file. Restore failed.', danger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFile(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File?'),
        content: const Text('Are you sure you want to permanently delete this backup file?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: danger), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.white)))
        ],
      )
    );

    if (confirm == true) {
      await file.delete();
      _showToast('Backup deleted', textMuted);
      _loadLocalFiles();
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Widget _buildFileTile(File file, bool isLast) {
    final fileName = file.path.split('/').last;
    final fileStat = file.statSync();
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(fileStat.modified);
    final sizeStr = _formatSize(fileStat.size);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: appBg, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.folder_zip, color: textMuted, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('$dateStr • $sizeStr', style: const TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: textLight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) {
                  if (val == 'restore') _restoreFromFile(file);
                  if (val == 'share') Share.shareXFiles([XFile(file.path)], text: 'Kashly Backup: $fileName');
                  if (val == 'delete') _deleteFile(file);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'restore', child: Row(children: [Icon(Icons.restore, size: 18, color: accent), SizedBox(width: 12), Text('Restore to App', style: TextStyle(fontWeight: FontWeight.bold, color: accent))])),
                  const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, size: 18, color: textDark), SizedBox(width: 12), Text('Share File', style: TextStyle(fontWeight: FontWeight.w600))])),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: danger), SizedBox(width: 12), Text('Delete', style: TextStyle(color: danger, fontWeight: FontWeight.w600))])),
                ],
              )
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: borderCol, indent: 72),
      ],
    );
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
                      SizedBox(height: 4), Text('Save to /Kashly', style: TextStyle(fontSize: 11, color: textMuted)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: _importDataExternal, borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderCol)),
                  child: const Column(
                    children: [
                      Icon(Icons.upload_file_rounded, color: textDark, size: 28), SizedBox(height: 12),
                      Text('Import Other', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                      SizedBox(height: 4), Text('Select external file', style: TextStyle(fontSize: 11, color: textMuted)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('LOCAL KASHLY FOLDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: textLight, letterSpacing: 1.5)),
            InkWell(
              onTap: _loadLocalFiles,
              child: const Icon(Icons.refresh, size: 18, color: textMuted),
            )
          ],
        ),
        const SizedBox(height: 12),
        
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderCol)),
          child: _localBackups.isEmpty 
            ? const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No backups found in emulated/0/Kashly.', textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontWeight: FontWeight.w600))),
              )
            : Column(
                children: _localBackups.map((file) => _buildFileTile(file, file == _localBackups.last)).toList(),
              ),
        )
      ],
    );
  }
}
