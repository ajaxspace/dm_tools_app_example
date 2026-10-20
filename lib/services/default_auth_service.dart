import 'package:dm_tools_app_example/domain/auth_exception.dart';
import 'package:dm_tools_app_example/domain/auth_user.dart';
import 'package:dm_tools_app_example/domain/credentials_validator.dart';
import 'package:dm_tools_app_example/services/auth_gateway.dart';
import 'package:dm_tools_app_example/services/auth_service.dart';
import 'package:dm_tools_app_example/services/session_store.dart';

/// Default [AuthService]: delegates authentication to an [AuthGateway] and
/// persists the resulting session via [SessionStore] when "remember me" is on.
class DefaultAuthService implements AuthService {
  DefaultAuthService({
    required AuthGateway gateway,
    required SessionStore sessionStore,
  })  : _gateway = gateway,
        _sessionStore = sessionStore;

  final AuthGateway _gateway;
  final SessionStore _sessionStore;

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
    final user = await _gateway.signInWithEmail(email, password);
    await _persistIfRemembered(user, remember);
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle({required bool remember}) async {
    final user = await _gateway.signInWithGoogle();
    await _persistIfRemembered(user, remember);
    return user;
  }

  @override
  Future<AuthUser> signInWithApple({required bool remember}) async {
    final user = await _gateway.signInWithApple();
    await _persistIfRemembered(user, remember);
    return user;
  }

  @override
  Future<AuthUser?> restoreSession() => _sessionStore.restore();

  @override
  Future<void> signOut() async {
    await _gateway.signOut();
    await _sessionStore.clear();
  }

  Future<void> _persistIfRemembered(AuthUser user, bool remember) async {
    if (remember) {
      await _sessionStore.save(user);
    }
  }
}
