import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trade_arena/data/api_client.dart';
import 'package:trade_arena/data/http_trading_repository.dart';
import 'package:trade_arena/data/models.dart';
import 'package:trade_arena/data/result.dart';
import 'package:trade_arena/models/auth_model.dart';

import 'support/memory_token_store.dart';

Map<String, Object?> snapshot() => {
  'user': {'id': '1', 'name': 'Trader', 'email': 'user@example.com'},
  'portfolio': {
    'id': 'p_1',
    'userId': '1',
    'cashBalance': 10000,
    'startingBalance': 10000.0,
    'createdAt': '2026-11-13T00:00:00Z',
  },
  'assets': [],
  'positions': [],
  'orders': [],
  'news': [],
  'participants': [],
  'asOf': '2026-11-13T00:00:00Z',
  'priceHistory': <String, Object>{},
};

void main() {
  ApiClient apiWith(
    Future<http.Response> Function(http.Request) handler, {
    Duration timeout = const Duration(seconds: 10),
  }) => ApiClient(
    baseUrl: Uri.parse('http://localhost:8080'),
    client: MockClient(handler),
    timeout: timeout,
  );

  test(
    'Repository отправляет Bearer и разбирает целые и дробные суммы',
    () async {
      final api = apiWith((r) async {
        expect(r.url.path, '/trading/snapshot');
        expect(r.headers['authorization'], 'Bearer saved-token');
        return http.Response(jsonEncode(snapshot()), 200);
      })..token = 'saved-token';
      final result = await HttpTradingRepository(api).fetchAll();
      expect(result, isA<Ok<TradingSnapshot>>());
      final value = (result as Ok<TradingSnapshot>).value;
      expect(value.portfolio.cashBalance, 10000.0);
      expect(() => value.orders.clear(), throwsUnsupportedError);
    },
  );

  test('Неверный JSON, неверные типы и неизвестный enum дают Err', () async {
    for (final body in [
      '<html>',
      '[]',
      '{"portfolio": null}',
      jsonEncode({
        ...snapshot(),
        'assets': [
          {
            'id': 'a',
            'symbol': 'A',
            'name': 'A',
            'market': 'unknown',
            'sector': 'test',
            'lastPrice': 1,
            'changePct': 0,
            'updatedAt': '2026-11-13T00:00:00Z',
          },
        ],
      }),
    ]) {
      final api = apiWith((_) async => http.Response(body, 200));
      expect(
        await HttpTradingRepository(api).fetchAll(),
        isA<Err<TradingSnapshot>>(),
      );
    }
  });

  test('Таймаут, разрыв соединения и ошибка сервера обрабатываются', () async {
    final timeoutApi = apiWith(
      (_) => Completer<http.Response>().future,
      timeout: const Duration(milliseconds: 5),
    );
    expect(
      await HttpTradingRepository(timeoutApi).fetchAll(),
      isA<Err<TradingSnapshot>>(),
    );
    final disconnected = apiWith(
      (_) async => throw http.ClientException('offline'),
    );
    expect(
      await HttpTradingRepository(disconnected).fetchAll(),
      isA<Err<TradingSnapshot>>(),
    );
    final failed = apiWith((_) async => http.Response('oops', 503));
    expect(
      await HttpTradingRepository(failed).fetchAll(),
      isA<Err<TradingSnapshot>>(),
    );
  });

  test(
    'Вход сохраняет только токен, неправильный пароль не стирает сессию',
    () async {
      var fail = false;
      final tokens = MemoryTokenStore();
      final api = apiWith((r) async {
        expect(r.headers.containsKey('authorization'), isFalse);
        return fail
            ? http.Response('{}', 401)
            : http.Response('{"token":"jwt"}', 200);
      });
      final auth = AuthModel(api, tokens);
      expect(await auth.login('user@example.com', 'password'), isNull);
      expect(tokens.value, 'jwt');
      fail = true;
      expect(
        await auth.login('user@example.com', 'wrong'),
        'Неверный email или пароль',
      );
      expect(auth.isAuthenticated, isTrue);
      await auth.logout();
      expect(tokens.value, isNull);
      expect(auth.isAuthenticated, isFalse);
    },
  );

  test('Защищённый 401 удаляет сохранённый токен', () async {
    final tokens = MemoryTokenStore()..value = 'expired';
    final api = apiWith((_) async => http.Response('{}', 401));
    final auth = AuthModel(api, tokens);
    await auth.restore();
    expect(
      await HttpTradingRepository(api).fetchAll(),
      isA<Err<TradingSnapshot>>(),
    );
    expect(auth.isAuthenticated, isFalse);
    expect(tokens.value, isNull);
  });

  test('Поздний 401 старой сессии не завершает новый вход', () async {
    final oldRequest = Completer<http.Response>();
    final started = Completer<void>();
    final api = apiWith((r) {
      if (r.url.path == '/auth/login') {
        return Future.value(http.Response('{"token":"new"}', 200));
      }
      started.complete();
      return oldRequest.future;
    })..token = 'old';
    final auth = AuthModel(api, MemoryTokenStore());
    final request = HttpTradingRepository(api).fetchAll();
    await started.future;
    await auth.login('user@example.com', 'password');
    oldRequest.complete(http.Response('{}', 401));
    await request;
    expect(api.token, 'new');
    expect(auth.isAuthenticated, isTrue);
  });

  test('Запись передаёт только поля заявки и принимает 201', () async {
    final api = apiWith((r) async {
      expect(r.method, 'POST');
      expect(r.url.path, '/orders');
      final body = jsonDecode(r.body) as Map;
      expect(body['quantity'], 2);
      expect(body.containsKey('executedPrice'), isFalse);
      return http.Response(jsonEncode(snapshot()), 201);
    });
    expect(
      await HttpTradingRepository(api).create(
        const OrderDraft(
          assetId: 'a_tsla',
          side: OrderSide.buy,
          type: OrderType.market,
          quantity: 2,
        ),
      ),
      isA<Ok<TradingSnapshot>>(),
    );
  });

  test('Пустой ответ 204 не декодируется как JSON', () async {
    final api = apiWith((_) async => http.Response('', 204));
    expect(
      await api.send('DELETE', '/notes/1', expected: [204]),
      isA<Ok<Map<String, dynamic>>>(),
    );
  });
}
