import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/news_card.dart';
import '../widgets/price_change_badge.dart';
import '../widgets/stat_tile.dart';
import '../widgets/ticker_avatar.dart';
import 'order_screen.dart';

// Форма графика за день: отклонения в % от плавного тренда.
// Нужны только этому экрану, поэтому лежат здесь, а не в mock_data.
const _chartShape = <double>[
  0.0, 0.18, 0.05, -0.12, -0.30, -0.22, 0.04, 0.21, 0.35, 0.16, //
  -0.08, -0.25, -0.10, 0.12, 0.28, 0.40, 0.22, 0.05, -0.15, -0.05, //
  0.14, 0.26, 0.10, 0.0,
];

/// Карточка акции: цена, график, моя позиция, кнопки и новости.
class StockDetailScreen extends StatelessWidget {
  const StockDetailScreen({super.key, required this.asset});

  final Asset asset;

  void _openOrder(BuildContext context, OrderSide side) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderScreen(asset: asset, side: side),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final colors = MarketColors.of(context);

    final position = positionFor(asset.id);
    final news = newsArticles
        .where((n) => n.symbols.contains(asset.symbol))
        .toList();

    // Цена на открытии дня, из неё считаем изменение в долларах
    final openPrice = asset.lastPrice / (1 + asset.changePct / 100);
    final lineColor = asset.changePct >= 0 ? colors.gain : colors.loss;

    return Scaffold(
      appBar: AppBar(title: Text(asset.symbol)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TickerAvatar(label: asset.symbol, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${asset.market.label} · ${asset.sector}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              formatMoney(asset.lastPrice),
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                PriceChangeBadge(
                  changePct: asset.changePct,
                  changeAmount: asset.lastPrice - openPrice,
                ),
                const SizedBox(width: 8),
                Text(
                  'сегодня',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: _PriceChart(
                openPrice: openPrice,
                lastPrice: asset.lastPrice,
                color: lineColor,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '1Д', label: Text('1Д')),
                  ButtonSegment(value: '1Н', label: Text('1Н')),
                  ButtonSegment(value: '1М', label: Text('1М')),
                ],
                selected: const {'1Д'},
                showSelectedIcon: false,
                onSelectionChanged: (_) {}, // переключение — в L4
              ),
            ),
            const SizedBox(height: 28),
            _SectionTitle('Моя позиция'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: position == null
                    ? Text(
                        'У вас пока нет акций ${asset.symbol}',
                        style: textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      )
                    : _PositionInfo(position: position, asset: asset),
              ),
            ),
            const SizedBox(height: 28),
            _SectionTitle('Информация'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'Рынок',
                        value: asset.market.label,
                      ),
                    ),
                    Expanded(
                      child: StatTile(label: 'Сектор', value: asset.sector),
                    ),
                    Expanded(
                      child: StatTile(
                        label: 'Обновлено',
                        value: formatDateTime(asset.updatedAt),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            _SectionTitle('Новости компании'),
            if (news.isEmpty)
              Text(
                'Свежих новостей по ${asset.symbol} нет',
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else
              // Список внутри прокрутки: shrinkWrap + без своей прокрутки
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: news.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) => NewsCard(article: news[index]),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _openOrder(context, OrderSide.sell),
                  child: const Text('Продать'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => _openOrder(context, OrderSide.buy),
                  child: const Text('Купить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Сетка 2×2 с данными позиции.
class _PositionInfo extends StatelessWidget {
  const _PositionInfo({required this.position, required this.asset});

  final Position position;
  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final value = position.quantity * asset.lastPrice;
    final profit = (asset.lastPrice - position.avgPrice) * position.quantity;
    final profitPct = (asset.lastPrice / position.avgPrice - 1) * 100;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Количество',
                value: '${position.quantity} шт.',
              ),
            ),
            Expanded(
              child: StatTile(
                label: 'Средняя цена',
                value: formatMoney(position.avgPrice),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatTile(label: 'Стоимость', value: formatMoney(value)),
            ),
            Expanded(
              child: StatTile(
                label: 'Прибыль',
                value: formatSignedMoney(profit),
                trailing: PriceChangeBadge(changePct: profitPct),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Линейный график цены за день на fl_chart.
class _PriceChart extends StatelessWidget {
  const _PriceChart({
    required this.openPrice,
    required this.lastPrice,
    required this.color,
  });

  final double openPrice;
  final double lastPrice;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Точка i = плавный переход от цены открытия к текущей + «шум» из _chartShape
    final last = _chartShape.length - 1;
    final spots = [
      for (var i = 0; i <= last; i++)
        FlSpot(
          i.toDouble(),
          openPrice +
              (lastPrice - openPrice) * i / last +
              lastPrice * _chartShape[i] / 100,
        ),
    ];

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
