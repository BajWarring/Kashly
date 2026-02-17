// UI ONLY

import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _biometrics = false;
  bool _autoBackup = false;
  String _currency = '₹ Indian Rupee';
  String _dateFormat = 'DD MMM YYYY';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        scrolledUnderElevation: 2,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        children: [
          // Profile card
          _ProfileCard(colorScheme: colorScheme),

          const SizedBox(height: 8),

          // Preferences section
          _SectionTitle(label: 'Preferences'),
          _SettingsTile(
            icon: Icons.currency_rupee_rounded,
            title: 'Currency',
            subtitle: _currency,
            colorScheme: colorScheme,
            onTap: () {},
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
          _SettingsTile(
            icon: Icons.calendar_today_outlined,
            title: 'Date Format',
            subtitle: _dateFormat,
            colorScheme: colorScheme,
            onTap: () {},
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
          _SwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Get reminders and alerts',
            value: _notifications,
            colorScheme: colorScheme,
            onChanged: (v) => setState(() => _notifications = v),
          ),
          _SwitchTile(
            icon: Icons.fingerprint_rounded,
            title: 'Biometric Lock',
            subtitle: 'Lock app with fingerprint',
            value: _biometrics,
            colorScheme: colorScheme,
            onChanged: (v) => setState(() => _biometrics = v),
          ),

          _SectionTitle(label: 'Data'),
          _SwitchTile(
            icon: Icons.cloud_upload_outlined,
            title: 'Auto Backup',
            subtitle: 'Backup data automatically',
            value: _autoBackup,
            colorScheme: colorScheme,
            onChanged: (v) => setState(() => _autoBackup = v),
          ),
          _SettingsTile(
            icon: Icons.download_outlined,
            title: 'Import Data',
            subtitle: 'Import from CSV or backup file',
            colorScheme: colorScheme,
            onTap: () {},
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
          _SettingsTile(
            icon: Icons.upload_outlined,
            title: 'Export All Data',
            subtitle: 'Export everything as CSV or PDF',
            colorScheme: colorScheme,
            onTap: () {},
            trailing: const Icon(Icons.chevron_right_rounded),
          ),

          _SectionTitle(label: 'About'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'About CashBook',
            subtitle: 'Version 1.0.0',
            colorScheme: colorScheme,
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'CashBook',
              applicationVersion: '1.0.0',
              applicationIcon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu_book_rounded, color: colorScheme.onPrimaryContainer),
              ),
              children: const [Text('A beautiful cashbook app with Material Design 3.')],
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            colorScheme: colorScheme,
            onTap: () {},
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
          ),

          const SizedBox(height: 16),

          // Sign out
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  icon: const Icon(Icons.logout_rounded, size: 28),
                  title: const Text('Sign Out?'),
                  content: const Text('You will need to log in again to access your data.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Sign Out')),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Profile card ──────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final ColorScheme colorScheme;
  const _ProfileCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        color: colorScheme.primaryContainer.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.primaryContainer),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('U',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onPrimary,
                      )),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text('user@example.com',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            )),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {},
                tooltip: 'Edit Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              )),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon, required this.title, required this.subtitle,
    required this.colorScheme, required this.onTap, this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: colorScheme.onSecondaryContainer),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
      trailing: trailing != null
          ? IconTheme(data: IconThemeData(color: colorScheme.onSurfaceVariant, size: 20), child: trailing!)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

// ── Switch tile ───────────────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ColorScheme colorScheme;
  final void Function(bool) onChanged;

  const _SwitchTile({
    required this.icon, required this.title, required this.subtitle,
    required this.value, required this.colorScheme, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: colorScheme.onSecondaryContainer),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
