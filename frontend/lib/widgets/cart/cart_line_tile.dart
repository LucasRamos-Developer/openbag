import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../services/cart_service.dart';
import '../../utils/formatters.dart';
import '../menu/menu_image.dart';

/// Linha de um pedido em montagem: foto, nome, complementos, observação, valor e quantidade.
/// Quantidade 0 (lixeira) remove a linha. Usada no carrinho do cliente e no pedido do balcão.
class CartLineTile extends StatelessWidget {
  final CartLine line;
  final ValueChanged<int> onQuantityChanged;

  /// Esconde a foto (listas compactas)
  final bool showImage;

  const CartLineTile({super.key, required this.line, required this.onQuantityChanged, this.showImage = true});

  @override
  Widget build(BuildContext context) {
    final muted = context.appColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showImage) ...[
            MenuImage(imageUrl: line.imageUrl, size: 56),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (line.options.isNotEmpty) Text(line.optionsSummary, style: TextStyle(color: muted, fontSize: 13)),
                if (line.notes != null) Text('Obs.: ${line.notes}', style: TextStyle(color: muted, fontSize: 13)),
                const SizedBox(height: 6),
                Text(formatMoney(line.totalPrice), style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          AppQuantityStepper(
            value: line.quantity,
            min: 0,
            showRemoveIcon: true,
            onChanged: onQuantityChanged,
          ),
        ],
      ),
    );
  }
}
