// UI ONLY

import 'package:flutter/material.dart';
import '../state/backup_state.dart';
import '../widgets/backup_status_icon.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _biometrics = false;
  String _currency = '₹ Indian Rupee';
  String _dateFormat = 'DD MMM YYYY';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backupState = BackupStateProvider.of(context);
    final backupInfo = backupState.info;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        scrolledUnderElevation: 2,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [const BackupStatusIcon()],
      ),
      body: ListView(
        children: [
          // ── Profile card ──────────────────────────────────────────────
          _ProfileCard(colorScheme: colorScheme),

          // ── Backup section ────────────────────────────────────────────
          _SectionTitle(label: 'Backup & Sync'),
          _BackupStatusCard(
            backupInfo: backupInfo,
            backupState: backupState,
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 4),
          _SwitchTile(
            icon: Icons.cloud_upload_outlined,
            title: 'Auto Backup',
            subtitle: 'Automatically backup after changes',
            value: backupInfo.autoBackupEnabled,
            colorScheme: colorScheme,
            onChanged: (v) => backupState.toggleAutoBackup(v),
          ),
          _SettingsTile(
            icon: Icons.restore_rounded,
            title: 'Restore from Backup',
            subtitle: 'Replace local data with cloud backup',
            colorScheme: colorScheme,
            onTap: () => _showRestoreDialog(context, backupState),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),

          // ── Backup history ────────────────────────────────────────────
          if (backupInfo.history.isNotEmpty) ...[
            _SectionTitle(label: 'Backup History'),
            _BackupHistoryCard(
              history: backupInfo.history,
              colorScheme: colorScheme,
              onRestore: (entry) => _showRestoreSpecificDialog(context, entry),
            ),
          ],

          // ── Preferences ───────────────────────────────────────────────
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

          // ── Data ──────────────────────────────────────────────────────
          _SectionTitle(label: 'Data'),
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

          // ── About ─────────────────────────────────────────────────────
          _SectionTitle(label: 'About'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'About CashBook',
            subtitle: 'Version 1.0.0 · Your data is automatically backed up securely.',
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
              children: const [
                Text('A beautiful cashbook app with Material Design 3.\n\nYour data is automatically backed up securely to Google Drive.'),
              ],
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

  void _showRestoreDialog(BuildContext context, BackupStateProviderState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.restore_rounded, size: 28),
        title: const Text('Restore Latest Backup?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will replace all current local data with the latest cloud backup.\n\nThis action cannot be undone.'),
            if (state.info.lastBackupTime != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_done_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Latest: ${_fmtDate(state.info.lastBackupTime!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Restoring from backup…'), behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showRestoreSpecificDialog(BuildContext context, BackupHistoryEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.history_rounded, size: 28),
        title: const Text('Restore this backup?'),
        content: Text('Restore backup from ${_fmtDate(entry.timestamp)}?\n\nSize: ${entry.size}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Restoring backup from ${_fmtDate(entry.timestamp)}…'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}, $h:$min ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}

// ── Backup status card ────────────────────────────────────────────────────

class _BackupStatusCard extends StatelessWidget {
  final BackupInfo backupInfo;
  final BackupStateProviderState backupState;
  final ColorScheme colorScheme;

  const _BackupStatusCard({
    required this.backupInfo,
    required this.backupState,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isOk = backupInfo.status == BackupStatus.synced ||
        backupInfo.status == BackupStatus.syncing;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isOk
                          ? const Color(0xFF1B8A3A).withOpacity(0.1)
                          : colorScheme.errorContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isOk ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      size: 20,
                      color: isOk ? const Color(0xFF1B8A3A) : colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(backupInfo.statusLabel,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                )),
                        if (backupInfo.connectedAccount != null)
                          Text(
                            backupInfo.connectedAccount!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Error banner
              if (backupInfo.status == BackupStatus.error &&
                  backupInfo.errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 15, color: colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          backupInfo.errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  _MiniStat(
                    label: 'Last backup',
                    value: backupInfo.lastBackupTime != null
                        ? _relTime(backupInfo.lastBackupTime!)
                        : 'Never',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(width: 8),
                  _MiniStat(
                    label: 'Backup size',
                    value: backupInfo.lastBackupSize ?? '—',
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(width: 8),
                  _MiniStat(
                    label: 'Saved copies',
                    value: '${backupInfo.history.length}/5',
                    colorScheme: colorScheme,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Backup now button
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text('Backup Now',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    backupState.triggerManualBackup();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Backup started…'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _MiniStat({required this.label, required this.value, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Backup history card ────────────────────────────────────────────────────

class _BackupHistoryCard extends StatelessWidget {
  final List<BackupHistoryEntry> history;
  final ColorScheme colorScheme;
  final void Function(BackupHistoryEntry) onRestore;

  const _BackupHistoryCard({
    required this.history,
    required this.colorScheme,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        margin: EdgeInsets.zero,
        child: Column(
          children: history.asMap().entries.map((e) {
            final isLast = e.key == history.length - 1;
            final entry = e.value;
            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: entry.isLatest
                          ? const Color(0xFF1B8A3A).withOpacity(0.12)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      entry.isLatest
                          ? Icons.cloud_done_rounded
                          : Icons.cloud_outlined,
                      size: 18,
                      color: entry.isLatest
                          ? const Color(0xFF1B8A3A)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        _fmtDate(entry.timestamp),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (entry.isLatest) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B8A3A).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Latest',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF1B8A3A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    entry.size,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.restore_rounded,
                        size: 20, color: colorScheme.primary),
                    tooltip: 'Restore this backup',
                    onPressed: () => onRestore(entry),
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: colorScheme.outlineVariant.withOpacity(0.4),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}, $h:$min ${dt.hour >= 12 ? 'PM' : 'AM'}';
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
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                child: Center(
                  child: Text('U',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colorScheme.onPrimary)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text('user@gmail.com',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable components ────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              )),
    );
  }
}

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
      subtitle: Text(subtitle,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
      trailing: trailing != null
          ? IconTheme(data: IconThemeData(color: colorScheme.onSurfaceVariant, size: 20), child: trailing!)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

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
      subtitle: Text(subtitle,
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
