import 'package:freezed_annotation/freezed.dart';

part 'backup_settings.freezed.dart';
part 'backup_settings.g.dart';

enum AutoBackupInterval { daily, weekly, monthly, custom }

@freezed
class BackupSettings with _$BackupSettings {
  const factory BackupSettings(
    { 
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
      String? bandwidthLimitKbps,
      required bool encryptionEnabled,
      String? encryptionPasswordHint,
      required bool promptBeforeOverwrite,
      required bool incrementalBackup,
    } 
  ) = _BackupSettings;

  factory BackupSettings.fromJson(Map<String, Object?> json) => _$BackupSettingsFromJson(json);
}
