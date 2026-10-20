import 'package:dm_tools_app_example/domain/auth_user.dart';

/// Identity-provider operations the app can perform.
///
/// Implementations throw [AuthException] on failure (including
/// [AuthCancelledException] when the user aborts the flow).
abstract interface class AuthGateway {
  Future<AuthUser> signInWithEmail(String email, String password);

  Future<AuthUser> signInWithGoogle();

  Future<AuthUser> signInWithApple();

  Future<void> signOut();
}
