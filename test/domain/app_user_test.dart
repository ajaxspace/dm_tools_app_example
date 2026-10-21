import 'package:dm_tools_app_example/domain/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUser', () {
    const googleUser = AppUser(
      id: 'google-1',
      provider: AuthProvider.google,
      displayName: 'Jane Doe',
      email: 'jane@example.com',
    );
    const appleUser = AppUser(
      id: 'apple-1',
      provider: AuthProvider.apple,
      displayName: 'John Roe',
      email: 'john@privaterelay.appleid.com',
    );

    test('toJson/fromJson roundtrips a Google user', () {
      final AppUser restored = AppUser.fromJson(googleUser.toJson());

      expect(restored, equals(googleUser));
      expect(restored.id, 'google-1');
      expect(restored.provider, AuthProvider.google);
      expect(restored.displayName, 'Jane Doe');
      expect(restored.email, 'jane@example.com');
    });

    test('toJson/fromJson roundtrips an Apple user', () {
      final AppUser restored = AppUser.fromJson(appleUser.toJson());

      expect(restored, equals(appleUser));
      expect(restored.provider, AuthProvider.apple);
    });

    test('toJson/fromJson roundtrips nullable profile fields', () {
      // Apple only returns name/email on the first authorization; later
      // credentials carry just the user identifier.
      const anonymousAppleUser = AppUser(
        id: 'apple-2',
        provider: AuthProvider.apple,
      );

      final AppUser restored = AppUser.fromJson(anonymousAppleUser.toJson());

      expect(restored, equals(anonymousAppleUser));
      expect(restored.displayName, isNull);
      expect(restored.email, isNull);
    });

    test('fromJson throws for an unknown provider', () {
      expect(
        () => AppUser.fromJson(<String, dynamic>{
          'id': 'x',
          'provider': 'microsoft',
        }),
        throwsArgumentError,
      );
    });

    test('users with different ids or providers are not equal', () {
      expect(googleUser, isNot(equals(appleUser)));
      expect(
        googleUser,
        isNot(
          equals(const AppUser(id: 'google-2', provider: AuthProvider.google)),
        ),
      );
      expect(googleUser, equals(googleUser));
    });

    test('copyWith replaces only the given fields', () {
      final AppUser updated = googleUser.copyWith(displayName: 'Jane Roe');

      expect(updated.displayName, 'Jane Roe');
      expect(updated.id, googleUser.id);
      expect(updated.provider, googleUser.provider);
      expect(updated.email, googleUser.email);
    });
  });
}
