import 'package:shared_preferences/shared_preferences.dart';

abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class PreferencesTokenStore implements TokenStore {
  PreferencesTokenStore(this.preferences);
  final SharedPreferencesAsync preferences;
  static const _key = 'auth_token';

  @override
  Future<String?> read() => preferences.getString(_key);
  @override
  Future<void> write(String token) => preferences.setString(_key, token);
  @override
  Future<void> clear() => preferences.remove(_key);
}
