import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'auth_service.dart';

class DriveService {
  static final DriveService instance = DriveService._init();
  DriveService._init();

  static const String _fileName = 'Kashly_Data_Sync.json';

  Future<drive.DriveApi?> _getApi() async {
    final client = await AuthService.instance.getAuthenticatedClient();
    if (client == null) return null;
    return drive.DriveApi(client);
  }

  Future<String?> getRemoteFileId() async {
    final api = await _getApi();
    if (api == null) return null;

    final fileList = await api.files.list(q: "name = '$_fileName' and trashed = false", spaces: 'drive');
    if (fileList.files != null && fileList.files!.isNotEmpty) {
      return fileList.files!.first.id;
    }
    return null;
  }

  Future<String?> downloadFile(String fileId) async {
    final api = await _getApi();
    if (api == null) return null;

    try {
      final drive.Media fileMedia = await api.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      return await utf8.decodeStream(fileMedia.stream);
    } catch (e) {
      return null;
    }
  }

  Future<void> uploadFile(String jsonContent, {String? existingFileId}) async {
    final api = await _getApi();
    if (api == null) throw Exception("Not authenticated");

    final List<int> bytes = utf8.encode(jsonContent);
    final stream = Stream.value(bytes);
    final media = drive.Media(stream, bytes.length);

    if (existingFileId != null) {
      await api.files.update(drive.File(), existingFileId, uploadMedia: media);
    } else {
      final newFile = drive.File()..name = _fileName;
      await api.files.create(newFile, uploadMedia: media);
    }
  }
}
