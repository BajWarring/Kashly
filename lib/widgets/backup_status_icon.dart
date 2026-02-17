// UI ONLY — backup_status_icon.dart

import 'package:flutter/material.dart';
import '../state/backup_state.dart';

/// Drop-in widget for AppBar actions — shows cloud icon with status
class BackupStatusIcon extends StatefulWidget {
  final VoidCallback? onTap;
  const BackupStatusIcon({super.key, this.onTap});

  @override
  State<BackupStatusIcon> createState() => _BackupStatusIconState();
}

class _BackupStatusIconState extends State<BackupStatusIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnim;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _spinAnim = CurvedAnimation(parent: _spinController, curve: Curves.linear);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final status = BackupStateProvider.of(context).info.status;
    if (status == BackupStatus.syncing) {
      _spinController.repeat();
    } else {
      _spinController.stop();
      _spinController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = BackupStateProvider.of(context);
    final info = state.info;
    final colorScheme = Theme.of(context).colorScheme;

    Widget icon;
    Color color;

    switch (info.status) {
      case BackupStatus.synced:
        icon = const Icon(Icons.cloud_done_rounded);
        color = const Color(0xFF1B8A3A);
        break;
      case BackupStatus.syncing:
        icon = RotationTransition(
          turns: _spinAnim,
          child: const Icon(Icons.cloud_sync_rounded),
        );
        color = colorScheme.primary;
        break;
      case BackupStatus.pending:
        icon = Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.cloud_outlined),
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.tertiary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 1.5),
                ),
              ),
            ),
          ],
        );
        color = colorScheme.tertiary;
        break;
      case BackupStatus.error:
        icon = Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.cloud_off_rounded, color: colorScheme.error),
            Positioned(
              right: -3,
              bottom: -3,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.surface, width: 1.5),
                ),
                child: Icon(Icons.warning_rounded,
                    size: 8, color: colorScheme.onError),
              ),
            ),
          ],
        );
        color = colorScheme.error;
        break;
      case BackupStatus.never:
        icon = const Icon(Icons.cloud_upload_outlined);
        color = colorScheme.onSurfaceVariant;
        break;
    }

    return Tooltip(
      message: info.statusLabel,
      child: IconButton(
        icon: IconTheme(
          data: IconThemeData(color: color, size: 22),
          child: icon,
        ),
        onPressed: widget.onTap ??
            () => _showBackupStatusSheet(context, state),
      ),
    );
  }

  void _showBackupStatusSheet(
      BuildContext context, BackupStateProviderState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => BackupStatusSheet(state: state),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }
}

/// Mini status text line for display below headers
class BackupStatusText extends StatelessWidget {
  const BackupStatusText({super.key});

  @override
  Widget build(BuildContext context) {
    final info = BackupStateProvider.of(context).info;
    final colorScheme = Theme.of(context).colorScheme;

    Color textColor;
    IconData dotIcon;

    switch (info.status) {
      case BackupStatus.synced:
        textColor = const Color(0xFF1B8A3A);
        dotIcon = Icons.check_circle_rounded;
        break;
      case BackupStatus.syncing:
        textColor = colorScheme.primary;
        dotIcon = Icons.sync_rounded;
        break;
      case BackupStatus.pending:
        textColor = colorScheme.tertiary;
        dotIcon = Icons.schedule_rounded;
        break;
      case BackupStatus.error:
        textColor = colorScheme.error;
        dotIcon = Icons.warning_amber_rounded;
        break;
      case BackupStatus.never:
        textColor = colorScheme.onSurfaceVariant;
        dotIcon = Icons.cloud_off_outlined;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(dotIcon, size: 11, color: textColor),
        const SizedBox(width: 4),
        Text(
          info.statusLabel,
          style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// Inline "Saving…" feedback shown after a data mutation
class SavingFeedback extends StatefulWidget {
  final Widget child;
  final bool saving;

  const SavingFeedback({super.key, required this.child, required this.saving});

  @override
  State<SavingFeedback> createState() => _SavingFeedbackState();
}

class _SavingFeedbackState extends State<SavingFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    if (widget.saving) _ctrl.forward();
  }

  @override
  void didUpdateWidget(SavingFeedback old) {
    super.didUpdateWidget(old);
    if (widget.saving && !old.saving) {
      _ctrl.forward();
    } else if (!widget.saving && old.saving) {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        FadeTransition(
          opacity: _fade,
          child: Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.inverseSurface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onInverseSurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Saving…',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onInverseSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

/// Bottom sheet showing full backup status
class BackupStatusSheet extends StatelessWidget {
  final BackupStateProviderState state;
  const BackupStatusSheet({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final info = state.info;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status card
            _StatusCard(info: info, colorScheme: colorScheme),
            const SizedBox(height: 12),

            // Error banner
            if (info.status == BackupStatus.error)
              _ErrorBanner(
                message: info.errorMessage ??
                    'Backup paused — will retry when connection is available.',
                colorScheme: colorScheme,
              ),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('Restore'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmRestore(context);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: const Text('Backup Now'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      state.triggerManualBackup();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRestore(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.restore_rounded, size: 28),
        title: const Text('Restore from Backup?'),
        content: const Text(
            'This will replace all current data with the latest cloud backup. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Restoring from backup…'),
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
}

class _StatusCard extends StatelessWidget {
  final BackupInfo info;
  final ColorScheme colorScheme;

  const _StatusCard({required this.info, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final isGood = info.status == BackupStatus.synced;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isGood
                        ? const Color(0xFF1B8A3A).withOpacity(0.12)
                        : colorScheme.errorContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isGood ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    color: isGood ? const Color(0xFF1B8A3A) : colorScheme.error,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.statusLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (info.connectedAccount != null)
                        Text(
                          info.connectedAccount!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (info.lastBackupSize != null) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatPill(
                      label: 'File size',
                      value: info.lastBackupSize ?? '—',
                      colorScheme: colorScheme),
                  const SizedBox(width: 8),
                  _StatPill(
                      label: 'Backups kept',
                      value: '${info.history.length}/5',
                      colorScheme: colorScheme),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _StatPill(
      {required this.label, required this.value, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final ColorScheme colorScheme;

  const _ErrorBanner({required this.message, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onErrorContainer,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
