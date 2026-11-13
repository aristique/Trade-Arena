import 'dart:convert';
import 'dart:io';

import 'package:server/app.dart';
import 'package:server/db.dart';
import 'package:server/files.dart';
import 'package:server/trading/trading_store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  late Handler handler;
  late Directory uploads;
  var counter = 0;
  setUpAll(() {
    initDb(':memory:');
    uploads = Directory.systemTemp.createTempSync('trading_test_');
    initFileStorage(uploads.path);
    handler = createHandler();
  });
  tearDownAll(() {
    db.close();
    uploads.deleteSync(recursive: true);
  });

  Future<Response> call(
    String method,
    String path,
    String token, [
    Map<String, Object?>? body,
  ]) async => handler(
    Request(
      method,
      Uri.parse('http://localhost$path'),
      headers: {
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      },
      body: body == null ? null : jsonEncode(body),
    ),
  );
  Future<Map<String, dynamic>> json(Response r) async =>
      jsonDecode(await r.readAsString()) as Map<String, dynamic>;
  Future<String> account() async {
    final r = await call('POST', '/auth/register', '', {
      'email': 'trader${counter++}@example.com',
      'password': 'password1',
      'name': 'Trader',
    });
    expect(r.statusCode, 201);
    return (await json(r))['token'] as String;
  }

  Map<String, Object?> draft({
    int quantity = 1,
    String side = 'buy',
    double? limit,
  }) => {
    'assetId': 'a_tsla',
    'side': side,
    'type': limit == null ? 'market' : 'limit',
    'quantity': quantity,
    if (limit != null) 'limitPrice': limit,
  };

  test('Новый счёт, покупка, продажа и реальные участники рейтинга', () async {
    final token = await account();
    final before = await json(await call('GET', '/trading/snapshot', token));
    expect((before['portfolio'] as Map)['cashBalance'], 10000);
    expect(before['orders'], isEmpty);
    expect(before['positions'], isEmpty);
    final buy = await call('POST', '/orders', token, draft());
    expect(buy.statusCode, 201);
    final after = await json(buy);
    expect((after['portfolio'] as Map)['cashBalance'], 9687.09);
    expect((after['positions'] as List).single['avgPrice'], 312.91);
    expect((after['orders'] as List).single['fee'], 0.31);
    final sold = await json(
      await call('POST', '/orders', token, draft(side: 'sell')),
    );
    expect(sold['positions'], isEmpty);
    expect((sold['portfolio'] as Map)['cashBalance'], 9999.38);
    expect((sold['orders'] as List).first['realizedProfit'], -0.62);
    final other = await json(
      await call('GET', '/trading/snapshot', await account()),
    );
    expect(
      (other['participants'] as List).any((p) => p['totalValue'] == 9999.38),
      isTrue,
    );
  });

  test('Резервы, обновление, отмена и откат неудачной операции', () async {
    final token = await account();
    final created = await json(
      await call('POST', '/orders', token, draft(quantity: 99, limit: 100)),
    );
    final id = (created['orders'] as List).first['id'];
    expect((await call('POST', '/orders', token, draft())).statusCode, 400);
    expect(
      (await call(
        'PUT',
        '/orders/$id',
        token,
        draft(quantity: 100, limit: 100),
      )).statusCode,
      400,
    );
    final unchanged = await json(await call('GET', '/orders/$id', token));
    expect(unchanged['quantity'], 99);
    final replaced = await json(
      await call('PUT', '/orders/$id', token, draft(quantity: 2, limit: 50)),
    );
    expect((replaced['orders'] as List).first['id'], id);
    expect((replaced['orders'] as List).first['quantity'], 2);
    final cancelled = await json(await call('DELETE', '/orders/$id', token));
    expect((cancelled['orders'] as List).first['status'], 'cancelled');
    expect((await call('DELETE', '/orders/$id', token)).statusCode, 409);
    expect((await call('POST', '/orders', token, draft())).statusCode, 201);
  });

  test('Чужие ордера недоступны, сброс затрагивает только владельца', () async {
    final first = await account();
    final second = await account();
    final snapshot = await json(
      await call('POST', '/orders', first, draft(limit: 50)),
    );
    final id = (snapshot['orders'] as List).first['id'];
    expect((await call('GET', '/orders/$id', second)).statusCode, 404);
    expect((await call('PUT', '/orders/$id', second, draft())).statusCode, 404);
    expect((await call('DELETE', '/orders/$id', second)).statusCode, 404);
    await call('POST', '/orders', second, draft());
    final reset = await json(await call('POST', '/portfolio/reset', first));
    expect(reset['orders'], isEmpty);
    expect((reset['portfolio'] as Map)['cashBalance'], 10000);
    final other = await json(await call('GET', '/trading/snapshot', second));
    expect((other['positions'] as List).length, 1);
  });

  test('Дневной ордер истекает по UTC, до отмены остаётся', () async {
    final token = await account();
    await call('POST', '/orders', token, {
      ...draft(limit: 50),
      'untilCancelled': false,
    });
    await call('POST', '/orders', token, draft(limit: 50));
    final user = await json(await call('GET', '/me', token));
    final future = TradingStore(
      db,
      clock: () => DateTime.now().toUtc().add(const Duration(days: 1)),
    );
    final orders = future.snapshot(user['id'] as int)['orders'] as List;
    expect(orders.first['status'], 'pending');
    expect(orders.last['status'], 'cancelled');
  });

  test('Серверный поиск и пагинация более двадцати ордеров', () async {
    final token = await account();
    for (var i = 0; i < 23; i++) {
      expect(
        (await call('POST', '/orders', token, draft(limit: 1))).statusCode,
        201,
      );
    }
    final first = await json(
      await call('GET', '/orders?page=1&limit=20&search=TSLA', token),
    );
    final second = await json(
      await call('GET', '/orders?page=2&limit=20&search=TSLA', token),
    );
    expect(first['total'], 23);
    expect((first['items'] as List).length, 20);
    expect((second['items'] as List).length, 3);
    final empty = await json(await call('GET', '/orders?search=AAPL', token));
    expect(empty['total'], 0);
    final assets = await json(await call('GET', '/assets?search=Apple', token));
    expect((assets['items'] as List).single['symbol'], 'AAPL');
  });

  test(
    'Неверные поля и параллельные покупки не меняют баланс ошибочно',
    () async {
      final token = await account();
      expect(
        (await call('POST', '/orders', token, {
          ...draft(),
          'quantity': 1.5,
        })).statusCode,
        400,
      );
      expect(
        (await call('POST', '/orders', token, draft(side: 'sell'))).statusCode,
        400,
      );
      expect(
        (await call('POST', '/orders', token, {
          ...draft(),
          'assetId': 'missing',
        })).statusCode,
        404,
      );
      final responses = await Future.wait([
        call('POST', '/orders', token, draft(quantity: 20)),
        call('POST', '/orders', token, draft(quantity: 20)),
      ]);
      expect(responses.map((r) => r.statusCode), containsAll([201, 400]));
      final snapshot = await json(
        await call('GET', '/trading/snapshot', token),
      );
      expect((snapshot['positions'] as List).single['quantity'], 20);
    },
  );
}
