import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/mock_trading_repository.dart';
import '../models/trading_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/data_view.dart';
import '../widgets/stat_tile.dart';
import '../widgets/ticker_avatar.dart';

/// Профиль: статистика, настройки и сброс портфеля.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _simulateError = false;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _simulateError = context.read<MockTradingRepository>().simulateError;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            tooltip: 'Обновить данные',
            onPressed: () => context.read<TradingModel>().load(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Симулировать сбой сети'),
            value: _simulateError,
            onChanged: (value) {
              setState(() => _simulateError = value);
              context.read<MockTradingRepository>().simulateError = value;
            },
          ),
          Expanded(child: DataView(builder: _buildContent)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, TradingModel model) {
    final currentUserName = model.user.name;
    final currentUserEmail = model.user.email;
    final portfolio = model.portfolio;
    final totalReturnPct = model.totalReturnPct;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final colors = MarketColors.of(context);
    final me = model.leaderboard.firstWhere((p) => p.isMe);
    final best = model.bestTrade;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            TickerAvatar(label: currentUserName, size: 64, highlighted: true),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUserName,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    currentUserEmail,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'В игре с ${formatDate(portfolio.createdAt)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'Доходность',
                        value: formatPercent(totalReturnPct),
                        valueColor: totalReturnPct >= 0
                            ? colors.gain
                            : colors.loss,
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        label: 'Место в рейтинге',
                        value: '${me.rank}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'Сделок',
                        value: '${me.tradesCount}',
                      ),
                    ),
                    Expanded(
                      child: StatTile(
                        label: 'Лучшая сделка',
                        value: best == null
                            ? 'Нет данных'
                            : '${model.byId(best.assetId)!.symbol} ${formatSignedMoney(best.realizedProfit!)}',
                        valueColor: colors.gain,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Настройки',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Уведомления'),
                value: _notifications,
                onChanged: (value) => setState(() => _notifications = value),
              ),
              const Divider(indent: 56),
              const ListTile(
                leading: Icon(Icons.attach_money),
                title: Text('Валюта'),
                trailing: Text('USD'),
              ),
              const Divider(indent: 56),
              const ListTile(
                leading: Icon(Icons.dark_mode_outlined),
                title: Text('Тема'),
                trailing: Text('Как в системе'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.error,
            side: BorderSide(color: scheme.error),
          ),
          icon: const Icon(Icons.restart_alt),
          label: const Text('Сбросить портфель'),
          onPressed: model.isSaving ? null : () => _resetPortfolio(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Баланс вернётся к ${formatMoney(portfolio.startingBalance)}, '
          'позиции и ордера будут удалены.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => _logout(context),
          child: const Text('Выйти'),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        actions: [
          // Закрываем через dialogCtx: у вкладок свои навигаторы
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    // ok == true, а не ok!: если закрыть диалог тапом мимо, придёт null
    if (ok == true && context.mounted) {
      context.go('/login'); // go: вкладки уходят из стека
    }
  }

  Future<void> _resetPortfolio(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Сбросить портфель?'),
        content: const Text(
          'Все позиции и история ордеров будут удалены. Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
              foregroundColor: Theme.of(dialogCtx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final model = context.read<TradingModel>();
      final error = await model.reset();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ??
                'Портфель сброшен, баланс снова '
                    '${formatMoney(model.portfolio.startingBalance)}',
          ),
        ),
      );
    }
  }
}
