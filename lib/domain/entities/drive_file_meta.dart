import 'package:freezed_annotation/freezed.dart';

part 'drive_file_meta.freezed.dart';
part 'drive_file_meta.g.dart';

@freezed
class DriveFileMeta with _$DriveFileMeta {
  const factory DriveFileMeta(
    { 
      required String fileId,
      required String name,
      required String mimeType,
      required int size,
      required DateTime createdTime,
      required DateTime modifiedTime,
      String? md5Checksum,
      String? version,
      required String ownerEmail,
    } 
  ) = _DriveFileMeta;

  factory DriveFileMeta.fromJson(Map<String, Object?> json) => _$DriveFileMetaFromJson(json);
}
