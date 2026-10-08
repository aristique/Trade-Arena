import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../widgets/filter_chips_row.dart';
import '../widgets/stock_tile.dart';
import 'stock_detail_screen.dart';

/// Рынок: поиск, фильтры по рынку и сектору, список акций.
class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Рынок')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SearchBar(
              hintText: 'Поиск по тикеру или компании',
              leading: Icon(Icons.search),
              elevation: WidgetStatePropertyAll(0),
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          FilterChipsRow(
            labels: ['Все рынки', for (final m in Market.values) m.label],
          ),
          const SizedBox(height: 8),
          const FilterChipsRow(labels: ['Все секторы', ...sectors]),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Text(
                  'Акции',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${assets.length}',
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  'Цена · за день',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: assets.length,
              itemBuilder: (context, index) => StockTile(
                asset: assets[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StockDetailScreen(asset: assets[index]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
