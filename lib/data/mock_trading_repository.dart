import 'mock_data.dart' as seed;
import 'models.dart';
import 'result.dart';
import 'trading_repository.dart';

/// Только этот файл знает исходные данные. На L5 заменяется реализацией HTTP.
class MockTradingRepository implements TradingRepository {
  MockTradingRepository({
    this.latency = const Duration(milliseconds: 800),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _portfolio = seed.portfolio,
       _positions = List.of(seed.positions),
       _orders = List.of(seed.orders);

  final Duration latency;
  final DateTime Function() _clock;
  bool simulateError = false;
  Portfolio _portfolio;
  List<Position> _positions;
  List<Order> _orders;
  int _nextId = 1000;
  static const _networkError = 'Сервер не отвечает — повторите попытку';

  Future<void> _wait() => Future<void>.delayed(latency);

  // Истечение дневных заявок проверяется на каждом обращении к хранилищу.
  void _expireDayOrders() {
    final now = _clock();
    _orders = [
      for (final o in _orders)
        if (o.status == OrderStatus.pending &&
            !o.untilCancelled &&
            DateTime(
              o.createdAt.year,
              o.createdAt.month,
              o.createdAt.day + 1,
            ).isAfter(now) == false)
          o.cancelled()
        else
          o,
    ];
  }

  TradingSnapshot _snapshot() => TradingSnapshot(
    user: const UserProfile(
      id: seed.currentUserId,
      name: seed.currentUserName,
      email: seed.currentUserEmail,
    ),
    portfolio: _portfolio,
    assets: seed.assets,
    positions: _positions,
    orders: _orders,
    news: seed.newsArticles,
    participants: seed.leaderboard.where((p) => !p.isMe).toList(),
    asOf: _clock(),
    priceHistory: {for (final asset in seed.assets) asset.id: _chart(asset)},
  );

  List<double> _chart(Asset asset) {
    const shape = [
      0.0,
      0.18,
      0.05,
      -0.12,
      -0.30,
      -0.22,
      0.04,
      0.21,
      0.35,
      0.16,
      -0.08,
      -0.25,
      -0.10,
      0.12,
      0.28,
      0.40,
      0.22,
      0.05,
      -0.15,
      -0.05,
      0.14,
      0.26,
      0.10,
      0.0,
    ];
    final open = asset.lastPrice / (1 + asset.changePct / 100);
    return [
      for (var i = 0; i < shape.length; i++)
        money(
          open +
              (asset.lastPrice - open) * i / (shape.length - 1) +
              asset.lastPrice * shape[i] / 100,
        ),
    ];
  }

  @override
  Future<Result<TradingSnapshot>> fetchAll() async {
    await _wait();
    if (simulateError) return const Err(_networkError);
    _expireDayOrders();
    return Ok(_snapshot());
  }

  @override
  Future<Result<Order>> fetchById(String id) async {
    await _wait();
    if (simulateError) return const Err(_networkError);
    _expireDayOrders();
    for (final order in _orders) {
      if (order.id == id) return Ok(order);
    }
    return const Err('Ордер не существует');
  }

  @override
  Future<Result<TradingSnapshot>> create(OrderDraft draft) async {
    await _wait();
    if (simulateError) return const Err(_networkError);
    _expireDayOrders();
    return _place(draft);
  }

  /// До изменения списков проверяем ВСЕ условия. Между проверкой и записью
  /// нет await: две параллельные заявки не могут потратить одни деньги.
  Result<TradingSnapshot> _place(OrderDraft draft, {Order? replacing}) {
    final matches = seed.assets.where((a) => a.id == draft.assetId);
    if (matches.isEmpty) return const Err('Акция не существует');
    final asset = matches.first;
    if (draft.quantity < 1 || draft.quantity > 1000000000) {
      return const Err('Количество должно быть от 1 до 1 000 000 000');
    }
    if (draft.type == OrderType.limit &&
        (draft.limitPrice == null ||
            !draft.limitPrice!.isFinite ||
            draft.limitPrice! < 0.01 ||
            draft.limitPrice! > 1000000000)) {
      return const Err(
        'Укажите конечную лимитную цену от 0,01 до 1 000 000 000',
      );
    }
    final limit = draft.type == OrderType.limit
        ? money(draft.limitPrice!)
        : null;
    final execute =
        draft.type == OrderType.market ||
        (draft.side == OrderSide.buy
            ? asset.lastPrice <= limit!
            : asset.lastPrice >= limit!);
    final price = execute ? asset.lastPrice : limit;
    final amount = money(price * draft.quantity);
    final fee = orderFee(amount);
    final otherOrders = _orders.where((o) => o.id != replacing?.id);
    Position? position;
    for (final p in _positions) {
      if (p.assetId == asset.id) position = p;
    }
    if (draft.side == OrderSide.buy) {
      if (money(amount + fee) >
          money(_portfolio.cashBalance - reservedCash(otherOrders))) {
        return const Err(
          'Недостаточно свободных средств с учётом ожидающих ордеров',
        );
      }
    } else if (draft.quantity >
        (position?.quantity ?? 0) - reservedShares(otherOrders, asset.id)) {
      return const Err(
        'Недостаточно свободных акций с учётом ожидающих ордеров',
      );
    }

    final now = _clock();
    final order = Order(
      id: replacing?.id ?? 'o_${_nextId++}',
      userId: _portfolio.userId,
      assetId: asset.id,
      side: draft.side,
      type: draft.type,
      quantity: draft.quantity,
      limitPrice: limit,
      executedPrice: execute ? price : null,
      fee: fee,
      status: execute ? OrderStatus.executed : OrderStatus.pending,
      createdAt: replacing?.createdAt ?? now,
      executedAt: execute ? now : null,
      untilCancelled: draft.untilCancelled,
      realizedProfit: execute && draft.side == OrderSide.sell
          ? money((price - position!.avgPrice) * draft.quantity - fee)
          : null,
    );
    if (execute) {
      final buying = draft.side == OrderSide.buy;
      _portfolio = Portfolio(
        id: _portfolio.id,
        userId: _portfolio.userId,
        cashBalance: money(
          _portfolio.cashBalance + (buying ? -amount - fee : amount - fee),
        ),
        startingBalance: _portfolio.startingBalance,
        createdAt: _portfolio.createdAt,
      );
      final quantity =
          (position?.quantity ?? 0) +
          (buying ? draft.quantity : -draft.quantity);
      _positions = [
        for (final p in _positions)
          if (p.assetId != asset.id) p,
        if (quantity > 0)
          Position(
            id: position?.id ?? 'pos_${_nextId++}',
            userId: _portfolio.userId,
            assetId: asset.id,
            quantity: quantity,
            avgPrice: buying
                ? (((position?.quantity ?? 0) * (position?.avgPrice ?? 0)) +
                          amount +
                          fee) /
                      quantity
                : position!.avgPrice,
          ),
      ];
    }
    _orders = [order, ...otherOrders];
    return Ok(_snapshot());
  }

  @override
  Future<Result<TradingSnapshot>> update(String id, OrderDraft draft) async {
    await _wait();
    if (simulateError) return const Err(_networkError);
    _expireDayOrders();
    final found = _orders.where((o) => o.id == id);
    if (found.isEmpty) return const Err('Ордер не существует');
    if (found.first.status != OrderStatus.pending) {
      return const Err('Можно изменить только ожидающий ордер');
    }
    return _place(draft, replacing: found.first);
  }

  @override
  Future<Result<TradingSnapshot>> delete(String id) async {
    await _wait();
    if (simulateError) return const Err(_networkError);
    _expireDayOrders();
    final index = _orders.indexWhere((o) => o.id == id);
    if (index < 0) return const Err('Ордер не существует');
    if (_orders[index].status != OrderStatus.pending) {
      return const Err('Можно отменить только ожидающий ордер');
    }
    _orders[index] = _orders[index].cancelled();
    return Ok(_snapshot());
  }

  @override
  Future<Result<TradingSnapshot>> resetPortfolio() async {
    await _wait();
    if (simulateError) return const Err(_networkError);
    _portfolio = Portfolio(
      id: _portfolio.id,
      userId: _portfolio.userId,
      cashBalance: _portfolio.startingBalance,
      startingBalance: _portfolio.startingBalance,
      createdAt: _clock(),
    );
    _positions = [];
    _orders = [];
    return Ok(_snapshot());
  }
}
