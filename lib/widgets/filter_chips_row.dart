import 'package:flutter/material.dart';

/// Горизонтальный ряд чипов-фильтров.
/// Выделен чип [selectedIndex], нажатие сообщает индекс через [onSelected].
class FilterChipsRow extends StatelessWidget {
  const FilterChipsRow({
    super.key,
    required this.labels,
    this.selectedIndex = 0,
    this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: labels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) => ChoiceChip(
          label: Text(labels[index]),
          selected: index == selectedIndex,
          onSelected: (_) => onSelected?.call(index),
        ),
      ),
    );
  }
}
