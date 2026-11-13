import 'models.dart';

Map<String, dynamic> _object(Object? value) => value as Map<String, dynamic>;
List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) decode) =>
    (value as List).map((item) => decode(_object(item))).toList();
double _number(Object? value) {
  final number = (value as num).toDouble();
  if (!number.isFinite) throw const FormatException('Non-finite number');
  return number;
}

Asset assetFromJson(Map<String, dynamic> j) => Asset(
  id: j['id'] as String,
  symbol: j['symbol'] as String,
  name: j['name'] as String,
  market: Market.values.byName(j['market'] as String),
  sector: j['sector'] as String,
  lastPrice: _number(j['lastPrice']),
  changePct: _number(j['changePct']),
  updatedAt: DateTime.parse(j['updatedAt'] as String),
);

Order orderFromJson(Map<String, dynamic> j) => Order(
  id: j['id'] as String,
  userId: j['userId'] as String,
  assetId: j['assetId'] as String,
  side: OrderSide.values.byName(j['side'] as String),
  type: OrderType.values.byName(j['type'] as String),
  quantity: j['quantity'] as int,
  limitPrice: j['limitPrice'] == null ? null : _number(j['limitPrice']),
  executedPrice: j['executedPrice'] == null
      ? null
      : _number(j['executedPrice']),
  fee: _number(j['fee']),
  status: OrderStatus.values.byName(j['status'] as String),
  createdAt: DateTime.parse(j['createdAt'] as String),
  executedAt: j['executedAt'] == null
      ? null
      : DateTime.parse(j['executedAt'] as String),
  untilCancelled: j['untilCancelled'] as bool,
  realizedProfit: j['realizedProfit'] == null
      ? null
      : _number(j['realizedProfit']),
);

Map<String, Object?> draftToJson(OrderDraft d) => {
  'assetId': d.assetId,
  'side': d.side.name,
  'type': d.type.name,
  'quantity': d.quantity,
  'limitPrice': d.limitPrice,
  'untilCancelled': d.untilCancelled,
};

TradingSnapshot snapshotFromJson(Map<String, dynamic> j) {
  final user = _object(j['user']);
  final portfolio = _object(j['portfolio']);
  return TradingSnapshot(
    user: UserProfile(
      id: user['id'] as String,
      name: user['name'] as String,
      email: user['email'] as String,
    ),
    portfolio: Portfolio(
      id: portfolio['id'] as String,
      userId: portfolio['userId'] as String,
      cashBalance: _number(portfolio['cashBalance']),
      startingBalance: _number(portfolio['startingBalance']),
      createdAt: DateTime.parse(portfolio['createdAt'] as String),
    ),
    assets: _list(j['assets'], assetFromJson),
    positions: _list(
      j['positions'],
      (p) => Position(
        id: p['id'] as String,
        userId: p['userId'] as String,
        assetId: p['assetId'] as String,
        quantity: p['quantity'] as int,
        avgPrice: _number(p['avgPrice']),
      ),
    ),
    orders: _list(j['orders'], orderFromJson),
    news: _list(
      j['news'],
      (n) => NewsArticle(
        id: n['id'] as String,
        title: n['title'] as String,
        summary: n['summary'] as String,
        url: n['url'] as String,
        source: n['source'] as String,
        imageUrl: n['imageUrl'] as String?,
        publishedAt: DateTime.parse(n['publishedAt'] as String),
        market: Market.values.byName(n['market'] as String),
        symbols: (n['symbols'] as List).cast<String>(),
      ),
    ),
    participants: _list(
      j['participants'],
      (p) => Participant(
        rank: p['rank'] as int,
        name: p['name'] as String,
        totalValue: _number(p['totalValue']),
        returnPct: _number(p['returnPct']),
        tradesCount: p['tradesCount'] as int,
        isMe: p['isMe'] as bool,
      ),
    ),
    asOf: DateTime.parse(j['asOf'] as String),
    priceHistory: _object(
      j['priceHistory'],
    ).map((id, points) => MapEntry(id, (points as List).map(_number).toList())),
  );
}
