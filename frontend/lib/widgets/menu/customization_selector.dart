import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/menu/menu.dart';
import '../../utils/formatters.dart';

/// Escolha de opções de um grupo de complementos pelo cliente.
/// Escolha única vira rádio; múltipla vira checkbox limitado ao máximo do grupo.
class CustomizationSelector extends StatelessWidget {
  final CustomizationGroup group;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  const CustomizationSelector({super.key, required this.group, required this.selected, required this.onChanged});

  bool get satisfied => selected.length >= group.minSelections;

  void _toggle(int optionId) {
    final next = Set<int>.of(selected);
    if (group.maxSelections == 1) {
      next
        ..clear()
        ..add(optionId);
    } else if (!next.remove(optionId) && next.length < group.maxSelections) {
      next.add(optionId);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final full = selected.length >= group.maxSelections;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: colorScheme.onSurface.withValues(alpha: 0.04),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    Text(group.ruleLabel, style: textTheme.bodySmall),
                  ],
                ),
              ),
              if (group.required)
                AppStatusChip(
                  label: satisfied ? 'Ok' : 'Obrigatório',
                  color: satisfied ? AppColors.successDark : AppColors.grey700,
                ),
            ],
          ),
        ),
        for (final option in group.options)
          AppChoiceTile(
            title: option.name,
            subtitle: !option.available
                ? 'Indisponível'
                : option.priceModifier > 0
                    ? '+ ${formatMoney(option.priceModifier)}'
                    : null,
            selected: selected.contains(option.id),
            multiple: group.maxSelections > 1,
            enabled: option.available && (selected.contains(option.id) || !full || group.maxSelections == 1),
            onTap: () => _toggle(option.id!),
          ),
      ],
    );
  }
}
