import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../utils/formatters.dart';

/// Preço do item; em promoção mostra o preço antigo riscado ao lado do atual
class PriceText extends StatelessWidget {
  final double price;
  final double? promotionalPrice;
  final TextStyle? style;

  const PriceText({super.key, required this.price, this.promotionalPrice, this.style});

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600);
    final onPromotion = promotionalPrice != null && promotionalPrice! < price;

    if (!onPromotion) {
      return Text(formatMoney(price), style: baseStyle);
    }
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(formatMoney(promotionalPrice!), style: baseStyle.copyWith(color: AppColors.successDark)),
        Text(
          formatMoney(price),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.normal,
            fontSize: (baseStyle.fontSize ?? 14) * 0.85,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            decoration: TextDecoration.lineThrough,
          ),
        ),
      ],
    );
  }
}
