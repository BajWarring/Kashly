import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme.dart';
import '../../../../core/application/sync_service.dart';

class GoogleDriveScreen extends StatelessWidget {
  const GoogleDriveScreen({super.key});

  String _formatLastSync(int ms) {
    if (ms == 0) return 'Never';
    return DateFormat('MMM d, yyyy • h:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(ms));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SyncService.instance,
      builder: (context, _) {
        final sync = SyncService.instance;
        final hasPending = sync.pendingChangesCount > 0;
        final isError = sync.status == SyncStatus.error;
        final isSuccess = sync.status == SyncStatus.success;

        return ListView(
          padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 60),
          children: [
            // ── 1. SYNC HEALTH DASHBOARD ──────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isError
                    ? dangerLight
                    : hasPending
                        ? warningLight
                        : isSuccess
                            ? successLight
                            : appBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isError
                      ? danger
                      : hasPending
                          ? warning
                          : isSuccess
                              ? success
                              : borderCol,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: sync.isSyncing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 3, color: accent),
                          )
                        : Icon(
                            isError
                                ? Icons.error_outline
                                : hasPending
                                    ? Icons.cloud_sync
                                    : Icons.cloud_done,
                            color: isError
                                ? danger
                                : hasPending
                                    ? warning
                                    : success,
                            size: 26,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sync.isSyncing
                              ? 'Syncing securely...'
                              : isError
                                  ? 'Sync Failed'
                                  : hasPending
                                      ? 'Unsaved Changes'
                                      : 'Everything is Up to Date',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isError
                                ? danger
                                : hasPending
                                    ? const Color(0xFF92400E)
                                    : textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasPending
                              ? '${sync.pendingChangesCount} changes waiting to sync'
                              : 'Last synced: ${_formatLastSync(sync.lastSyncTime)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isError
                                ? danger
                                : hasPending
                                    ? const Color(0xFFB45309)
                                    : textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (sync.isSignedIn)
                    ElevatedButton(
                      onPressed: sync.isSyncing
                          ? null
                          : () => sync.performTwoWaySync(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: textDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      child: Text(
                        hasPending ? 'Sync Now' : 'Force Sync',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 2. ACCOUNT / SIGN-IN CARD ─────────────────────────────────
            if (!sync.isSignedIn) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                          color: accentLight, shape: BoxShape.circle),
                      child: const Icon(Icons.add_to_drive,
                          size: 32, color: accent),
                    ),
                    const SizedBox(height: 16),
                    const Text('Connect Cloud Storage',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textDark)),
                    const SizedBox(height: 8),
                    const Text(
                      'Enable seamless, conflict-free sync across all your devices using your personal Google Drive.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: textMuted, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await sync.signIn();
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                'Login Failed:\n${e.toString().replaceAll('Exception: ', '')}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: danger,
                              duration: const Duration(seconds: 6),
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        },
                        icon: const Icon(Icons.g_mobiledata,
                            color: Colors.white, size: 28),
                        label: const Text('Sign in with Google',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // ── SIGNED-IN CARD ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  children: [
                    // Account row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFF1E293B),
                          backgroundImage: sync.userPhotoUrl != null
                              ? NetworkImage(sync.userPhotoUrl!)
                              : null,
                          child: sync.userPhotoUrl == null
                              ? Text(
                                  sync.userEmail
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      'G',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sync.userEmail ?? 'Signed In',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text('Google Drive Connected',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: success,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => sync.signOut(),
                          style: TextButton.styleFrom(
                            backgroundColor: appBg,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Unlink',
                              style: TextStyle(
                                  color: textMuted,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ),
                      ],
                    ),

                    // Storage bar (only if we have data)
                    if (sync.driveStorageUsed != '—') ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(height: 1, color: borderCol),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Drive Storage Used:',
                              style: TextStyle(
                                  color: textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          Text(
                            '${sync.driveStorageUsed} / ${sync.driveStorageTotal}',
                            style: const TextStyle(
                                color: textDark,
                                fontSize: 13,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: sync.driveStorageFraction,
                          backgroundColor: appBg,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(accent),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── 3. BACKUP FILES ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('DRIVE BACKUPS',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: textLight,
                          letterSpacing: 1.5)),
                  Text(
                    '${sync.driveBackupFiles.length} / 5 files',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (sync.driveBackupFiles.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_off, color: textLight, size: 32),
                      const SizedBox(height: 12),
                      Text(
                        sync.isSyncing
                            ? 'Loading backup files...'
                            : 'No backups yet.\nSync now to create your first backup.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: textMuted, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderCol),
                  ),
                  child: Column(
                    children: sync.driveBackupFiles.asMap().entries.map((e) {
                      final index = e.key;
                      final file = e.value;
                      final isLast =
                          index == sync.driveBackupFiles.length - 1;
                      return _BackupFileTile(
                        file: file,
                        isLast: isLast,
                        onRestore: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              title: Text(
                                'Restore from "${file['label']}"?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              content: const Text(
                                'Your existing data will be merged with this backup. '
                                'New entries not in this backup will be kept. '
                                'Only older records will be overwritten.',
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: accent),
                                  onPressed: () =>
                                      Navigator.pop(ctx, true),
                                  child: const Text('Restore',
                                      style:
                                          TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            await sync.restoreFromDriveBackup(
                                file['name'] ?? '');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text('Restore completed!',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                                backgroundColor: success,
                                behavior: SnackBarBehavior.floating,
                              ));
                            }
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 16),

              // Folder location hint
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: accentLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.folder, color: accent, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Backups stored in Google Drive → "Kashly App Backups" folder',
                        style: TextStyle(
                            fontSize: 12,
                            color: accent,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ── Reusable backup file tile ────────────────────────────────────────────────

class _BackupFileTile extends StatelessWidget {
  final Map<String, String> file;
  final bool isLast;
  final VoidCallback onRestore;

  const _BackupFileTile({
    required this.file,
    required this.isLast,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentWeek = file['name'] == 'current_week_backup.json';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isCurrentWeek ? accentLight : appBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCurrentWeek ? Icons.cloud_done : Icons.cloud,
                  color: isCurrentWeek ? accent : textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          file['label'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: textDark),
                        ),
                        if (isCurrentWeek) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: successLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Latest',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: success)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${file['modified'] ?? '—'} • ${file['size'] ?? '—'}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: textMuted,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      file['name'] ?? '',
                      style: const TextStyle(
                          fontSize: 10,
                          color: textLight,
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: textLight),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                onSelected: (val) {
                  if (val == 'restore') onRestore();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'restore',
                    child: Row(children: [
                      Icon(Icons.restore, size: 18, color: accent),
                      SizedBox(width: 12),
                      Text('Restore to App',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: accent)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: borderCol, indent: 72),
      ],
    );
  }
}
