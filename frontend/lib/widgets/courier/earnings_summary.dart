import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/courier/courier_earnings.dart';
import '../../utils/formatters.dart';

/// Ganhos de hoje, da semana e do mês lado a lado, com as entregas e os km rodados
class EarningsSummary extends StatelessWidget {
  final CourierEarnings earnings;

  const EarningsSummary({super.key, required this.earnings});

  @override
  Widget build(BuildContext context) {
    // Sempre lado a lado: no celular os três cabem compactos e o gráfico fica visível
    return Row(
      children: [
        Expanded(child: _Tile(label: 'Hoje', total: earnings.today)),
        const SizedBox(width: 8),
        Expanded(child: _Tile(label: 'Semana', total: earnings.week)),
        const SizedBox(width: 8),
        Expanded(child: _Tile(label: 'Mês', total: earnings.month)),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final EarningsTotal total;

  const _Tile({required this.label, required this.total});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodySmall),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(formatMoney(total.amount), style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Text('${total.deliveries} ${total.deliveries == 1 ? 'entrega' : 'entregas'}', style: textTheme.bodySmall),
          Text(formatKm(total.distanceKm), style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
