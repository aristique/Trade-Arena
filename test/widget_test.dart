import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trade_arena/main.dart';

void main() {
  testWidgets('Приложение запускается', (WidgetTester tester) async {
    await tester.pumpWidget(const TradeArenaApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
