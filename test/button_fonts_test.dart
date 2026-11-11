import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_arena/theme/app_theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('Кнопки сохраняют шрифт темы: ${brightness.name}', (
      tester,
    ) async {
      final theme = brightness == Brightness.light
          ? AppTheme.light
          : AppTheme.dark;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Column(
              children: [
                FilledButton(onPressed: () {}, child: const Text('Купить')),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  onPressed: () {},
                  child: const Text('Отменить ордер'),
                ),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Сбросить портфель'),
                ),
              ],
            ),
          ),
        ),
      );

      for (final label in ['Купить', 'Отменить ордер', 'Сбросить портфель']) {
        final text = tester.widget<RichText>(
          find.descendant(
            of: find
                .ancestor(
                  of: find.text(label),
                  matching: find.byWidgetPredicate(
                    (widget) => widget is ButtonStyleButton,
                  ),
                )
                .first,
            matching: find.byType(RichText),
          ),
        );
        // Проверяем стиль реального текста после разрешения ButtonStyle,
        // а не только наличие правильной строки в дереве виджетов.
        expect(
          text.text.style!.fontFamily,
          theme.textTheme.labelLarge!.fontFamily,
          reason: '$label должен сохранять шрифт темы',
        );
        expect(text.text.style!.fontSize, 16);
        expect(text.text.style!.fontWeight, FontWeight.w600);
      }
    });
  }
}
