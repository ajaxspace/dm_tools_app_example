import 'package:dm_tools_app_example/domain/auth_exception.dart';
import 'package:dm_tools_app_example/domain/auth_user.dart';
import 'package:dm_tools_app_example/ui/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'fakes.dart';

Widget _host(
  FakeAuthService service, {
  bool appleAvailable = true,
  ValueChanged<AuthUser>? onAuthenticated,
}) {
  return MaterialApp(
    home: LoginPage(
      authService: service,
      appleSignInAvailable: appleAvailable,
      onAuthenticated: onAuthenticated,
    ),
  );
}

Future<void> _enterCredentials(
  WidgetTester tester, {
  String email = 'user@example.com',
  String password = 'secret123',
}) async {
  await tester.enterText(find.byKey(const Key('login_email_field')), email);
  await tester.enterText(find.byKey(const Key('login_password_field')), password);
  await tester.pump();
}

Future<void> _tapSignIn(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('login_submit_button')));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginPage rendering', () {
    testWidgets('renders email, password, remember me and all buttons', (
      tester,
    ) async {
      await tester.pumpWidget(_host(FakeAuthService()));

      expect(find.byKey(const Key('login_email_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.byKey(const Key('login_remember_me')), findsOneWidget);
      expect(find.byKey(const Key('login_google_button')), findsOneWidget);
      expect(find.byKey(const Key('login_apple_button')), findsOneWidget);
    });

    testWidgets('hides the Apple button when Apple sign-in is unavailable', (
      tester,
    ) async {
      await tester.pumpWidget(_host(FakeAuthService(), appleAvailable: false));

      expect(find.byKey(const Key('login_apple_button')), findsNothing);
      expect(find.byKey(const Key('login_google_button')), findsOneWidget);
    });

    testWidgets('remember me is checked by default', (tester) async {
      await tester.pumpWidget(_host(FakeAuthService()));

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });
  });

  group('LoginPage validation', () {
    testWidgets('shows both field errors when submitting empty form', (
      tester,
    ) async {
      await tester.pumpWidget(_host(FakeAuthService()));
      await _tapSignIn(tester);

      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('rejects malformed email addresses', (tester) async {
      await tester.pumpWidget(_host(FakeAuthService()));
      for (final bad in const ['plainaddress', 'a@b', 'foo@bar@baz.com']) {
        await _enterCredentials(tester, email: bad);
        await _tapSignIn(tester);
        expect(find.text('Enter a valid email address'), findsOneWidget,
            reason: '$bad should be rejected');
      }
    });

    testWidgets('rejects short passwords', (tester) async {
      await tester.pumpWidget(_host(FakeAuthService()));
      for (final short in const ['12345', 'ab1']) {
        await _enterCredentials(tester, password: short);
        await _tapSignIn(tester);
        expect(find.text('Password must be at least 6 characters'),
            findsOneWidget,
            reason: '"$short" should be rejected');
      }
    });

    testWidgets('does not call the service when validation fails', (
      tester,
    ) async {
      final service = FakeAuthService();
      await tester.pumpWidget(_host(service));
      await _enterCredentials(tester, email: 'not-an-email');
      await _tapSignIn(tester);

      expect(service.emailCalls, 0);
    });
  });

  group('LoginPage email sign-in', () {
    testWidgets('submits credentials and remember-me flag', (tester) async {
      final service = FakeAuthService();
      AuthUser? authenticated;
      await tester.pumpWidget(_host(
        service,
        onAuthenticated: (user) => authenticated = user,
      ));

      await _enterCredentials(tester);
      // Remember me is checked by default; leave it checked.
      await _tapSignIn(tester);

      expect(service.emailCalls, 1);
      expect(service.lastEmail, 'user@example.com');
      expect(service.lastPassword, 'secret123');
      expect(service.lastRemember, isTrue);
      expect(authenticated, isNotNull);
    });

    testWidgets('reports remember-me unchecked when toggled off', (
      tester,
    ) async {
      final service = FakeAuthService();
      await tester.pumpWidget(_host(service));

      await _enterCredentials(tester);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await _tapSignIn(tester);

      expect(service.emailCalls, 1);
      expect(service.lastRemember, isFalse);
    });

    testWidgets('finishes autofill context after a successful sign-in', (
      tester,
    ) async {
      final finished = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.textInput,
        (call) async {
          if (call.method == 'TextInput.finishAutofillContext') {
            finished.add(call);
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.textInput, null));

      await tester.pumpWidget(_host(FakeAuthService()));
      await _enterCredentials(tester);
      await _tapSignIn(tester);

      expect(finished, isNotEmpty);
    });

    testWidgets('shows an error banner when sign-in fails', (tester) async {
      await tester.pumpWidget(_host(
        FakeAuthService(
          error: const AuthException('Invalid email or password.'),
        ),
      ));

      await _enterCredentials(tester);
      await _tapSignIn(tester);

      expect(find.byKey(const Key('login_error_banner')), findsOneWidget);
      expect(find.text('Invalid email or password.'), findsOneWidget);
    });

    testWidgets('user cancellation shows no error banner', (tester) async {
      await tester.pumpWidget(_host(
        FakeAuthService(error: AuthCancelledException('cancelled')),
      ));

      await _enterCredentials(tester);
      await _tapSignIn(tester);

      expect(find.byKey(const Key('login_error_banner')), findsNothing);
    });

    testWidgets('shows a progress indicator while signing in', (
      tester,
    ) async {
      final service = BlockingAuthService();
      await tester.pumpWidget(_host(service));
      await _enterCredentials(tester);
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      service.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('LoginPage federated sign-in', () {
    testWidgets('Google button calls signInWithGoogle', (tester) async {
      final service = FakeAuthService();
      AuthUser? authenticated;
      await tester.pumpWidget(_host(
        service,
        onAuthenticated: (user) => authenticated = user,
      ));

      await tester.tap(find.byKey(const Key('login_google_button')));
      await tester.pumpAndSettle();

      expect(service.googleCalls, 1);
      expect(service.emailCalls, 0);
      expect(service.lastRemember, isTrue);
      expect(authenticated, isNotNull);
    });

    testWidgets('Apple button calls signInWithApple', (tester) async {
      final service = FakeAuthService();
      AuthUser? authenticated;
      await tester.pumpWidget(_host(
        service,
        onAuthenticated: (user) => authenticated = user,
      ));

      await tester.tap(find.byKey(const Key('login_apple_button')));
      await tester.pumpAndSettle();

      expect(service.appleCalls, 1);
      expect(service.lastRemember, isTrue);
      expect(authenticated, isNotNull);
    });

    testWidgets('Google failure shows the error banner', (tester) async {
      await tester.pumpWidget(_host(
        FakeAuthService(
          error: const AuthException('Google sign-in failed.'),
        ),
      ));

      await tester.tap(find.byKey(const Key('login_google_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_error_banner')), findsOneWidget);
      expect(find.text('Google sign-in failed.'), findsOneWidget);
    });

    testWidgets('renders the Apple-branded button from the package', (
      tester,
    ) async {
      await tester.pumpWidget(_host(FakeAuthService()));

      expect(find.byType(SignInWithAppleButton), findsOneWidget);
    });
  });
}
