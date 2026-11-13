import 'package:shelf/shelf.dart';

import 'db.dart';
import 'errors.dart';
import 'security.dart';
import 'trading/schema.dart';

Future<Response> register(Request request) async {
  final body = await readJsonBody(request);
  if (body == null) return validationError('Body must be a JSON object');

  final email = stringField(body, 'email');
  final password = stringField(body, 'password');
  final name = stringField(body, 'name');
  if (email == null || !email.contains('@')) {
    return validationError('A valid email is required');
  }
  if (password == null) return validationError('password is required');
  if (name == null) return validationError('name is required');

  final existing = db.select('SELECT id FROM users WHERE email = ?', [email]);
  if (existing.isNotEmpty) return emailTaken();

  final passwordHash = hashPassword(password);
  final id = transaction(db, () {
    final createdAt = nowIso();
    db.execute(
      'INSERT INTO users (email, password_hash, name, created_at) VALUES (?, ?, ?, ?)',
      [email, passwordHash, name, createdAt],
    );
    final id = db.lastInsertRowId;
    db.execute(
      'INSERT INTO portfolios (user_id, cash_cents, starting_cents, created_at) '
      'VALUES (?, 1000000, 1000000, ?)',
      [id, createdAt],
    );
    return id;
  });

  return jsonResponse({
    'token': issueToken(id),
    'user': {'id': id, 'email': email, 'name': name},
  }, status: 201);
}

Future<Response> login(Request request) async {
  final body = await readJsonBody(request);
  final email = body == null ? null : stringField(body, 'email');
  final password = body == null ? null : stringField(body, 'password');
  if (email == null || password == null) {
    return unauthorized('Invalid email or password');
  }

  final rows = db.select('SELECT * FROM users WHERE email = ?', [email]);
  if (rows.isEmpty) return unauthorized('Invalid email or password');

  final user = rows.first;
  if (!verifyPassword(password, user['password_hash'] as String)) {
    return unauthorized('Invalid email or password');
  }

  return jsonResponse({
    'token': issueToken(user['id'] as int),
    'user': {'id': user['id'], 'email': user['email'], 'name': user['name']},
  });
}

Future<Response> me(Request request) async {
  final rows = db.select('SELECT id, email, name FROM users WHERE id = ?', [
    currentUserId(request),
  ]);
  if (rows.isEmpty) return unauthorized();
  final user = rows.first;
  return jsonResponse({
    'id': user['id'],
    'email': user['email'],
    'name': user['name'],
  });
}

Handler requireAuth(Handler inner) => (Request request) {
  final header = request.headers['authorization'] ?? '';
  if (!header.startsWith('Bearer ')) return unauthorized();
  final userId = verifyToken(header.substring('Bearer '.length));
  if (userId == null) return unauthorized();
  return inner(request.change(context: {'userId': userId}));
};

int currentUserId(Request request) => request.context['userId'] as int;
