import 'package:flutter/material.dart';

import '../data/models.dart';
import '../utils/format.dart';
import 'price_change_badge.dart';
import 'ticker_avatar.dart';

/// Строка акции: аватар, тикер, название, цена и изменение.
/// На экране рынка показывает цену акции, в портфеле — стоимость позиции.
class StockTile extends StatelessWidget {
  const StockTile({
    super.key,
    required this.asset,
    this.subtitle,
    this.value,
    this.changePct,
    this.onTap,
  });

  final Asset asset;
  final String? subtitle; // по умолчанию — название компании
  final double? value; // по умолчанию — цена акции
  final double? changePct; // по умолчанию — изменение за день
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
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
                    asset.symbol,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle ?? asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
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
                  formatMoney(value ?? asset.lastPrice),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                PriceChangeBadge(changePct: changePct ?? asset.changePct),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
