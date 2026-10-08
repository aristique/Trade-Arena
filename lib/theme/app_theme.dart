import 'package:flutter/material.dart';

/// Цвета роста и падения цены.
/// Вынесены в ThemeExtension, чтобы в экранах не было зашитых цветов:
/// виджеты берут их через MarketColors.of(context).
@immutable
class MarketColors extends ThemeExtension<MarketColors> {
  const MarketColors({
    required this.gain,
    required this.onGain,
    required this.gainContainer,
    required this.loss,
    required this.onLoss,
    required this.lossContainer,
  });

  final Color gain; // текст/линия при росте
  final Color onGain; // текст поверх gainContainer
  final Color gainContainer; // фон бейджа при росте
  final Color loss;
  final Color onLoss;
  final Color lossContainer;

  static const light = MarketColors(
    gain: Color(0xFF0F9D58),
    onGain: Color(0xFF0B6B3C),
    gainContainer: Color(0xFFDDF4E6),
    loss: Color(0xFFD93025),
    onLoss: Color(0xFFA1221A),
    lossContainer: Color(0xFFFCE3E1),
  );

  static const dark = MarketColors(
    gain: Color(0xFF3DD68C),
    onGain: Color(0xFF8EF0BE),
    gainContainer: Color(0xFF113D29),
    loss: Color(0xFFFF6B5E),
    onLoss: Color(0xFFFFB4AB),
    lossContainer: Color(0xFF4A1A16),
  );

  /// Короткий доступ из любого виджета.
  static MarketColors of(BuildContext context) =>
      Theme.of(context).extension<MarketColors>()!;

  @override
  MarketColors copyWith({
    Color? gain,
    Color? onGain,
    Color? gainContainer,
    Color? loss,
    Color? onLoss,
    Color? lossContainer,
  }) {
    return MarketColors(
      gain: gain ?? this.gain,
      onGain: onGain ?? this.onGain,
      gainContainer: gainContainer ?? this.gainContainer,
      loss: loss ?? this.loss,
      onLoss: onLoss ?? this.onLoss,
      lossContainer: lossContainer ?? this.lossContainer,
    );
  }

  // Нужен для плавной анимации при смене светлой/тёмной темы.
  @override
  MarketColors lerp(MarketColors? other, double t) {
    if (other == null) return this;
    return MarketColors(
      gain: Color.lerp(gain, other.gain, t)!,
      onGain: Color.lerp(onGain, other.onGain, t)!,
      gainContainer: Color.lerp(gainContainer, other.gainContainer, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      onLoss: Color.lerp(onLoss, other.onLoss, t)!,
      lossContainer: Color.lerp(lossContainer, other.lossContainer, t)!,
    );
  }
}

class AppTheme {
  // Насыщенный синий — привычный цвет финансовых приложений:
  // ассоциируется с надёжностью и не спорит с зелёным/красным цветом цен.
  static const seedColor = Color(0xFF1F5EFF);

  static ThemeData get light => _build(Brightness.light, MarketColors.light);
  static ThemeData get dark => _build(Brightness.dark, MarketColors.dark);

  static ThemeData _build(Brightness brightness, MarketColors marketColors) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [marketColors],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        showCheckmark: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
      ),
    );
  }
}
