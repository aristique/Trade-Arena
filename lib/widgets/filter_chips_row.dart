import 'package:flutter/material.dart';

/// Горизонтальный ряд чипов-фильтров. На L2 выбор не меняется —
/// выделен чип с индексом [selectedIndex].
class FilterChipsRow extends StatelessWidget {
  const FilterChipsRow({
    super.key,
    required this.labels,
    this.selectedIndex = 0,
  });

  final List<String> labels;
  final int selectedIndex;

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
          onSelected: (_) {}, // фильтрация появится в следующих лабораторных
        ),
      ),
    );
  }
}
