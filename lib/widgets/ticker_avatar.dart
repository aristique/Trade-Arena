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

    // Цвет фона выбирается по первой букве, чтобы соседние
    // кружки отличались, но цвета всё равно берутся из темы.
    final palette = [
      (scheme.primaryContainer, scheme.onPrimaryContainer),
      (scheme.secondaryContainer, scheme.onSecondaryContainer),
      (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    ];
    final (bg, fg) = highlighted
        ? (scheme.primary, scheme.onPrimary)
        : palette[label.codeUnitAt(0) % palette.length];

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        _shortLabel(label),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.32,
        ),
      ),
    );
  }

  // "AAPL" -> "AA", "Мария Чебан" -> "МЧ"
  static String _shortLabel(String text) {
    final words = text.trim().split(' ');
    if (words.length > 1) return (words[0][0] + words[1][0]).toUpperCase();
    return text.length > 2 ? text.substring(0, 2) : text;
  }
}
