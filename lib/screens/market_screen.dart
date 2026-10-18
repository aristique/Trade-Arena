import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../widgets/filter_chips_row.dart';
import '../widgets/stock_tile.dart';

/// Рынок: поиск, фильтры по рынку и сектору, список акций.
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String _query = '';
  int _marketIndex = 0; // 0 — все рынки, дальше по порядку Market.values
  int _sectorIndex = 0; // 0 — все секторы, дальше по списку sectors

  List<Asset> get _filtered {
    final query = _query.trim().toLowerCase();
    return assets.where((a) {
      final matchesQuery =
          a.symbol.toLowerCase().contains(query) ||
          a.name.toLowerCase().contains(query);
      final matchesMarket =
          _marketIndex == 0 || a.market == Market.values[_marketIndex - 1];
      final matchesSector =
          _sectorIndex == 0 || a.sector == sectors[_sectorIndex - 1];
      return matchesQuery && matchesMarket && matchesSector;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final list = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Рынок')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SearchBar(
              hintText: 'Поиск по тикеру или компании',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          FilterChipsRow(
            labels: ['Все рынки', for (final m in Market.values) m.label],
            selectedIndex: _marketIndex,
            onSelected: (i) => setState(() => _marketIndex = i),
          ),
          const SizedBox(height: 8),
          FilterChipsRow(
            labels: ['Все секторы', ...sectors],
            selectedIndex: _sectorIndex,
            onSelected: (i) => setState(() => _sectorIndex = i),
          ),
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
                  '${list.length}',
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
            child: list.isEmpty
                ? Center(
                    child: Text(
                      'Ничего не найдено',
                      style: textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) => StockTile(
                      asset: list[index],
                      onTap: () => context.push('/market/${list[index].id}'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
