import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../widgets/filter_chips_row.dart';
import '../widgets/news_card.dart';

/// Лента новостей по рынкам, где у пользователя есть позиции.
class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Новости')),
      body: Column(
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
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: newsArticles.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  NewsCard(article: newsArticles[index]),
            ),
          ),
        ],
      ),
    );
  }
}
