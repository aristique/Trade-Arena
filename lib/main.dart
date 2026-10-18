import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TradeArenaApp());
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
