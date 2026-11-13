import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trade_arena/main.dart' as app;
import 'package:trade_arena/models/trading_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Регистрация, сделка, сохранённая сессия и смена пользователя', (
    tester,
  ) async {
    await SharedPreferencesAsync().remove('auth_token');
    await app.main();

    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (finder.evaluate().isNotEmpty) return;
      }
      fail('Не появился элемент: $finder');
    }

    Future<void> register(String email) async {
      await waitFor(find.text('Нет аккаунта? Зарегистрируйтесь'));
      await tester.tap(find.text('Нет аккаунта? Зарегистрируйтесь'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Backend Test');
      await tester.enterText(fields.at(1), email);
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await waitFor(find.byType(NavigationBar));
      await waitFor(find.text('Apple Inc.'));
    }

    TradingModel model() =>
        tester.element(find.byType(NavigationBar)).read<TradingModel>();
    final email = 'android${DateTime.now().microsecondsSinceEpoch}@example.com';
    await register(email);
    expect(model().portfolio.cashBalance, 10000);
    expect(model().positions, isEmpty);

    await tester.enterText(find.byType(TextField).first, 'TSLA');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tesla Inc.'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Купить'));
    await tester.tap(find.widgetWithText(FilledButton, 'Купить'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Купить 1 TSLA'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Купить 1 TSLA'));
    await waitFor(find.text('Моя позиция'));
    expect(model().portfolio.cashBalance, 9687.09);
    expect(model().positions.single.assetId, 'a_tsla');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await app.main();
    await waitFor(find.byType(NavigationBar));
    await waitFor(find.text('Apple Inc.'));
    expect(model().portfolio.cashBalance, 9687.09);
    expect(model().orders.length, 1);

    await tester.tap(find.text('Профиль').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(TextButton, 'Выйти'));
    await tester.tap(find.widgetWithText(TextButton, 'Выйти'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Выйти'));
    await waitFor(find.text('Нет аккаунта? Зарегистрируйтесь'));
    expect(await SharedPreferencesAsync().getString('auth_token'), isNull);

    await register('second$email');
    expect(model().portfolio.cashBalance, 10000);
    expect(model().positions, isEmpty);
    expect(model().orders, isEmpty);
  });
}
