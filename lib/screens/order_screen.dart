import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../models/trading_model.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/data_view.dart';
import '../widgets/ticker_avatar.dart';

/// Форма ордера: покупка/продажа, рыночный/лимитный, количество и итог.
class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key, required this.assetId, required this.side});

  final String assetId;
  final OrderSide side;

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController(text: '1');
  final _limitCtrl = TextEditingController();

  late OrderSide _side; // начальное значение приходит из адреса
  OrderType _type = OrderType.market;
  bool _untilCancelled = true;

  @override
  void initState() {
    super.initState();
    _side = widget.side;
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  int get _quantity {
    final value = int.tryParse(_quantityCtrl.text) ?? 0;
    return value >= 0 && value <= 1000000000 ? value : 0;
  }

  // Лимитная цена из поля, запятую принимаем как точку: «12,5» = 12.5
  double? get _limitPrice =>
      double.tryParse(_limitCtrl.text.replaceAll(',', '.'));

  // Цена для расчёта: у лимитного ордера — введённый лимит, иначе текущая
  double _price(Asset asset) {
    final limit = _limitPrice;
    if (_type == OrderType.limit &&
        limit != null &&
        limit.isFinite &&
        limit >= 0.01 &&
        limit <= 1000000000) {
      final rounded = money(limit);
      final executes = _side == OrderSide.buy
          ? asset.lastPrice <= rounded
          : asset.lastPrice >= rounded;
      return executes ? asset.lastPrice : rounded;
    }
    return asset.lastPrice;
  }

  String? _validateQuantity(String? value, Asset asset) {
    final quantity = int.tryParse(value ?? '');
    if (quantity == null) return 'Введите количество';
    if (quantity < 1) return 'Минимум 1 акция';
    if (quantity > 1000000000) return 'Слишком большое количество';

    final model = context.read<TradingModel>();

    if (_side == OrderSide.buy) {
      final amount = money(quantity * _price(asset));
      final cost = money(amount + orderFee(amount));
      if (cost > model.availableCash) {
        return 'Не хватает средств: нужно ${formatMoney(cost)}';
      }
    } else {
      final owned = model.availableShares(asset.id);
      if (owned == 0) return 'У вас нет акций ${asset.symbol}';
      if (quantity > owned) return 'В портфеле только $owned шт.';
    }
    return null;
  }

  String? _validateLimit(String? value) {
    if (_type != OrderType.limit) return null; // у рыночного поле не нужно
    final price = _limitPrice;
    if (price == null) return 'Введите цену';
    if (!price.isFinite || price < 0.01 || price > 1000000000) {
      return 'Цена должна быть от 0,01 до 1 000 000 000';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final model = context.read<TradingModel>();
    final error = await model.create(
      OrderDraft(
        assetId: widget.assetId,
        side: _side,
        type: _type,
        quantity: _quantity,
        limitPrice: _limitPrice,
        untilCancelled: _untilCancelled,
      ),
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final order = model.orders.first;
    final message = order.status == OrderStatus.executed
        ? 'Сделка исполнена'
        : 'Лимитный ордер создан';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    context.pop(); // форма открыта через push, закрываем через pop
  }

  @override
  Widget build(BuildContext context) {
    return DataView(
      builder: (context, model) {
        final scheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final colors = MarketColors.of(context);

        final asset = model.byId(widget.assetId);
        if (asset == null) {
          return const Scaffold(
            body: Center(child: Text('Акция не существует')),
          );
        }
        final isBuy = _side == OrderSide.buy;
        final isLimit = _type == OrderType.limit;

        // Итог считается заново при каждом вводе (setState в onChanged)
        final amount = money(_price(asset) * _quantity);
        final fee = orderFee(amount);
        // При покупке комиссия добавляется к сумме, при продаже — вычитается
        final total = isBuy ? amount + fee : amount - fee;

        return Scaffold(
          appBar: AppBar(title: Text(isBuy ? 'Покупка' : 'Продажа')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: AbsorbPointer(
              absorbing: model.isSaving,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        TickerAvatar(label: asset.symbol),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                asset.symbol,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                asset.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatMoney(asset.lastPrice),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SegmentedButton<OrderSide>(
                      segments: const [
                        ButtonSegment(
                          value: OrderSide.buy,
                          label: Text('Купить'),
                        ),
                        ButtonSegment(
                          value: OrderSide.sell,
                          label: Text('Продать'),
                        ),
                      ],
                      selected: {_side},
                      showSelectedIcon: false,
                      onSelectionChanged: (value) =>
                          setState(() => _side = value.first),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<OrderType>(
                      segments: const [
                        ButtonSegment(
                          value: OrderType.market,
                          label: Text('Рыночный'),
                        ),
                        ButtonSegment(
                          value: OrderType.limit,
                          label: Text('Лимитный'),
                        ),
                      ],
                      selected: {_type},
                      showSelectedIcon: false,
                      onSelectionChanged: (value) =>
                          setState(() => _type = value.first),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _quantityCtrl,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      // Только цифры: минус, точку и буквы ввести нельзя
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) => _validateQuantity(value, asset),
                      decoration: InputDecoration(
                        labelText: 'Количество',
                        suffixText: 'шт.',
                        helperText: isBuy
                            ? 'Свободно: ${formatMoney(model.availableCash)}'
                            : 'Доступно: ${model.availableShares(asset.id)} шт.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _limitCtrl,
                      onChanged: (_) => setState(() {}),
                      enabled: isLimit,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      validator: _validateLimit,
                      decoration: InputDecoration(
                        labelText: 'Лимитная цена',
                        prefixText: '\$ ',
                        hintText: formatNumber(asset.lastPrice),
                        helperText: 'Только для лимитного ордера',
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Рыночный ордер исполняется сразу, срок ему не нужен
                    if (isLimit)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Действует до отмены'),
                        subtitle: const Text(
                          'Иначе ордер снимется в конце дня',
                        ),
                        value: _untilCancelled,
                        onChanged: (value) =>
                            setState(() => _untilCancelled = value),
                      ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _SummaryRow(
                              label: isLimit
                                  ? 'Цена для расчёта'
                                  : 'Цена за акцию',
                              value: formatMoney(_price(asset)),
                            ),
                            _SummaryRow(
                              label: 'Количество',
                              value: '$_quantity шт.',
                            ),
                            _SummaryRow(
                              label: 'Сумма',
                              value: formatMoney(amount),
                            ),
                            _SummaryRow(
                              label: 'Комиссия 0,1 %',
                              value: formatMoney(fee),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(),
                            ),
                            _SummaryRow(
                              label: isBuy
                                  ? 'Итого к оплате'
                                  : 'Итого к зачислению',
                              value: formatMoney(total),
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                // Продажа выделяется цветом падения, как в брокерских приложениях
                style: isBuy
                    ? null
                    : FilledButton.styleFrom(
                        backgroundColor: colors.loss,
                        foregroundColor: scheme.onError,
                      ),
                onPressed: model.isSaving ? null : _submit,
                child: model.isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        '${isBuy ? 'Купить' : 'Продать'} $_quantity ${asset.symbol}',
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final weight = bold ? FontWeight.w700 : FontWeight.w500;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyLarge?.copyWith(
                color: bold ? scheme.onSurface : scheme.onSurfaceVariant,
                fontWeight: bold ? FontWeight.w600 : null,
              ),
            ),
          ),
          Text(value, style: textTheme.bodyLarge?.copyWith(fontWeight: weight)),
        ],
      ),
    );
  }
}
