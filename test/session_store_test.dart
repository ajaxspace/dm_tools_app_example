import 'package:dm_tools_app_example/services/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('restore returns null when nothing was persisted', () async {
      final store = SessionStore();

      expect(await store.restore(), isNull);
    });

    test('save followed by restore returns the same user', () async {
      final store = SessionStore();
      await store.save(tGoogleUser);

      final restored = await store.restore();
      expect(restored, isNotNull);
      expect(restored!.id, tGoogleUser.id);
      expect(restored.email, tGoogleUser.email);
      expect(restored.displayName, tGoogleUser.displayName);
      expect(restored.provider, tGoogleUser.provider);
    });

    test('saving a second user replaces the first', () async {
      final store = SessionStore();
      await store.save(tGoogleUser);
      await store.save(tAppleUser);

      final restored = await store.restore();
      expect(restored, tAppleUser);
    });

    test('clear removes the persisted session', () async {
      final store = SessionStore();
      await store.save(tEmailUser);
      await store.clear();

      expect(await store.restore(), isNull);
    });

    test('different users round-trip with distinct payloads', () async {
      final store = SessionStore();
      final users = [tEmailUser, tGoogleUser, tAppleUser];
      for (final user in users) {
        await store.save(user);
        expect(await store.restore(), user);
      }
    });
  });
}
