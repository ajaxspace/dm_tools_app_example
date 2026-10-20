import 'package:dm_tools_app_example/domain/auth_exception.dart';
import 'package:dm_tools_app_example/main.dart';
import 'package:dm_tools_app_example/ui/home_page.dart';
import 'package:dm_tools_app_example/ui/login_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('starts on the login page when no session is stored', (
    tester,
  ) async {
    await tester.pumpWidget(DmToolsApp(authService: FakeAuthService()));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('skips login straight to home when a session is restored', (
    tester,
  ) async {
    await tester.pumpWidget(
      DmToolsApp(authService: FakeAuthService(restoredUser: tGoogleUser)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
    expect(find.text(tGoogleUser.email!), findsOneWidget);
  });

  testWidgets('signing in from the login page lands on home', (tester) async {
    await tester.pumpWidget(DmToolsApp(authService: FakeAuthService()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'secret123',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('signing out from home returns to the login page', (
    tester,
  ) async {
    final service = FakeAuthService(restoredUser: tGoogleUser);
    await tester.pumpWidget(DmToolsApp(authService: service));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_sign_out_button')));
    await tester.pumpAndSettle();

    expect(service.signOutCalls, 1);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('a failed sign-in keeps the user on the login page', (
    tester,
  ) async {
    await tester.pumpWidget(DmToolsApp(
      authService: FakeAuthService(
        error: const AuthException('Invalid email or password.'),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'user@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login_password_field')),
      'secret123',
    );
    await tester.tap(find.byKey(const Key('login_submit_button')));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Invalid email or password.'), findsOneWidget);
  });
}
