import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../utils/format.dart';
import '../widgets/price_change_badge.dart';
import '../widgets/stat_tile.dart';
import '../widgets/stock_tile.dart';
import '../widgets/ticker_avatar.dart';
import 'stock_detail_screen.dart';

/// Портфель: итоговая стоимость, распределение и вкладки «Позиции» / «Ордера».
class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Портфель')),
        // NestedScrollView: сводка прокручивается, а вкладки остаются сверху
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            const SliverToBoxAdapter(child: _Summary()),
            SliverAppBar(
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
          ],
          body: TabBarView(
            children: [
              ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: positions.length,
                separatorBuilder: (context, index) => const Divider(indent: 72),
                itemBuilder: (context, index) {
                  final position = positions[index];
                  final asset = assetById(position.assetId);
                  return StockTile(
                    asset: asset,
                    subtitle:
                        '${position.quantity} шт. · ср. ${formatMoney(position.avgPrice)}',
                    value: position.quantity * asset.lastPrice,
                    changePct: (asset.lastPrice / position.avgPrice - 1) * 100,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StockDetailScreen(asset: asset),
                      ),
                    ),
                  );
                },
              ),
              ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: orders.length,
                separatorBuilder: (context, index) => const Divider(indent: 72),
                itemBuilder: (context, index) =>
                    _OrderTile(order: orders[index]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Верхняя часть: стоимость, доходность, деньги и распределение по рынкам.
class _Summary extends StatelessWidget {
  const _Summary();

  @override
  Widget build(BuildContext context) {
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
                          value: formatMoney(portfolio.cashBalance),
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
  const _OrderTile({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final asset = assetById(order.assetId);

    final sideText = order.side == OrderSide.buy ? 'Покупка' : 'Продажа';
    final typeText = order.type == OrderType.market ? 'Рыночный' : 'Лимитный';
    // Для исполненного показываем цену сделки, иначе — лимитную цену
    final price = order.executedPrice ?? order.limitPrice!;

    return Padding(
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
    );
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
