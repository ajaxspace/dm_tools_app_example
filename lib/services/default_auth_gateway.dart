import 'package:dm_tools_app_example/domain/auth_exception.dart';
import 'package:dm_tools_app_example/domain/auth_user.dart';
import 'package:dm_tools_app_example/domain/credentials_validator.dart';
import 'package:dm_tools_app_example/services/auth_gateway.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// [AuthGateway] backed by the platform plugins.
///
/// - Google: `google_sign_in` (credentials are saved/offered for autofill by
///   Google Password Manager where the platform supports it).
/// - Apple: `sign_in_with_apple`, following Apple's Sign in with Apple
///   guidelines (offered only where the capability is available).
/// - Email/password: local stub — no backend is wired in this example app, a
///   well-formed credential is accepted and mapped to a local identity.
///   Replace the body with a real identity API call.
class DefaultAuthGateway implements AuthGateway {
  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    if (!CredentialsValidator.isValidEmail(email) ||
        !CredentialsValidator.isValidPassword(password)) {
      throw const AuthException('Invalid email or password.');
    }
    final normalized = email.trim().toLowerCase();
    return AuthUser(
      id: 'local:$normalized',
      email: normalized,
      displayName: normalized.split('@').first,
      provider: AuthProvider.email,
    );
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      return AuthUser(
        id: account.id,
        email: account.email,
        displayName: account.displayName,
        provider: AuthProvider.google,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthCancelledException(e.description ?? 'Google sign-in cancelled.');
      }
      throw AuthException(
          e.description?.isNotEmpty ?? false ? e.description! : 'Google sign-in failed.');
    }
  }

  @override
  Future<AuthUser> signInWithApple() async {
    if (!await SignInWithApple.isAvailable()) {
      throw const AuthException(
          'Sign in with Apple is not available on this device.');
    }
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.fullName,
          AppleIDAuthorizationScopes.email,
        ],
      );
      final name = [
        ?credential.givenName,
        ?credential.familyName,
      ].where((part) => part.isNotEmpty).join(' ').trim();
      return AuthUser(
        id: credential.userIdentifier ?? 'apple:${credential.email ?? 'unknown'}',
        email: (credential.email?.isNotEmpty ?? false) ? credential.email : null,
        displayName: name.isEmpty ? null : name,
        provider: AuthProvider.apple,
      );
    } on AuthException {
      rethrow;
    } on Exception catch (e) {
      throw AuthException('Apple sign-in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } on Exception {
        // Already signed out — nothing to do.
      }
    }
    // Apple: sign-out is server-side per Apple's guidelines; no client-side
    // revocation API is exposed to apps.
  }
}
