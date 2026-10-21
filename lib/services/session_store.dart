import 'dart:convert';

import 'package:dm_tools_app_example/domain/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the account to remember between app launches.
///
/// The store holds at most one remembered account: [save] replaces any
/// previous one and [clear] forgets it entirely (sign-out).
abstract class SessionStore {
  /// Remembers [user] across app restarts.
  Future<void> save(AppUser user);

  /// Returns the remembered account, or `null` when none was saved.
  Future<AppUser?> load();

  /// Forgets the remembered account, if any.
  Future<void> clear();
}

/// [SessionStore] backed by `shared_preferences` (local device storage).
class SharedPreferencesSessionStore implements SessionStore {
  /// Creates a store. Tests may inject a [prefs] instance with mock
  /// initial values; production resolves the real one lazily.
  SharedPreferencesSessionStore({SharedPreferences? prefs})
      : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _prefsCache;

  static const String _storageKey = 'remembered_account';

  Future<SharedPreferences> _prefs() async {
    return _prefsOverride ??= await SharedPreferences.getInstance();
  }

  @override
  Future<void> save(AppUser user) async {
    final SharedPreferences prefs = await _prefs();
    await prefs.setString(_storageKey, jsonEncode(user.toJson()));
  }

  @override
  Future<AppUser?> load() async {
    final SharedPreferences prefs = await _prefs();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null) {
      return null;
    }
    return AppUser.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> clear() async {
    final SharedPreferences prefs = await _prefs();
    await prefs.remove(_storageKey);
  }
}

/// In-memory [SessionStore] for tests and previews; nothing survives the
/// process lifetime.
class InMemorySessionStore implements SessionStore {
  AppUser? _user;

  @override
  Future<void> save(AppUser user) async {
    _user = user;
  }

  @override
  Future<AppUser?> load() async {
    return _user;
  }

  @override
  Future<void> clear() async {
    _user = null;
  }
}
