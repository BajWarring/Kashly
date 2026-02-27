enum AutoBackupInterval { daily, weekly, monthly, custom }

class AppBackupSettings {
  final bool autoBackupEnabled;
  final AutoBackupInterval autoBackupInterval;
  final String? autoBackupTime;
  final int maxLocalBackups;
  final String? localBackupPath;
  final bool driveBackupEnabled;
  final bool driveAutoVersioning;
  final String? driveBackupFolderId;
  final bool includeAttachmentsInDrive;
  final bool uploadOnMeteredNetwork;
  final bool onlyOnUnmeteredNetwork;
  final bool backupOverRoaming;
  final bool backupOnlyWhenCharging;
  final int? bandwidthLimitKbps;
  final bool encryptionEnabled;
  final String? encryptionPasswordHint;
  final bool promptBeforeOverwrite;
  final bool incrementalBackup;
  final bool requireBiometricToRestore;
  final bool notifyOnSuccess;
  final bool notifyOnFailure;
  final String? doNotDisturbStart;
  final String? doNotDisturbEnd;

  const AppBackupSettings({
    this.autoBackupEnabled = false,
    this.autoBackupInterval = AutoBackupInterval.daily,
    this.autoBackupTime,
    this.maxLocalBackups = 5,
    this.localBackupPath,
    this.driveBackupEnabled = false,
    this.driveAutoVersioning = true,
    this.driveBackupFolderId,
    this.includeAttachmentsInDrive = false,
    this.uploadOnMeteredNetwork = true,
    this.onlyOnUnmeteredNetwork = false,
    this.backupOverRoaming = false,
    this.backupOnlyWhenCharging = false,
    this.bandwidthLimitKbps,
    this.encryptionEnabled = false,
    this.encryptionPasswordHint,
    this.promptBeforeOverwrite = true,
    this.incrementalBackup = true,
    this.requireBiometricToRestore = false,
    this.notifyOnSuccess = true,
    this.notifyOnFailure = true,
    this.doNotDisturbStart,
    this.doNotDisturbEnd,
  });

  AppBackupSettings copyWith({
    bool? autoBackupEnabled,
    AutoBackupInterval? autoBackupInterval,
    String? autoBackupTime,
    int? maxLocalBackups,
    String? localBackupPath,
    bool? driveBackupEnabled,
    bool? driveAutoVersioning,
    String? driveBackupFolderId,
    bool? includeAttachmentsInDrive,
    bool? uploadOnMeteredNetwork,
    bool? onlyOnUnmeteredNetwork,
    bool? backupOverRoaming,
    bool? backupOnlyWhenCharging,
    int? bandwidthLimitKbps,
    bool? encryptionEnabled,
    String? encryptionPasswordHint,
    bool? promptBeforeOverwrite,
    bool? incrementalBackup,
    bool? requireBiometricToRestore,
    bool? notifyOnSuccess,
    bool? notifyOnFailure,
    String? doNotDisturbStart,
    String? doNotDisturbEnd,
  }) =>
      AppBackupSettings(
        autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
        autoBackupInterval: autoBackupInterval ?? this.autoBackupInterval,
        autoBackupTime: autoBackupTime ?? this.autoBackupTime,
        maxLocalBackups: maxLocalBackups ?? this.maxLocalBackups,
        localBackupPath: localBackupPath ?? this.localBackupPath,
        driveBackupEnabled: driveBackupEnabled ?? this.driveBackupEnabled,
        driveAutoVersioning: driveAutoVersioning ?? this.driveAutoVersioning,
        driveBackupFolderId: driveBackupFolderId ?? this.driveBackupFolderId,
        includeAttachmentsInDrive:
            includeAttachmentsInDrive ?? this.includeAttachmentsInDrive,
        uploadOnMeteredNetwork:
            uploadOnMeteredNetwork ?? this.uploadOnMeteredNetwork,
        onlyOnUnmeteredNetwork:
            onlyOnUnmeteredNetwork ?? this.onlyOnUnmeteredNetwork,
        backupOverRoaming: backupOverRoaming ?? this.backupOverRoaming,
        backupOnlyWhenCharging:
            backupOnlyWhenCharging ?? this.backupOnlyWhenCharging,
        bandwidthLimitKbps: bandwidthLimitKbps ?? this.bandwidthLimitKbps,
        encryptionEnabled: encryptionEnabled ?? this.encryptionEnabled,
        encryptionPasswordHint:
            encryptionPasswordHint ?? this.encryptionPasswordHint,
        promptBeforeOverwrite:
            promptBeforeOverwrite ?? this.promptBeforeOverwrite,
        incrementalBackup: incrementalBackup ?? this.incrementalBackup,
        requireBiometricToRestore:
            requireBiometricToRestore ?? this.requireBiometricToRestore,
        notifyOnSuccess: notifyOnSuccess ?? this.notifyOnSuccess,
        notifyOnFailure: notifyOnFailure ?? this.notifyOnFailure,
        doNotDisturbStart: doNotDisturbStart ?? this.doNotDisturbStart,
        doNotDisturbEnd: doNotDisturbEnd ?? this.doNotDisturbEnd,
      );

  Map<String, dynamic> toJson() => {
        'autoBackupEnabled': autoBackupEnabled,
        'autoBackupInterval': autoBackupInterval.name,
        'autoBackupTime': autoBackupTime,
        'maxLocalBackups': maxLocalBackups,
        'localBackupPath': localBackupPath,
        'driveBackupEnabled': driveBackupEnabled,
        'driveAutoVersioning': driveAutoVersioning,
        'driveBackupFolderId': driveBackupFolderId,
        'includeAttachmentsInDrive': includeAttachmentsInDrive,
        'uploadOnMeteredNetwork': uploadOnMeteredNetwork,
        'onlyOnUnmeteredNetwork': onlyOnUnmeteredNetwork,
        'backupOverRoaming': backupOverRoaming,
        'backupOnlyWhenCharging': backupOnlyWhenCharging,
        'bandwidthLimitKbps': bandwidthLimitKbps,
        'encryptionEnabled': encryptionEnabled,
        'encryptionPasswordHint': encryptionPasswordHint,
        'promptBeforeOverwrite': promptBeforeOverwrite,
        'incrementalBackup': incrementalBackup,
        'requireBiometricToRestore': requireBiometricToRestore,
        'notifyOnSuccess': notifyOnSuccess,
        'notifyOnFailure': notifyOnFailure,
        'doNotDisturbStart': doNotDisturbStart,
        'doNotDisturbEnd': doNotDisturbEnd,
      };

  factory AppBackupSettings.fromJson(Map<String, dynamic> json) =>
      AppBackupSettings(
        autoBackupEnabled: json['autoBackupEnabled'] as bool? ?? false,
        autoBackupInterval: AutoBackupInterval.values.firstWhere(
          (e) => e.name == json['autoBackupInterval'],
          orElse: () => AutoBackupInterval.daily,
        ),
        autoBackupTime: json['autoBackupTime'] as String?,
        maxLocalBackups: json['maxLocalBackups'] as int? ?? 5,
        localBackupPath: json['localBackupPath'] as String?,
        driveBackupEnabled: json['driveBackupEnabled'] as bool? ?? false,
        driveAutoVersioning: json['driveAutoVersioning'] as bool? ?? true,
        driveBackupFolderId: json['driveBackupFolderId'] as String?,
        includeAttachmentsInDrive:
            json['includeAttachmentsInDrive'] as bool? ?? false,
        uploadOnMeteredNetwork:
            json['uploadOnMeteredNetwork'] as bool? ?? true,
        onlyOnUnmeteredNetwork:
            json['onlyOnUnmeteredNetwork'] as bool? ?? false,
        backupOverRoaming: json['backupOverRoaming'] as bool? ?? false,
        backupOnlyWhenCharging:
            json['backupOnlyWhenCharging'] as bool? ?? false,
        bandwidthLimitKbps: json['bandwidthLimitKbps'] as int?,
        encryptionEnabled: json['encryptionEnabled'] as bool? ?? false,
        encryptionPasswordHint: json['encryptionPasswordHint'] as String?,
        promptBeforeOverwrite: json['promptBeforeOverwrite'] as bool? ?? true,
        incrementalBackup: json['incrementalBackup'] as bool? ?? true,
        requireBiometricToRestore:
            json['requireBiometricToRestore'] as bool? ?? false,
        notifyOnSuccess: json['notifyOnSuccess'] as bool? ?? true,
        notifyOnFailure: json['notifyOnFailure'] as bool? ?? true,
        doNotDisturbStart: json['doNotDisturbStart'] as String?,
        doNotDisturbEnd: json['doNotDisturbEnd'] as String?,
      );
}
