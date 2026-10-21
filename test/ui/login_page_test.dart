import 'dart:async';

import 'package:dm_tools_app_example/domain/app_user.dart';
import 'package:dm_tools_app_example/services/session_controller.dart';
import 'package:dm_tools_app_example/services/session_store.dart';
import 'package:dm_tools_app_example/ui/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../fakes/fake_auth_service.dart';

class _RecordingStore implements SessionStore {
  _RecordingStore();

  AppUser? saved;
  bool cleared = false;
  int saveCalls = 0;

  @override
  Future<void> clear() async {
    cleared = true;
    saved = null;
  }

  @override
  Future<AppUser?> load() async => cleared ? null : saved;

  @override
  Future<void> save(AppUser user) async {
    saveCalls++;
    saved = user;
  }
}

/// Pumps the login page under [platform] and returns the wired pieces.
Future<(FakeAuthService, _RecordingStore, SessionController)> _pumpLogin(
  WidgetTester tester, {
  required FakeAuthService auth,
  required _RecordingStore store,
}) async {
  final controller = SessionController(authService: auth, sessionStore: store);
  await tester.pumpWidget(MaterialApp(home: LoginPage(controller: controller)));
  await tester.pump();
  return (auth, store, controller);
}

void main() {
  testWidgets('renders Google and Apple buttons plus the remember-me toggle', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final (_, _, _) = await _pumpLogin(
      tester,
      auth: FakeAuthService(),
      store: _RecordingStore(),
    );

    expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
    expect(find.byType(SignInWithAppleButton), findsOneWidget);
    expect(find.byKey(const Key('remember_me_toggle')), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('remember_me_toggle')))
          .value,
      isFalse,
      reason: 'remember-me defaults to off',
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Google button is shown on Android, Apple button is not', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await _pumpLogin(tester, auth: FakeAuthService(), store: _RecordingStore());

    expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
    expect(
      find.byType(SignInWithAppleButton),
      findsNothing,
      reason: 'Apple sign-in is iOS-only by platform convention',
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'toggling remember-me then signing in with Google persists the account',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final (auth, store, _) = await _pumpLogin(
        tester,
        auth: FakeAuthService(googleResult: testUser()),
        store: _RecordingStore(),
      );

      await tester.tap(find.byKey(const Key('remember_me_toggle')));
      await tester.pump();
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('remember_me_toggle')))
            .value,
        isTrue,
      );

      await tester.tap(find.byKey(const Key('google_sign_in_button')));
      await tester.pumpAndSettle();

      expect(auth.googleSignInCalls, 1);
      expect(store.saveCalls, 1, reason: 'remember-me was on');
      expect(store.saved?.email, 'test@example.com');
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('signing in with Google without remember-me skips persistence', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final (auth, store, _) = await _pumpLogin(
      tester,
      auth: FakeAuthService(googleResult: testUser()),
      store: _RecordingStore(),
    );

    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pumpAndSettle();

    expect(auth.googleSignInCalls, 1);
    expect(store.saveCalls, 0);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('tapping the Apple button starts Apple sign-in on iOS', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final (auth, _, controller) = await _pumpLogin(
      tester,
      auth: FakeAuthService(appleResult: testUser(id: 'a-1')),
      store: _RecordingStore(),
    );

    await tester.tap(find.byType(SignInWithAppleButton));
    await tester.pumpAndSettle();

    expect(auth.appleSignInCalls, 1);
    expect(controller.status, SessionStatus.signedIn);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('buttons show progress while a sign-in is in flight', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final gate = Completer<AppUser?>();
    final (_, _, controller) = await _pumpLogin(
      tester,
      auth: FakeAuthService(googleGate: gate),
      store: _RecordingStore(),
    );

    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pump();

    expect(controller.busy, isTrue);
    expect(find.byKey(const Key('login_progress')), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('google_sign_in_button')),
          )
          .onPressed,
      isNull,
      reason: 'the button is disabled while a sign-in runs',
    );

    gate.complete(testUser());
    await tester.pumpAndSettle();

    expect(controller.busy, isFalse);
    expect(find.byKey(const Key('login_progress')), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a failed sign-in shows an inline error message', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await _pumpLogin(
      tester,
      auth: FakeAuthService(googleError: Exception('no network')),
      store: _RecordingStore(),
    );

    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_error_text')), findsOneWidget);
    expect(find.textContaining('no network'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
