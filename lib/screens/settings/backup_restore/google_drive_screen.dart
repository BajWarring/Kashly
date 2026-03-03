import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme.dart';
import '../../../../core/sync/sync_service.dart';

class GoogleDriveScreen extends StatefulWidget {
  const GoogleDriveScreen({super.key});

  @override
  State<GoogleDriveScreen> createState() => _GoogleDriveScreenState();
}

class _GoogleDriveScreenState extends State<GoogleDriveScreen> {
  @override
  void initState() {
    super.initState();
    SyncService.instance.addListener(_onSyncChanged);
  }

  @override
  void dispose() {
    SyncService.instance.removeListener(_onSyncChanged);
    super.dispose();
  }

  void _onSyncChanged() {
    if (mounted) setState(() {});
  }

  String _formatDate(int ms) {
    if (ms == 0) return 'Never';
    return DateFormat('MMM d, yyyy • h:mm a').format(DateTime.fromMillisecondsSinceEpoch(ms));
  }

  @override
  Widget build(BuildContext context) {
    final syncServ = SyncService.instance;
    final bool hasPending = syncServ.pendingChanges > 0;
    
    return ListView(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 60),
      children: [
        
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
                child: syncServ.isSyncing 
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
                      hasPending ? '${syncServ.pendingChanges} edits waiting to be synced.' : 'Your data is securely backed up to the cloud.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: hasPending ? const Color(0xFFB45309) : const Color(0xFF047857)),
                    ),
                  ],
                ),
              ),
              if (hasPending && syncServ.isSignedIn)
                ElevatedButton(
                  onPressed: syncServ.isSyncing ? null : () => syncServ.performSync(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: warning, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  child: const Text('Sync', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (!syncServ.isSignedIn)
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
                const Text('Securely sync your cashbooks across devices automatically via Google Drive.', textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 13, height: 1.5)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => syncServ.signIn(),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 40, height: 40, decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle), child: Center(child: Text(syncServ.userEmail?.substring(0,1).toUpperCase() ?? 'G', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)))),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(syncServ.userEmail ?? 'Signed In', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                        const Text('Google Drive Connected', style: TextStyle(fontSize: 12, color: success, fontWeight: FontWeight.w500)),
                      ],
                    )),
                    TextButton(
                      onPressed: () => syncServ.signOut(),
                      style: TextButton.styleFrom(backgroundColor: appBg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Unlink', style: TextStyle(color: textMuted, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: borderCol)),
                Text('Last Synced: ${_formatDate(syncServ.lastSyncTime)}', style: const TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }
}
