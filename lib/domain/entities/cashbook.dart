import 'package:freezed_annotation/freezed_annotation.dart';

part 'cashbook.freezed.dart';

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
  }) = _Cashbook;
}

enum SyncStatus { synced, pending, error, conflict }

@freezed
class BackupSettings with _$BackupSettings {
  const factory BackupSettings({
    required bool autoBackupEnabled,
    required bool includeAttachments,
    DateTime? lastBackupAt,
    String? lastBackupFileId,
  }) = _BackupSettings;
}
