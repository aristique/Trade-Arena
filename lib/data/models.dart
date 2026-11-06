// Модели данных TradeArena. Все цены — в долларах США.

enum Market {
  us('США'),
  india('Индия'),
  europe('Европа');

  const Market(this.label);
  final String label;
}

enum OrderSide { buy, sell }

enum OrderType { market, limit }

enum OrderStatus { pending, executed, cancelled }

class Asset {
  const Asset({
    required this.id,
    required this.symbol,
    required this.name,
    required this.market,
    required this.sector,
    required this.lastPrice,
    required this.changePct,
    required this.updatedAt,
  });

  final String id;
  final String symbol;
  final String name;
  final Market market;
  final String sector;
  final double lastPrice;
  final double changePct; // изменение за день в процентах
  final DateTime updatedAt;
}

class Portfolio {
  const Portfolio({
    required this.id,
    required this.userId,
    required this.cashBalance,
    required this.startingBalance,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final double cashBalance;
  final double startingBalance;
  final DateTime createdAt;
}

class Position {
  const Position({
    required this.id,
    required this.userId,
    required this.assetId,
    required this.quantity,
    required this.avgPrice,
  });

  final String id;
  final String userId;
  final String assetId;
  final int quantity;
  final double avgPrice; // средняя цена покупки
}

class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.assetId,
    required this.side,
    required this.type,
    required this.quantity,
    this.limitPrice,
    this.executedPrice,
    required this.fee,
    required this.status,
    required this.createdAt,
    this.executedAt,
    this.untilCancelled = true,
    this.realizedProfit,
  });

  final String id;
  final String userId;
  final String assetId;
  final OrderSide side;
  final OrderType type;
  final int quantity;
  final double? limitPrice; // только для лимитных ордеров
  final double? executedPrice; // null, пока ордер не исполнен
  final double fee;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? executedAt;
  final bool untilCancelled;
  final double? realizedProfit;

  Order cancelled() => Order(
    id: id, userId: userId, assetId: assetId, side: side, type: type,
    quantity: quantity, limitPrice: limitPrice, executedPrice: executedPrice,
    fee: fee, status: OrderStatus.cancelled, createdAt: createdAt,
    executedAt: executedAt, untilCancelled: untilCancelled,
    realizedProfit: realizedProfit,
  );
}

class NewsArticle {
  NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.url,
    required this.source,
    this.imageUrl,
    required this.publishedAt,
    required this.market,
    required List<String> symbols,
  }) : symbols = List.unmodifiable(symbols);

  final String id;
  final String title;
  final String summary;
  final String url;
  final String source;
  final String? imageUrl; // на L2 картинки не загружаем
  final DateTime publishedAt;
  final Market market;
  final List<String> symbols;
}

/// Участник рейтинга. На L2 — просто готовый список.
class Participant {
  const Participant({
    required this.rank,
    required this.name,
    required this.totalValue,
    required this.returnPct,
    required this.tradesCount,
    this.isMe = false,
  });

  final int rank;
  final String name;
  final double totalValue;
  final double returnPct;
  final int tradesCount;
  final bool isMe;
}

/// Поля формы. Id, комиссия, статус и время определяются хранилищем.
class OrderDraft {
  const OrderDraft({required this.assetId, required this.side,
    required this.type, required this.quantity, this.limitPrice,
    this.untilCancelled = true});
  final String assetId;
  final OrderSide side;
  final OrderType type;
  final int quantity;
  final double? limitPrice;
  final bool untilCancelled;
}

class UserProfile {
  const UserProfile({required this.id, required this.name, required this.email});
  final String id;
  final String name;
  final String email;
}

/// Неизменяемый ответ источника, без Flutter и без зависимости от mock-а.
class TradingSnapshot {
  TradingSnapshot({required this.user, required this.portfolio,
    required List<Asset> assets, required List<Position> positions,
    required List<Order> orders, required List<NewsArticle> news,
    required List<Participant> participants, required this.asOf})
    : assets = List.unmodifiable(assets), positions = List.unmodifiable(positions),
      orders = List.unmodifiable(orders), news = List.unmodifiable(news),
      participants = List.unmodifiable(participants);
  final UserProfile user;
  final Portfolio portfolio;
  final List<Asset> assets;
  final List<Position> positions;
  final List<Order> orders;
  final List<NewsArticle> news;
  final List<Participant> participants;
  final DateTime asOf;
}

const tradingFeeRate = 0.001;

/// Расчёты одинаковы на клиенте и в mock-е; суммы округляются до цента.
double money(double value) => (value * 100).roundToDouble() / 100;
double orderFee(double amount) => money(amount * tradingFeeRate);

double reservedCash(Iterable<Order> orders) => money(orders
  .where((o) => o.status == OrderStatus.pending && o.side == OrderSide.buy)
  .fold<double>(0, (sum, o) => sum + money(o.quantity * o.limitPrice!) + o.fee));

int reservedShares(Iterable<Order> orders, String assetId) => orders
  .where((o) => o.status == OrderStatus.pending && o.side == OrderSide.sell && o.assetId == assetId)
  .fold(0, (sum, o) => sum + o.quantity);
