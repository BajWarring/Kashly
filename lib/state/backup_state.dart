// STATE LAYER — backup_state.dart
// Bridges BackupService to UI state.

import 'package:flutter/material.dart';
import '../services/backup_service.dart';

export '../services/backup_service.dart' show BackupMetadata, BackupServiceState;

// ── BackupInfo (UI model) ─────────────────────────────────────────────────

class BackupInfo {
  final BackupServiceState status;
  final DateTime? lastBackupTime;
  final String? lastBackupSize;
  final String? errorMessage;
  final String? connectedAccount;
  final List<BackupMetadata> history;
  final bool autoBackupEnabled;

  const BackupInfo({
    this.status = BackupServiceState.idle,
    this.lastBackupTime,
    this.lastBackupSize,
    this.errorMessage,
    this.connectedAccount,
    this.history = const [],
    this.autoBackupEnabled = true,
  });

  // Legacy compat
  BackupStatus get legacyStatus {
    switch (status) {
      case BackupServiceState.synced:
        return BackupStatus.synced;
      case BackupServiceState.syncing:
        return BackupStatus.syncing;
      case BackupServiceState.pending:
        return BackupStatus.pending;
      case BackupServiceState.error:
        return BackupStatus.error;
      case BackupServiceState.idle:
        return lastBackupTime == null ? BackupStatus.never : BackupStatus.synced;
    }
  }

  String get statusLabel {
    switch (status) {
      case BackupServiceState.synced:
        return lastBackupTime != null
            ? 'Backed up ${_relativeTime(lastBackupTime!)}'
            : 'Backed up';
      case BackupServiceState.syncing:
        return 'Syncing…';
      case BackupServiceState.pending:
        return 'Changes pending…';
      case BackupServiceState.error:
        return 'Backup paused';
      case BackupServiceState.idle:
        return lastBackupTime != null
            ? 'Last backup ${_relativeTime(lastBackupTime!)}'
            : 'Not backed up yet';
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

// Legacy enum for existing UI code
enum BackupStatus { synced, syncing, pending, error, never }

// ── BackupStateProvider ────────────────────────────────────────────────────

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
  final _service = BackupService.instance;

  BackupInfo _info = const BackupInfo(
    status: BackupServiceState.idle,
    autoBackupEnabled: true,
  );

  BackupInfo get info => _info;

  @override
  void initState() {
    super.initState();
    _service.onStateChanged = _onServiceStateChanged;
    _syncFromService();
  }

  void _syncFromService() {
    setState(() {
      _info = BackupInfo(
        status: _service.state,
        lastBackupTime: _service.lastBackupTime,
        lastBackupSize: _service.lastBackupSize,
        errorMessage: _service.errorMessage,
        connectedAccount: _service.connectedEmail,
        history: _service.backupHistory,
        autoBackupEnabled: _service.autoBackupEnabled,
      );
    });
  }

  void _onServiceStateChanged(BackupServiceState state) {
    if (mounted) _syncFromService();
  }

  /// Called after any data change to trigger auto-backup
  void notifyDataChanged() {
    _service.notifyDataChanged();
    _setState(BackupServiceState.pending);
  }

  Future<void> triggerManualBackup() async {
    await _service.runBackup();
  }

  Future<String?> signIn() async {
    final email = await _service.signIn();
    _syncFromService();
    return email;
  }

  Future<void> signOut() async {
    await _service.signOut();
    _syncFromService();
  }

  Future<bool> restoreLatest() async {
    final result = await _service.restoreLatest();
    _syncFromService();
    return result;
  }

  Future<bool> restoreFromBackup(BackupMetadata backup) async {
    final result = await _service.restoreFromBackup(backup);
    _syncFromService();
    return result;
  }

  Future<void> toggleAutoBackup(bool enabled) async {
    await _service.setAutoBackup(enabled);
    _syncFromService();
  }

  void _setState(BackupServiceState status) {
    setState(() {
      _info = BackupInfo(
        status: status,
        lastBackupTime: _service.lastBackupTime,
        lastBackupSize: _service.lastBackupSize,
        errorMessage: _service.errorMessage,
        connectedAccount: _service.connectedEmail,
        history: _service.backupHistory,
        autoBackupEnabled: _service.autoBackupEnabled,
      );
    });
  }

  // Legacy compat methods
  void simulateError() {
    setState(() {
      _info = BackupInfo(
        status: BackupServiceState.error,
        lastBackupTime: _info.lastBackupTime,
        lastBackupSize: _info.lastBackupSize,
        errorMessage: 'Backup paused — will retry when connection is available.',
        connectedAccount: _info.connectedAccount,
        history: _info.history,
        autoBackupEnabled: _info.autoBackupEnabled,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _BackupInherited(state: this, child: widget.child);
  }

  @override
  void dispose() {
    _service.onStateChanged = null;
    super.dispose();
  }
}

class _BackupInherited extends InheritedWidget {
  final BackupStateProviderState state;

  const _BackupInherited({required this.state, required super.child});

  @override
  bool updateShouldNotify(_BackupInherited old) => true;
}
