import 'dart:convert';
import 'dart:io';

import 'package:server/app.dart';
import 'package:server/db.dart';
import 'package:server/files.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late Handler handler;
  late Directory uploads;
  setUpAll(() {
    initDb(':memory:');
    uploads = Directory.systemTemp.createTempSync('trade_arena_test_');
    initFileStorage(uploads.path);
    handler = createHandler();
  });
  tearDownAll(() {
    db.close();
    uploads.deleteSync(recursive: true);
  });

  Future<Response> call(
    String method,
    String path, {
    String? token,
    Map<String, Object?>? body,
  }) async => handler(
    Request(
      method,
      Uri.parse('http://localhost$path'),
      headers: {
        if (token != null) 'authorization': 'Bearer $token',
        if (body != null) 'content-type': 'application/json',
      },
      body: body == null ? null : jsonEncode(body),
    ),
  );
  Future<Map<String, dynamic>> json(Response response) async =>
      jsonDecode(await response.readAsString()) as Map<String, dynamic>;

  test(
    'Пробелы в пароле сохраняются, регистр email не меняет аккаунт',
    () async {
      const account = {
        'email': 'MixedCase@example.com',
        'password': ' password123 ',
        'name': 'Case',
      };
      expect(
        (await call('POST', '/auth/register', body: account)).statusCode,
        201,
      );
      expect(
        (await call(
          'POST',
          '/auth/register',
          body: {...account, 'email': 'mixedcase@example.com'},
        )).statusCode,
        409,
      );
      expect(
        (await call(
          'POST',
          '/auth/login',
          body: {...account, 'email': 'MIXEDCASE@example.com'},
        )).statusCode,
        200,
      );
      expect(
        (await call(
          'POST',
          '/auth/login',
          body: {...account, 'password': 'password123'},
        )).statusCode,
        401,
      );
    },
  );

  test('Авторизация, CRUD заметок и изоляция пользователей', () async {
    expect((await call('GET', '/health')).statusCode, 200);
    expect((await call('GET', '/me')).statusCode, 401);
    const account = {
      'email': 'first@example.com',
      'password': 'password1',
      'name': 'First',
    };
    final registered = await call('POST', '/auth/register', body: account);
    expect(registered.statusCode, 201);
    final token = (await json(registered))['token'] as String;
    expect(
      (await call('POST', '/auth/register', body: account)).statusCode,
      409,
    );
    expect(
      (await call(
        'POST',
        '/auth/login',
        body: {'email': account['email'], 'password': 'wrong'},
      )).statusCode,
      401,
    );
    expect((await call('POST', '/auth/login', body: account)).statusCode, 200);
    expect((await call('GET', '/me', token: token)).statusCode, 200);
    final other = await json(
      await call(
        'POST',
        '/auth/register',
        body: {...account, 'email': 'second@example.com'},
      ),
    );
    final created = await call(
      'POST',
      '/notes',
      token: token,
      body: {'title': 'Тестовая заметка', 'content': 'Проверка поиска'},
    );
    expect(created.statusCode, 201);
    final id = (await json(created))['id'];
    expect(
      (await call(
        'GET',
        '/notes/$id',
        token: other['token'] as String,
      )).statusCode,
      404,
    );
    final list = await json(
      await call(
        'GET',
        '/notes?page=1&limit=1&search=${Uri.encodeComponent('Тестовая')}',
        token: token,
      ),
    );
    expect(list['total'], 1);
    expect((list['items'] as List).length, 1);
    expect(
      (await call(
        'PUT',
        '/notes/$id',
        token: token,
        body: {'title': 'Изменено'},
      )).statusCode,
      200,
    );
    final deleted = await call('DELETE', '/notes/$id', token: token);
    expect(deleted.statusCode, 204);
    expect(await deleted.readAsString(), isEmpty);
    expect((await call('GET', '/notes/$id', token: token)).statusCode, 404);
  });
}
