import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/mock_trading_repository.dart';
import 'data/trading_repository.dart';
import 'models/trading_model.dart';

import 'router.dart';
import 'theme/app_theme.dart';

void main() {
  // Единственное место выбора источника. На L5 здесь будет HttpRepository.
  final repository = MockTradingRepository();
  runApp(MultiProvider(providers: [
    Provider<TradingRepository>.value(value: repository),
    // Только для демонстрационного переключателя аварии в профиле.
    Provider<MockTradingRepository>.value(value: repository),
    ChangeNotifierProvider(create: (_) => TradingModel(repository)..load()),
  ], child: const TradeArenaApp()));
}

class TradeArenaApp extends StatelessWidget {
  const TradeArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TradeArena',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // светлая или тёмная — как в системе
      scrollBehavior: const AppScrollBehavior(), // без растягивания у края
      routerConfig: router, // стартовый экран задан в router.dart
    );
  }
}
