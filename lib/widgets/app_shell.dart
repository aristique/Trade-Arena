import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/trading_model.dart';

/// Обёртка с нижней панелью вкладок.
/// Состояния нет: какая вкладка открыта, знает роутер.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell, // содержимое текущей вкладки
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.candlestick_chart_outlined),
            selectedIcon: Icon(Icons.candlestick_chart),
            label: 'Рынок',
          ),
          NavigationDestination(
            icon: Consumer<TradingModel>(
              builder: (context, model, child) => Badge(
                isLabelVisible: model.pendingCount > 0,
                label: Text('${model.pendingCount}'),
                child: child!,
              ),
              child: const Icon(Icons.pie_chart_outline),
            ),
            selectedIcon: Consumer<TradingModel>(
              builder: (context, model, child) => Badge(
                isLabelVisible: model.pendingCount > 0,
                label: Text('${model.pendingCount}'),
                child: child!,
              ),
              child: const Icon(Icons.pie_chart),
            ),
            label: 'Портфель',
          ),
          const NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Новости',
          ),
          const NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'Рейтинг',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
