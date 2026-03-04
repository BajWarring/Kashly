import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme.dart';
import '../../../../core/application/sync_service.dart';

class GoogleDriveScreen extends StatelessWidget {
  const GoogleDriveScreen({super.key});

  String _formatDate(int ms) {
    if (ms == 0) return 'Never';
    return DateFormat('MMM d, yyyy • h:mm a').format(DateTime.fromMillisecondsSinceEpoch(ms));
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder replaces the need for stateful addListener logic
    return ListenableBuilder(
      listenable: SyncService.instance,
      builder: (context, _) {
        final syncServ = SyncService.instance;
        final isError = syncServ.status == SyncStatus.error;
        final isSuccess = syncServ.status == SyncStatus.success;
        
        Color boxColor = isError ? dangerLight : (isSuccess ? successLight : appBg);
        Color borderColor = isError ? danger : (isSuccess ? success : borderCol);
        IconData statusIcon = isError ? Icons.error_outline : (isSuccess ? Icons.cloud_done : Icons.cloud_sync);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // --- STATUS DASHBOARD ---
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: boxColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: syncServ.isSyncing 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: accent))
                      : Icon(statusIcon, color: borderColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          syncServ.isSyncing ? 'Syncing securely...' : (isError ? 'Sync Failed' : 'Two-Way Sync Active'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last synced: ${_formatDate(syncServ.lastSyncTime)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (syncServ.isSignedIn)
                    ElevatedButton(
                      onPressed: syncServ.isSyncing ? null : () => syncServ.performTwoWaySync(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: textDark, elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Force Sync', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- ACCOUNT CONTROL ---
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
                    const Text('Enable seamless, conflict-free sync across all your devices using your personal Google Drive.', textAlign: TextAlign.center, style: TextStyle(color: textMuted, fontSize: 13, height: 1.5)),
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
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF1E293B),
                          backgroundImage: syncServ.userPhotoUrl != null ? NetworkImage(syncServ.userPhotoUrl!) : null,
                          child: syncServ.userPhotoUrl == null 
                            ? Text(syncServ.userEmail?.substring(0, 1).toUpperCase() ?? 'G', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))
                            : null,
                        ),
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Storage Used:', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('45.2 MB / 15 GB', style: TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: 0.05, backgroundColor: appBg, valueColor: const AlwaysStoppedAnimation<Color>(accent), borderRadius: BorderRadius.circular(4), minHeight: 6),
                  ],
                ),
              ),
          ],
        );
      }
    );
  }
}
