import 'package:dm_tools_app_example/domain/auth_exception.dart';
import 'package:dm_tools_app_example/services/auth_service.dart';
import 'package:dm_tools_app_example/services/default_auth_service.dart';
import 'package:dm_tools_app_example/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

DefaultAuthService _service(FakeAuthGateway gateway) =>
    DefaultAuthService(gateway: gateway, sessionStore: SessionStore());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('DefaultAuthService.signInWithEmail', () {
    test('persists the session when remember-me is on', () async {
      final gateway = FakeAuthGateway();
      final service = _service(gateway);

      final user = await service.signInWithEmail(
        'user@example.com',
        'secret123',
        remember: true,
      );

      expect(gateway.emailCalls, 1);
      expect(gateway.lastEmail, 'user@example.com');
      expect(gateway.lastPassword, 'secret123');
      expect(user, tEmailUser);

      final restored = await service.restoreSession();
      expect(restored, tEmailUser);
    });

    test('does not persist the session when remember-me is off', () async {
      final service = _service(FakeAuthGateway());

      final user = await service.signInWithEmail(
        'user@example.com',
        'secret123',
        remember: false,
      );

      expect(user, tEmailUser);
      expect(await service.restoreSession(), isNull);
    });

    test('propagates gateway failures without persisting', () async {
      final gateway = FakeAuthGateway(
        emailError: const AuthException('Invalid email or password.'),
      );
      final service = _service(gateway);

      await expectLater(
        service.signInWithEmail('user@example.com', 'secret123',
            remember: true),
        throwsA(isA<AuthException>()),
      );
      expect(await service.restoreSession(), isNull);
    });

    test('rejects malformed credentials before hitting the gateway', () async {
      final gateway = FakeAuthGateway();
      final service = _service(gateway);

      await expectLater(
        service.signInWithEmail('not-an-email', 'secret123', remember: true),
        throwsA(isA<AuthException>()),
      );
      expect(gateway.emailCalls, 0);
    });
  });

  group('DefaultAuthService federated sign-in', () {
    test('signInWithGoogle persists the Google user', () async {
      final gateway = FakeAuthGateway();
      final service = _service(gateway);

      final user = await service.signInWithGoogle(remember: true);

      expect(gateway.googleCalls, 1);
      expect(user, tGoogleUser);
      expect(await service.restoreSession(), tGoogleUser);
    });

    test('signInWithApple persists the Apple user', () async {
      final gateway = FakeAuthGateway();
      final service = _service(gateway);

      final user = await service.signInWithApple(remember: true);

      expect(gateway.appleCalls, 1);
      expect(user, tAppleUser);
      expect(await service.restoreSession(), tAppleUser);
    });

    test('federated failure with remember-me leaves no session', () async {
      final gateway = FakeAuthGateway(
        googleError: const AuthException('Google sign-in failed.'),
      );
      final service = _service(gateway);

      await expectLater(
        service.signInWithGoogle(remember: true),
        throwsA(isA<AuthException>()),
      );
      expect(await service.restoreSession(), isNull);
    });
  });

  group('DefaultAuthService.signOut', () {
    test('clears the session and signs out of the gateway', () async {
      final gateway = FakeAuthGateway();
      final service = _service(gateway);
      await service.signInWithEmail('user@example.com', 'secret123',
          remember: true);

      await service.signOut();

      expect(gateway.signOutCalls, 1);
      expect(await service.restoreSession(), isNull);
    });
  });
}
