import 'package:dm_tools_app_example/domain/app_user.dart';
import 'package:dm_tools_app_example/services/auth_service.dart';

/// Programmable [AuthService] fake for tests: returns canned results and
/// records the calls the code under test made.
class FakeAuthService implements AuthService {
  FakeAuthService({
    this.googleResult,
    this.appleResult,
    this.googleError,
    this.appleError,
  });

  /// Result returned by [signInWithGoogle] — a user on success, `null` when
  /// the flow was canceled by the user.
  AppUser? googleResult;
  AppUser? appleResult;

  /// When set, [signInWithGoogle] throws this instead of returning.
  Object? googleError;
  Object? appleError;

  int googleSignInCalls = 0;
  int appleSignInCalls = 0;
  int signOutCalls = 0;

  @override
  Future<AppUser?> signInWithGoogle() async {
    googleSignInCalls++;
    if (googleError != null) {
      throw googleError!;
    }
    return googleResult;
  }

  @override
  Future<AppUser?> signInWithApple() async {
    appleSignInCalls++;
    if (appleError != null) {
      throw appleError!;
    }
    return appleResult;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

/// Simple signed-in user builder for tests.
AppUser testUser({String id = 'u-1', AuthProvider provider = AuthProvider.google}) {
  return AppUser(
    id: id,
    provider: provider,
    displayName: 'Test User',
    email: 'test@example.com',
  );
}
