import 'package:dm_tools_app_example/domain/app_user.dart';
import 'package:dm_tools_app_example/main.dart';
import 'package:dm_tools_app_example/services/session_controller.dart';
import 'package:dm_tools_app_example/services/session_store.dart';
import 'package:dm_tools_app_example/ui/home_page.dart';
import 'package:dm_tools_app_example/ui/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_auth_service.dart';

/// In-memory store shared across "app restarts" within a test.
class SharedMemorySessionStore implements SessionStore {
  AppUser? _saved;

  @override
  Future<void> clear() async {
    _saved = null;
  }

  @override
  Future<AppUser?> load() async => _saved;

  @override
  Future<void> save(AppUser user) async {
    _saved = user;
  }
}

void main() {
  testWidgets('starts on the login page when no session is remembered',
      (tester) async {
    final controller = SessionController(
      authService: FakeAuthService(),
      sessionStore: SharedMemorySessionStore(),
    );

    await tester.pumpWidget(DmToolsApp(sessionController: controller));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('restores a remembered session and skips the login page',
      (tester) async {
    final store = SharedMemorySessionStore();
    await store.save(const AppUser(
      id: 'u-1',
      provider: AuthProvider.google,
      displayName: 'Jane Doe',
      email: 'jane@example.com',
    ));

    final controller = SessionController(
      authService: FakeAuthService(),
      sessionStore: store,
    );
    await tester.pumpWidget(DmToolsApp(sessionController: controller));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
    expect(find.text('Jane Doe'), findsOneWidget);
  });

  testWidgets(
      'remembered session survives a simulated restart; sign-out returns to login',
      (tester) async {
    final store = SharedMemorySessionStore();

    // First launch: sign in with remember-me enabled.
    final firstLaunch = SessionController(
      authService: FakeAuthService(googleResult: testUser()),
      sessionStore: store,
    );
    await tester.pumpWidget(DmToolsApp(sessionController: firstLaunch));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('remember_me_toggle')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(store.load(), completion(isNotNull));

    // Second launch: a brand new controller over the same persisted store.
    final secondLaunch = SessionController(
      authService: FakeAuthService(),
      sessionStore: store,
    );
    await tester.pumpWidget(DmToolsApp(sessionController: secondLaunch));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget,
        reason: 'remember-me restores the account on app start');
    expect(find.byType(LoginPage), findsNothing);

    // Sign-out: back to the login page, remembered account cleared.
    await tester.tap(find.byKey(const Key('sign_out_button')));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(store.load(), completion(isNull),
        reason: 'sign-out clears the remembered account');
  });

  testWidgets('session is NOT restored when remember-me was off',
      (tester) async {
    final store = SharedMemorySessionStore();

    final firstLaunch = SessionController(
      authService: FakeAuthService(googleResult: testUser()),
      sessionStore: store,
    );
    await tester.pumpWidget(DmToolsApp(sessionController: firstLaunch));
    await tester.pumpAndSettle();

    // Remember-me stays off (default).
    await tester.tap(find.byKey(const Key('google_sign_in_button')));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);

    final secondLaunch = SessionController(
      authService: FakeAuthService(),
      sessionStore: store,
    );
    await tester.pumpWidget(DmToolsApp(sessionController: secondLaunch));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget,
        reason: 'nothing was persisted, so login is required again');
    expect(find.byType(HomePage), findsNothing);
  });
}
