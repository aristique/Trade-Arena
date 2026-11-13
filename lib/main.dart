import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/api_client.dart';
import 'data/http_trading_repository.dart';
import 'data/token_store.dart';
import 'data/trading_repository.dart';
import 'models/auth_model.dart';
import 'models/trading_model.dart';
import 'router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const configuredUrl = String.fromEnvironment('API_BASE_URL');
  final defaultUrl = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8080'
      : 'http://localhost:8080';
  final api = ApiClient(
    baseUrl: Uri.parse(configuredUrl.isEmpty ? defaultUrl : configuredUrl),
    client: http.Client(),
  );
  final auth = AuthModel(api, PreferencesTokenStore(SharedPreferencesAsync()));
  await auth.restore();
  final appRouter = createRouter(auth: auth);
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>(
          create: (_) => api,
          dispose: (_, value) => value.close(),
        ),
        Provider<TradingRepository>(create: (_) => HttpTradingRepository(api)),
        ChangeNotifierProvider(create: (_) => auth),
      ],
      child: _SessionApp(routerConfig: appRouter),
    ),
  );
}

class _SessionApp extends StatelessWidget {
  const _SessionApp({required this.routerConfig});
  final GoRouter routerConfig;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthModel>();
    return ChangeNotifierProvider(
      key: ValueKey(auth.generation),
      create: (context) {
        final model = TradingModel(context.read<TradingRepository>());
        if (auth.isAuthenticated) model.load();
        return model;
      },
      child: TradeArenaApp(routerConfig: routerConfig),
    );
  }
}

class TradeArenaApp extends StatelessWidget {
  const TradeArenaApp({super.key, this.routerConfig});
  final GoRouter? routerConfig;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'TradeArena',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    themeMode: ThemeMode.system,
    scrollBehavior: const AppScrollBehavior(),
    routerConfig: routerConfig ?? router,
  );
}
