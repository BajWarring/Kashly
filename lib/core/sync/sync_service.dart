import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../database_helper.dart';

// 1. AUTH CLIENT
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  GoogleAuthClient(this._headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

// 2. MAIN SYNC ENGINE
class SyncService extends ChangeNotifier {
  static final SyncService instance = SyncService._init();
  SyncService._init();

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveFileScope]);
  
  bool isSyncing = false;
  bool isSignedIn = false;
  String? userEmail;
  int lastSyncTime = 0;
  int pendingChanges = 0;

  Timer? _debounceTimer;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    lastSyncTime = prefs.getInt('lastSyncTime') ?? 0;
    
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      isSignedIn = account != null;
      userEmail = account?.email;
      notifyListeners();
      if (isSignedIn) refreshPendingCount();
    });
    
    await _googleSignIn.signInSilently();
    await refreshPendingCount();
  }

  Future<void> signIn() async { await _googleSignIn.signIn(); }
  Future<void> signOut() async { await _googleSignIn.signOut(); }

  Future<void> refreshPendingCount() async {
    pendingChanges = await DatabaseHelper.instance.getPendingChangesCount(lastSyncTime);
    notifyListeners();
  }

  // Hybrid Event Logic: Called after any DB change
  void triggerAutoSync() {
    refreshPendingCount();
    if (!isSignedIn) return;

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 15), () {
      performSync();
    });
  }

  Future<void> performSync() async {
    if (isSyncing || !isSignedIn) return;
    
    final account = _googleSignIn.currentUser;
    if (account == null) return;

    isSyncing = true;
    notifyListeners();

    try {
      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      // 1. Find Backup File
      final fileList = await driveApi.files.list(q: "name = 'Kashly_Sync_Data.json' and trashed = false", spaces: 'drive');
      String? fileId;
      
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        fileId = fileList.files!.first.id;
        
        // 2. Download and Merge Remote Data
        final drive.Media fileMedia = await driveApi.files.get(fileId!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
        final jsonStr = await utf8.decodeStream(fileMedia.stream);
        
        await DatabaseHelper.instance.mergeDatabaseJSON(jsonStr);
      }

      // 3. Extract newly merged Local DB and Upload
      final localJson = await DatabaseHelper.instance.exportDatabaseJSON();
      final List<int> bytes = utf8.encode(localJson);
      final stream = Stream.value(bytes);
      final media = drive.Media(stream, bytes.length);

      if (fileId != null) {
        await driveApi.files.update(drive.File(), fileId, uploadMedia: media);
      } else {
        final newFile = drive.File()..name = 'Kashly_Sync_Data.json';
        await driveApi.files.create(newFile, uploadMedia: media);
      }

      // 4. Update Time
      lastSyncTime = DateTime.now().millisecondsSinceEpoch;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastSyncTime', lastSyncTime);
      await refreshPendingCount();

    } catch (e) {
      debugPrint("Sync Error: $e");
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }
}
