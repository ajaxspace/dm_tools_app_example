import 'package:dm_tools_app_example/domain/app_user.dart';
import 'package:dm_tools_app_example/services/session_controller.dart';
import 'package:dm_tools_app_example/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  group('SessionController', () {
    test('restore() with a remembered user ends signed in', () async {
      final user = testUser();
      final store = _RecordingStore(initial: user);
      final controller = SessionController(
        authService: FakeAuthService(),
        sessionStore: store,
      );

      await controller.restore();

      expect(controller.status, SessionStatus.signedIn);
      expect(controller.user, equals(user));
      expect(controller.busy, isFalse);
    });

    test('restore() with nothing remembered ends signed out', () async {
      final controller = SessionController(
        authService: FakeAuthService(),
        sessionStore: _RecordingStore(),
      );

      await controller.restore();

      expect(controller.status, SessionStatus.signedOut);
      expect(controller.user, isNull);
    });

    test('restore() is idempotent when called twice', () async {
      final user = testUser();
      final controller = SessionController(
        authService: FakeAuthService(),
        sessionStore: _RecordingStore(initial: user),
      );

      await controller.restore();
      await controller.restore();

      expect(controller.status, SessionStatus.signedIn);
      expect(controller.user, equals(user));
    });

    test(
      'signInWithGoogle(remember: true) signs in and persists the account',
      () async {
        final user = testUser();
        final store = _RecordingStore();
        final auth = FakeAuthService(googleResult: user);
        final controller = SessionController(authService: auth, sessionStore: store);

        await controller.signInWithGoogle(remember: true);

        expect(controller.status, SessionStatus.signedIn);
        expect(controller.user, equals(user));
        expect(auth.googleSignInCalls, 1);
        expect(store.saveCalls, 1);
        expect(store.saved, equals(user));
      },
    );

    test(
      'signInWithApple(remember: true) signs in and persists the account',
      () async {
        final user = testUser(id: 'a-1', provider: AuthProvider.apple);
        final store = _RecordingStore();
        final auth = FakeAuthService(appleResult: user);
        final controller = SessionController(authService: auth, sessionStore: store);

        await controller.signInWithApple(remember: true);

        expect(controller.status, SessionStatus.signedIn);
        expect(controller.user, equals(user));
        expect(auth.appleSignInCalls, 1);
        expect(store.saved, equals(user));
      },
    );

    test('signInWithGoogle(remember: false) signs in without persisting', () async {
      final store = _RecordingStore();
      final controller = SessionController(
        authService: FakeAuthService(googleResult: testUser()),
        sessionStore: store,
      );

      await controller.signInWithGoogle(remember: false);

      expect(controller.status, SessionStatus.signedIn);
      expect(store.saveCalls, 0);
      expect(store.saved, isNull);
    });

    test('a canceled sign-in keeps the controller signed out', () async {
      final store = _RecordingStore();
      final controller = SessionController(
        authService: FakeAuthService(), // results default to null = canceled
        sessionStore: store,
      );

      await controller.signInWithGoogle(remember: true);
      await controller.signInWithApple(remember: true);

      expect(controller.status, SessionStatus.signedOut);
      expect(controller.user, isNull);
      expect(store.saveCalls, 0);
      expect(controller.error, isNull, reason: 'user cancel is not an error');
    });

    test('a failing sign-in exposes the error and stays signed out', () async {
      final store = _RecordingStore();
      final controller = SessionController(
        authService: FakeAuthService(googleError: Exception('network down')),
        sessionStore: store,
      );

      await controller.signInWithGoogle(remember: true);

      expect(controller.status, SessionStatus.signedOut);
      expect(controller.error, isNotNull);
      expect(store.saveCalls, 0);
    });

    test('signOut() clears the remembered account and returns to signed out',
        () async {
      final user = testUser();
      final store = _RecordingStore(initial: user);
      final auth = FakeAuthService();
      final controller = SessionController(authService: auth, sessionStore: store);
      await controller.restore();
      expect(controller.status, SessionStatus.signedIn);

      await controller.signOut();

      expect(controller.status, SessionStatus.signedOut);
      expect(controller.user, isNull);
      expect(auth.signOutCalls, 1);
      expect(store.cleared, isTrue);
    });

    test('notifies listeners on every state transition', () async {
      final controller = SessionController(
        authService: FakeAuthService(googleResult: testUser()),
        sessionStore: _RecordingStore(),
      );
      final transitions = <SessionStatus>[];
      controller.addListener(() => transitions.add(controller.status));

      await controller.restore();
      await controller.signInWithGoogle(remember: true);
      await controller.signOut();

      expect(transitions.first, SessionStatus.restoring);
      expect(transitions, containsAll(<SessionStatus>[
        SessionStatus.signedOut,
        SessionStatus.signedIn,
      ]));
      expect(transitions.last, SessionStatus.signedOut);
    });
  });
}
