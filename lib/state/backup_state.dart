// STATE LAYER — backup_state.dart
// Pure UI state. No platform calls here.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum BackupStatus {
  synced,
  syncing,
  pending,
  error,
  never,
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
  // Start with never — no fake backup data
  BackupInfo _info = const BackupInfo(
    status: BackupStatus.never,
    autoBackupEnabled: true,
  );

  BackupInfo get info => _info;

  void notifyDataChanged() {
    _updateStatus(BackupStatus.pending);
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
          size: '${(0.8 + (history.length * 0.1)).toStringAsFixed(1)} MB',
          version: 'v${now.millisecondsSinceEpoch}',
          isLatest: true,
        );
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
        if (history.length > 5) history = history.take(5).toList();
      }

      _info = _info.copyWith(
        status: status,
        lastBackupTime: newBackupNow ? now : _info.lastBackupTime,
        lastBackupSize:
            newBackupNow ? history.first.size : _info.lastBackupSize,
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
