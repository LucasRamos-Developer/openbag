import 'package:flutter/material.dart';

/// Seletor de quantidade: [−] 2 [+]
class AppQuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  /// Com [min] 0, o botão de menos vira lixeira quando o valor é 1
  final bool showRemoveIcon;

  const AppQuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 50,
    this.showRemoveIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final atMin = value <= min;
    final removes = showRemoveIcon && value == 1;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: removes ? 'Remover' : 'Diminuir',
            icon: Icon(removes ? Icons.delete_outline : Icons.remove, size: 20),
            color: colorScheme.primary,
            onPressed: atMin && !removes ? null : () => onChanged(value - 1),
          ),
          SizedBox(
            width: 28,
            child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Aumentar',
            icon: const Icon(Icons.add, size: 20),
            color: colorScheme.primary,
            onPressed: value >= max ? null : () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}
