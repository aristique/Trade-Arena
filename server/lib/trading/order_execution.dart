class TradingFailure implements Exception {
  const TradingFailure(this.code, this.message, {this.status = 400});
  final String code;
  final String message;
  final int status;
}

class OrderInput {
  const OrderInput({
    required this.assetId,
    required this.side,
    required this.type,
    required this.quantity,
    this.limitCents,
    this.untilCancelled = true,
  });
  final String assetId;
  final String side;
  final String type;
  final int quantity;
  final int? limitCents;
  final bool untilCancelled;

  factory OrderInput.fromJson(Map<String, dynamic> json) {
    final quantity = json['quantity'];
    final price = json['limitPrice'];
    if (json['assetId'] is! String ||
        !['buy', 'sell'].contains(json['side']) ||
        !['market', 'limit'].contains(json['type']) ||
        quantity is! int ||
        quantity < 1 ||
        quantity > 1000000000 ||
        (json.containsKey('untilCancelled') &&
            json['untilCancelled'] is! bool)) {
      throw const TradingFailure('VALIDATION_ERROR', 'Проверьте поля заявки');
    }
    if (json['type'] == 'limit' &&
        (price is! num ||
            !price.isFinite ||
            price < 0.01 ||
            price > 1000000000)) {
      throw const TradingFailure(
        'VALIDATION_ERROR',
        'Укажите корректную лимитную цену',
      );
    }
    return OrderInput(
      assetId: json['assetId'] as String,
      side: json['side'] as String,
      type: json['type'] as String,
      quantity: quantity,
      limitCents: json['type'] == 'limit'
          ? ((price as num) * 100).round()
          : null,
      untilCancelled: json['untilCancelled'] as bool? ?? true,
    );
  }
}

class TradePlan {
  const TradePlan({
    required this.execute,
    required this.priceCents,
    required this.feeCents,
    required this.cashCents,
    required this.quantity,
    required this.avgPrice,
    this.realizedCents,
  });
  final bool execute;
  final int priceCents;
  final int feeCents;
  final int cashCents;
  final int quantity;
  final double avgPrice;
  final int? realizedCents;
}

TradePlan planOrder(
  OrderInput order, {
  required int quoteCents,
  required int cashCents,
  required int reservedCashCents,
  required int quantity,
  required int reservedQuantity,
  required double avgPrice,
}) {
  final buying = order.side == 'buy';
  final execute =
      order.type == 'market' ||
      (buying
          ? quoteCents <= order.limitCents!
          : quoteCents >= order.limitCents!);
  final price = execute ? quoteCents : order.limitCents!;
  final amount = price * order.quantity;
  final fee = (amount + 500) ~/ 1000;
  if (buying && amount + fee > cashCents - reservedCashCents) {
    throw const TradingFailure(
      'INSUFFICIENT_FUNDS',
      'Недостаточно свободных средств с учётом ожидающих ордеров',
    );
  }
  if (!buying && order.quantity > quantity - reservedQuantity) {
    throw const TradingFailure(
      'INSUFFICIENT_SHARES',
      'Недостаточно свободных акций с учётом ожидающих ордеров',
    );
  }
  final nextQuantity = quantity + (buying ? order.quantity : -order.quantity);
  return TradePlan(
    execute: execute,
    priceCents: price,
    feeCents: fee,
    cashCents: execute
        ? cashCents + (buying ? -amount - fee : amount - fee)
        : cashCents,
    quantity: execute ? nextQuantity : quantity,
    avgPrice: execute && buying
        ? (quantity * avgPrice + (amount + fee) / 100) / nextQuantity
        : avgPrice,
    realizedCents: execute && !buying
        ? ((price / 100 - avgPrice) * order.quantity * 100).round() - fee
        : null,
  );
}
