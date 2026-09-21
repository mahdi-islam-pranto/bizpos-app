import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import 'me.dart';

/// The last `/me` answer, kept so a cold start can draw the right menu on the
/// first frame instead of a spinner.
///
/// It is a *hint*, never the truth: `/me` is always refetched behind it, because
/// an owner may have changed the person's role since the app was last open.
/// Nothing secret lives here — the token is in the keystore.
class MeCache {
  const MeCache._();

  static const _key = 'bizpos.me';

  static Future<Me?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return Me.fromJson(decoded);
    } catch (e) {
      developer.log('could not read the cached session: $e', name: 'session');
      return null;
    }
  }

  static Future<void> write(Me me) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(me.toJson()));
    } catch (e) {
      developer.log('could not cache the session: $e', name: 'session');
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // Nothing to do: a stale cache is discarded on the next sign-in anyway.
    }
  }
}
