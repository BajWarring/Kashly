import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class DriveService {
  static final DriveService instance = DriveService._init();
  DriveService._init();

  static const String _folderName = 'Kashly App Backups';
  static const String _lastSyncWeekPrefKey = 'lastSyncIsoWeek';

  // 5 rotating weekly backup filenames, index 0 = newest
  static const List<String> weeklyFileNames = [
    'current_week_backup.json',
    'one_week_ago_backup.json',
    'two_weeks_ago_backup.json',
    'three_weeks_ago_backup.json',
    'four_weeks_ago_backup.json',
  ];

  Future<drive.DriveApi?> _getApi() async {
    final client = await AuthService.instance.getAuthenticatedClient();
    if (client == null) return null;
    return drive.DriveApi(client);
  }

  // ─── FOLDER ──────────────────────────────────────────────────────────────────

  Future<String> _getOrCreateFolder() async {
    final api = await _getApi();
    if (api == null) throw Exception('Not authenticated');

    final q = "name = '$_folderName' "
        "and mimeType = 'application/vnd.google-apps.folder' "
        "and trashed = false";
    final result = await api.files.list(q: q, spaces: 'drive', $fields: 'files(id)');

    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first.id!;
    }

    final folder = drive.File()
      ..name = _folderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await api.files.create(folder, $fields: 'id');
    debugPrint('[DriveService] Created folder "$_folderName" id=${created.id}');
    return created.id!;
  }

  // ─── FILE HELPERS ─────────────────────────────────────────────────────────────

  Future<drive.File?> _findFile(
      drive.DriveApi api, String fileName, String folderId) async {
    final q = "name = '$fileName' and '$folderId' in parents and trashed = false";
    final result = await api.files.list(
      q: q,
      spaces: 'drive',
      $fields: 'files(id,name,size,modifiedTime)',
    );
    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first;
    }
    return null;
  }

  Future<void> _upsertFile(
    drive.DriveApi api, {
    required String fileName,
    required String folderId,
    required String jsonContent,
  }) async {
    final bytes = utf8.encode(jsonContent);
    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );

    final existing = await _findFile(api, fileName, folderId);
    if (existing != null) {
      await api.files.update(drive.File(), existing.id!, uploadMedia: media);
      debugPrint('[DriveService] Updated: $fileName');
    } else {
      final newFile = drive.File()
        ..name = fileName
        ..parents = [folderId];
      await api.files.create(newFile, uploadMedia: media);
      debugPrint('[DriveService] Created: $fileName');
    }
  }

  // ─── WEEKLY ROTATION ─────────────────────────────────────────────────────────

  String _isoWeekKey(DateTime date) {
    // ISO week: Monday-based, week 1 = week containing first Thursday
    final thursday = date.add(Duration(days: 4 - date.weekday));
    final weekOfYear =
        1 + (thursday.difference(DateTime(thursday.year)).inDays ~/ 7);
    return '${thursday.year}-W${weekOfYear.toString().padLeft(2, '0')}';
  }

  /// Uploads json with weekly rotation.
  /// - Same week  → updates current_week_backup.json only
  /// - New week   → rotates all 5 slots, then writes new current
  Future<void> uploadWithWeeklyRotation(String jsonContent) async {
    final api = await _getApi();
    if (api == null) throw Exception('Not authenticated');

    final folderId = await _getOrCreateFolder();
    final currentWeekKey = _isoWeekKey(DateTime.now());

    final prefs = await SharedPreferences.getInstance();
    final lastWeekKey = prefs.getString(_lastSyncWeekPrefKey) ?? '';

    final isNewWeek = lastWeekKey.isNotEmpty && lastWeekKey != currentWeekKey;

    if (isNewWeek) {
      await _rotateWeeklyBackups(api, folderId);
    }

    await _upsertFile(
      api,
      fileName: weeklyFileNames[0],
      folderId: folderId,
      jsonContent: jsonContent,
    );

    await prefs.setString(_lastSyncWeekPrefKey, currentWeekKey);
    debugPrint('[DriveService] Sync done. Week=$currentWeekKey rotated=$isNewWeek');
  }

  /// Rotates slots: four_weeks_ago deleted, others shift down by one position.
  Future<void> _rotateWeeklyBackups(
      drive.DriveApi api, String folderId) async {
    debugPrint('[DriveService] Rotating weekly backup slots...');

    // Delete oldest (four_weeks_ago)
    final oldest = await _findFile(api, weeklyFileNames[4], folderId);
    if (oldest != null) {
      await api.files.delete(oldest.id!);
      debugPrint('[DriveService] Deleted: ${weeklyFileNames[4]}');
    }

    // Rename from second-oldest toward newest: [3]→[4], [2]→[3], [1]→[2], [0]→[1]
    for (int i = weeklyFileNames.length - 1; i > 0; i--) {
      final src = await _findFile(api, weeklyFileNames[i - 1], folderId);
      if (src != null) {
        await api.files.update(
          drive.File()..name = weeklyFileNames[i],
          src.id!,
        );
        debugPrint(
            '[DriveService] Renamed ${weeklyFileNames[i - 1]} → ${weeklyFileNames[i]}');
      }
    }
  }

  // ─── DOWNLOAD ─────────────────────────────────────────────────────────────────

  Future<String?> downloadCurrentBackup() async {
    final api = await _getApi();
    if (api == null) return null;
    try {
      final folderId = await _getOrCreateFolder();
      final file = await _findFile(api, weeklyFileNames[0], folderId);
      if (file == null) return null;
      return await _downloadById(api, file.id!);
    } catch (e) {
      debugPrint('[DriveService] downloadCurrentBackup error: $e');
      return null;
    }
  }

  Future<String?> downloadBackupByName(String fileName) async {
    final api = await _getApi();
    if (api == null) return null;
    try {
      final folderId = await _getOrCreateFolder();
      final file = await _findFile(api, fileName, folderId);
      if (file == null) return null;
      return await _downloadById(api, file.id!);
    } catch (e) {
      debugPrint('[DriveService] downloadBackupByName error: $e');
      return null;
    }
  }

  Future<String> _downloadById(drive.DriveApi api, String fileId) async {
    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    return utf8.decodeStream(media.stream);
  }

  // ─── STORAGE INFO ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDriveStorageInfo() async {
    final api = await _getApi();
    if (api == null) return {};
    try {
      final about = await api.about.get($fields: 'storageQuota');
      final quota = about.storageQuota;
      final usedBytes = int.tryParse(quota?.usage ?? '0') ?? 0;
      final totalBytes = int.tryParse(quota?.limit ?? '0') ?? 0;
      return {
        'used': _fmtBytes(usedBytes),
        'total': totalBytes > 0 ? _fmtBytes(totalBytes) : 'Unlimited',
        'fraction': totalBytes > 0 ? (usedBytes / totalBytes).clamp(0.0, 1.0) : 0.0,
      };
    } catch (e) {
      debugPrint('[DriveService] getDriveStorageInfo error: $e');
      return {};
    }
  }

  /// Returns metadata for all existing backup files in the Drive folder.
  Future<List<Map<String, String>>> listBackupFiles() async {
    final api = await _getApi();
    if (api == null) return [];
    try {
      final folderId = await _getOrCreateFolder();
      final List<Map<String, String>> result = [];
      for (final fileName in weeklyFileNames) {
        final file = await _findFile(api, fileName, folderId);
        if (file != null) {
          result.add({
            'name': fileName,
            'label': _labelForFile(fileName),
            'size': file.size != null
                ? _fmtBytes(int.tryParse(file.size!) ?? 0)
                : '—',
            'modified': file.modifiedTime != null
                ? _fmtDate(file.modifiedTime!)
                : '—',
          });
        }
      }
      return result;
    } catch (e) {
      debugPrint('[DriveService] listBackupFiles error: $e');
      return [];
    }
  }

  // ─── FORMATTING HELPERS ───────────────────────────────────────────────────────

  String _labelForFile(String fileName) {
    switch (fileName) {
      case 'current_week_backup.json':    return 'This Week';
      case 'one_week_ago_backup.json':    return '1 Week Ago';
      case 'two_weeks_ago_backup.json':   return '2 Weeks Ago';
      case 'three_weeks_ago_backup.json': return '3 Weeks Ago';
      case 'four_weeks_ago_backup.json':  return '4 Weeks Ago';
      default: return fileName;
    }
  }

  String _fmtBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _fmtDate(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inDays == 0) return 'Today, ${_fmtTime(local)}';
    if (diff.inDays == 1) return 'Yesterday, ${_fmtTime(local)}';
    return '${local.day} ${_monthName(local.month)} ${local.year}, ${_fmtTime(local)}';
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? 'AM' : 'PM'}';
  }

  String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}
