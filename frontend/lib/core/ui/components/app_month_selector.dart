import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';

/// Seletor compacto de mês: ‹ setembro de 2026 ›. Cabe no celular ao lado do título.
/// [label] formata o mês; [lastMonth] limita o avanço (ex: o mês atual).
class AppMonthSelector extends StatelessWidget {
  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final String Function(DateTime month) label;
  final DateTime? lastMonth;

  const AppMonthSelector({
    super.key,
    required this.month,
    required this.onChanged,
    required this.label,
    this.lastMonth,
  });

  static DateTime _shift(DateTime month, int delta) => DateTime(month.year, month.month + delta);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final canForward = lastMonth == null ||
        _shift(month, 1).isBefore(DateTime(lastMonth!.year, lastMonth!.month + 1));
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Mês anterior',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onChanged(_shift(month, -1)),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 132),
            child: Text(
              label(month),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Próximo mês',
            icon: const Icon(Icons.chevron_right),
            onPressed: canForward ? () => onChanged(_shift(month, 1)) : null,
          ),
        ],
      ),
    );
  }
}
