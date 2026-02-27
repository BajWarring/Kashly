enum TransactionSyncStatus { synced, pending, error, conflict }

enum TransactionType { cashIn, cashOut }

class DriveMeta {
  final String? fileId;
  final String? driveFileName;
  final DateTime? lastSyncedAt;
  final String? md5Checksum;
  final String? version;
  final bool isUploaded;
  final bool isModifiedSinceUpload;

  const DriveMeta({
    this.fileId,
    this.driveFileName,
    this.lastSyncedAt,
    this.md5Checksum,
    this.version,
    this.isUploaded = false,
    this.isModifiedSinceUpload = false,
  });

  DriveMeta copyWith({
    String? fileId,
    String? driveFileName,
    DateTime? lastSyncedAt,
    String? md5Checksum,
    String? version,
    bool? isUploaded,
    bool? isModifiedSinceUpload,
  }) =>
      DriveMeta(
        fileId: fileId ?? this.fileId,
        driveFileName: driveFileName ?? this.driveFileName,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        md5Checksum: md5Checksum ?? this.md5Checksum,
        version: version ?? this.version,
        isUploaded: isUploaded ?? this.isUploaded,
        isModifiedSinceUpload:
            isModifiedSinceUpload ?? this.isModifiedSinceUpload,
      );

  Map<String, dynamic> toJson() => {
        'fileId': fileId,
        'driveFileName': driveFileName,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'md5Checksum': md5Checksum,
        'version': version,
        'isUploaded': isUploaded,
        'isModifiedSinceUpload': isModifiedSinceUpload,
      };

  factory DriveMeta.fromJson(Map<String, dynamic> json) => DriveMeta(
        fileId: json['fileId'] as String?,
        driveFileName: json['driveFileName'] as String?,
        lastSyncedAt: json['lastSyncedAt'] != null
            ? DateTime.parse(json['lastSyncedAt'] as String)
            : null,
        md5Checksum: json['md5Checksum'] as String?,
        version: json['version'] as String?,
        isUploaded: json['isUploaded'] as bool? ?? false,
        isModifiedSinceUpload: json['isModifiedSinceUpload'] as bool? ?? false,
      );
}

class Transaction {
  final String id;
  final String cashbookId;
  final double amount;
  final TransactionType type;
  final String category;
  final String remark;
  final String method;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TransactionSyncStatus syncStatus;
  final DriveMeta driveMeta;
  final bool hasAttachment;
  final String? attachmentPath;
  final bool isReconciled;
  final String? parentTransactionId;
  final bool isSplit;

  const Transaction({
    required this.id,
    required this.cashbookId,
    required this.amount,
    required this.type,
    required this.category,
    required this.remark,
    required this.method,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    required this.driveMeta,
    this.hasAttachment = false,
    this.attachmentPath,
    this.isReconciled = false,
    this.parentTransactionId,
    this.isSplit = false,
  });

  Transaction copyWith({
    String? id,
    String? cashbookId,
    double? amount,
    TransactionType? type,
    String? category,
    String? remark,
    String? method,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    TransactionSyncStatus? syncStatus,
    DriveMeta? driveMeta,
    bool? hasAttachment,
    String? attachmentPath,
    bool? isReconciled,
    String? parentTransactionId,
    bool? isSplit,
  }) =>
      Transaction(
        id: id ?? this.id,
        cashbookId: cashbookId ?? this.cashbookId,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        category: category ?? this.category,
        remark: remark ?? this.remark,
        method: method ?? this.method,
        date: date ?? this.date,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
        driveMeta: driveMeta ?? this.driveMeta,
        hasAttachment: hasAttachment ?? this.hasAttachment,
        attachmentPath: attachmentPath ?? this.attachmentPath,
        isReconciled: isReconciled ?? this.isReconciled,
        parentTransactionId: parentTransactionId ?? this.parentTransactionId,
        isSplit: isSplit ?? this.isSplit,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'cashbookId': cashbookId,
        'amount': amount,
        'type': type.name,
        'category': category,
        'remark': remark,
        'method': method,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'syncStatus': syncStatus.name,
        'driveMeta': driveMeta.toJson(),
        'hasAttachment': hasAttachment,
        'attachmentPath': attachmentPath,
        'isReconciled': isReconciled,
        'parentTransactionId': parentTransactionId,
        'isSplit': isSplit,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        cashbookId: json['cashbookId'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: TransactionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => TransactionType.cashIn,
        ),
        category: json['category'] as String,
        remark: json['remark'] as String? ?? '',
        method: json['method'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        syncStatus: TransactionSyncStatus.values.firstWhere(
          (e) => e.name == json['syncStatus'],
          orElse: () => TransactionSyncStatus.pending,
        ),
        driveMeta: DriveMeta.fromJson(
            json['driveMeta'] as Map<String, dynamic>? ?? {}),
        hasAttachment: json['hasAttachment'] as bool? ?? false,
        attachmentPath: json['attachmentPath'] as String?,
        isReconciled: json['isReconciled'] as bool? ?? false,
        parentTransactionId: json['parentTransactionId'] as String?,
        isSplit: json['isSplit'] as bool? ?? false,
      );
}
