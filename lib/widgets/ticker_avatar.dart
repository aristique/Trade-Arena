import 'package:flutter/material.dart';

/// Кружок с тикером или инициалами вместо логотипа.
class TickerAvatar extends StatelessWidget {
  const TickerAvatar({
    super.key,
    required this.label,
    this.size = 44,
    this.highlighted = false,
  });

  final String label; // тикер (AAPL) или имя пользователя
  final double size;
  final bool highlighted; // акцентный цвет, например для «моей» строки

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Обычный кружок — нейтральный, выделенный — основного цвета темы
    final bg = highlighted ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = highlighted ? scheme.onPrimary : scheme.onSurface;

    final text = _shortLabel(label);
    // Чем длиннее подпись, тем мельче шрифт, чтобы она влезла в круг
    final fontScale = switch (text.length) {
      <= 2 => 0.34,
      3 => 0.27,
      _ => 0.23,
    };

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: size * fontScale,
        ),
      ),
    );
  }

  // Тикер — до 4 букв ("HDFCBANK" -> "HDFC"), имя — инициалы ("Мария Чебан" -> "МЧ")
  static String _shortLabel(String text) {
    final words = text.trim().split(' ');
    if (words.length > 1) return (words[0][0] + words[1][0]).toUpperCase();
    final isTicker = text == text.toUpperCase();
    final length = isTicker ? 4 : 2;
    final short = text.length > length ? text.substring(0, length) : text;
    return short.toUpperCase();
  }
}
