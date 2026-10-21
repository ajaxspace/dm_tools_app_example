import 'dart:async';

import 'package:dm_tools_app_example/domain/app_user.dart';
import 'package:dm_tools_app_example/services/auth_service.dart';

/// Programmable [AuthService] fake for tests: returns canned results,
/// records the calls the code under test made, and optionally gates a
/// flow on a [Completer] so tests can hold it in-flight.
class FakeAuthService implements AuthService {
  FakeAuthService({
    this.googleResult,
    this.appleResult,
    this.googleError,
    this.appleError,
    this.googleGate,
    this.appleGate,
  });

  /// Result returned by [signInWithGoogle] — a user on success, `null`
  /// when the flow was canceled by the user.
  AppUser? googleResult;
  AppUser? appleResult;

  /// When set, the respective sign-in throws this instead of returning.
  Object? googleError;
  Object? appleError;

  /// When set, [signInWithGoogle] stays in flight until the completer is
  /// resolved — lets tests assert the busy state.
  Completer<AppUser?>? googleGate;
  Completer<AppUser?>? appleGate;

  int googleSignInCalls = 0;
  int appleSignInCalls = 0;
  int signOutCalls = 0;

  @override
  Future<AppUser?> signInWithGoogle() async {
    googleSignInCalls++;
    final Completer<AppUser?>? gate = googleGate;
    if (gate != null) {
      return gate.future;
    }
    if (googleError != null) {
      throw googleError!;
    }
    return googleResult;
  }

  @override
  Future<AppUser?> signInWithApple() async {
    appleSignInCalls++;
    final Completer<AppUser?>? gate = appleGate;
    if (gate != null) {
      return gate.future;
    }
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
AppUser testUser({
  String id = 'u-1',
  AuthProvider provider = AuthProvider.google,
}) {
  return AppUser(
    id: id,
    provider: provider,
    displayName: 'Test User',
    email: 'test@example.com',
  );
}
