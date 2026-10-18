import 'package:go_router/go_router.dart';

import 'data/models.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/market_screen.dart';
import 'screens/news_screen.dart';
import 'screens/order_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/stock_detail_screen.dart';
import 'widgets/app_shell.dart';

// Карта приложения: у каждого экрана свой адрес.
// Роутер создаётся один раз, поэтому после изменений здесь нужен restart (R).
final router = GoRouter(
  initialLocation: '/login',
  routes: [
    // Вход вне вкладок, поэтому на нём нет нижней панели
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/market/:id', // /market/a_aapl
      builder: (context, state) =>
          StockDetailScreen(assetId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/market/:id/order', // /market/a_aapl/order?side=sell
      builder: (context, state) {
        final side = state.uri.queryParameters['side'] == 'sell'
            ? OrderSide.sell
            : OrderSide.buy;
        return OrderScreen(assetId: state.pathParameters['id']!, side: side);
      },
    ),

    // Разделы с вкладками. indexedStack хранит стек и прокрутку каждой вкладки
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/market',
              builder: (context, state) => const MarketScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/portfolio',
              builder: (context, state) => const PortfolioScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/news',
              builder: (context, state) => const NewsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/leaderboard',
              builder: (context, state) => const LeaderboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
