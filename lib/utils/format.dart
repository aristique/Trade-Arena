import '../data/mock_data.dart';

// Простые функции форматирования без пакета intl.
// Формат как в русской локали: пробел между разрядами, запятая в дробной части.

const _nbsp = ' '; // неразрывный пробел, чтобы сумма не переносилась
const _minus = '−'; // типографский минус

/// 12345.6 -> "12 345,60"
String formatNumber(double value, {int decimals = 2}) {
  final parts = value.abs().toStringAsFixed(decimals).split('.');
  final intPart = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    // ставим пробел перед каждой группой из трёх цифр
    if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(_nbsp);
    buffer.write(intPart[i]);
  }
  final sign = value < 0 ? _minus : '';
  return decimals > 0 ? '$sign$buffer,${parts[1]}' : '$sign$buffer';
}

/// 12345.6 -> "$12 345,60"
String formatMoney(double value) {
  final sign = value < 0 ? _minus : '';
  return '$sign\$${formatNumber(value.abs())}';
}

/// Деньги со знаком: "+$412,30" / "−$18,05"
String formatSignedMoney(double value) =>
    value >= 0 ? '+${formatMoney(value)}' : formatMoney(value);

/// Процент со знаком: "+1,32 %" / "−0,85 %"
String formatPercent(double value) {
  final sign = value >= 0 ? '+' : '';
  return '$sign${formatNumber(value)}$_nbsp%';
}

String _two(int n) => n.toString().padLeft(2, '0');

const _months = [
  'янв',
  'фев',
  'мар',
  'апр',
  'мая',
  'июн',
  'июл',
  'авг',
  'сен',
  'окт',
  'ноя',
  'дек',
];

/// "9 окт, 14:30"
String formatDateTime(DateTime d) =>
    '${d.day} ${_months[d.month - 1]}, ${_two(d.hour)}:${_two(d.minute)}';

/// "14 сен 2026"
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// "5 мин назад", "3 ч назад", "2 дн назад" относительно mockNow
String timeAgo(DateTime d) {
  final diff = mockNow.difference(d);
  if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
  if (diff.inHours < 24) return '${diff.inHours} ч назад';
  return '${diff.inDays} дн назад';
}
