import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class AuthState {
  final GoogleSignInAccount? user;
  final bool isAuthenticated;

  AuthState({this.user, this.isAuthenticated = false});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '928192611170-em5ubrl4beokniveah3cnf17leq36eo1.apps.googleusercontent.com',
    scopes: [drive.DriveApi.driveScope], // For Drive access
  );

  Future<void> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        state = AuthState(user: account, isAuthenticated: true);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    state = AuthState();
  }

  Future<void> switchAccount() async {
    await signOut();
    await signIn(); // Allows selecting different account
  }

  // Get auth headers for Drive API
  Future<Map<String, String>> getHeaders() async {
    return await state.user?.authHeaders ?? {};
  }
}
