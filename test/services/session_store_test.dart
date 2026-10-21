import 'package:dm_tools_app_example/domain/app_user.dart';
import 'package:dm_tools_app_example/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesSessionStore', () {
    const user = AppUser(
      id: 'user-1',
      provider: AuthProvider.google,
      displayName: 'Jane Doe',
      email: 'jane@example.com',
    );
    const otherUser = AppUser(
      id: 'user-2',
      provider: AuthProvider.apple,
      displayName: 'John Roe',
      email: 'john@example.com',
    );

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('load returns null when nothing was saved', () async {
      final SessionStore store = SharedPreferencesSessionStore(
        prefs: await SharedPreferences.getInstance(),
      );

      expect(await store.load(), isNull);
    });

    test('save then load returns the remembered user', () async {
      final SessionStore store = SharedPreferencesSessionStore(
        prefs: await SharedPreferences.getInstance(),
      );

      await store.save(user);

      expect(await store.load(), equals(user));
    });

    test('save overwrites a previously remembered user', () async {
      final SessionStore store = SharedPreferencesSessionStore(
        prefs: await SharedPreferences.getInstance(),
      );

      await store.save(user);
      await store.save(otherUser);

      expect(await store.load(), equals(otherUser));
    });

    test('clear removes the remembered user', () async {
      final SessionStore store = SharedPreferencesSessionStore(
        prefs: await SharedPreferences.getInstance(),
      );

      await store.save(user);
      await store.clear();

      expect(await store.load(), isNull);
    });
  });

  group('InMemorySessionStore', () {
    test('behaves like the persistent store', () async {
      const user = AppUser(id: 'u', provider: AuthProvider.apple);
      final InMemorySessionStore store = InMemorySessionStore();

      expect(await store.load(), isNull);

      await store.save(user);
      expect(await store.load(), equals(user));

      await store.clear();
      expect(await store.load(), isNull);
    });
  });
}
