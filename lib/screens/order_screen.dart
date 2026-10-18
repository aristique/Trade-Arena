import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/ticker_avatar.dart';

/// Количество для предпросмотра. На L2 поле не связано с расчётом.
const _previewQuantity = 4;

/// Комиссия брокера — 0,1 % от суммы сделки.
const _feeRate = 0.001;

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
  final _quantityCtrl = TextEditingController(text: '$_previewQuantity');
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.pop(); // форма открыта через push, закрываем через pop
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final colors = MarketColors.of(context);

    final asset = assetById(widget.assetId);
    final isBuy = _side == OrderSide.buy;
    final isLimit = _type == OrderType.limit;
    final position = positionFor(asset.id);

    final amount = asset.lastPrice * _previewQuantity;
    final fee = amount * _feeRate;
    // При покупке комиссия добавляется к сумме, при продаже — вычитается
    final total = isBuy ? amount + fee : amount - fee;

    return Scaffold(
      appBar: AppBar(title: Text(isBuy ? 'Покупка' : 'Продажа')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                  ButtonSegment(value: OrderSide.buy, label: Text('Купить')),
                  ButtonSegment(value: OrderSide.sell, label: Text('Продать')),
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
                keyboardType: TextInputType.number,
                // Только цифры: минус, точку и буквы ввести нельзя
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final quantity = int.tryParse(value ?? '');
                  if (quantity == null) return 'Введите количество';
                  if (quantity < 1) return 'Минимум 1 акция';
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Количество',
                  suffixText: 'шт.',
                  helperText: isBuy
                      ? 'Свободно: ${formatMoney(portfolio.cashBalance)}'
                      : 'В портфеле: ${position?.quantity ?? 0} шт.',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _limitCtrl,
                enabled: isLimit,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
                  subtitle: const Text('Иначе ордер снимется в конце дня'),
                  value: _untilCancelled,
                  onChanged: (value) => setState(() => _untilCancelled = value),
                ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SummaryRow(
                        label: 'Цена за акцию',
                        value: formatMoney(asset.lastPrice),
                      ),
                      _SummaryRow(
                        label: 'Количество',
                        value: '$_previewQuantity шт.',
                      ),
                      _SummaryRow(label: 'Сумма', value: formatMoney(amount)),
                      _SummaryRow(
                        label: 'Комиссия 0,1 %',
                        value: formatMoney(fee),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(),
                      ),
                      _SummaryRow(
                        label: isBuy ? 'Итого к оплате' : 'Итого к зачислению',
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
            onPressed: _submit,
            child: Text(
              '${isBuy ? 'Купить' : 'Продать'} $_previewQuantity ${asset.symbol}',
            ),
          ),
        ),
      ),
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
