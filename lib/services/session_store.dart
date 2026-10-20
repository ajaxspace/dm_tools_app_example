import 'dart:convert';

import 'package:dm_tools_app_example/domain/auth_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the signed-in user locally so the session survives app restarts
/// ("remember me").
class SessionStore {
  static const String _storageKey = 'auth.session';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> save(AuthUser user) async {
    final prefs = await _prefs;
    await prefs.setString(_key, jsonEncode(user.toJson()));
  }

  /// Returns the persisted session, or null when none was stored (or the
  /// stored payload is unreadable, in which case it is discarded).
  Future<AuthUser?> restore() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_key);
  }

  String get _key => _storageKey;
}
