import 'package:dm_tools_app_example/domain/auth_user.dart';

/// Application-facing authentication operations, combining an identity
/// provider gateway with session persistence.
abstract interface class AuthService {
  Future<AuthUser> signInWithEmail(
    String email,
    String password, {
    required bool remember,
  });

  Future<AuthUser> signInWithGoogle({required bool remember});

  Future<AuthUser> signInWithApple({required bool remember});

  /// Returns the persisted session ("remember me"), or null.
  Future<AuthUser?> restoreSession();

  Future<void> signOut();
}
