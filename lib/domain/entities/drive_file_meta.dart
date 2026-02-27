class DriveFileMeta {
  final String fileId;
  final String name;
  final String mimeType;
  final int size;
  final DateTime createdTime;
  final DateTime modifiedTime;
  final String? md5Checksum;
  final String? version;
  final String ownerEmail;

  const DriveFileMeta({
    required this.fileId,
    required this.name,
    required this.mimeType,
    required this.size,
    required this.createdTime,
    required this.modifiedTime,
    this.md5Checksum,
    this.version,
    required this.ownerEmail,
  });

  DriveFileMeta copyWith({
    String? fileId,
    String? name,
    String? mimeType,
    int? size,
    DateTime? createdTime,
    DateTime? modifiedTime,
    String? md5Checksum,
    String? version,
    String? ownerEmail,
  }) =>
      DriveFileMeta(
        fileId: fileId ?? this.fileId,
        name: name ?? this.name,
        mimeType: mimeType ?? this.mimeType,
        size: size ?? this.size,
        createdTime: createdTime ?? this.createdTime,
        modifiedTime: modifiedTime ?? this.modifiedTime,
        md5Checksum: md5Checksum ?? this.md5Checksum,
        version: version ?? this.version,
        ownerEmail: ownerEmail ?? this.ownerEmail,
      );

  Map<String, dynamic> toJson() => {
        'fileId': fileId,
        'name': name,
        'mimeType': mimeType,
        'size': size,
        'createdTime': createdTime.toIso8601String(),
        'modifiedTime': modifiedTime.toIso8601String(),
        'md5Checksum': md5Checksum,
        'version': version,
        'ownerEmail': ownerEmail,
      };

  factory DriveFileMeta.fromJson(Map<String, dynamic> json) => DriveFileMeta(
        fileId: json['fileId'] as String,
        name: json['name'] as String,
        mimeType: json['mimeType'] as String,
        size: json['size'] as int,
        createdTime: DateTime.parse(json['createdTime'] as String),
        modifiedTime: DateTime.parse(json['modifiedTime'] as String),
        md5Checksum: json['md5Checksum'] as String?,
        version: json['version'] as String?,
        ownerEmail: json['ownerEmail'] as String,
      );
}
