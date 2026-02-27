enum BackupType { local, googleDrive }

enum BackupStatus { success, failed, partial }

class BackupRecord {
  final String id;
  final BackupType type;
  final List<String> cashbookIds;
  final int transactionCount;
  final String fileName;
  final int fileSizeBytes;
  final DateTime createdAt;
  final String? driveFileId;
  final BackupStatus status;
  final String? notes;
  final String? checksum;

  const BackupRecord({
    required this.id,
    required this.type,
    required this.cashbookIds,
    required this.transactionCount,
    required this.fileName,
    required this.fileSizeBytes,
    required this.createdAt,
    this.driveFileId,
    required this.status,
    this.notes,
    this.checksum,
  });

  BackupRecord copyWith({
    String? id,
    BackupType? type,
    List<String>? cashbookIds,
    int? transactionCount,
    String? fileName,
    int? fileSizeBytes,
    DateTime? createdAt,
    String? driveFileId,
    BackupStatus? status,
    String? notes,
    String? checksum,
  }) =>
      BackupRecord(
        id: id ?? this.id,
        type: type ?? this.type,
        cashbookIds: cashbookIds ?? this.cashbookIds,
        transactionCount: transactionCount ?? this.transactionCount,
        fileName: fileName ?? this.fileName,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        createdAt: createdAt ?? this.createdAt,
        driveFileId: driveFileId ?? this.driveFileId,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        checksum: checksum ?? this.checksum,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'cashbookIds': cashbookIds,
        'transactionCount': transactionCount,
        'fileName': fileName,
        'fileSizeBytes': fileSizeBytes,
        'createdAt': createdAt.toIso8601String(),
        'driveFileId': driveFileId,
        'status': status.name,
        'notes': notes,
        'checksum': checksum,
      };

  factory BackupRecord.fromJson(Map<String, dynamic> json) => BackupRecord(
        id: json['id'] as String,
        type: BackupType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => BackupType.local,
        ),
        cashbookIds: List<String>.from(json['cashbookIds'] as List),
        transactionCount: json['transactionCount'] as int,
        fileName: json['fileName'] as String,
        fileSizeBytes: json['fileSizeBytes'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        driveFileId: json['driveFileId'] as String?,
        status: BackupStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => BackupStatus.failed,
        ),
        notes: json['notes'] as String?,
        checksum: json['checksum'] as String?,
      );
}
