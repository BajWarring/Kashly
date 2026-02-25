import 'package:freezed_annotation/freezed_annotation.dart';

part 'backup_settings.freezed.dart';
part 'backup_settings.g.dart';

enum AutoBackupInterval { daily, weekly, monthly, custom }

@freezed
class AppBackupSettings with _$AppBackupSettings {
  const factory AppBackupSettings({
    @Default(false) bool autoBackupEnabled,
    @Default(AutoBackupInterval.daily) AutoBackupInterval autoBackupInterval,
    String? autoBackupTime,
    @Default(5) int maxLocalBackups,
    String? localBackupPath,
    @Default(false) bool driveBackupEnabled,
    @Default(true) bool driveAutoVersioning,
    String? driveBackupFolderId,
    @Default(false) bool includeAttachmentsInDrive,
    @Default(true) bool uploadOnMeteredNetwork,
    @Default(false) bool onlyOnUnmeteredNetwork,
    @Default(false) bool backupOverRoaming,
    @Default(false) bool backupOnlyWhenCharging,
    int? bandwidthLimitKbps,
    @Default(false) bool encryptionEnabled,
    String? encryptionPasswordHint,
    @Default(true) bool promptBeforeOverwrite,
    @Default(true) bool incrementalBackup,
    @Default(false) bool requireBiometricToRestore,
    @Default(true) bool notifyOnSuccess,
    @Default(true) bool notifyOnFailure,
    String? doNotDisturbStart,
    String? doNotDisturbEnd,
  }) = _AppBackupSettings;

  factory AppBackupSettings.fromJson(Map<String, Object?> json) =>
      _$AppBackupSettingsFromJson(json);
}
