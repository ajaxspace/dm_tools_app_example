import 'package:dm_tools_app_example/domain/app_user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Signs users in through the social providers and signs them out.
///
/// Cancellation is reported as `null` (not an exception): the caller can
/// distinguish "user backed out" from "the flow failed".
abstract class AuthService {
  /// Runs the Google sign-in flow. Returns the account, or `null` when the
  /// user canceled.
  Future<AppUser?> signInWithGoogle();

  /// Runs the Apple sign-in flow. Returns the account, or `null` when the
  /// user canceled.
  Future<AppUser?> signInWithApple();

  /// Signs the user out of the active provider session.
  Future<void> signOut();
}

/// Real [AuthService] backed by the `google_sign_in` and
/// `sign_in_with_apple` plugins.
class GoogleAppleAuthService implements AuthService {
  /// Creates the service. Tests may inject a [googleSignIn] instance.
  GoogleAppleAuthService({GoogleSignIn? googleSignIn})
    : _googleSignInOverride = googleSignIn;

  final GoogleSignIn? _googleSignInOverride;
  GoogleSignIn? _googleSignIn;
  bool _googleInitialized = false;

  GoogleSignIn get _google {
    return _googleSignInOverride ?? _googleSignIn ?? GoogleSignIn.instance;
  }

  Future<void> _ensureGoogleInitialized() async {
    if (!_googleInitialized) {
      await _google.initialize();
      _googleInitialized = true;
    }
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    // GoogleSignIn 7.x requires a single initialize() before authenticate().
    await _ensureGoogleInitialized();

    try {
      final GoogleSignInAccount account = await _google.authenticate(
        scopeHint: const <String>['email'],
      );
      return AppUser(
        id: account.id,
        provider: AuthProvider.google,
        displayName: account.displayName,
        email: account.email,
      );
    } on GoogleSignInException catch (exception) {
      if (exception.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<AppUser?> signInWithApple() async {
    try {
      final AuthorizationCredentialAppleID credential =
          await SignInWithApple.getAppleIDCredential(
            scopes: <AppleIDAuthorizationScopes>[
              AppleIDAuthorizationScopes.fullName,
              AppleIDAuthorizationScopes.email,
            ],
          );

      final String displayName =
          <String?>[credential.givenName, credential.familyName]
              .whereType<String>()
              .map((String part) => part.trim())
              .where((String part) => part.isNotEmpty)
              .join(' ');

      return AppUser(
        // iOS always reports a userIdentifier; on other platforms fall
        // back to the identity token so the account is still addressable.
        id:
            credential.userIdentifier ??
            credential.identityToken ??
            'apple-unknown',
        provider: AuthProvider.apple,
        displayName: displayName.isEmpty ? null : displayName,
        email: credential.email,
      );
    } on SignInWithAppleAuthorizationException catch (exception) {
      if (exception.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Initialize first: GoogleSignIn 7.x requires it before any call,
      // including signOut(). This also cleans a Google SDK-side session
      // left over from a previous process (remember-me restore path).
      await _ensureGoogleInitialized();
      await _google.signOut();
    } on GoogleSignInException {
      // Best effort: a device without Google services must still be able
      // to sign out of the local session; the caller clears the store
      // regardless.
    }
  }
}
