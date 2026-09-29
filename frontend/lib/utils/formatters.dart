import 'package:intl/intl.dart';
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

/// Formatter para CPF: XXX.XXX.XXX-XX
final cpfFormatter = MaskTextInputFormatter(
  mask: '###.###.###-##',
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

/// Telefone brasileiro fixo ou celular: (XX) XXXX-XXXX com até 10 dígitos, (XX) XXXXX-XXXX com 11
class PhoneFormatter extends TextInputFormatter {
  static String format(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    final d = digits.length > 11 ? digits.substring(0, 11) : digits;
    if (d.isEmpty) return '';
    if (d.length <= 2) return '($d';
    final split = d.length == 11 ? 7 : 6;
    if (d.length <= split) return '(${d.substring(0, 2)}) ${d.substring(2)}';
    return '(${d.substring(0, 2)}) ${d.substring(2, split)}-${d.substring(split)}';
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final formatted = format(newValue.text);
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
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

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// Data no formato dd/MM/aaaa ('-' se nula)
/// Data no formato da API (yyyy-MM-dd), no dia local
String apiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';

String formatDate(DateTime? date) {
  if (date == null) return '-';
  return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
}

/// Hora no formato HH:mm ('-' se nula)
String formatTime(DateTime? date) {
  if (date == null) return '-';
  return '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
}

/// Data e hora no formato dd/MM/aaaa HH:mm ('-' se nula)
String formatDateTime(DateTime? date) {
  if (date == null) return '-';
  return '${formatDate(date)} ${formatTime(date)}';
}

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

/// Valor em reais: R$ 12,90
String formatMoney(num value) => _currency.format(value);

final _count = NumberFormat.decimalPattern('pt_BR');

/// Número inteiro com separador de milhar (1.245)
String formatCount(num value) => _count.format(value);

/// Lê o texto de um campo com [MoneyFormatter] ("12,90") como número; null se vazio
double? parseMoney(String text) {
  final normalized = text.trim().replaceAll('.', '').replaceAll(',', '.');
  return normalized.isEmpty ? null : double.tryParse(normalized);
}

/// Valor para preencher um campo com [MoneyFormatter] ("12,90")
String moneyInput(num value) => value.toStringAsFixed(2).replaceAll('.', ',');

/// Taxa de entrega para o cliente: "Grátis", "R\$ 8,00" ou, se depende da distância, "a partir de R\$ 10,00"
String formatDeliveryFee(double fee, {bool byDistance = false}) {
  if (byDistance) return 'a partir de ${formatMoney(fee)}';
  return fee > 0 ? formatMoney(fee) : 'Grátis';
}

/// Distância com uma casa decimal: "8,0 km"
String formatDistance(double km) => '${km.toStringAsFixed(1).replaceAll('.', ',')} km';

/// Percentual sem zeros à toa: "5%", "2,5%"
String formatPercent(num value) {
  // Só tira os zeros depois da vírgula ("10.00" vira "10", "2.50" vira "2,5")
  final text = value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  return '${text.replaceAll('.', ',')}%';
}

const _monthNames = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];

/// "setembro de 2026"
String formatMonth(DateTime month) => '${_monthNames[month.month - 1]} de ${month.year}';

/// "set/26" (rótulos curtos de gráfico)
String formatMonthShort(DateTime month) =>
    '${_monthNames[month.month - 1].substring(0, 3)}/${(month.year % 100).toString().padLeft(2, '0')}';

/// "2026-09" (parâmetro de mês da API)
String apiMonth(DateTime month) => '${month.year}-${month.month.toString().padLeft(2, '0')}';
