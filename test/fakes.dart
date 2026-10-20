import 'package:dm_tools_app_example/domain/auth_exception.dart';
import 'package:dm_tools_app_example/domain/auth_user.dart';
import 'package:dm_tools_app_example/services/auth_gateway.dart';
import 'package:dm_tools_app_example/services/auth_service.dart';

/// Deterministic users reused across tests.
const tEmailUser = AuthUser(
  id: 'local:user@example.com',
  email: 'user@example.com',
  displayName: 'user',
  provider: AuthProvider.email,
);

const tGoogleUser = AuthUser(
  id: 'google-42',
  email: 'google.user@gmail.com',
  displayName: 'Google User',
  provider: AuthProvider.google,
);

const tAppleUser = AuthUser(
  id: 'apple.001234.abcdef.1234',
  email: 'apple.user@icloud.com',
  displayName: 'Apple User',
  provider: AuthProvider.apple,
);

/// [AuthGateway] test double that records calls and returns canned users.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({
    this.emailUser = tEmailUser,
    this.googleUser = tGoogleUser,
    this.appleUser = tAppleUser,
    this.emailError,
    this.googleError,
    this.appleError,
  });

  final AuthUser emailUser;
  final AuthUser googleUser;
  final AuthUser appleUser;
  final Object? emailError;
  final Object? googleError;
  final Object? appleError;

  int emailCalls = 0;
  int googleCalls = 0;
  int appleCalls = 0;
  int signOutCalls = 0;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    emailCalls++;
    lastEmail = email;
    lastPassword = password;
    final error = emailError;
    if (error != null) throw error;
    return emailUser;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    googleCalls++;
    final error = googleError;
    if (error != null) throw error;
    return googleUser;
  }

  @override
  Future<AuthUser> signInWithApple() async {
    appleCalls++;
    final error = appleError;
    if (error != null) throw error;
    return appleUser;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

/// [AuthService] test double for widget tests.
class FakeAuthService implements AuthService {
  FakeAuthService({
    this.user = tEmailUser,
    this.restoredUser,
    this.error,
  });

  final AuthUser user;
  final AuthUser? restoredUser;
  final Object? error;

  int emailCalls = 0;
  int googleCalls = 0;
  int appleCalls = 0;
  int signOutCalls = 0;
  String? lastEmail;
  String? lastPassword;
  bool? lastRemember;

  @override
  Future<AuthUser> signInWithEmail(
    String email,
    String password, {
    required bool remember,
  }) async {
    emailCalls++;
    lastEmail = email;
    lastPassword = password;
    lastRemember = remember;
    final err = error;
    if (err != null) throw err;
    return user;
  }

  @override
  Future<AuthUser> signInWithGoogle({required bool remember}) async {
    googleCalls++;
    lastRemember = remember;
    final err = error;
    if (err != null) throw err;
    return user;
  }

  @override
  Future<AuthUser> signInWithApple({required bool remember}) async {
    appleCalls++;
    lastRemember = remember;
    final err = error;
    if (err != null) throw err;
    return user;
  }

  @override
  Future<AuthUser?> restoreSession() async => restoredUser;

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

/// A failing [AuthService] that throws [AuthException] on any sign-in.
class FailingAuthService extends FakeAuthService {
  FailingAuthService({super.error});
}

/// Convenience builder for an [AuthException].
AuthException authError(String message) => AuthException(message);
