import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../application/sync_service.dart';
import '../theme.dart';

/// The three visual cloud states shown across the app.
enum SyncCloudState { synced, syncing, pending, disconnected }

SyncCloudState getSyncCloudState(SyncService sync) {
  if (!sync.isSignedIn) return SyncCloudState.disconnected;
  if (sync.isSyncing) return SyncCloudState.syncing;
  if (sync.status == SyncStatus.error || sync.pendingChangesCount > 0) {
    return SyncCloudState.pending;
  }
  return SyncCloudState.synced;
}

Color getSyncStateColor(SyncCloudState state) {
  switch (state) {
    case SyncCloudState.synced:
      return success;
    case SyncCloudState.syncing:
      return warning;
    case SyncCloudState.pending:
      return danger;
    case SyncCloudState.disconnected:
      return textMuted;
  }
}

// ─── Main Icon Widget ────────────────────────────────────────────────────────

class SyncStatusIcon extends StatefulWidget {
  const SyncStatusIcon({super.key});

  @override
  State<SyncStatusIcon> createState() => _SyncStatusIconState();
}

class _SyncStatusIconState extends State<SyncStatusIcon>
    with SingleTickerProviderStateMixin {
  final GlobalKey _iconKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  late AnimationController _rotationCtrl;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    _closeOverlay();
    super.dispose();
  }

  // Called whenever SyncService fires — refreshes the open popup in place.
  void _onSyncChanged() {
    if (mounted) setState(() {});
    _overlayEntry?.markNeedsBuild();
  }

  void _closeOverlay() {
    SyncService.instance.removeListener(_onSyncChanged);
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleOverlay() {
    if (_overlayEntry != null) {
      _closeOverlay();
      setState(() {});
      return;
    }

    final box = _iconKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final Offset pos = box.localToGlobal(Offset.zero);
    final Size sz = box.size;

    SyncService.instance.addListener(_onSyncChanged);

    _overlayEntry = OverlayEntry(
      builder: (ctx) {
        final sync = SyncService.instance;
        final state = getSyncCloudState(sync);
        final screenW = MediaQuery.of(ctx).size.width;
        const popupW = 272.0;

        // Right-align popup to the icon; clamp so it never goes off-screen.
        double left = pos.dx + sz.width - popupW;
        if (left < 12) left = 12;
        if (left + popupW > screenW - 12) left = screenW - popupW - 12;

        return Stack(
          children: [
            // Transparent dismiss layer
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  _closeOverlay();
                  if (mounted) setState(() {});
                },
                behavior: HitTestBehavior.translucent,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            // Popup card
            Positioned(
              top: pos.dy + sz.height + 6,
              left: left,
              width: popupW,
              child: Material(
                elevation: 16,
                shadowColor: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                child: _SyncPopup(
                  sync: sync,
                  state: state,
                  onClose: () {
                    _closeOverlay();
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SyncService.instance,
      builder: (context, _) {
        final sync = SyncService.instance;
        final state = getSyncCloudState(sync);
        final color = getSyncStateColor(state);
        final isOpen = _overlayEntry != null;

        Widget iconChild;
        switch (state) {
          case SyncCloudState.syncing:
            iconChild = RotationTransition(
              turns: _rotationCtrl,
              child: Icon(Icons.cloud_sync_rounded, color: color, size: 20),
            );
          case SyncCloudState.synced:
            iconChild =
                Icon(Icons.cloud_done_rounded, color: color, size: 20);
          case SyncCloudState.pending:
            iconChild =
                Icon(Icons.cloud_upload_rounded, color: color, size: 20);
          case SyncCloudState.disconnected:
            iconChild =
                Icon(Icons.cloud_off_rounded, color: color, size: 20);
        }

        return GestureDetector(
          key: _iconKey,
          onTap: _toggleOverlay,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isOpen
                  ? color.withValues(alpha: 0.20)
                  : color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: isOpen
                  ? Border.all(color: color.withValues(alpha: 0.35), width: 1.5)
                  : null,
            ),
            child: Center(child: iconChild),
          ),
        );
      },
    );
  }
}

// ─── Popup Content ───────────────────────────────────────────────────────────

class _SyncPopup extends StatelessWidget {
  final SyncService sync;
  final SyncCloudState state;
  final VoidCallback onClose;

  const _SyncPopup({
    required this.sync,
    required this.state,
    required this.onClose,
  });

  String _fmtLastSync(int ms) {
    if (ms == 0) return 'Never';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    // Re-subscribe inside the popup so it rebuilds on sync changes too.
    return ListenableBuilder(
      listenable: SyncService.instance,
      builder: (context, _) {
        final s = SyncService.instance;
        final liveState = getSyncCloudState(s);
        final color = getSyncStateColor(liveState);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: _buildHeaderIcon(liveState, color)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title(liveState, s),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: liveState == SyncCloudState.disconnected
                                ? textDark
                                : color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subtitle(liveState, s),
                          style: const TextStyle(
                            fontSize: 11,
                            color: textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Progress bar (syncing) ───────────────────────────────────
              if (liveState == SyncCloudState.syncing) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    color: warning,
                    backgroundColor: warningLight,
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Uploading your changes to Google Drive…',
                  style: TextStyle(
                    fontSize: 11,
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              // ── Force Sync button (pending) ──────────────────────────────
              if (liveState == SyncCloudState.pending) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      onClose();
                      s.performTwoWaySync();
                    },
                    icon: const Icon(Icons.sync_rounded,
                        size: 16, color: Colors.white),
                    label: const Text(
                      'Force Sync Now',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: danger,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],

              // ── Sign-in button (disconnected) ────────────────────────────
              if (liveState == SyncCloudState.disconnected) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      onClose();
                      try {
                        await s.signIn();
                      } catch (_) {}
                    },
                    icon: const Icon(Icons.g_mobiledata,
                        size: 22, color: Colors.white),
                    label: const Text(
                      'Sign in with Google',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderIcon(SyncCloudState state, Color color) {
    switch (state) {
      case SyncCloudState.synced:
        return Icon(Icons.cloud_done_rounded, color: color, size: 22);
      case SyncCloudState.syncing:
        return SizedBox(
          width: 20,
          height: 20,
          child:
              CircularProgressIndicator(strokeWidth: 2.5, color: color),
        );
      case SyncCloudState.pending:
        return Icon(Icons.cloud_upload_rounded, color: color, size: 22);
      case SyncCloudState.disconnected:
        return Icon(Icons.cloud_off_rounded, color: color, size: 22);
    }
  }

  String _title(SyncCloudState state, SyncService s) {
    switch (state) {
      case SyncCloudState.synced:
        return 'All cashbooks synced';
      case SyncCloudState.syncing:
        return 'Syncing to Drive…';
      case SyncCloudState.pending:
        final n = s.pendingChangesCount;
        return '$n change${n == 1 ? '' : 's'} pending';
      case SyncCloudState.disconnected:
        return 'Drive not connected';
    }
  }

  String _subtitle(SyncCloudState state, SyncService s) {
    switch (state) {
      case SyncCloudState.synced:
        return 'Last synced: ${_fmtLastSync(s.lastSyncTime)}';
      case SyncCloudState.syncing:
        return 'Please wait…';
      case SyncCloudState.pending:
        return s.status == SyncStatus.error
            ? 'Last sync failed — tap to retry'
            : 'Last synced: ${_fmtLastSync(s.lastSyncTime)}';
      case SyncCloudState.disconnected:
        return 'Sign in to backup your data';
    }
  }
}
