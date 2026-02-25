import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum SyncStatus { synced, pending, error, conflict }

enum Type { in, out }

@freezed
class DriveMeta with _$DriveMeta {
  const factory DriveMeta(
    { 
      required String fileId,
      required String driveFileName,
      DateTime? lastSyncedAt,
      String? md5Checksum,
      String? version,
      required bool isUploaded,
      required bool isModifiedSinceUpload,
    } 
  ) = _DriveMeta;

  factory DriveMeta.fromJson(Map<String, Object?> json) => _$DriveMetaFromJson(json);
}

@freezed
class Transaction with _$Transaction {
  const factory Transaction(
    { 
      required String id,
      required String cashbookId,
      required double amount,
      required Type type,
      required String category,
      required String remark,
      required String method,
      required DateTime date,
      required DateTime createdAt,
      required DateTime updatedAt,
      required SyncStatus syncStatus,
      required DriveMeta driveMeta,
      required bool hasAttachment,
      required bool isReconciled,
    } 
  ) = _Transaction;

  factory Transaction.fromJson(Map<String, Object?> json) => _$TransactionFromJson(json);
}
