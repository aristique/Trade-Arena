import 'models.dart';
import 'result.dart';

/// Контракт источника данных. Сделка возвращает весь согласованный снимок:
/// баланс, позиции и ордера обновляются одним ответом, как одной транзакцией.
abstract interface class TradingRepository {
  Future<Result<TradingSnapshot>> fetchAll();
  Future<Result<Order>> fetchById(String id);
  Future<Result<TradingSnapshot>> create(OrderDraft draft);
  Future<Result<TradingSnapshot>> update(String id, OrderDraft draft);

  /// Логическое удаление ожидающего ордера: история сохраняется.
  Future<Result<TradingSnapshot>> delete(String id);
  Future<Result<TradingSnapshot>> resetPortfolio();
}
