import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionSyncStatus { synced, pending, error, conflict }

enum TransactionType { cashIn, cashOut }

@freezed
class DriveMeta with _$DriveMeta {
  const factory DriveMeta({
    String? fileId,
    String? driveFileName,
    DateTime? lastSyncedAt,
    String? md5Checksum,
    String? version,
    @Default(false) bool isUploaded,
    @Default(false) bool isModifiedSinceUpload,
  }) = _DriveMeta;

  factory DriveMeta.fromJson(Map<String, Object?> json) =>
      _$DriveMetaFromJson(json);
}

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String cashbookId,
    required double amount,
    required TransactionType type,
    required String category,
    required String remark,
    required String method,
    required DateTime date,
    required DateTime createdAt,
    required DateTime updatedAt,
    required TransactionSyncStatus syncStatus,
    required DriveMeta driveMeta,
    @Default(false) bool hasAttachment,
    String? attachmentPath,
    @Default(false) bool isReconciled,
    String? parentTransactionId,
    @Default(false) bool isSplit,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, Object?> json) =>
      _$TransactionFromJson(json);
}
