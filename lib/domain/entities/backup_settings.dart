import 'package:freezed_annotation/freezed_annotation.dart';

part 'backup_settings.freezed.dart';
part 'backup_settings.g.dart';

enum AutoBackupInterval { daily, weekly, monthly, custom }

@freezed
class AppBackupSettings with _$AppBackupSettings {
  const factory AppBackupSettings({
    required bool autoBackupEnabled,
    required AutoBackupInterval autoBackupInterval,
    String? autoBackupTime,
    required int maxLocalBackups,
    String? localBackupPath,
    required bool driveBackupEnabled,
    required bool driveAutoVersioning,
    String? driveBackupFolderId,
    required bool includeAttachmentsInDrive,
    required bool uploadOnMeteredNetwork,
    required bool onlyOnUnmeteredNetwork,
    required bool backupOverRoaming,
    required bool backupOnlyWhenCharging,
    int? bandwidthLimitKbps,
    required bool encryptionEnabled,
    String? encryptionPasswordHint,
    required bool promptBeforeOverwrite,
    required bool incrementalBackup,
  }) = _AppBackupSettings;

  factory AppBackupSettings.fromJson(Map<String, Object?> json) => _$AppBackupSettingsFromJson(json);
}
