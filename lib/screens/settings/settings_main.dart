import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/application/sync_service.dart';
import 'backup_restore/backup_manager_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _buildGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 8), 
          child: Text(
            title, 
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textLight, letterSpacing: 1.2)
          )
        ),
        Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: borderCol)
          ),
          child: Column(children: children),
        )
      ],
    );
  }

  Widget _buildTile(IconData icon, String title, String? subtitle, Color iconCol, Color iconBg, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40, height: 40, 
        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)), 
        child: Icon(icon, color: iconCol, size: 20)
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w500)) : null,
      trailing: const Icon(Icons.chevron_right, color: textLight),
      onTap: onTap ?? () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder ensures this screen rebuilds the exact moment SyncService updates
    return ListenableBuilder(
      listenable: SyncService.instance,
      builder: (context, _) {
        final syncServ = SyncService.instance;

        return ListView(
          padding: const EdgeInsets.only(top: 10, bottom: 100),
          children: [
            _buildGroup('CLOUD BACKUP', [
              if (!syncServ.isSignedIn)
                _buildTile(Icons.cloud, 'Sign in with Google', 'Securely backup to Google Drive', accent, accentLight, onTap: () async {
                  await syncServ.signIn();
                })
              else
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: accent,
                    backgroundImage: syncServ.userPhotoUrl != null ? NetworkImage(syncServ.userPhotoUrl!) : null,
                    child: syncServ.userPhotoUrl == null 
                      ? Text(syncServ.userEmail?.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      : null,
                  ),
                  title: Text(syncServ.userEmail ?? 'Signed In', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                  subtitle: const Text('Google Drive Connected', style: TextStyle(fontSize: 12, color: success, fontWeight: FontWeight.w500)),
                  trailing: TextButton(
                    onPressed: () => syncServ.signOut(),
                    style: TextButton.styleFrom(backgroundColor: appBg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Unlink', style: TextStyle(color: textMuted, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
            ]),
            
            _buildGroup('DATA & ANALYTICS', [
              _buildTile(Icons.save_alt, 'Backup & Restore', null, textMuted, appBg, onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupManagerScreen()));
              }),
              const Divider(height: 1, color: borderCol),
              _buildTile(Icons.bar_chart, 'Reports', null, textMuted, appBg),
            ]),
            
            _buildGroup('PREFERENCES', [
              _buildTile(Icons.palette, 'Appearance', null, textMuted, appBg),
              const Divider(height: 1, color: borderCol),
              _buildTile(Icons.tune, 'Advanced', null, textMuted, appBg),
              const Divider(height: 1, color: borderCol),
              _buildTile(Icons.info_outline, 'About', null, textMuted, appBg),
            ]),
            
            const Center(
              child: Text(
                'Version 2.0.4', 
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textLight, letterSpacing: 1.5)
              )
            )
          ],
        );
      },
    );
  }
}
