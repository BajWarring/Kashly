import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import 'google_drive_screen.dart';
import 'local_backup_restore_screen.dart';
import '../../../../core/sync/sync_service.dart';

class BackupManagerScreen extends StatefulWidget {
  const BackupManagerScreen({super.key});

  @override
  State<BackupManagerScreen> createState() => _BackupManagerScreenState();
}

class _BackupManagerScreenState extends State<BackupManagerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initialize Sync Engine when opening settings
    SyncService.instance.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('Backup & Restore'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(color: borderCol.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderCol)),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: accent, unselectedLabelColor: textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.cloud_queue, size: 18), SizedBox(width: 8), Text('Google Drive')])),
                Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.folder_outlined, size: 18), SizedBox(width: 8), Text('Local Device')])),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [ GoogleDriveScreen(), LocalBackupRestoreScreen() ],
            ),
          )
        ],
      ),
    );
  }
}
