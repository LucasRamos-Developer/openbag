import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

/// Formatter para CNPJ no formato ##.###.###/####-00
/// Os 12 primeiros caracteres são alfanuméricos, os 2 últimos são dígitos
class CNPJFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final buffer = StringBuffer();
    int nonMaskCount = 0;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];

      // Ignora caracteres de formatação
      if (char == '.' || char == '-' || char == '/') {
        continue;
      }

      // Primeiros 12 caracteres: alfanuméricos
      if (nonMaskCount < 12) {
        if (RegExp(r'[a-zA-Z0-9]').hasMatch(char)) {
          if (nonMaskCount == 2 || nonMaskCount == 5) {
            buffer.write('.');
          } else if (nonMaskCount == 8) {
            buffer.write('/');
          }
          buffer.write(char.toUpperCase());
          nonMaskCount++;
        }
      }
      // Últimos 2 caracteres: apenas dígitos
      else if (nonMaskCount < 14) {
        if (RegExp(r'[0-9]').hasMatch(char)) {
          if (nonMaskCount == 12) {
            buffer.write('-');
          }
          buffer.write(char);
          nonMaskCount++;
        }
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatter para telefone brasileiro: +55 (XX) XXXXX-XXXX
final phoneFormatter = MaskTextInputFormatter(
  mask: '+55 (##) #####-####',
  filter: {"#": RegExp(r'[0-9]')},
  type: MaskAutoCompletionType.lazy,
);

/// Formatter para telefone brasileiro alternativo: (XX) XXXXX-XXXX
final phoneFormatterShort = MaskTextInputFormatter(
  mask: '(##) #####-####',
  filter: {"#": RegExp(r'[0-9]')},
  type: MaskAutoCompletionType.lazy,
);

/// Formatter para CEP: XXXXX-XXX
final cepFormatter = MaskTextInputFormatter(
  mask: '#####-###',
  filter: {"#": RegExp(r'[0-9]')},
  type: MaskAutoCompletionType.lazy,
);

/// Formatter para valores monetários (R$ 0,00)
class MoneyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove tudo que não é dígito
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '0,00');
    }

    // Converte para double (centavos)
    final value = int.parse(digitsOnly);
    final formattedValue = (value / 100).toStringAsFixed(2).replaceAll('.', ',');

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}

/// Formatter para números inteiros positivos
class IntegerFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove tudo que não é dígito
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Remove zeros à esquerda
    final parsed = int.tryParse(digitsOnly);
    if (parsed == null) {
      return oldValue;
    }

    final formatted = parsed.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
