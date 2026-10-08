import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Изменение цены: «▲ +1,32 %» зелёным или «▼ −0,85 %» красным.
/// Знак и стрелка дублируют цвет — понятно и без различения цветов.
class PriceChangeBadge extends StatelessWidget {
  const PriceChangeBadge({
    super.key,
    required this.changePct,
    this.changeAmount,
    this.filled = true,
  });

  final double changePct;
  final double? changeAmount; // если задано — показываем ещё и сумму
  final bool filled; // false — только цветной текст без фона

  @override
  Widget build(BuildContext context) {
    final colors = MarketColors.of(context);
    final isUp = changePct >= 0;

    final arrow = isUp ? '▲' : '▼';
    final text = changeAmount == null
        ? '$arrow ${formatPercent(changePct)}'
        : '$arrow ${formatSignedMoney(changeAmount!)} (${formatPercent(changePct)})';

    final label = Text(
      text,
      style: TextStyle(
        color: filled
            ? (isUp ? colors.onGain : colors.onLoss)
            : (isUp ? colors.gain : colors.loss),
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );

    if (!filled) return label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isUp ? colors.gainContainer : colors.lossContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: label,
    );
  }
}
