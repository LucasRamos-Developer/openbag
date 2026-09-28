import 'package:flutter/material.dart';
import '../../utils/formatters.dart';

/// Resumo de valores do pedido: subtotal, taxa de entrega e total
class PriceSummary extends StatelessWidget {
  final double subtotal;

  /// Nula na retirada na loja: a linha da taxa não aparece
  final double? deliveryFee;
  final double total;

  /// A taxa ainda depende do endereço: mostra "a partir de" e o total como mínimo
  final bool deliveryFeeFrom;

  /// Distância usada no cálculo da taxa, quando ela é por distância
  final double? deliveryDistanceKm;

  /// Mostra "Calculando…" no lugar da taxa (consulta em andamento)
  final bool calculating;

  const PriceSummary({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.deliveryFeeFrom = false,
    this.deliveryDistanceKm,
    this.calculating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row('Subtotal', formatMoney(subtotal)),
        if (deliveryFee != null)
          _row(
            deliveryDistanceKm != null
                ? 'Taxa de entrega (${formatDistance(deliveryDistanceKm!)})'
                : 'Taxa de entrega',
            calculating ? 'Calculando…' : formatDeliveryFee(deliveryFee!, byDistance: deliveryFeeFrom),
          ),
        const Divider(height: 24),
        _row('Total', deliveryFeeFrom ? 'a partir de ${formatMoney(total)}' : formatMoney(total), bold: true),
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
