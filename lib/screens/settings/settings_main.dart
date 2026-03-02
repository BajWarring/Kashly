import 'package:flutter/material.dart';
import '../../core/theme.dart';

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

  Widget _buildTile(IconData icon, String title, String? subtitle, Color iconCol, Color iconBg) {
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
      onTap: () {
        // Future sub-pages will go here
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 10, bottom: 100),
      children: [
        _buildGroup('CLOUD BACKUP', [
          _buildTile(Icons.cloud, 'Sign in with Google', 'Securely backup to Google Drive', accent, accentLight),
        ]),
        
        _buildGroup('DATA & ANALYTICS', [
          _buildTile(Icons.save_alt, 'Backup & Restore', null, textMuted, appBg),
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
  }
}
