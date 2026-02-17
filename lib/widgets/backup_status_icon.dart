import 'package:flutter/material.dart';
import '../state/backup_state.dart';

class BackupStatusIcon extends StatefulWidget {
  final VoidCallback? onTap;
  const BackupStatusIcon({super.key, this.onTap});
  @override
  State<BackupStatusIcon> createState() => _BackupStatusIconState();
}

class _BackupStatusIconState extends State<BackupStatusIcon> with SingleTickerProviderStateMixin {
  late AnimationController _spin;
  late Animation<double> _spinAnim;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _spinAnim = CurvedAnimation(parent: _spin, curve: Curves.linear);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final status = BackupStateProvider.of(context).info.status;
    if (status == BackupServiceState.syncing) _spin.repeat();
    else { _spin.stop(); _spin.reset(); }
  }

  @override
  Widget build(BuildContext context) {
    final state = BackupStateProvider.of(context);
    final info = state.info;
    final cs = Theme.of(context).colorScheme;
    Widget icon; Color color;
    switch (info.status) {
      case BackupServiceState.synced: icon = const Icon(Icons.cloud_done_rounded); color = const Color(0xFF1B8A3A); break;
      case BackupServiceState.syncing: icon = RotationTransition(turns: _spinAnim, child: const Icon(Icons.cloud_sync_rounded)); color = cs.primary; break;
      case BackupServiceState.pending:
        icon = Stack(clipBehavior: Clip.none, children: [const Icon(Icons.cloud_outlined), Positioned(right: -2, top: -2, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: cs.tertiary, shape: BoxShape.circle, border: Border.all(color: cs.surface, width: 1.5))))]);
        color = cs.tertiary; break;
      case BackupServiceState.error:
        icon = Stack(clipBehavior: Clip.none, children: [Icon(Icons.cloud_off_rounded, color: cs.error), Positioned(right: -3, bottom: -3, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: cs.error, shape: BoxShape.circle, border: Border.all(color: cs.surface, width: 1.5)), child: Icon(Icons.warning_rounded, size: 8, color: cs.onError)))]);
        color = cs.error; break;
      case BackupServiceState.idle: icon = const Icon(Icons.cloud_upload_outlined); color = cs.onSurfaceVariant; break;
    }
    return Tooltip(message: info.statusLabel, child: IconButton(icon: IconTheme(data: IconThemeData(color: color, size: 22), child: icon), onPressed: widget.onTap ?? () => showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (_) => _BackupSheet(state: state))));
  }

  @override
  void dispose() { _spin.dispose(); super.dispose(); }
}

class BackupStatusText extends StatelessWidget {
  const BackupStatusText({super.key});
  @override
  Widget build(BuildContext context) {
    final info = BackupStateProvider.of(context).info;
    final cs = Theme.of(context).colorScheme;
    Color c; IconData ic;
    switch (info.status) {
      case BackupServiceState.synced: c = const Color(0xFF1B8A3A); ic = Icons.check_circle_rounded; break;
      case BackupServiceState.syncing: c = cs.primary; ic = Icons.sync_rounded; break;
      case BackupServiceState.pending: c = cs.tertiary; ic = Icons.schedule_rounded; break;
      case BackupServiceState.error: c = cs.error; ic = Icons.warning_amber_rounded; break;
      case BackupServiceState.idle: c = cs.onSurfaceVariant; ic = Icons.cloud_off_outlined; break;
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(ic, size: 11, color: c), const SizedBox(width: 4), Text(info.statusLabel, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w500))]);
  }
}

class _BackupSheet extends StatelessWidget {
  final BackupStateProviderState state;
  const _BackupSheet({required this.state});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final info = state.info;
    return SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(16,12,16,16), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Center(child: Container(width: 32, height: 4, decoration: BoxDecoration(color: cs.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 16),
      Card(elevation: 0, color: cs.surfaceContainerLow, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), margin: EdgeInsets.zero, child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: info.status == BackupServiceState.synced ? const Color(0xFF1B8A3A).withValues(alpha: 0.12) : cs.errorContainer.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)), child: Icon(info.status == BackupServiceState.synced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded, color: info.status == BackupServiceState.synced ? const Color(0xFF1B8A3A) : cs.error, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(info.statusLabel, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          if (info.connectedAccount != null) Text(info.connectedAccount!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ])),
      ]))),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.restore_rounded, size: 18), label: const Text('Restore'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () async { Navigator.pop(context); await state.restoreLatest(); })),
        const SizedBox(width: 10),
        Expanded(child: FilledButton.icon(icon: const Icon(Icons.cloud_upload_outlined, size: 18), label: const Text('Backup Now'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () { Navigator.pop(context); state.triggerManualBackup(); })),
      ]),
    ])));
  }
}

// Export for backwards compat
class BackupStatusSheet extends StatelessWidget {
  final BackupStateProviderState state;
  const BackupStatusSheet({super.key, required this.state});
  @override
  Widget build(BuildContext context) => _BackupSheet(state: state);
}
