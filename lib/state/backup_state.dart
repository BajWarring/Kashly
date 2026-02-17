// STATE LAYER — backup_state.dart
// Pure UI state. No platform calls here.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum BackupStatus {
  synced,      // All data safely backed up
  syncing,     // Upload in progress
  pending,     // Changes queued, debounce timer running
  error,       // Last backup failed
  never,       // First launch, no backup yet
}

class BackupInfo {
  final BackupStatus status;
  final DateTime? lastBackupTime;
  final String? lastBackupSize;
  final String? errorMessage;
  final String? connectedAccount;
  final List<BackupHistoryEntry> history;
  final bool autoBackupEnabled;

  const BackupInfo({
    this.status = BackupStatus.never,
    this.lastBackupTime,
    this.lastBackupSize,
    this.errorMessage,
    this.connectedAccount,
    this.history = const [],
    this.autoBackupEnabled = true,
  });

  BackupInfo copyWith({
    BackupStatus? status,
    DateTime? lastBackupTime,
    String? lastBackupSize,
    String? errorMessage,
    String? connectedAccount,
    List<BackupHistoryEntry>? history,
    bool? autoBackupEnabled,
  }) {
    return BackupInfo(
      status: status ?? this.status,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      lastBackupSize: lastBackupSize ?? this.lastBackupSize,
      errorMessage: errorMessage ?? this.errorMessage,
      connectedAccount: connectedAccount ?? this.connectedAccount,
      history: history ?? this.history,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
    );
  }

  String get statusLabel {
    switch (status) {
      case BackupStatus.synced:
        return lastBackupTime != null
            ? 'Backed up ${_relativeTime(lastBackupTime!)}'
            : 'Backed up';
      case BackupStatus.syncing:
        return 'Syncing…';
      case BackupStatus.pending:
        return 'Changes pending…';
      case BackupStatus.error:
        return 'Backup paused';
      case BackupStatus.never:
        return 'Not backed up yet';
    }
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class BackupHistoryEntry {
  final String id;
  final DateTime timestamp;
  final String size;
  final String version;
  final bool isLatest;

  const BackupHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.size,
    required this.version,
    this.isLatest = false,
  });
}

// ── InheritedWidget provider ──────────────────────────────────────────────

class BackupStateProvider extends StatefulWidget {
  final Widget child;
  const BackupStateProvider({super.key, required this.child});

  @override
  State<BackupStateProvider> createState() => BackupStateProviderState();

  static BackupStateProviderState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_BackupInherited>()!
        .state;
  }
}

class BackupStateProviderState extends State<BackupStateProvider> {
  BackupInfo _info = BackupInfo(
    status: BackupStatus.synced,
    lastBackupTime: DateTime.now().subtract(const Duration(minutes: 4)),
    lastBackupSize: '1.2 MB',
    connectedAccount: 'user@gmail.com',
    autoBackupEnabled: true,
    history: [
      BackupHistoryEntry(
        id: 'bk5',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        size: '1.2 MB',
        version: 'v${DateTime.now().subtract(const Duration(minutes: 4)).millisecondsSinceEpoch}',
        isLatest: true,
      ),
      BackupHistoryEntry(
        id: 'bk4',
        timestamp: DateTime.now().subtract(const Duration(hours: 26)),
        size: '1.1 MB',
        version: 'v${DateTime.now().subtract(const Duration(hours: 26)).millisecondsSinceEpoch}',
      ),
      BackupHistoryEntry(
        id: 'bk3',
        timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
        size: '1.0 MB',
        version: 'v${DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch}',
      ),
      BackupHistoryEntry(
        id: 'bk2',
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
        size: '0.9 MB',
        version: 'v${DateTime.now().subtract(const Duration(days: 4)).millisecondsSinceEpoch}',
      ),
      BackupHistoryEntry(
        id: 'bk1',
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
        size: '0.8 MB',
        version: 'v${DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch}',
      ),
    ],
  );

  BackupInfo get info => _info;

  /// Called after any data mutation — triggers pending → debounce → syncing → synced
  void notifyDataChanged() {
    _updateStatus(BackupStatus.pending);
    // Simulate debounce + sync (20s in real impl)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _updateStatus(BackupStatus.syncing);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _updateStatus(BackupStatus.synced, newBackupNow: true);
        }
      });
    });
  }

  void triggerManualBackup() {
    _updateStatus(BackupStatus.syncing);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _updateStatus(BackupStatus.synced, newBackupNow: true);
    });
  }

  void simulateError() {
    _updateStatus(BackupStatus.error,
        errorMessage: 'Network unavailable. Will retry automatically.');
  }

  void toggleAutoBackup(bool enabled) {
    setState(() {
      _info = _info.copyWith(autoBackupEnabled: enabled);
    });
  }

  void _updateStatus(BackupStatus status,
      {bool newBackupNow = false, String? errorMessage}) {
    setState(() {
      final now = DateTime.now();
      List<BackupHistoryEntry> history = _info.history;

      if (newBackupNow) {
        final newEntry = BackupHistoryEntry(
          id: 'bk_${now.millisecondsSinceEpoch}',
          timestamp: now,
          size: '${(1.2 + (history.length * 0.05)).toStringAsFixed(1)} MB',
          version: 'v${now.millisecondsSinceEpoch}',
          isLatest: true,
        );
        // Mark old entries as not latest
        history = [
          newEntry,
          ...history.map((e) => BackupHistoryEntry(
                id: e.id,
                timestamp: e.timestamp,
                size: e.size,
                version: e.version,
                isLatest: false,
              )),
        ];
        // Keep max 5
        if (history.length > 5) history = history.take(5).toList();
      }

      _info = _info.copyWith(
        status: status,
        lastBackupTime: newBackupNow ? now : _info.lastBackupTime,
        lastBackupSize: newBackupNow
            ? history.first.size
            : _info.lastBackupSize,
        errorMessage: errorMessage,
        history: history,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _BackupInherited(state: this, child: widget.child);
  }
}

class _BackupInherited extends InheritedWidget {
  final BackupStateProviderState state;

  const _BackupInherited({required this.state, required super.child});

  @override
  bool updateShouldNotify(_BackupInherited old) => true;
}
