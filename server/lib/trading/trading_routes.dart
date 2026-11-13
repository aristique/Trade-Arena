import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

import '../auth.dart';
import '../errors.dart';
import 'order_execution.dart';
import 'trading_store.dart';

class TradingRoutes {
  TradingRoutes(this.db) : store = TradingStore(db);
  final Database db;
  final TradingStore store;

  Handler get handler {
    final router = Router()
      ..get(
        '/trading/snapshot',
        _guard((r) => jsonResponse(store.snapshot(currentUserId(r)))),
      )
      ..get('/assets', _guard(_assets))
      ..get('/assets/<id>', _guard(_asset))
      ..get(
        '/portfolio',
        _guard(
          (r) => jsonResponse(store.snapshot(currentUserId(r))['portfolio']!),
        ),
      )
      ..get(
        '/positions',
        _guard(
          (r) => jsonResponse(store.snapshot(currentUserId(r))['positions']!),
        ),
      )
      ..get('/orders', _guard(_orders))
      ..get(
        '/orders/<id>',
        _guard(
          (r) => jsonResponse(store.order(currentUserId(r), r.params['id']!)),
        ),
      )
      ..post('/orders', _guard((r) => _place(r)))
      ..put(
        '/orders/<id>',
        _guard((r) => _place(r, replacingId: r.params['id'])),
      )
      ..delete(
        '/orders/<id>',
        _guard(
          (r) => jsonResponse(store.cancel(currentUserId(r), r.params['id']!)),
        ),
      )
      ..post(
        '/portfolio/reset',
        _guard((r) => jsonResponse(store.reset(currentUserId(r)))),
      );
    return router.call;
  }

  Handler _guard(FutureOr<Response> Function(Request) action) =>
      requireAuth((r) async {
        try {
          return await action(r);
        } on TradingFailure catch (e) {
          return apiError(e.status, e.code, e.message);
        }
      });

  Future<Response> _place(Request r, {String? replacingId}) async {
    final body = await readJsonBody(r);
    if (body == null) return validationError('Ожидается JSON-объект');
    final input = OrderInput.fromJson(body);
    return jsonResponse(
      store.place(currentUserId(r), input, replacingId: replacingId),
      status: replacingId == null ? 201 : 200,
    );
  }

  Response _asset(Request r) {
    final rows = db.select('SELECT * FROM assets WHERE id = ?', [
      r.params['id'],
    ]);
    return rows.isEmpty
        ? notFound('Акция не существует')
        : jsonResponse(assetJson(rows.single));
  }

  Response _assets(Request r) {
    final q = r.url.queryParameters;
    final conditions = <String>[];
    final args = <Object?>[];
    if ((q['search'] ?? '').isNotEmpty) {
      conditions.add('(symbol LIKE ? OR name LIKE ?)');
      args.addAll(['%${q['search']}%', '%${q['search']}%']);
    }
    for (final column in ['market', 'sector']) {
      if ((q[column] ?? '').isNotEmpty) {
        conditions.add('$column = ?');
        args.add(q[column]);
      }
    }
    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    return _page(r, 'assets', where, args, assetJson, 'symbol');
  }

  Response _orders(Request r) {
    store.snapshot(currentUserId(r));
    final search = r.url.queryParameters['search'] ?? '';
    return _page(
      r,
      'orders',
      'WHERE user_id = ? AND asset_id IN (SELECT id FROM assets WHERE symbol LIKE ? OR name LIKE ?)',
      [currentUserId(r), '%$search%', '%$search%'],
      orderJson,
      'id DESC',
    );
  }

  Response _page(
    Request r,
    String table,
    String where,
    List<Object?> args,
    Map<String, Object?> Function(Row) encode,
    String order,
  ) {
    final q = r.url.queryParameters;
    final page = (int.tryParse(q['page'] ?? '') ?? 1).clamp(1, 1000000);
    final limit = (int.tryParse(q['limit'] ?? '') ?? 20).clamp(1, 100);
    final total = db
        .select('SELECT COUNT(*) AS n FROM $table $where', args)
        .single['n'];
    final items = db
        .select(
          'SELECT * FROM $table $where ORDER BY $order LIMIT ? OFFSET ?',
          [...args, limit, (page - 1) * limit],
        )
        .map(encode)
        .toList();
    return jsonResponse({
      'items': items,
      'page': page,
      'limit': limit,
      'total': total,
    });
  }
}
