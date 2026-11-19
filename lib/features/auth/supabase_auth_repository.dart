import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/repositories.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);
  final GoTrueClient _auth;

  @override
  bool get isSignedIn => _auth.currentSession != null;

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithPassword(email: email, password: password);
    } on AuthRetryableFetchException {
      throw const AuthFailure(AuthFailureKind.connection);
    } on AuthException {
      throw const AuthFailure(AuthFailureKind.invalidCredentials);
    } catch (_) {
      // Socket/HTTP errors before Supabase answers.
      throw const AuthFailure(AuthFailureKind.connection);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
