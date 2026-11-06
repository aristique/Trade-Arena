import 'package:flutter/material.dart';

import '../data/models.dart';
import '../widgets/data_view.dart';
import '../widgets/filter_chips_row.dart';
import '../widgets/news_card.dart';

/// Лента новостей по рынкам, где у пользователя есть позиции.
class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  int _marketIndex = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DataScreen(
      title: 'Новости',
      builder: (context, model) {
        final markets = model.positions
            .map((p) => model.byId(p.assetId)!.market)
            .toSet();
        final newsArticles = model.news
            .where(
              (n) =>
                  markets.contains(n.market) &&
                  (_marketIndex == 0 ||
                      n.market == Market.values[_marketIndex - 1]),
            )
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'По рынкам, где у вас есть позиции',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            FilterChipsRow(
              labels: ['Все', for (final m in Market.values) m.label],
              selectedIndex: _marketIndex,
              onSelected: (i) => setState(() => _marketIndex = i),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: newsArticles.isEmpty
                  ? const Center(child: Text('Нет новостей по вашим позициям'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: newsArticles.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          NewsCard(article: newsArticles[index]),
                    ),
            ),
          ],
        );
      },
    );
  }
}
