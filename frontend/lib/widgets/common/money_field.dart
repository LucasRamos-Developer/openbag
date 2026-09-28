import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../utils/formatters.dart';

/// Campo de valor em reais: teclado numérico, máscara "1.234,56" e validação opcional de obrigatório
class MoneyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? helperText;
  final bool required;
  final bool enabled;

  const MoneyField({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
    this.required = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      labelText: label,
      helperText: helperText,
      prefixText: 'R\$ ',
      variant: TextFieldVariant.filled,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [MoneyFormatter()],
      validator: required ? (v) => (parseMoney(v ?? '') ?? 0) <= 0 ? 'Informe o valor' : null : null,
    );
  }
}
