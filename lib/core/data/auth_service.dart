import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  GoogleAuthClient(this._headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  // OPTION A: driveFile scope (secure, app-only)
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [drive.DriveApi.driveFileScope]);
  
  Future<GoogleSignInAccount?> signIn() async => await _googleSignIn.signIn();
  Future<GoogleSignInAccount?> signInSilently() async => await _googleSignIn.signInSilently();
  Future<void> signOut() async => await _googleSignIn.signOut();
  
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<GoogleAuthClient?> getAuthenticatedClient() async {
    final account = currentUser;
    if (account == null) return null;
    final headers = await account.authHeaders;
    return GoogleAuthClient(headers);
  }
}
