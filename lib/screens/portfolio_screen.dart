import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../models/trading_model.dart';
import '../utils/format.dart';
import '../widgets/data_view.dart';
import '../widgets/price_change_badge.dart';
import '../widgets/stat_tile.dart';
import '../widgets/stock_tile.dart';
import '../widgets/ticker_avatar.dart';

/// Портфель: итоговая стоимость, распределение и вкладки «Позиции» / «Ордера».
class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DataView(
      builder: (context, model) {
        final positions = model.positions;
        final orders = model.orders;
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Портфель'),
              actions: [
                IconButton(
                  tooltip: 'Обновить данные',
                  onPressed: () => model.load(),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            // NestedScrollView: сводка прокручивается, а вкладки остаются сверху
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                const SliverToBoxAdapter(child: _Summary()),
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    context,
                  ),
                  sliver: SliverAppBar(
                    pinned: true,
                    primary: false,
                    automaticallyImplyLeading: false,
                    toolbarHeight: 0,
                    bottom: TabBar(
                      tabs: [
                        Tab(text: 'Позиции · ${positions.length}'),
                        Tab(text: 'Ордера · ${orders.length}'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _PortfolioList(
                    name: 'positions',
                    emptyMessage: 'Пока нет позиций',
                    itemCount: positions.length,
                    separatorBuilder: (context, index) =>
                        const Divider(indent: 72),
                    itemBuilder: (context, index) {
                      final position = positions[index];
                      final asset = model.byId(position.assetId)!;
                      return StockTile(
                        key: ValueKey(position.id),
                        asset: asset,
                        subtitle:
                            '${position.quantity} шт. · ср. ${formatMoney(position.avgPrice)}',
                        value: position.quantity * asset.lastPrice,
                        changePct:
                            (asset.lastPrice / position.avgPrice - 1) * 100,
                        onTap: () => context.push('/portfolio/${asset.id}'),
                      );
                    },
                  ),
                  _PortfolioList(
                    name: 'orders',
                    emptyMessage: 'Пока нет ордеров',
                    itemCount: orders.length,
                    separatorBuilder: (context, index) =>
                        const Divider(indent: 72),
                    itemBuilder: (context, index) => _OrderTile(
                      key: ValueKey(orders[index].id),
                      order: orders[index],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Компенсирует закреплённую TabBar, чтобы первая строка оставалась доступной
/// после прокрутки сводки и переключения между позициями и ордерами.
class _PortfolioList extends StatelessWidget {
  const _PortfolioList({
    required this.name,
    required this.emptyMessage,
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
  });
  final String name;
  final String emptyMessage;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    key: PageStorageKey(name),
    slivers: [
      SliverOverlapInjector(
        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
      ),
      if (itemCount == 0)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text(emptyMessage)),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          sliver: SliverList.separated(
            itemCount: itemCount,
            itemBuilder: itemBuilder,
            separatorBuilder: separatorBuilder,
          ),
        ),
    ],
  );
}

/// Верхняя часть: стоимость, доходность, деньги и распределение по рынкам.
class _Summary extends StatelessWidget {
  const _Summary();

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TradingModel>();
    final positions = model.positions;
    final portfolio = model.portfolio;
    final totalValue = model.totalValue;
    final totalReturnPct = model.totalReturnPct;
    final positionsValue = model.positionsValue;
    Asset assetById(String id) => model.byId(id)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Стоимость позиций по каждому рынку
    final byMarket = {
      for (final m in Market.values)
        m: positions
            .where((p) => assetById(p.assetId).market == m)
            .fold<double>(
              0,
              (sum, p) => sum + p.quantity * assetById(p.assetId).lastPrice,
            ),
    };

    // Цвета сегментов берём из схемы темы
    final segmentColors = {
      Market.us: scheme.primary,
      Market.india: scheme.tertiary,
      Market.europe: scheme.secondary,
    };
    final cashColor = scheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Общая стоимость',
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatMoney(totalValue),
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              PriceChangeBadge(
                changePct: totalReturnPct,
                changeAmount: totalValue - portfolio.startingBalance,
              ),
              const SizedBox(width: 8),
              Text(
                'с ${formatDate(portfolio.createdAt)}',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: 'Свободные средства',
                          value: formatMoney(model.availableCash),
                          trailing: Text(
                            'В резерве: ${formatMoney(reservedCash(model.orders))}',
                          ),
                        ),
                      ),
                      Expanded(
                        child: StatTile(
                          label: 'В акциях',
                          value: formatMoney(positionsValue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Распределение по рынкам',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Полоса из сегментов: ширина пропорциональна стоимости
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          for (final m in Market.values)
                            Expanded(
                              flex: (byMarket[m]! * 100).round(),
                              child: Container(color: segmentColors[m]),
                            ),
                          Expanded(
                            flex: (portfolio.cashBalance * 100).round(),
                            child: Container(color: cashColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      for (final m in Market.values)
                        _Legend(
                          color: segmentColors[m]!,
                          label: m.label,
                          share: byMarket[m]! / totalValue,
                        ),
                      _Legend(
                        color: cashColor,
                        label: 'Деньги',
                        share: portfolio.cashBalance / totalValue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.share,
  });

  final Color color;
  final String label;
  final double share; // доля от 0 до 1

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label ', style: textTheme.bodySmall),
        Text(
          '${formatNumber(share * 100, decimals: 1)} %',
          style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Строка ордера: операция, тип, количество, цена и статус.
class _OrderTile extends StatelessWidget {
  const _OrderTile({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final model = context.watch<TradingModel>();
    final asset = model.byId(order.assetId)!;

    final sideText = order.side == OrderSide.buy ? 'Покупка' : 'Продажа';
    final typeText = order.type == OrderType.market ? 'Рыночный' : 'Лимитный';
    // Для исполненного показываем цену сделки, иначе — лимитную цену
    final price = order.executedPrice ?? order.limitPrice!;

    // Отменить можно только ожидающий ордер
    return InkWell(
      onTap: order.status == OrderStatus.pending && !model.isSaving
          ? () => _cancel(context)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            TickerAvatar(label: asset.symbol),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$sideText ${asset.symbol}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$typeText · ${order.quantity} шт. · ${formatDateTime(order.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMoney(price),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                _StatusChip(status: order.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final asset = context.read<TradingModel>().byId(order.assetId)!;
    final action = order.side == OrderSide.buy ? 'покупку' : 'продажу';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Отменить ордер?'),
        content: Text(
          'Лимитный ордер на $action ${order.quantity} ${asset.symbol} '
          'по ${formatMoney(order.limitPrice!)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Нет'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
              foregroundColor: Theme.of(dialogCtx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Отменить ордер'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final error = await context.read<TradingModel>().cancel(order.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ??
                'Ордер на $action ${order.quantity} ${asset.symbol} отменён',
          ),
        ),
      );
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (text, bg, fg) = switch (status) {
      OrderStatus.executed => (
        'Исполнен',
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      OrderStatus.pending => (
        'Ожидает',
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      OrderStatus.cancelled => (
        'Отменён',
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
