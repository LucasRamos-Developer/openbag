import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';
import 'app_select.dart';

/// Faixa horizontal rolável de chips de filtro com seleção única.
/// Itens com [SelectItem.icon] mostram o ícone; o ativo fica preenchido com ✓.
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
  final double height;

  const AppFilterChips({
    super.key,
    required this.items,
    required this.value,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          // Com ícone, o chip ativo troca o ícone por ✓ (padrão visual do cardápio)
          final selected = item.value == value;
          final colors = context.appColors;
          return ChoiceChip(
            avatar: item.icon == null
                ? null
                : Icon(selected ? Icons.check : item.icon, size: 20, color: selected ? colors.onAction : colors.primaryText),
            showCheckmark: item.icon == null,
            label: Text(item.label),
            selected: selected,
            onSelected: (_) => onSelected(item.value),
          );
        },
      ),
    );
  }
}
