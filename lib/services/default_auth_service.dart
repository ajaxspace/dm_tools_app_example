import 'package:dm_tools_app_example/domain/auth_exception.dart';
import 'package:dm_tools_app_example/domain/auth_user.dart';
import 'package:dm_tools_app_example/domain/credentials_validator.dart';
import 'package:dm_tools_app_example/services/auth_gateway.dart';
import 'package:dm_tools_app_example/services/auth_service.dart';
import 'package:dm_tools_app_example/services/session_store.dart';

/// Default [AuthService]: delegates authentication to an [AuthGateway] and
/// persists the resulting session via [SessionStore] when "remember me" is on.
class DefaultAuthService implements AuthService {
  DefaultAuthService({required this.gateway, required this.sessionStore});

  final AuthGateway gateway;
  final SessionStore sessionStore;

  @override
  Future<AuthUser> signInWithEmail(
    String email,
    String password, {
    required bool remember,
  }) async {
    if (!CredentialsValidator.isValidEmail(email) ||
        !CredentialsValidator.isValidPassword(password)) {
      throw const AuthException('Invalid email or password.');
    }
    final user = await gateway.signInWithEmail(email, password);
    await _persistIfRemembered(user, remember);
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle({required bool remember}) async {
    final user = await gateway.signInWithGoogle();
    await _persistIfRemembered(user, remember);
    return user;
  }

  @override
  Future<AuthUser> signInWithApple({required bool remember}) async {
    final user = await gateway.signInWithApple();
    await _persistIfRemembered(user, remember);
    return user;
  }

  @override
  Future<AuthUser?> restoreSession() => sessionStore.restore();

  @override
  Future<void> signOut() async {
    await gateway.signOut();
    await sessionStore.clear();
  }

  Future<void> _persistIfRemembered(AuthUser user, bool remember) async {
    if (remember) {
      await sessionStore.save(user);
    }
  }
}
