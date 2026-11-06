import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/result.dart';
import '../data/trading_repository.dart';

/// Один согласованный снимок для всех вкладок: торговля не может обновить
/// баланс отдельно от позиций или рейтинга. Источник передаётся снаружи.
class TradingModel extends ChangeNotifier {
  TradingModel(this._repository);
  final TradingRepository _repository;
  TradingSnapshot? _data;
  bool _loading = false;
  bool _saving = false;
  bool _disposed = false;
  String? _error;

  bool get isLoading => _loading;
  bool get isSaving => _saving;
  String? get error => _error;
  bool get hasData => _data != null;
  List<Asset> get assets => _data?.assets ?? const [];
  List<Position> get positions => _data?.positions ?? const [];
  List<Order> get orders => _data?.orders ?? const [];
  List<NewsArticle> get news => _data?.news ?? const [];
  List<double> priceHistory(String id) => _data?.priceHistory[id] ?? const [];
  UserProfile get user => _data!.user;
  Portfolio get portfolio => _data!.portfolio;
  List<String> get sectors =>
      List.unmodifiable(assets.map((a) => a.sector).toSet());
  Asset? byId(String id) {
    for (final a in assets) {
      if (a.id == id) return a;
    }
    return null;
  }

  Position? positionFor(String id) {
    for (final p in positions) {
      if (p.assetId == id) return p;
    }
    return null;
  }

  double get positionsValue => money(
    positions.fold<double>(
      0,
      (sum, p) => sum + p.quantity * (byId(p.assetId)?.lastPrice ?? 0),
    ),
  );
  double get totalValue => money(portfolio.cashBalance + positionsValue);
  double get totalReturnPct =>
      (totalValue / portfolio.startingBalance - 1) * 100;
  double get availableCash =>
      money(portfolio.cashBalance - reservedCash(orders));
  int availableShares(String id) =>
      (positionFor(id)?.quantity ?? 0) - reservedShares(orders, id);
  int get pendingCount =>
      orders.where((o) => o.status == OrderStatus.pending).length;
  int get tradesCount =>
      orders.where((o) => o.status == OrderStatus.executed).length;
  Order? get bestTrade {
    Order? best;
    for (final order in orders) {
      if (order.realizedProfit != null &&
          (best == null || order.realizedProfit! > best.realizedProfit!)) {
        best = order;
      }
    }
    return best;
  }

  List<Participant> get leaderboard {
    if (_data == null) return const [];
    final ranked =
        [
          ..._data!.participants,
          Participant(
            rank: 0,
            name: user.name,
            totalValue: totalValue,
            returnPct: totalReturnPct,
            tradesCount: tradesCount,
            isMe: true,
          ),
        ]..sort((a, b) {
          final result = b.returnPct.compareTo(a.returnPct);
          return result != 0 ? result : a.name.compareTo(b.name);
        });
    return List.unmodifiable([
      for (var i = 0; i < ranked.length; i++)
        Participant(
          rank: i + 1,
          name: ranked[i].name,
          totalValue: ranked[i].totalValue,
          returnPct: ranked[i].returnPct,
          tradesCount: ranked[i].tradesCount,
          isMe: ranked[i].isMe,
        ),
    ]);
  }

  Future<void> load() async {
    if (_loading || _saving || _disposed) return;
    _loading = true;
    _error = null;
    notifyListeners();
    switch (await _repository.fetchAll()) {
      case Ok(:final value):
        _data = value;
      case Err(:final msg):
        _error = msg;
    }
    _loading = false;
    if (!_disposed) notifyListeners();
  }

  Future<String?> create(OrderDraft draft) =>
      _mutate(() => _repository.create(draft));
  Future<String?> update(String id, OrderDraft draft) =>
      _mutate(() => _repository.update(id, draft));
  Future<String?> cancel(String id) => _mutate(() => _repository.delete(id));
  Future<String?> reset() => _mutate(_repository.resetPortfolio);

  Future<String?> _mutate(
    Future<Result<TradingSnapshot>> Function() action,
  ) async {
    if (_saving || _loading || _disposed) {
      return 'Дождитесь завершения текущей операции';
    }
    _saving = true;
    notifyListeners();
    String? error;
    switch (await action()) {
      case Ok(:final value):
        _data = value;
        _error = null;
      case Err(:final msg):
        error = msg;
    }
    _saving = false;
    if (!_disposed) notifyListeners();
    return error;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
