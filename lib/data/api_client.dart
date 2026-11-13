import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'result.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.client,
    this.timeout = const Duration(seconds: 10),
  });
  final Uri baseUrl;
  final http.Client client;
  final Duration timeout;
  String? token;
  Future<void> Function()? onUnauthorized;

  Future<Result<Map<String, dynamic>>> send(
    String method,
    String path, {
    Map<String, Object?>? body,
    bool authenticated = true,
    List<int> expected = const [200],
    Map<String, String>? query,
  }) async {
    final requestToken = token;
    final uri = baseUrl.resolve(path).replace(queryParameters: query);
    try {
      final request = http.Request(method, uri)
        ..headers['accept'] = 'application/json';
      if (authenticated && requestToken != null) {
        request.headers['authorization'] = 'Bearer $requestToken';
      }
      if (body != null) {
        request.headers['content-type'] = 'application/json; charset=utf-8';
        request.body = jsonEncode(body);
      }
      final response = await (() async {
        final streamed = await client.send(request);
        return http.Response.fromStream(streamed);
      })().timeout(timeout);
      if (response.statusCode == 401 &&
          authenticated &&
          token == requestToken) {
        await onUnauthorized?.call();
        return const Err('Сессия завершена. Войдите снова');
      }
      if (!expected.contains(response.statusCode)) {
        return Err(_errorMessage(response, authenticated));
      }
      if (response.statusCode == 204) return const Ok({});
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        return const Err('Сервер вернул неверный формат данных');
      }
      return Ok(decoded);
    } on TimeoutException {
      return const Err('Сервер не ответил вовремя. Повторите попытку');
    } on http.ClientException {
      return const Err(
        'Не удалось подключиться к серверу. Проверьте соединение',
      );
    } on FormatException {
      return const Err('Сервер вернул неверный формат данных');
    }
  }

  String _errorMessage(http.Response response, bool authenticated) {
    if (response.statusCode == 401 && !authenticated) {
      return 'Неверный email или пароль';
    }
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final error = decoded is Map ? decoded['error'] : null;
      final code = error is Map ? error['code'] : null;
      return switch (code) {
        'EMAIL_TAKEN' => 'Этот email уже зарегистрирован',
        'VALIDATION_ERROR' => 'Проверьте введённые данные',
        'INSUFFICIENT_FUNDS' =>
          'Недостаточно свободных средств с учётом ожидающих ордеров',
        'INSUFFICIENT_SHARES' =>
          'Недостаточно свободных акций с учётом ожидающих ордеров',
        'ORDER_NOT_PENDING' =>
          'Изменить или отменить можно только ожидающий ордер',
        'NOT_FOUND' => 'Запрошенные данные не найдены',
        _ => 'Ошибка сервера (${response.statusCode}). Повторите попытку',
      };
    } on FormatException {
      return 'Ошибка сервера (${response.statusCode}). Повторите попытку';
    }
  }

  void close() => client.close();
}
