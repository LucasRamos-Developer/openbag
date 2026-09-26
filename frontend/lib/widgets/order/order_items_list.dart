import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/order/order.dart';
import '../../utils/formatters.dart';

/// Itens do pedido com complementos e observações.
/// [large] aumenta a fonte para a tela da cozinha; [showPrices] esconde valores (cozinha).
class OrderItemsList extends StatelessWidget {
  final List<OrderLine> items;
  final bool large;
  final bool showPrices;

  const OrderItemsList({super.key, required this.items, this.large = false, this.showPrices = true});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    final base = large ? 18.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in items)
          Padding(
            padding: EdgeInsets.symmetric(vertical: large ? 6 : 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${line.quantity}x  ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: base)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.name, style: TextStyle(fontSize: base, fontWeight: large ? FontWeight.w600 : null)),
                      for (final c in line.customizations)
                        Text('${c.groupName}: ${c.optionName}', style: TextStyle(color: muted, fontSize: base - 2)),
                      if (line.notes != null)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warningLighter.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Obs.: ${line.notes}',
                              style: TextStyle(fontSize: base - 2, fontWeight: FontWeight.w600, color: AppColors.warningDarker)),
                        ),
                    ],
                  ),
                ),
                if (showPrices) Text(formatMoney(line.totalPrice), style: TextStyle(fontSize: base)),
              ],
            ),
          ),
      ],
    );
  }
}
