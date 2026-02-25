import 'package:freezed_annotation/freezed_annotation.dart';

part 'cashbook.freezed.dart';
part 'cashbook.g.dart';

enum SyncStatus { synced, pending, error, conflict }

@freezed
class BackupSettings with _$BackupSettings {
  const factory BackupSettings({
    required bool autoBackupEnabled,
    required bool includeAttachments,
    DateTime? lastBackupAt,
    String? lastBackupFileId,
  }) = _BackupSettings;

  factory BackupSettings.fromJson(Map<String, Object?> json) =>
      _$BackupSettingsFromJson(json);
}

@freezed
class Cashbook with _$Cashbook {
  const factory Cashbook({
    required String id,
    required String name,
    required String currency,
    required double openingBalance,
    required DateTime createdAt,
    required DateTime updatedAt,
    required SyncStatus syncStatus,
    required BackupSettings backupSettings,
    @Default(false) bool isArchived,
  }) = _Cashbook;

  factory Cashbook.fromJson(Map<String, Object?> json) =>
      _$CashbookFromJson(json);
}
