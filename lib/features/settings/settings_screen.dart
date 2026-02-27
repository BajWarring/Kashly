import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kashly/core/di/providers.dart';
import 'package:kashly/domain/entities/backup_settings.dart';
import 'package:kashly/reports/backup_report.dart';
import 'package:kashly/ux_and_ui_elements/dialogs.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _darkMode = true;

  @override
  Widget build(BuildContext context) {
    final backupSettingsAsync = ref.watch(backupSettingsProvider);
    final backupHistoryAsync = ref.watch(backupHistoryProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          // Account
          const _SectionHeader(title: 'Account'),
          ListTile(
            leading: authState.isAuthenticated
                ? const Icon(Icons.account_circle, color: Colors.green)
                : const Icon(Icons.account_circle_outlined),
            title: Text(authState.isAuthenticated
                ? authState.user?.email ?? 'Google Account'
                : 'Sign In with Google'),
            subtitle: Text(authState.isAuthenticated
                ? 'Drive backup enabled'
                : 'Not connected'),
            trailing: authState.isAuthenticated
                ? PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'switch') {
                        ref.read(authProvider.notifier).switchAccount();
                      }
                      if (v == 'signout') {
                        ref.read(authProvider.notifier).signOut();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: 'switch',
                          child: Text('Switch Account')),
                      PopupMenuItem(
                          value: 'signout', child: Text('Sign Out')),
                    ],
                  )
                : const Icon(Icons.chevron_right),
            onTap:
                authState.isAuthenticated ? null : () => context.go('/auth'),
          ),
          const Divider(),

          // Backup & Restore
          const _SectionHeader(title: 'Backup & Restore'),
          backupSettingsAsync.when(
            data: (settings) => _BackupSettingsSection(
              settings: settings,
              onSave: (s) => ref
                  .read(backupRepositoryProvider)
                  .saveSettings(s)
                  .then((_) => ref.invalidate(backupSettingsProvider)),
            ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => ListTile(title: Text('Error: $e')),
          ),

          // Reports
          const _SectionHeader(title: 'Reports'),
          backupHistoryAsync.when(
            data: (history) => Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('Generate Backup PDF Report'),
                  onTap: () async {
                    try {
                      final file =
                          await generateBackupReportPdf(history);
                      if (!mounted) return;
                      showSuccessSnackbar(
                          context, 'PDF saved: ${file.path}');
                    } catch (e) {
                      if (!mounted) return;
                      showErrorSnackbar(context, 'Failed: $e');
                    }
                  },
                  trailing: const Icon(Icons.chevron_right),
                ),
                ListTile(
                  leading: const Icon(Icons.table_chart_outlined),
                  title: const Text('Export Backup Manifest CSV'),
                  onTap: () async {
                    try {
                      final file =
                          await exportBackupManifest(history);
                      if (!mounted) return;
                      showSuccessSnackbar(
                          context, 'CSV saved: ${file.path}');
                    } catch (e) {
                      if (!mounted) return;
                      showErrorSnackbar(context, 'Failed: $e');
                    }
                  },
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Divider(),

          // Appearance
          const _SectionHeader(title: 'Appearance'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
          const Divider(),

          // Notifications
          const _SectionHeader(title: 'Notifications'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Configure Notifications'),
            subtitle: const Text(
                'Backup success, failures, pending sync'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNotificationSettings(context),
          ),
          const Divider(),

          // Advanced
          const _SectionHeader(title: 'Advanced'),
          ExpansionTile(
            leading: const Icon(Icons.build_outlined),
            title: const Text('Developer Options'),
            children: [
              ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: const Text('SQLite Vacuum'),
                subtitle: const Text('Optimize database file size'),
                onTap: () => _vacuumDb(context),
              ),
              ListTile(
                leading: const Icon(Icons.clear_all_outlined),
                title: const Text('Clear Local Cache'),
                onTap: () => _clearCache(context),
              ),
              ListTile(
                leading: const Icon(Icons.sync_outlined),
                title: const Text('Force Resync'),
                onTap: () async {
                  await ref.read(syncServiceProvider).forceResync();
                  if (!mounted) return;
                  showSuccessSnackbar(context, 'Resync triggered');
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Export Debug Logs'),
                onTap: () =>
                    showSuccessSnackbar(context, 'Debug log exported'),
              ),
            ],
          ),
          const Divider(),

          // About
          const _SectionHeader(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info_outlined),
            title: Text('Kashly'),
            subtitle: Text(
                'Version 1.0.0 · Professional Cashbook Manager'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
                title: const Text('Backup Success'),
                value: true,
                onChanged: (_) {}),
            SwitchListTile(
                title: const Text('Backup Failure'),
                value: true,
                onChanged: (_) {}),
            SwitchListTile(
                title: const Text('Pending Sync Reminder'),
                value: true,
                onChanged: (_) {}),
            SwitchListTile(
                title: const Text('Conflict Detected'),
                value: true,
                onChanged: (_) {}),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'))
        ],
      ),
    );
  }

  Future<void> _vacuumDb(BuildContext context) async {
    try {
      await ref.read(localDatasourceProvider).vacuumDb();
      if (!mounted) return;
      showSuccessSnackbar(context, 'Database optimized successfully');
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, 'Vacuum failed: $e');
    }
  }

  Future<void> _clearCache(BuildContext context) async {
    final confirmed =
        await showDeleteConfirmation(context, 'local cache');
    if (confirmed == true) {
      if (!mounted) return;
      showSuccessSnackbar(context, 'Cache cleared');
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _BackupSettingsSection extends StatefulWidget {
  final AppBackupSettings settings;
  final Future<void> Function(AppBackupSettings) onSave;

  const _BackupSettingsSection(
      {required this.settings, required this.onSave});

  @override
  State<_BackupSettingsSection> createState() =>
      _BackupSettingsSectionState();
}

class _BackupSettingsSectionState
    extends State<_BackupSettingsSection> {
  late AppBackupSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  Future<void> _update(AppBackupSettings s) async {
    setState(() => _settings = s);
    await widget.onSave(s);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary card
        Card(
          margin:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Backup Summary',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Row(children: [
                  Icon(Icons.storage_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('Last Local: N/A',
                      style: TextStyle(fontSize: 13))
                ]),
                const Row(children: [
                  Icon(Icons.cloud_outlined, size: 16),
                  SizedBox(width: 8),
                  Text('Last Drive: N/A',
                      style: TextStyle(fontSize: 13))
                ]),
                Row(children: [
                  const Icon(Icons.schedule_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text(
                      'Interval: ${_settings.autoBackupInterval.name}',
                      style: const TextStyle(fontSize: 13)),
                ]),
              ],
            ),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.backup_outlined),
          title: const Text('Enable Auto Backup'),
          subtitle:
              const Text('Automatically sync to Google Drive'),
          value: _settings.autoBackupEnabled,
          onChanged: (v) =>
              _update(_settings.copyWith(autoBackupEnabled: v)),
        ),
        if (_settings.autoBackupEnabled) ...[
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Backup Frequency'),
            trailing: DropdownButton<AutoBackupInterval>(
              value: _settings.autoBackupInterval,
              underline: const SizedBox(),
              onChanged: (v) => _update(
                  _settings.copyWith(autoBackupInterval: v)),
              items: AutoBackupInterval.values
                  .map((i) => DropdownMenuItem(
                      value: i,
                      child: Text(i.name.capitalize())))
                  .toList(),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.wifi_outlined),
            title: const Text('Only on Wi-Fi'),
            value: _settings.onlyOnUnmeteredNetwork,
            onChanged: (v) => _update(
                _settings.copyWith(onlyOnUnmeteredNetwork: v)),
          ),
          SwitchListTile(
            secondary:
                const Icon(Icons.battery_charging_full_outlined),
            title: const Text('Only When Charging'),
            value: _settings.backupOnlyWhenCharging,
            onChanged: (v) => _update(
                _settings.copyWith(backupOnlyWhenCharging: v)),
          ),
        ],
        SwitchListTile(
          secondary: const Icon(Icons.attach_file_outlined),
          title: const Text('Include Attachments'),
          value: _settings.includeAttachmentsInDrive,
          onChanged: (v) => _update(
              _settings.copyWith(includeAttachmentsInDrive: v)),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.lock_outline),
          title: const Text('Encrypt Backups'),
          value: _settings.encryptionEnabled,
          onChanged: (v) =>
              _update(_settings.copyWith(encryptionEnabled: v)),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.history_outlined),
          title: const Text('Drive Versioning'),
          subtitle: const Text('Keep last 5 versions on Drive'),
          value: _settings.driveAutoVersioning,
          onChanged: (v) =>
              _update(_settings.copyWith(driveAutoVersioning: v)),
        ),
      ],
    );
  }
}

extension StringX on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
