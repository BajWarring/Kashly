import 'package:freezed_annotation/freezed_annotation.dart';

part 'backup_record.freezed.dart';
part 'backup_record.g.dart';

enum Type { local, google_drive }

enum Status { success, failed, partial }

@freezed
class BackupRecord with _$BackupRecord {
  const factory BackupRecord(
    { 
      required String id,
      required Type type,
      required List<String> cashbookIds,
      required int transactionCount,
      required String fileName,
      required int fileSizeBytes,
      required DateTime createdAt,
      String? driveFileId,
      required Status status,
      String? notes,
    } 
  ) = _BackupRecord;

  factory BackupRecord.fromJson(Map<String, Object?> json) => _$BackupRecordFromJson(json);
}
