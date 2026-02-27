import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class AuthState {
  final GoogleSignInAccount? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    GoogleSignInAccount? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) =>
      AuthState(
        user: user ?? this.user,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '928192611170-em5ubrl4beokniveah3cnf17leq36eo1.apps.googleusercontent.com',
    scopes: [drive.DriveApi.driveScope, drive.DriveApi.driveFileScope],
  );

  Future<void> _init() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        state = AuthState(user: account, isAuthenticated: true);
      }
    } catch (_) {}
  }

  Future<void> signIn() async {
    state = state.copyWith(isLoading: true);
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        state = AuthState(user: account, isAuthenticated: true);
      } else {
        state = const AuthState(error: 'Sign-in cancelled');
      }
    } catch (e) {
      state = AuthState(error: 'Sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    state = const AuthState();
  }

  Future<void> switchAccount() async {
    await _googleSignIn.disconnect();
    state = const AuthState();
    await signIn();
  }

  Future<Map<String, String>> getAuthHeaders() async {
    if (state.user == null) return {};
    return await state.user!.authHeaders;
  }
}
