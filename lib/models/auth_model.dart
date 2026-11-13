import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/result.dart';
import '../data/token_store.dart';

class AuthModel extends ChangeNotifier {
  AuthModel(this._api, this._tokens) {
    _api.onUnauthorized = logout;
  }
  final ApiClient _api;
  final TokenStore _tokens;
  bool _busy = false;
  int _generation = 0;
  bool get isBusy => _busy;
  bool get isAuthenticated => _api.token != null;
  int get generation => _generation;

  Future<void> restore() async {
    _api.token = await _tokens.read();
  }

  Future<String?> login(String email, String password) => _authenticate(
    '/auth/login',
    {'email': email.trim(), 'password': password},
  );
  Future<String?> register(String name, String email, String password) =>
      _authenticate('/auth/register', {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      });

  Future<String?> _authenticate(String path, Map<String, Object?> body) async {
    if (_busy) return 'Дождитесь завершения входа';
    _busy = true;
    notifyListeners();
    try {
      final result = await _api.send(
        'POST',
        path,
        body: body,
        authenticated: false,
        expected: path.endsWith('register') ? [201] : [200],
      );
      switch (result) {
        case Err(:final msg):
          return msg;
        case Ok(:final value):
          final token = value['token'];
          if (token is! String || token.isEmpty) {
            return 'Сервер не вернул токен входа';
          }
          await _tokens.write(token);
          _api.token = token;
          _generation++;
          return null;
      }
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_api.token == null) return;
    _api.token = null;
    _generation++;
    notifyListeners();
    await _tokens.clear();
  }
}
