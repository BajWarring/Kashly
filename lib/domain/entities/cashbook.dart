enum SyncStatus { synced, pending, error, conflict }

class BackupSettings {
  final bool autoBackupEnabled;
  final bool includeAttachments;
  final DateTime? lastBackupAt;
  final String? lastBackupFileId;

  const BackupSettings({
    required this.autoBackupEnabled,
    required this.includeAttachments,
    this.lastBackupAt,
    this.lastBackupFileId,
  });

  BackupSettings copyWith({
    bool? autoBackupEnabled,
    bool? includeAttachments,
    DateTime? lastBackupAt,
    String? lastBackupFileId,
  }) =>
      BackupSettings(
        autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
        includeAttachments: includeAttachments ?? this.includeAttachments,
        lastBackupAt: lastBackupAt ?? this.lastBackupAt,
        lastBackupFileId: lastBackupFileId ?? this.lastBackupFileId,
      );

  Map<String, dynamic> toJson() => {
        'autoBackupEnabled': autoBackupEnabled,
        'includeAttachments': includeAttachments,
        'lastBackupAt': lastBackupAt?.toIso8601String(),
        'lastBackupFileId': lastBackupFileId,
      };

  factory BackupSettings.fromJson(Map<String, dynamic> json) => BackupSettings(
        autoBackupEnabled: json['autoBackupEnabled'] as bool? ?? false,
        includeAttachments: json['includeAttachments'] as bool? ?? false,
        lastBackupAt: json['lastBackupAt'] != null
            ? DateTime.parse(json['lastBackupAt'] as String)
            : null,
        lastBackupFileId: json['lastBackupFileId'] as String?,
      );
}

class Cashbook {
  final String id;
  final String name;
  final String currency;
  final double openingBalance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final BackupSettings backupSettings;
  final bool isArchived;

  const Cashbook({
    required this.id,
    required this.name,
    required this.currency,
    required this.openingBalance,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    required this.backupSettings,
    this.isArchived = false,
  });

  Cashbook copyWith({
    String? id,
    String? name,
    String? currency,
    double? openingBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    BackupSettings? backupSettings,
    bool? isArchived,
  }) =>
      Cashbook(
        id: id ?? this.id,
        name: name ?? this.name,
        currency: currency ?? this.currency,
        openingBalance: openingBalance ?? this.openingBalance,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
        backupSettings: backupSettings ?? this.backupSettings,
        isArchived: isArchived ?? this.isArchived,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'currency': currency,
        'openingBalance': openingBalance,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'syncStatus': syncStatus.name,
        'backupSettings': backupSettings.toJson(),
        'isArchived': isArchived,
      };

  factory Cashbook.fromJson(Map<String, dynamic> json) => Cashbook(
        id: json['id'] as String,
        name: json['name'] as String,
        currency: json['currency'] as String,
        openingBalance: (json['openingBalance'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        syncStatus: SyncStatus.values.firstWhere(
          (e) => e.name == json['syncStatus'],
          orElse: () => SyncStatus.pending,
        ),
        backupSettings: BackupSettings.fromJson(
            json['backupSettings'] as Map<String, dynamic>),
        isArchived: json['isArchived'] as bool? ?? false,
      );
}
