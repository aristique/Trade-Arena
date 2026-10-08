import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../utils/format.dart';
import '../widgets/price_change_badge.dart';
import '../widgets/ticker_avatar.dart';

/// Общее число участников (на L2 — просто число).
const _participantsTotal = 128;

/// Рейтинг участников по доходности. Строка пользователя выделена.
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final me = leaderboard.firstWhere((p) => p.isMe);

    return Scaffold(
      appBar: AppBar(title: const Text('Рейтинг')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'week', label: Text('Неделя')),
                ButtonSegment(value: 'month', label: Text('Месяц')),
                ButtonSegment(value: 'all', label: Text('Всё время')),
              ],
              selected: const {'all'},
              showSelectedIcon: false,
              onSelectionChanged: (_) {},
            ),
          ),
          // Карточка с местом пользователя
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: scheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ваше место',
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            '${me.rank} из $_participantsTotal',
                            style: textTheme.headlineSmall?.copyWith(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PriceChangeBadge(changePct: me.returnPct),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text('№', style: _headerStyle(context)),
                ),
                Expanded(child: Text('Участник', style: _headerStyle(context))),
                Text('Доходность', style: _headerStyle(context)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
              itemCount: leaderboard.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) =>
                  _ParticipantRow(participant: leaderboard[index]),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle? _headerStyle(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.participant});

  final Participant participant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isTop3 = participant.rank <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      // «Моя» строка подсвечивается фоном
      decoration: BoxDecoration(
        color: participant.isMe ? scheme.secondaryContainer : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: isTop3
                ? Icon(Icons.emoji_events, color: scheme.tertiary, size: 22)
                : Text(
                    '${participant.rank}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
          ),
          TickerAvatar(
            label: participant.name,
            size: 40,
            highlighted: participant.isMe,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.isMe
                      ? '${participant.name} (вы)'
                      : participant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${formatMoney(participant.totalValue)} · ${participant.tradesCount} сделок',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PriceChangeBadge(changePct: participant.returnPct),
        ],
      ),
    );
  }
}
