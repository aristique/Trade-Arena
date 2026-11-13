import 'dart:convert';
import 'dart:io';

import 'package:server/auth.dart';
import 'package:server/db.dart';
import 'package:server/security.dart';
import 'package:server/trading/order_execution.dart';
import 'package:server/trading/schema.dart';
import 'package:server/trading/trading_store.dart';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('Сделки и аккаунт сохраняются после повторного открытия базы', () async {
    final directory = Directory.systemTemp.createTempSync(
      'trading_persistence_',
    );
    final path = '${directory.path}/test.db';
    try {
      initDb(path);
      final registered = await register(
        Request(
          'POST',
          Uri.parse('http://localhost/auth/register'),
          body: jsonEncode({
            'email': 'persist@example.com',
            'password': 'password123',
            'name': 'Persist',
          }),
        ),
      );
      expect(registered.statusCode, 201);
      final body = jsonDecode(await registered.readAsString()) as Map;
      final userId = (body['user'] as Map)['id'] as int;
      final passwordHash =
          db.select('SELECT password_hash FROM users WHERE id = ?', [
                userId,
              ]).single['password_hash']
              as String;
      expect(passwordHash, isNot('password123'));
      expect(verifyPassword('password123', passwordHash), isTrue);
      final store = TradingStore(db);
      store.place(
        userId,
        const OrderInput(
          assetId: 'a_tsla',
          side: 'buy',
          type: 'market',
          quantity: 1,
        ),
      );
      store.place(
        userId,
        const OrderInput(
          assetId: 'a_tsla',
          side: 'buy',
          type: 'limit',
          quantity: 1,
          limitCents: 5000,
        ),
      );
      db.close();

      final reopened = sqlite3.open(path);
      try {
        initTradingSchema(reopened);
        final persisted = TradingStore(reopened).snapshot(userId);
        expect((persisted['portfolio'] as Map)['cashBalance'], 9687.09);
        expect((persisted['positions'] as List).single['quantity'], 1);
        expect((persisted['orders'] as List).length, 2);
        expect((persisted['orders'] as List).first['status'], 'pending');
        expect((persisted['user'] as Map)['email'], 'persist@example.com');
      } finally {
        reopened.close();
      }
    } finally {
      directory.deleteSync(recursive: true);
    }
  });
}
