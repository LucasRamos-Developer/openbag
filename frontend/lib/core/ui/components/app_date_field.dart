import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';

/// Campo de data que abre o seletor nativo (calendário no celular). Sem digitação, sem máscara.
class AppDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;

  /// Permite limpar a data (ex: "sem validade")
  final bool clearable;
  final String? hint;

  AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    this.clearable = false,
    this.hint,
  })  : firstDate = firstDate ?? DateTime(2020),
        lastDate = lastDate ?? DateTime(2100);

  static String _two(int v) => v.toString().padLeft(2, '0');

  Future<void> _pick(BuildContext context) async {
    final initial = value ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : (initial.isAfter(lastDate) ? lastDate : initial),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: label,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = value == null ? (hint ?? 'Escolher data') : '${_two(value!.day)}/${_two(value!.month)}/${value!.year}';
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: clearable && value != null
              ? IconButton(tooltip: 'Limpar', icon: const Icon(Icons.close), onPressed: () => onChanged(null))
              : null,
        ),
        child: Text(text, style: TextStyle(color: value == null ? colors.textMuted : colors.text)),
      ),
    );
  }
}
