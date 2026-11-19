import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/repositories.dart';

/// Whether the owner is signed in. The router redirects on changes.
class AuthController extends Notifier<bool> {
  @override
  bool build() => ref.watch(authRepositoryProvider).isSignedIn;

  /// Throws [AuthFailure].
  Future<void> signIn(String email, String password) async {
    await ref.read(authRepositoryProvider).signIn(email, password);
    state = true;
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = false;
  }
}

final authControllerProvider = NotifierProvider<AuthController, bool>(
  AuthController.new,
);
