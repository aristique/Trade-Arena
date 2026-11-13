import 'api_client.dart';
import 'models.dart';
import 'result.dart';
import 'trading_json.dart';
import 'trading_repository.dart';

class HttpTradingRepository implements TradingRepository {
  HttpTradingRepository(this.api);
  final ApiClient api;

  Future<Result<T>> _request<T>(
    String method,
    String path,
    T Function(Map<String, dynamic>) decode, {
    OrderDraft? draft,
    int status = 200,
  }) async {
    final result = await api.send(
      method,
      path,
      body: draft == null ? null : draftToJson(draft),
      expected: [status],
    );
    switch (result) {
      case Err(:final msg):
        return Err(msg);
      case Ok(:final value):
        try {
          return Ok(decode(value));
        } on FormatException {
          return const Err('Сервер вернул неверный формат данных');
        } on TypeError {
          return const Err('Сервер вернул неверный формат данных');
        } on ArgumentError {
          return const Err('Сервер вернул неверный формат данных');
        }
    }
  }

  @override
  Future<Result<TradingSnapshot>> fetchAll() =>
      _request('GET', '/trading/snapshot', snapshotFromJson);
  @override
  Future<Result<Order>> fetchById(String id) =>
      _request('GET', '/orders/${Uri.encodeComponent(id)}', orderFromJson);
  @override
  Future<Result<TradingSnapshot>> create(OrderDraft draft) =>
      _request('POST', '/orders', snapshotFromJson, draft: draft, status: 201);
  @override
  Future<Result<TradingSnapshot>> update(String id, OrderDraft draft) =>
      _request(
        'PUT',
        '/orders/${Uri.encodeComponent(id)}',
        snapshotFromJson,
        draft: draft,
      );
  @override
  Future<Result<TradingSnapshot>> delete(String id) => _request(
    'DELETE',
    '/orders/${Uri.encodeComponent(id)}',
    snapshotFromJson,
  );
  @override
  Future<Result<TradingSnapshot>> resetPortfolio() =>
      _request('POST', '/portfolio/reset', snapshotFromJson);
}
