import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/trading_model.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min,
      children: [Text(message, textAlign: TextAlign.center), const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: const Text('Повторить'))])));
}

/// Общие loading / error / data, в том числе для уже открытых вкладок.
class DataView extends StatelessWidget {
  const DataView({super.key, required this.builder});
  final Widget Function(BuildContext, TradingModel) builder;
  @override
  Widget build(BuildContext context) {
    final model = context.watch<TradingModel>();
    if (model.isLoading) return const Center(child: CircularProgressIndicator());
    if (model.error != null) return ErrorView(message: model.error!,
      onRetry: () => context.read<TradingModel>().load());
    if (!model.hasData) return ErrorView(message: 'Данные ещё не загружены',
      onRetry: () => context.read<TradingModel>().load());
    return builder(context, model);
  }
}

class DataScreen extends StatelessWidget {
  const DataScreen({super.key, required this.title, required this.builder});
  final String title;
  final Widget Function(BuildContext, TradingModel) builder;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)), body: DataView(builder: builder));
}
