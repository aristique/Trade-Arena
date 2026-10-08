import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/stat_tile.dart';
import '../widgets/ticker_avatar.dart';
import 'login_screen.dart';

/// Профиль: статистика, настройки и сброс портфеля.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final colors = MarketColors.of(context);
    final me = leaderboard.firstWhere((p) => p.isMe);

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              const TickerAvatar(
                label: currentUserName,
                size: 64,
                highlighted: true,
              ),
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
                      // Лучшая сделка: продажа TSLA по $341,20 (куплено по $314,30)
                      Expanded(
                        child: StatTile(
                          label: 'Лучшая сделка',
                          value: 'TSLA ▲ +\$134,50',
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
                  title: const Text('Уведомления об ордерах'),
                  value: true,
                  onChanged: (_) {},
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
            onPressed: () => _confirmReset(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Баланс вернётся к ${formatMoney(portfolio.startingBalance)}, '
            'позиции и ордера будут удалены.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  // Диалог подтверждения. Сам сброс появится вместе с торговой логикой (L4).
  void _confirmReset(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сбросить портфель?'),
        content: const Text(
          'Все позиции и история ордеров будут удалены. Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}
