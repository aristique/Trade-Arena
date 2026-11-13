import 'package:sqlite3/sqlite3.dart';

import 'order_execution.dart';
import 'schema.dart';

class TradingStore {
  TradingStore(this.db, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final Database db;
  final DateTime Function() clock;

  Map<String, Object?> snapshot(int userId) => transaction(db, () {
    _expire(userId);
    return _snapshot(userId);
  });

  void _expire(int userId) {
    final now = clock().toUtc();
    final dayStart = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).toIso8601String();
    db.execute(
      '''UPDATE orders SET status = 'cancelled'
      WHERE user_id = ? AND status = 'pending' AND until_cancelled = 0
      AND created_at < ?''',
      [userId, dayStart],
    );
  }

  Map<String, Object?> _snapshot(int userId) {
    final user = db.select('SELECT id, email, name FROM users WHERE id = ?', [
      userId,
    ]).single;
    final portfolio = db.select('SELECT * FROM portfolios WHERE user_id = ?', [
      userId,
    ]).single;
    final assets = db
        .select('SELECT * FROM assets ORDER BY symbol')
        .map(assetJson)
        .toList();
    final participants = db.select(
      '''
      SELECT u.name, p.cash_cents, p.starting_cents,
        COALESCE((SELECT SUM(pos.quantity * a.price_cents) FROM positions pos
          JOIN assets a ON a.id = pos.asset_id WHERE pos.user_id = u.id), 0) AS value,
        (SELECT COUNT(*) FROM orders o WHERE o.user_id = u.id
          AND o.status = 'executed') AS trades
      FROM users u JOIN portfolios p ON p.user_id = u.id WHERE u.id != ?
    ''',
      [userId],
    );
    return {
      'user': {
        'id': '${user['id']}',
        'name': user['name'],
        'email': user['email'],
      },
      'portfolio': {
        'id': 'p_$userId',
        'userId': '$userId',
        'cashBalance': (portfolio['cash_cents'] as int) / 100,
        'startingBalance': (portfolio['starting_cents'] as int) / 100,
        'createdAt': portfolio['created_at'],
      },
      'assets': assets,
      'positions': db
          .select(
            'SELECT * FROM positions WHERE user_id = ? ORDER BY asset_id',
            [userId],
          )
          .map(positionJson)
          .toList(),
      'orders': db
          .select('SELECT * FROM orders WHERE user_id = ? ORDER BY id DESC', [
            userId,
          ])
          .map(orderJson)
          .toList(),
      'news': <Object>[],
      'participants': [
        for (final row in participants)
          {
            'rank': 0,
            'name': row['name'],
            'totalValue':
                ((row['cash_cents'] as int) + (row['value'] as int)) / 100,
            'returnPct':
                (((row['cash_cents'] as int) + (row['value'] as int)) /
                        (row['starting_cents'] as int) -
                    1) *
                100,
            'tradesCount': row['trades'],
            'isMe': false,
          },
      ],
      'asOf': clock().toUtc().toIso8601String(),
      'priceHistory': <String, Object>{},
    };
  }

  Map<String, Object?> order(int userId, String id) => transaction(db, () {
    _expire(userId);
    return orderJson(_findOrder(userId, id));
  });

  Row _findOrder(int userId, String id) {
    final rows = db.select(
      'SELECT * FROM orders WHERE user_id = ? AND id = ?',
      [userId, id],
    );
    if (rows.isEmpty) {
      throw const TradingFailure(
        'NOT_FOUND',
        'Ордер не существует',
        status: 404,
      );
    }
    return rows.single;
  }

  Map<String, Object?> place(
    int userId,
    OrderInput input, {
    String? replacingId,
  }) => transaction(db, () {
    _expire(userId);
    Row? previous;
    if (replacingId != null) {
      previous = _findOrder(userId, replacingId);
      _requirePending(previous);
    }
    final assets = db.select('SELECT * FROM assets WHERE id = ?', [
      input.assetId,
    ]);
    if (assets.isEmpty) {
      throw const TradingFailure(
        'NOT_FOUND',
        'Акция не существует',
        status: 404,
      );
    }
    final portfolio = db.select('SELECT * FROM portfolios WHERE user_id = ?', [
      userId,
    ]).single;
    final positions = db.select(
      'SELECT * FROM positions WHERE user_id = ? AND asset_id = ?',
      [userId, input.assetId],
    );
    final position = positions.isEmpty ? null : positions.single;
    final reserved = db
        .select(
          '''
      SELECT COALESCE(SUM(CASE WHEN side = 'buy' THEN quantity * limit_cents + fee_cents ELSE 0 END), 0) AS cash,
        COALESCE(SUM(CASE WHEN side = 'sell' AND asset_id = ? THEN quantity ELSE 0 END), 0) AS shares
      FROM orders WHERE user_id = ? AND status = 'pending' AND id != ?
    ''',
          [input.assetId, userId, previous?['id'] ?? -1],
        )
        .single;
    final plan = planOrder(
      input,
      quoteCents: assets.single['price_cents'] as int,
      cashCents: portfolio['cash_cents'] as int,
      reservedCashCents: reserved['cash'] as int,
      quantity: position?['quantity'] as int? ?? 0,
      reservedQuantity: reserved['shares'] as int,
      avgPrice: (position?['avg_price'] as num?)?.toDouble() ?? 0,
    );
    final now = clock().toUtc().toIso8601String();
    final values = [
      input.assetId,
      input.side,
      input.type,
      input.quantity,
      input.limitCents,
      plan.execute ? plan.priceCents : null,
      plan.feeCents,
      plan.execute ? 'executed' : 'pending',
      previous?['created_at'] ?? now,
      plan.execute ? now : null,
      input.untilCancelled ? 1 : 0,
      plan.realizedCents,
    ];
    if (previous == null) {
      db.execute(
        '''INSERT INTO orders
        (asset_id, side, type, quantity, limit_cents, executed_cents, fee_cents,
        status, created_at, executed_at, until_cancelled, realized_cents, user_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [...values, userId],
      );
    } else {
      db.execute(
        '''UPDATE orders SET asset_id = ?, side = ?, type = ?, quantity = ?,
        limit_cents = ?, executed_cents = ?, fee_cents = ?, status = ?, created_at = ?,
        executed_at = ?, until_cancelled = ?, realized_cents = ?
        WHERE id = ? AND user_id = ?''',
        [...values, previous['id'], userId],
      );
    }
    if (plan.execute) {
      db.execute('UPDATE portfolios SET cash_cents = ? WHERE user_id = ?', [
        plan.cashCents,
        userId,
      ]);
      if (plan.quantity == 0) {
        db.execute('DELETE FROM positions WHERE user_id = ? AND asset_id = ?', [
          userId,
          input.assetId,
        ]);
      } else {
        db.execute(
          '''INSERT INTO positions (user_id, asset_id, quantity, avg_price)
          VALUES (?, ?, ?, ?) ON CONFLICT(user_id, asset_id)
          DO UPDATE SET quantity = excluded.quantity, avg_price = excluded.avg_price''',
          [userId, input.assetId, plan.quantity, plan.avgPrice],
        );
      }
    }
    return _snapshot(userId);
  });

  Map<String, Object?> cancel(int userId, String id) => transaction(db, () {
    _expire(userId);
    final order = _findOrder(userId, id);
    _requirePending(order);
    db.execute(
      "UPDATE orders SET status = 'cancelled' WHERE id = ? AND user_id = ?",
      [id, userId],
    );
    return _snapshot(userId);
  });

  void _requirePending(Row order) {
    if (order['status'] != 'pending') {
      throw const TradingFailure(
        'ORDER_NOT_PENDING',
        'Изменить или отменить можно только ожидающий ордер',
        status: 409,
      );
    }
  }

  Map<String, Object?> reset(int userId) => transaction(db, () {
    db.execute('DELETE FROM orders WHERE user_id = ?', [userId]);
    db.execute('DELETE FROM positions WHERE user_id = ?', [userId]);
    db.execute(
      'UPDATE portfolios SET cash_cents = starting_cents, created_at = ? WHERE user_id = ?',
      [clock().toUtc().toIso8601String(), userId],
    );
    return _snapshot(userId);
  });
}

Map<String, Object?> assetJson(Row row) => {
  'id': row['id'],
  'symbol': row['symbol'],
  'name': row['name'],
  'market': row['market'],
  'sector': row['sector'],
  'lastPrice': (row['price_cents'] as int) / 100,
  'changePct': row['change_pct'],
  'updatedAt': row['updated_at'],
};

Map<String, Object?> positionJson(Row row) => {
  'id': 'pos_${row['user_id']}_${row['asset_id']}',
  'userId': '${row['user_id']}',
  'assetId': row['asset_id'],
  'quantity': row['quantity'],
  'avgPrice': row['avg_price'],
};

Map<String, Object?> orderJson(Row row) => {
  'id': '${row['id']}',
  'userId': '${row['user_id']}',
  'assetId': row['asset_id'],
  'side': row['side'],
  'type': row['type'],
  'quantity': row['quantity'],
  'limitPrice': (row['limit_cents'] as int?) == null
      ? null
      : (row['limit_cents'] as int) / 100,
  'executedPrice': (row['executed_cents'] as int?) == null
      ? null
      : (row['executed_cents'] as int) / 100,
  'fee': (row['fee_cents'] as int) / 100,
  'status': row['status'],
  'createdAt': row['created_at'],
  'executedAt': row['executed_at'],
  'untilCancelled': row['until_cancelled'] == 1,
  'realizedProfit': row['realized_cents'] == null
      ? null
      : (row['realized_cents'] as int) / 100,
};
