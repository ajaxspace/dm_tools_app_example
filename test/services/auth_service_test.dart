import 'package:dm_tools_app_example/domain/app_user.dart';
import 'package:dm_tools_app_example/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sign_in_with_apple_platform_interface/sign_in_with_apple_platform_interface.dart';

/// Records calls and returns canned authentication results.
class _FakeGooglePlatform extends GoogleSignInPlatform {
  AuthenticationResults? authenticateResult;
  Object? authenticateError;
  int initCalls = 0;
  int authenticateCalls = 0;
  int signOutCalls = 0;

  @override
  Future<void> init(InitParameters params) async {
    initCalls++;
  }

  @override
  Future<AuthenticationResults?>? attemptLightweightAuthentication(
    AttemptLightweightAuthenticationParameters params,
  ) async {
    return null;
  }

  @override
  bool supportsAuthenticate() => true;

  @override
  bool authorizationRequiresUserInteraction() => false;

  @override
  Future<AuthenticationResults> authenticate(
    AuthenticateParameters params,
  ) async {
    authenticateCalls++;
    final Object? error = authenticateError;
    if (error != null) {
      throw error;
    }
    return authenticateResult!;
  }

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) async {
    return null;
  }

  @override
  Future<ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
    ServerAuthorizationTokensForScopesParameters params,
  ) async {
    return null;
  }

  @override
  Future<void> signOut(SignOutParams params) async {
    signOutCalls++;
  }

  @override
  Future<void> disconnect(DisconnectParams params) async {
    signOutCalls++;
  }
}

/// Records calls and returns canned Apple credentials.
class _FakeApplePlatform extends SignInWithApplePlatform {
  AuthorizationCredentialAppleID? credential;
  SignInWithAppleException? error;
  int getAppleIDCredentialCalls = 0;

  @override
  Future<AuthorizationCredentialAppleID> getAppleIDCredential({
    required List<AppleIDAuthorizationScopes> scopes,
    WebAuthenticationOptions? webAuthenticationOptions,
    String? nonce,
    String? state,
  }) async {
    getAppleIDCredentialCalls++;
    final SignInWithAppleException? failure = error;
    if (failure != null) {
      throw failure;
    }
    return credential!;
  }

  @override
  Future<CredentialState> getCredentialState(String userIdentifier) async {
    return CredentialState.authorized;
  }

  @override
  Future<bool> isAvailable() async {
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeGooglePlatform googlePlatform;
  late _FakeApplePlatform applePlatform;
  late GoogleAppleAuthService service;

  setUp(() {
    googlePlatform = _FakeGooglePlatform();
    GoogleSignInPlatform.instance = googlePlatform;
    applePlatform = _FakeApplePlatform();
    SignInWithApplePlatform.instance = applePlatform;
    service = GoogleAppleAuthService();
  });

  group('signInWithGoogle', () {
    test('maps the platform account to an AppUser', () async {
      googlePlatform.authenticateResult = const AuthenticationResults(
        user: GoogleSignInUserData(
          id: 'g-1',
          email: 'jane@gmail.com',
          displayName: 'Jane Doe',
        ),
        authenticationTokens: AuthenticationTokenData(idToken: 'token-1'),
      );

      final AppUser? user = await service.signInWithGoogle();

      expect(user, isNotNull);
      expect(user!.id, 'g-1');
      expect(user.provider, AuthProvider.google);
      expect(user.displayName, 'Jane Doe');
      expect(user.email, 'jane@gmail.com');
      expect(googlePlatform.initCalls, 1);
      expect(googlePlatform.authenticateCalls, 1);
    });

    test('initializes the Google SDK only once across multiple sign-ins',
        () async {
      googlePlatform.authenticateResult = const AuthenticationResults(
        user: GoogleSignInUserData(id: 'g-1', email: 'jane@gmail.com'),
        authenticationTokens: AuthenticationTokenData(idToken: 'token-1'),
      );

      await service.signInWithGoogle();
      await service.signInWithGoogle();

      expect(googlePlatform.initCalls, 1,
          reason: 'GoogleSignIn 7.x requires a single initialize() call');
      expect(googlePlatform.authenticateCalls, 2);
    });

    test('returns null when the user cancels the Google flow', () async {
      googlePlatform.authenticateError = const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      );

      final AppUser? user = await service.signInWithGoogle();

      expect(user, isNull);
    });

    test('rethrows non-cancellation Google errors', () async {
      googlePlatform.authenticateError = const GoogleSignInException(
        code: GoogleSignInExceptionCode.networkError,
      );

      await expectLater(service.signInWithGoogle(), throwsException);
    });
  });

  group('signInWithApple', () {
    test('maps the Apple credential to an AppUser', () async {
      applePlatform.credential = const AuthorizationCredentialAppleID(
        userIdentifier: 'a-1',
        givenName: 'John',
        familyName: 'Roe',
        email: 'john@privaterelay.appleid.com',
        authorizationCode: 'code',
        identityToken: 'jwt',
        state: null,
      );

      final AppUser? user = await service.signInWithApple();

      expect(user, isNotNull);
      expect(user!.id, 'a-1');
      expect(user.provider, AuthProvider.apple);
      expect(user.displayName, 'John Roe',
          reason: 'given and family name are joined');
      expect(user.email, 'john@privaterelay.appleid.com');
      expect(applePlatform.getAppleIDCredentialCalls, 1);
    });

    test('handles credentials without name or email (re-authorization)',
        () async {
      applePlatform.credential = const AuthorizationCredentialAppleID(
        userIdentifier: 'a-1',
        givenName: null,
        familyName: null,
        email: null,
        authorizationCode: 'code',
        identityToken: 'jwt',
        state: null,
      );

      final AppUser? user = await service.signInWithApple();

      expect(user!.displayName, isNull);
      expect(user.email, isNull);
      expect(user.id, 'a-1');
    });

    test('falls back to the identity token when no user identifier exists',
        () async {
      applePlatform.credential = const AuthorizationCredentialAppleID(
        userIdentifier: null,
        givenName: null,
        familyName: null,
        email: null,
        authorizationCode: 'code',
        identityToken: 'jwt-fallback',
        state: null,
      );

      final AppUser? user = await service.signInWithApple();

      expect(user!.id, 'jwt-fallback');
    });

    test('returns null when the user cancels the Apple flow', () async {
      applePlatform.error = const SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.canceled,
        message: 'user canceled',
      );

      final AppUser? user = await service.signInWithApple();

      expect(user, isNull);
    });

    test('rethrows non-cancellation Apple errors', () async {
      applePlatform.error = const SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.failed,
        message: 'boom',
      );

      await expectLater(service.signInWithApple(), throwsException);
    });
  });

  group('signOut', () {
    test('signs out from Google', () async {
      await service.signOut();

      expect(googlePlatform.signOutCalls, 1);
    });

    test('does not sign out from Google before the first sign-in', () async {
      final fresh = GoogleAppleAuthService();

      await fresh.signOut();

      expect(googlePlatform.signOutCalls, 0,
          reason: 'signOut before initialize would throw on the real SDK');
    });
  });
}
