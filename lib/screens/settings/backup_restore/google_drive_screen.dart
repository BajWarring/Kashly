import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import 'backup_models.dart';
import 'backup_file_tile.dart';

class GoogleDriveScreen extends StatefulWidget {
  const GoogleDriveScreen({super.key});

  @override
  State<GoogleDriveScreen> createState() => _GoogleDriveScreenState();
}

class _GoogleDriveScreenState extends State<GoogleDriveScreen> {
  bool _isGoogleSignedIn = false;
  bool _isSyncing = false;
  
  List<PendingSync> pendingItems = [
    PendingSync('Main Business', 3),
    PendingSync('Dubai Trip', 1),
  ];
  
  List<BackupFile> cloudBackups = [
    BackupFile('Kashly_Cloud_Sync_03Mar.bak', 'Today, 08:30 AM', '4.2 MB', true),
    BackupFile('Kashly_Cloud_Sync_28Feb.bak', '28 Feb 2026, 11:00 PM', '3.9 MB', true),
  ];

  void _triggerCloudSync() async {
    if (!_isGoogleSignedIn) {
      _showToast('Please sign in to Google Drive first.', danger);
      return;
    }
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    setState(() {
      _isSyncing = false;
      pendingItems.clear(); 
      cloudBackups.insert(0, BackupFile('Kashly_Cloud_Sync_JustNow.bak', 'Just now', '4.3 MB', true));
    });
    _showToast('All data successfully synced to Drive.', success);
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
    bool hasPending = pendingItems.isNotEmpty;
    
    return ListView(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 60),
      children: [
        // --- 1. CLOUD SYNC HEALTH DASHBOARD ---
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: hasPending ? warningLight : success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: hasPending ? warning.withValues(alpha: 0.3) : success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasPending ? warning.withValues(alpha: 0.2) : success.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: _isSyncing 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))
                  : Icon(hasPending ? Icons.cloud_sync : Icons.cloud_done, color: hasPending ? warning : success, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPending ? 'Unsaved Changes' : 'Everything is Up to Date',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: hasPending ? const Color(0xFF92400E) : const Color(0xFF065F46)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasPending ? '${pendingItems.fold(0, (sum, item) => sum + item.pendingEntries)} entries waiting to be backed up.' : 'Your data is securely backed up to the cloud.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: hasPending ? const Color(0xFFB45309) : const Color(0xFF047857)),
                    ),
                  ],
                ),
              ),
              if (hasPending)
                ElevatedButton(
                  onPressed: _isSyncing ? null : _triggerCloudSync,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: warning,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  child: const Text('Sync', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
            ],
          ),
        ),
        const SizedBox(height: 16),

        // --- 2. PENDING SYNCS HORIZONTAL LIST ---
        if (hasPending) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: textMuted),
                const SizedBox(width: 8),
                const Text('WAITING FOR CLOUD UPLOAD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: textMuted, letterSpacing: 1.5)),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pendingItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = pendingItems[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderCol)),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      const Icon(Icons.book, size: 14, color: textMuted),
                      const SizedBox(width: 8),
                      Text(item.bookName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: warningLight, borderRadius: BorderRadius.circular(6)),
                        child: Text('+${item.pendingEntries}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: warning)),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // --- 3. ACCOUNT STATUS ---
        if (!_isGoogleSignedIn)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderCol)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(width: 64, height: 64, decoration: const BoxDecoration(color: accentLight, shape: BoxShape.circle), child: const Icon(Icons.add_to_drive, size: 32, color: accent)),
                const SizedBox(height: 16),
                const Text('Connect Cloud Storage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                const SizedBox(height: 8),
                const Text('Securely backup your cashbooks to Google Drive to enable seamless syncing.', textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 13, height: 1.5)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _isGoogleSignedIn = true),
                    icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 28),
                    label: const Text('Sign in with Google', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  ),
                )
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderCol)),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(width: 40, height: 40, decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle), child: const Center(child: Text('B', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)))),
                    const SizedBox(width: 16),
                    const Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('business@kashly.app', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                        Text('Google Drive Connected', style: TextStyle(fontSize: 12, color: success, fontWeight: FontWeight.w500)),
                      ],
                    )),
                    TextButton(
                      onPressed: () => setState(() => _isGoogleSignedIn = false),
                      style: TextButton.styleFrom(backgroundColor: appBg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Unlink', style: TextStyle(color: textMuted, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: borderCol)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Storage Used:', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                    const Text('45.2 MB / 15 GB', style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: 0.05, backgroundColor: appBg, valueColor: const AlwaysStoppedAnimation<Color>(accent), borderRadius: BorderRadius.circular(4), minHeight: 6),
              ],
            ),
          ),
        
        const SizedBox(height: 32),
        
        // --- 4. CLOUD DIRECTORY ---
        if (_isGoogleSignedIn) ...[
          const Text('DRIVE DIRECTORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: textLight, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderCol)),
            child: Column(
              children: cloudBackups.map((file) => BackupFileTile(file: file, isLast: file == cloudBackups.last)).toList(),
            ),
          )
        ]
      ],
    );
  }
}
