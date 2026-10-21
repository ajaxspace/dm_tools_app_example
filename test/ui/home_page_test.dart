import 'package:dm_tools_app_example/domain/app_user.dart';
import 'package:dm_tools_app_example/services/session_controller.dart';
import 'package:dm_tools_app_example/services/session_store.dart';
import 'package:dm_tools_app_example/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth_service.dart';

class _RecordingStore implements SessionStore {
  _RecordingStore({this.initial});

  final AppUser? initial;
  AppUser? saved;
  bool cleared = false;

  @override
  Future<void> clear() async {
    cleared = true;
    saved = null;
  }

  @override
  Future<AppUser?> load() async => cleared ? null : saved ?? initial;

  @override
  Future<void> save(AppUser user) async {
    saved = user;
  }
}

void main() {
  const user = AppUser(
    id: 'u-1',
    provider: AuthProvider.google,
    displayName: 'Jane Doe',
    email: 'jane@example.com',
  );

  testWidgets('shows the signed-in account details', (tester) async {
    final controller = SessionController(
      authService: FakeAuthService(),
      sessionStore: _RecordingStore(initial: user),
    );
    await controller.restore();

    await tester.pumpWidget(
      MaterialApp(home: HomePage(controller: controller)),
    );

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('jane@example.com'), findsOneWidget);
  });

  testWidgets(
    'falls back to the provider label when the profile has no display name',
    (tester) async {
      const anonymous = AppUser(id: 'a-1', provider: AuthProvider.apple);
      final controller = SessionController(
        authService: FakeAuthService(),
        sessionStore: _RecordingStore(initial: anonymous),
      );
      await controller.restore();

      await tester.pumpWidget(
        MaterialApp(home: HomePage(controller: controller)),
      );

      expect(find.text('Apple account'), findsOneWidget);
    },
  );

  testWidgets('sign-out clears the remembered account', (tester) async {
    final auth = FakeAuthService();
    final store = _RecordingStore(initial: user);
    final controller = SessionController(
      authService: auth,
      sessionStore: store,
    );
    await controller.restore();

    await tester.pumpWidget(
      MaterialApp(home: HomePage(controller: controller)),
    );

    await tester.tap(find.byKey(const Key('sign_out_button')));
    await tester.pumpAndSettle();

    expect(auth.signOutCalls, 1);
    expect(store.cleared, isTrue);
    expect(controller.status, SessionStatus.signedOut);
  });
}
