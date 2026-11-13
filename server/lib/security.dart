import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

final String jwtSecret =
    Platform.environment['JWT_SECRET'] ?? 'dev-secret-change-me';

String issueToken(int userId) {
  final header = _b64Json({'alg': 'HS256', 'typ': 'JWT'});
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final payload = _b64Json({
    'sub': '$userId',
    'iat': now,
    'exp': now + 7 * 24 * 60 * 60, // 7 days
  });
  return '$header.$payload.${_sign('$header.$payload')}';
}

int? verifyToken(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  if (!_constantTimeEquals(_sign('${parts[0]}.${parts[1]}'), parts[2])) {
    return null;
  }
  try {
    final payload =
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
            as Map<String, dynamic>;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (now >= (payload['exp'] as int)) return null;
    return int.parse(payload['sub'] as String);
  } catch (_) {
    return null;
  }
}

String _b64Json(Map<String, Object> data) =>
    _stripPadding(base64Url.encode(utf8.encode(jsonEncode(data))));

String _sign(String data) => _stripPadding(
  base64Url.encode(
    Hmac(sha256, utf8.encode(jwtSecret)).convert(utf8.encode(data)).bytes,
  ),
);

String _stripPadding(String s) => s.replaceAll('=', '');

const _iterations = 100000;
final _random = Random.secure();

String hashPassword(String password) {
  final salt = List<int>.generate(16, (_) => _random.nextInt(256));
  final hash = _pbkdf2(password, salt, _iterations);
  return '$_iterations:${base64.encode(salt)}:${base64.encode(hash)}';
}

bool verifyPassword(String password, String stored) {
  final parts = stored.split(':');
  if (parts.length != 3) return false;
  final iterations = int.tryParse(parts[0]);
  if (iterations == null) return false;
  final hash = _pbkdf2(password, base64.decode(parts[1]), iterations);
  return _constantTimeEquals(base64.encode(hash), parts[2]);
}

List<int> _pbkdf2(String password, List<int> salt, int iterations) {
  final hmac = Hmac(sha256, utf8.encode(password));
  var block = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
  final result = List<int>.of(block);
  for (var i = 1; i < iterations; i++) {
    block = hmac.convert(block).bytes;
    for (var j = 0; j < result.length; j++) {
      result[j] ^= block[j];
    }
  }
  return result;
}

bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}
