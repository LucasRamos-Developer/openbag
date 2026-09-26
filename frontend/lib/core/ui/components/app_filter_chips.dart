import 'package:flutter/material.dart';
import 'app_select.dart';

/// Faixa horizontal rolável de chips de filtro com seleção única
///
/// Reaproveita [SelectItem]; o valor pode ser anulável para representar "Todos":
/// ```dart
/// AppFilterChips<Status?>(
///   items: const [SelectItem(value: null, label: 'Todos'), SelectItem(value: Status.ACTIVE, label: 'Ativos')],
///   value: _filter,
///   onSelected: (value) => setState(() => _filter = value),
/// )
/// ```
class AppFilterChips<T> extends StatelessWidget {
  final List<SelectItem<T>> items;
  final T value;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  const AppFilterChips({
    super.key,
    required this.items,
    required this.value,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return ChoiceChip(
            label: Text(item.label),
            selected: item.value == value,
            onSelected: (_) => onSelected(item.value),
          );
        },
      ),
    );
  }
}
