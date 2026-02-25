import 'package:freezed_annotation/freezed_annotation.dart';

part 'backup_record.freezed.dart';
part 'backup_record.g.dart';

enum BackupType { local, googleDrive }

enum BackupStatus { success, failed, partial }

@freezed
class BackupRecord with _$BackupRecord {
  const factory BackupRecord({
    required String id,
    required BackupType type,
    required List<String> cashbookIds,
    required int transactionCount,
    required String fileName,
    required int fileSizeBytes,
    required DateTime createdAt,
    String? driveFileId,
    required BackupStatus status,
    String? notes,
    String? checksum,
  }) = _BackupRecord;

  factory BackupRecord.fromJson(Map<String, Object?> json) =>
      _$BackupRecordFromJson(json);
}
