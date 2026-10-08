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
}

class NewsArticle {
  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.url,
    required this.source,
    this.imageUrl,
    required this.publishedAt,
    required this.market,
    required this.symbols,
  });

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
