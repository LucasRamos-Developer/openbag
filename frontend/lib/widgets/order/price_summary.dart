import 'package:flutter/material.dart';
import '../../utils/formatters.dart';

/// Resumo de valores do pedido: subtotal, taxa de entrega e total
class PriceSummary extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double total;

  const PriceSummary({super.key, required this.subtotal, required this.deliveryFee, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row('Subtotal', formatMoney(subtotal)),
        _row('Taxa de entrega', deliveryFee == 0 ? 'Grátis' : formatMoney(deliveryFee)),
        const Divider(height: 24),
        _row('Total', formatMoney(total), bold: true),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.normal, fontSize: bold ? 17 : 15);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [Expanded(child: Text(label, style: style)), Text(value, style: style)]),
    );
  }
}
