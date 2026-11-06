import 'package:flutter_test/flutter_test.dart';
import 'package:trade_arena/data/mock_trading_repository.dart';
import 'package:trade_arena/data/models.dart';
import 'package:trade_arena/data/result.dart';
import 'package:trade_arena/models/trading_model.dart';

TradingSnapshot value(Result<TradingSnapshot> result) =>
    (result as Ok<TradingSnapshot>).value;
OrderDraft draft({
  String asset = 'a_tsla',
  int quantity = 1,
  OrderSide side = OrderSide.buy,
  double? limit,
  bool untilCancelled = true,
}) => OrderDraft(
  assetId: asset,
  side: side,
  type: limit == null ? OrderType.market : OrderType.limit,
  quantity: quantity,
  limitPrice: limit,
  untilCancelled: untilCancelled,
);

void main() {
  late MockTradingRepository repo;
  setUp(() => repo = MockTradingRepository(latency: Duration.zero));

  test(
    'Покупка обновляет деньги, позицию, комиссию и историю одним снимком',
    () async {
      final before = value(await repo.fetchAll());
      final after = value(await repo.create(draft()));
      expect(after.portfolio.cashBalance, 928.94);
      expect(
        after.positions.singleWhere((p) => p.assetId == 'a_tsla').quantity,
        1,
      );
      expect(
        after.positions.singleWhere((p) => p.assetId == 'a_tsla').avgPrice,
        312.91,
      );
      expect(after.orders.first.fee, 0.31);
      expect(after.orders.first.status, OrderStatus.executed);
      expect(after.orders.first.id, isNot(before.orders.first.id));
      expect(before.positions.any((p) => p.assetId == 'a_tsla'), isFalse);
    },
  );

  test('Продажа части и всей позиции сохраняет среднюю цену и удаляет нулевой остаток', () async {
    final partial = value(
      await repo.create(
        draft(asset: 'a_aapl', quantity: 3, side: OrderSide.sell),
      ),
    );
    expect(
      partial.positions.singleWhere((p) => p.assetId == 'a_aapl').quantity,
      5,
    );
    expect(
      partial.positions.singleWhere((p) => p.assetId == 'a_aapl').avgPrice,
      231.4,
    );
    expect(partial.portfolio.cashBalance, 1986.01);
    final all = value(
      await repo.create(
        draft(asset: 'a_aapl', quantity: 5, side: OrderSide.sell),
      ),
    );
    expect(all.positions.where((p) => p.assetId == 'a_aapl'), isEmpty);
    expect(all.orders.first.realizedProfit, closeTo(83.26, 0.001));
  });

  test(
    'Повторная покупка пересчитывает среднюю стоимость с комиссией',
    () async {
      final after = value(await repo.create(draft(asset: 'a_aapl')));
      final p = after.positions.singleWhere((p) => p.assetId == 'a_aapl');
      expect(p.quantity, 9);
      expect(p.avgPrice, closeTo((8 * 231.4 + 248.3 + 0.25) / 9, 0.00001));
    },
  );

  test(
    'Лимитная покупка резервирует деньги и не меняет позицию до исполнения',
    () async {
      final after = value(await repo.create(draft(limit: 100, quantity: 5)));
      expect(after.orders.first.status, OrderStatus.pending);
      expect(after.portfolio.cashBalance, 1241.85);
      expect(reservedCash(after.orders), 1146.15);
      expect(after.positions.where((p) => p.assetId == 'a_tsla'), isEmpty);
      expect(await repo.create(draft()), isA<Err<TradingSnapshot>>());
    },
  );

  test(
    'Лимитная продажа и рыночная продажа учитывают уже зарезервированные акции',
    () async {
      // В исходном портфеле 12 NVDA, четыре уже в ожидающем ордере.
      expect(
        await repo.create(
          draft(asset: 'a_nvda', quantity: 9, side: OrderSide.sell),
        ),
        isA<Err<TradingSnapshot>>(),
      );
      final pending = value(
        await repo.create(
          draft(asset: 'a_nvda', quantity: 8, side: OrderSide.sell, limit: 300),
        ),
      );
      expect(reservedShares(pending.orders, 'a_nvda'), 12);
      expect(
        await repo.create(draft(asset: 'a_nvda', side: OrderSide.sell)),
        isA<Err<TradingSnapshot>>(),
      );
    },
  );

  test(
    'Подходящий лимит исполняется по текущей, более выгодной цене',
    () async {
      final after = value(await repo.create(draft(limit: 400)));
      expect(after.orders.first.status, OrderStatus.executed);
      expect(after.orders.first.executedPrice, 312.6);
      expect(after.portfolio.cashBalance, 928.94);
    },
  );

  test(
    'Отмена освобождает резерв, оставляет историю, запрещает повторную отмену',
    () async {
      final after = value(await repo.delete('o_8'));
      expect(reservedCash(after.orders), 0);
      expect(
        after.orders.singleWhere((o) => o.id == 'o_8').status,
        OrderStatus.cancelled,
      );
      expect(await repo.delete('o_8'), isA<Err<TradingSnapshot>>());
      expect(await repo.delete('missing'), isA<Err<TradingSnapshot>>());
    },
  );

  test(
    'Обновление ожидающего ордера заменяет его собственный резерв',
    () async {
      final after = value(
        await repo.update(
          'o_8',
          draft(asset: 'a_amzn', limit: 210, quantity: 5),
        ),
      );
      expect(after.orders.where((o) => o.id == 'o_8').length, 1);
      expect(after.orders.first.quantity, 5);
      expect(reservedCash(after.orders), 1051.05);
      expect(await repo.update('o_6', draft()), isA<Err<TradingSnapshot>>());
      expect(
        await repo.update('missing', draft()),
        isA<Err<TradingSnapshot>>(),
      );
    },
  );

  test(
    'Провал обновления не отменяет старый ордер и не меняет данные',
    () async {
      final before = value(await repo.fetchAll());
      expect(
        await repo.update('o_8', draft(limit: 300, quantity: 100)),
        isA<Err<TradingSnapshot>>(),
      );
      final after = value(await repo.fetchAll());
      expect(after.portfolio.cashBalance, before.portfolio.cashBalance);
      expect(after.orders.singleWhere((o) => o.id == 'o_8').quantity, 3);
    },
  );

  test('Все методы возвращают Err при аварии; неудачная мутация не оставляет следа', () async {
    final before = value(await repo.fetchAll());
    repo.simulateError = true;
    expect(await repo.fetchAll(), isA<Err<TradingSnapshot>>());
    expect(await repo.fetchById('o_8'), isA<Err<Order>>());
    expect(await repo.create(draft()), isA<Err<TradingSnapshot>>());
    expect(await repo.update('o_8', draft()), isA<Err<TradingSnapshot>>());
    expect(await repo.delete('o_8'), isA<Err<TradingSnapshot>>());
    expect(await repo.resetPortfolio(), isA<Err<TradingSnapshot>>());
    repo.simulateError = false;
    final after = value(await repo.fetchAll());
    expect(after.orders.length, before.orders.length);
    expect(after.portfolio.cashBalance, before.portfolio.cashBalance);
    expect(after.orders.first.status, before.orders.first.status);
  });

  test(
    'Сброс восстанавливает стартовый баланс и очищает позиции с историей',
    () async {
      final after = value(await repo.resetPortfolio());
      expect(after.portfolio.cashBalance, 10000);
      expect(after.positions, isEmpty);
      expect(after.orders, isEmpty);
      expect(after.assets, isNotEmpty);
    },
  );

  test('Снимок не допускает внешнее изменение коллекций', () async {
    final after = value(await repo.fetchAll());
    expect(() => after.orders.clear(), throwsUnsupportedError);
    expect(() => after.positions.clear(), throwsUnsupportedError);
    expect(() => after.assets.clear(), throwsUnsupportedError);
    expect(() => after.news.first.symbols.clear(), throwsUnsupportedError);
    expect(
      () => after.priceHistory.values.first.clear(),
      throwsUnsupportedError,
    );
  });

  test('Неизвестные id и недопустимые значения возвращают ошибки', () async {
    expect(await repo.fetchById('o_8'), isA<Ok<Order>>());
    expect(await repo.fetchById('missing'), isA<Err<Order>>());
    for (final bad in [
      draft(asset: 'missing'),
      draft(quantity: 0),
      draft(quantity: -1),
      draft(limit: double.nan),
      draft(limit: double.infinity),
      draft(limit: 0),
      draft(limit: 0.001),
      draft(quantity: 1000000001),
    ]) {
      expect(await repo.create(bad), isA<Err<TradingSnapshot>>());
    }
  });

  test('Параллельные запросы не могут потратить одни и те же деньги', () async {
    final results = await Future.wait([
      repo.create(draft()),
      repo.create(draft()),
    ]);
    expect(results.whereType<Ok<TradingSnapshot>>().length, 1);
    expect(results.whereType<Err<TradingSnapshot>>().length, 1);
  });

  test('Дневной лимит истекает ровно в полночь, GTC остаётся', () async {
    var now = DateTime(2026, 11, 6, 18);
    repo = MockTradingRepository(latency: Duration.zero, clock: () => now);
    final first = value(
      await repo.create(draft(limit: 100, untilCancelled: false)),
    );
    final id = first.orders.first.id;
    now = DateTime(2026, 11, 7);
    final nextDay = value(await repo.fetchAll());
    expect(
      nextDay.orders.singleWhere((o) => o.id == id).status,
      OrderStatus.cancelled,
    );
    expect(
      nextDay.orders.singleWhere((o) => o.id == 'o_8').status,
      OrderStatus.pending,
    );
  });

  test('Модель публикует loading/error/data, уведомляет подписчиков и пересчитывает рейтинг', () async {
    final model = TradingModel(repo);
    final states = <bool>[];
    model.addListener(() => states.add(model.isLoading));
    repo.simulateError = true;
    await model.load();
    expect(states, [true, false]);
    expect(model.error, isNotNull);
    repo.simulateError = false;
    await model.load();
    expect(model.error, isNull);
    expect(model.byId('missing'), isNull);
    final before = model.totalValue;
    expect(await model.create(draft()), isNull);
    expect(model.totalValue, closeTo(before - 0.31, 0.001));
    expect(
      model.leaderboard.singleWhere((p) => p.isMe).totalValue,
      model.totalValue,
    );
    expect(
      model.leaderboard.singleWhere((p) => p.isMe).tradesCount,
      model.tradesCount,
    );
    repo.simulateError = true;
    final sameOrders = model.orders;
    expect(await model.create(draft()), isNotNull);
    expect(model.orders, same(sameOrders));
    expect(model.isSaving, isFalse);
    model.dispose();
  });
}
