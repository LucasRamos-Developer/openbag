import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';
import 'app_adaptive_sheet.dart';
import 'app_select.dart';

/// Filtro compacto em forma de chip ("Veículo: Moto ▾"). Ao tocar, abre as opções com
/// [showAppActionSheet]: menu de baixo para cima no celular, menu suspenso no desktop.
///
/// O chip fica destacado quando o valor escolhido é diferente de [emptyValue] (o "Todos").
class AppDropdownChip<T> extends StatelessWidget {
  final String label;
  final List<SelectItem<T>> items;
  final T value;
  final ValueChanged<T> onSelected;

  /// Valor que representa "sem filtro" (normalmente null)
  final T? emptyValue;

  const AppDropdownChip({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onSelected,
    this.emptyValue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final active = value != emptyValue;
    final current = items.where((item) => item.value == value).firstOrNull;

    return Builder(
      builder: (chipContext) => InputChip(
        avatar: current?.icon != null && active ? Icon(current!.icon, size: 18, color: colors.onAction) : null,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(active && current != null ? '$label: ${current.label}' : label),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 20, color: active ? colors.onAction : colors.textMuted),
          ],
        ),
        selected: active,
        showCheckmark: false,
        onPressed: () async {
          final chosen = await showAppActionSheet<_Choice<T>>(
            chipContext,
            title: label,
            actions: [
              for (final item in items)
                AppSheetAction(
                  value: _Choice(item.value),
                  label: item.label,
                  icon: item.icon,
                  selected: item.value == value,
                ),
            ],
          );
          if (chosen != null) onSelected(chosen.value);
        },
      ),
    );
  }
}

/// Embrulha o valor para distinguir "escolheu null (Todos)" de "fechou sem escolher"
class _Choice<T> {
  final T value;
  const _Choice(this.value);
}
