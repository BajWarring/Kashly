import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashly/core/di/providers.dart';
import 'package:kashly/core/utils/icons.dart';
import 'package:kashly/core/utils/utils.dart';
import 'package:kashly/core/theme/app_theme.dart';
import 'package:kashly/domain/entities/backup_record.dart';
import 'package:kashly/domain/entities/transaction.dart';
import 'package:kashly/reports/backup_report.dart';
import 'package:kashly/ux_and_ui_elements/dialogs.dart';
import 'package:kashly/services/sync_engine/sync_service.dart';

class BackupCenterScreen extends ConsumerStatefulWidget {
  const BackupCenterScreen({super.key});

  @override
  ConsumerState<BackupCenterScreen> createState() => _BackupCenterScreenState();
}

class _BackupCenterScreenState extends ConsumerState<BackupCenterScreen> {
  final Set<String> _selectedEntries = {};
  bool _selectAll = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final nonUploadedAsync = ref.watch(nonUploadedTransactionsProvider);
    final conflictsAsync = ref.watch(conflictTransactionsProvider);
    final backupHistoryAsync = ref.watch(backupHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup Center', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Drive status banner
            _DriveStatusCard(isConnected: authState.isAuthenticated, email: authState.user?.email),
            const SizedBox(height: 16),

            // Storage usage
            _StorageUsageCard(backupsAsync: backupHistoryAsync),
            const SizedBox(height: 16),

            // Quick actions
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _runBackup(context),
                    icon: const Icon(Icons.backup_outlined, size: 18),
                    label: const Text('Backup Now'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _runRestore(context),
                    icon: const Icon(Icons.restore_outlined, size: 18),
                    label: const Text('Restore'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Non-uploaded entries
            nonUploadedAsync.when(
              data: (entries) => _NonUploadedSection(
                entries: entries,
                selectedIds: _selectedEntries,
                selectAll: _selectAll,
                onSelectAll: (v) => setState(() {
                  _selectAll = v;
                  if (v) {
                    _selectedEntries.addAll(entries.map((e) => e.id));
                  } else {
                    _selectedEntries.clear();
                  }
                }),
                onSelect: (id, selected) => setState(() {
                  selected ? _selectedEntries.add(id) : _selectedEntries.remove(id);
                }),
                onUploadSelected: _uploadSelected,
                onIgnoreSelected: _ignoreSelected,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // Conflicts
            conflictsAsync.when(
              data: (conflicts) => conflicts.isNotEmpty
                  ? _ConflictsSection(conflicts: conflicts, onResolve: _resolveConflict)
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Backup history
            backupHistoryAsync.when(
              data: (history) => _BackupHistorySection(history: history),
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Text('History error: $e'),
            ),
            const SizedBox(height: 16),

            // Reports
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reports', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => backupHistoryAsync.whenData((h) => _generatePdf(context, h)),
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                            label: const Text('PDF Report'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => backupHistoryAsync.whenData((h) => _exportCsv(context, h)),
                            icon: const Icon(Icons.table_chart_outlined, size: 16),
                            label: const Text('CSV Export'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshAll() async {
    ref.invalidate(nonUploadedTransactionsProvider);
    ref.invalidate(conflictTransactionsProvider);
    ref.invalidate(backupHistoryProvider);
  }

  Future<void> _runBackup(BuildContext context) async {
    try {
      await ref.read(backupServiceProvider).manualBackup(context);
      _refreshAll();
      if (context.mounted) showSuccessSnackbar(context, 'Backup completed successfully');
    } catch (e) {
      if (context.mounted) showErrorSnackbar(context, 'Backup failed: $e');
    }
  }

  Future<void> _runRestore(BuildContext context) async {
    final history = await ref.read(backupRepositoryProvider).getBackupHistory();
    if (!context.mounted) return;
    if (history.isEmpty) {
      showErrorSnackbar(context, 'No backups available to restore');
      return;
    }
    // Show restore options dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Backup to Restore'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: history.length,
            itemBuilder: (c, i) {
              final b = history[i];
              return ListTile(
                leading: Icon(b.type == BackupType.googleDrive ? Icons.cloud_outlined : Icons.storage_outlined),
                title: Text(b.fileName),
                subtitle: Text('${formatDateTime(b.createdAt)} · ${formatFileSize(b.fileSizeBytes)}'),
                trailing: Icon(
                  b.status == BackupStatus.success ? Icons.check_circle : Icons.error_outline,
                  color: b.status == BackupStatus.success ? Colors.green : Colors.red,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(backupServiceProvider).restoreFromBackup(b, context);
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
      ),
    );
  }

  Future<void> _uploadSelected(BuildContext context) async {
    if (_selectedEntries.isEmpty) return;
    final confirmed = await showOverwriteDriveFileConfirmation(context);
    if (confirmed != true) return;
    try {
      await ref.read(syncServiceProvider).triggerSync(SyncTrigger.manual);
      _refreshAll();
      if (context.mounted) showSuccessSnackbar(context, 'Upload queued for ${_selectedEntries.length} entries');
    } catch (e) {
      if (context.mounted) showErrorSnackbar(context, 'Upload failed: $e');
    }
  }

  Future<void> _ignoreSelected(BuildContext context) async {
    // Mark selected as locally uploaded only
    setState(() {
      _selectedEntries.clear();
      _selectAll = false;
    });
    if (context.mounted) showSuccessSnackbar(context, 'Entries marked as local-only');
  }

  Future<void> _resolveConflict(BuildContext context, Transaction tx) async {
    final resolution = await showConflictResolutionModal(
      context,
      'Transaction: ${tx.category}\nAmount: ${tx.amount}\nDate: ${formatDate(tx.date)}',
    );
    if (resolution == null) return;
    await ref.read(transactionRepositoryProvider).resolveConflict(tx.id, resolution);
    ref.invalidate(conflictTransactionsProvider);
    if (context.mounted) showSuccessSnackbar(context, 'Conflict resolved ($resolution)');
  }

  Future<void> _generatePdf(BuildContext context, List<BackupRecord> records) async {
    try {
      final file = await generateBackupReportPdf(records);
      if (context.mounted) showSuccessSnackbar(context, 'PDF saved: ${file.path}');
    } catch (e) {
      if (context.mounted) showErrorSnackbar(context, 'PDF generation failed: $e');
    }
  }

  Future<void> _exportCsv(BuildContext context, List<BackupRecord> records) async {
    try {
      final file = await exportBackupManifest(records);
      if (context.mounted) showSuccessSnackbar(context, 'CSV saved: ${file.path}');
    } catch (e) {
      if (context.mounted) showErrorSnackbar(context, 'CSV export failed: $e');
    }
  }
}

class _DriveStatusCard extends StatelessWidget {
  final bool isConnected;
  final String? email;
  const _DriveStatusCard({required this.isConnected, this.email});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isConnected
          ? Colors.green.shade900.withValues(alpha: 0.2)
          : Colors.orange.shade900.withValues(alpha: 0.2),
      child: ListTile(
        leading: Icon(
          isConnected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          color: isConnected ? Colors.green : Colors.orange,
        ),
        title: Text(
          isConnected ? 'Google Drive Connected' : 'Drive Not Connected',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(isConnected ? email ?? 'Backup enabled' : 'Sign in to enable cloud backup'),
        trailing: getDriveFileIcon(isConnected ? 'drive_ok' : 'drive_missing'),
      ),
    );
  }
}

class _StorageUsageCard extends StatelessWidget {
  final AsyncValue<List<BackupRecord>> backupsAsync;
  const _StorageUsageCard({required this.backupsAsync});

  @override
  Widget build(BuildContext context) {
    return backupsAsync.when(
      data: (records) {
        final totalBytes = records.fold<int>(0, (sum, r) => sum + r.fileSizeBytes);
        final usagePercent = (totalBytes / (1024 * 1024 * 100)).clamp(0.0, 1.0);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Local Storage Used', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(formatFileSize(totalBytes), style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: usagePercent,
                    minHeight: 8,
                    backgroundColor: AppColors.surfaceVariant,
                    color: usagePercent > 0.8 ? Colors.red : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${records.length} backup records', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _NonUploadedSection extends StatelessWidget {
  final List<Transaction> entries;
  final Set<String> selectedIds;
  final bool selectAll;
  final ValueChanged<bool> onSelectAll;
  final Function(String, bool) onSelect;
  final Function(BuildContext) onUploadSelected;
  final Function(BuildContext) onIgnoreSelected;

  const _NonUploadedSection({
    required this.entries,
    required this.selectedIds,
    required this.selectAll,
    required this.onSelectAll,
    required this.onSelect,
    required this.onUploadSelected,
    required this.onIgnoreSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: entries.isNotEmpty,
        leading: Icon(
          Icons.cloud_upload_outlined,
          color: entries.isEmpty ? Colors.green : Colors.orange,
        ),
        title: Text(
          entries.isEmpty ? 'All Synced ✓' : '${entries.length} Pending Upload',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: entries.isEmpty ? null : const Text('Tap to manage pending entries'),
        children: [
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('All transactions are synced to Drive.', style: TextStyle(color: Colors.grey)),
            )
          else ...[
            // Summary counts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _CountBadge(label: 'Not Uploaded', count: entries.where((e) => !e.driveMeta.isUploaded).length, color: Colors.orange),
                  const SizedBox(width: 8),
                  _CountBadge(label: 'Modified', count: entries.where((e) => e.driveMeta.isModifiedSinceUpload).length, color: Colors.amber),
                  const Spacer(),
                  Checkbox(
                    value: selectAll,
                    onChanged: (v) => onSelectAll(v ?? false),
                  ),
                  const Text('Select All', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            // Action buttons
            if (selectedIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () => onUploadSelected(context),
                      icon: const Icon(Icons.upload, size: 16),
                      label: Text('Upload (${selectedIds.length})'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => onIgnoreSelected(context),
                      child: const Text('Local Only'),
                    ),
                  ],
                ),
              ),
            // Entry list
            ...entries.take(10).map((tx) => CheckboxListTile(
              dense: true,
              value: selectedIds.contains(tx.id),
              onChanged: (v) => onSelect(tx.id, v ?? false),
              secondary: getSyncStatusIconFromEnum(tx.syncStatus),
              title: Text('${tx.category} · ${formatCurrency(tx.amount, '')}'),
              subtitle: Text(formatDate(tx.date)),
              controlAffinity: ListTileControlAffinity.leading,
            )),
            if (entries.length > 10)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('+${entries.length - 10} more entries', style: const TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
              ),
          ],
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CountBadge({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('$count $label', style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

class _ConflictsSection extends StatelessWidget {
  final List<Transaction> conflicts;
  final Function(BuildContext, Transaction) onResolve;
  const _ConflictsSection({required this.conflicts, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.deepOrange.shade900.withValues(alpha: 0.15),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.warning_amber, color: Colors.deepOrange),
        title: Text('${conflicts.length} Conflicts Need Resolution', style: const TextStyle(fontWeight: FontWeight.w600)),
        children: conflicts.map((tx) => ListTile(
          dense: true,
          title: Text('${tx.category} · ${formatCurrency(tx.amount, '')}'),
          subtitle: Text(formatDate(tx.date)),
          trailing: FilledButton.tonal(
            onPressed: () => onResolve(context, tx),
            child: const Text('Resolve'),
          ),
        )).toList(),
      ),
    );
  }
}

class _BackupHistorySection extends StatelessWidget {
  final List<BackupRecord> history;
  const _BackupHistorySection({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.history_outlined),
        title: const Text('Backup History', style: TextStyle(fontWeight: FontWeight.w600)),
        children: history.take(10).map((record) => ListTile(
          dense: true,
          leading: Icon(
            record.type == BackupType.googleDrive ? Icons.cloud_outlined : Icons.storage_outlined,
            size: 18,
          ),
          title: Text(record.fileName, overflow: TextOverflow.ellipsis),
          subtitle: Text('${formatDateTime(record.createdAt)} · ${formatFileSize(record.fileSizeBytes)} · ${record.transactionCount} tx'),
          trailing: Icon(
            record.status == BackupStatus.success ? Icons.check_circle : record.status == BackupStatus.partial ? Icons.warning_amber : Icons.error_outline,
            color: record.status == BackupStatus.success ? Colors.green : record.status == BackupStatus.partial ? Colors.amber : Colors.red,
            size: 18,
          ),
        )).toList(),
      ),
    );
  }
}
