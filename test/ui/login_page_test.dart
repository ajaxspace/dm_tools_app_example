import 'package:dm_tools_app_example/domain/app_user.dart';
import 'package:dm_tools_app_example/services/session_controller.dart';
import 'package:dm_tools_app_example/services/session_store.dart';
import 'package:dm_tools_app_example/ui/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../fakes/fake_auth_service.dart';

class _RecordingStore implements SessionStore {
  _RecordingStore({this.initial});

  final AppUser? initial;
  AppUser? saved;
  bool cleared = false;
  int saveCalls = 0;

  @override
  Future<void> clear() async {
    cleared = true;
    saved = null;
  }

  @override
  Future<AppUser?> load() async => cleared ? null : saved ?? initial;

  @override
  Future<void> save(AppUser user) async {
    saveCalls++;
    saved = user;
  }
}

SessionController _controller({
  required FakeAuthService auth,
  required _RecordingStore store,
}) {
  return SessionController(authService: auth, sessionStore: store);
}

Future<void> _pumpLogin(
  WidgetTester tester, {
  required SessionController controller,
}) async {
  await tester.pumpWidget(
    MaterialApp(home: LoginPage(controller: controller)),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    // Tests run as TargetPlatform.android by default on the CI host.
    debugDefaultTargetPlatformOverride = null;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('renders Google and Apple buttons plus the remember-me toggle',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final controller = _controller(auth: FakeAuthService(), store: _RecordingStore());

    await _pumpLogin(tester, controller: controller);

    expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
    expect(find.byType(SignInWithAppleButton), findsOneWidget);
    expect(find.byKey(const Key('remember_me_toggle')), findsOneWidget);
    expect(
      tester.widget<Switch>(find.byKey(const Key('remember_me_toggle'))).value,
      isFalse,
      reason: 'remember-me defaults to off',
    );
  });

  testWidgets('Google button is shown on Android', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final controller = _controller(auth: FakeAuthService(), store: _RecordingStore());

    await _pumpLogin(tester, controller: controller);

    expect(find.byKey(const Key('google_sign_in_button')), findsOneWidget);
    expect(find.byType(SignInWithAppleButton), findsNothing,
        reason: 'Apple sign-in is iOS-only by platform convention');
  });

  testWidgets(
      'toggling remember-me then signing in with Google persists the account',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final auth = FakeAuthService(googleResult: testUser());
    final store = _RecordingStore();
    final controller = _controller(auth: auth, store: store);

    await _pumpLogin(tester, controller: controller);

    await tester.tap(find.byKey(const Key('remember_me_toggle')));
    await tester.pump();
    expect(
      tester.widget<Switch>(find.byKey(const Key('remember_me_toggle'))).value,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pumpAndSettle();

    expect(auth.googleSignInCalls, 1);
    expect(store.saveCalls, 1, reason: 'remember-me was on');
    expect(store.saved?.email, 'test@example.com');
  });

  testWidgets(
      'signing in with Google without remember-me skips persistence',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final auth = FakeAuthService(googleResult: testUser());
    final store = _RecordingStore();
    final controller = _controller(auth: auth, store: store);

    await _pumpLogin(tester, controller: controller);

    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pumpAndSettle();

    expect(auth.googleSignInCalls, 1);
    expect(store.saveCalls, 0);
  });

  testWidgets('tapping the Apple button starts Apple sign-in on iOS',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final auth = FakeAuthService(appleResult: testUser(id: 'a-1'));
    final store = _RecordingStore();
    final controller = _controller(auth: auth, store: store);

    await _pumpLogin(tester, controller: controller);

    await tester.tap(find.byType(SignInWithAppleButton));
    await tester.pumpAndSettle();

    expect(auth.appleSignInCalls, 1);
    expect(controller.status, SessionStatus.signedIn);
  });

  testWidgets('buttons are disabled while a sign-in is in progress',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final auth = FakeAuthService(googleResult: testUser());
    final controller = _controller(auth: auth, store: _RecordingStore());

    await _pumpLogin(tester, controller: controller);

    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    // No pumpAndSettle: assert the in-flight state before it completes.
    await tester.pump();
    await tester.pump();

    expect(controller.busy, isTrue);
    expect(find.byKey(const Key('login_progress')), findsOneWidget);

    await tester.pumpAndSettle();
    expect(controller.busy, isFalse);
  });

  testWidgets('a failed sign-in shows an inline error message', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final controller = _controller(
      auth: FakeAuthService(googleError: Exception('no network')),
      store: _RecordingStore(),
    );

    await _pumpLogin(tester, controller: controller);

    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login_error_text')), findsOneWidget);
    expect(find.textContaining('no network'), findsOneWidget);
  });
}
