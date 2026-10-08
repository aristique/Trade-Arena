import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

void main() {
  runApp(const TradeArenaApp());
}

class TradeArenaApp extends StatelessWidget {
  const TradeArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TradeArena',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const Scaffold(body: Center(child: Text('TradeArena'))),
    );
  }
}
