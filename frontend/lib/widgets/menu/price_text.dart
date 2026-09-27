import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../utils/formatters.dart';

/// Preço do item; em promoção mostra o preço antigo riscado, menor, à esquerda do preço atual
class PriceText extends StatelessWidget {
  final double price;
  final double? promotionalPrice;
  final TextStyle? style;

  /// Tamanho do preço antigo em relação ao atual
  static const double oldPriceScale = 0.72;

  const PriceText({super.key, required this.price, this.promotionalPrice, this.style});

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w600);
    final onPromotion = promotionalPrice != null && promotionalPrice! < price;

    if (!onPromotion) {
      return Text(formatMoney(price), style: baseStyle);
    }
    final muted = context.appColors.textMuted;
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          formatMoney(price),
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: (baseStyle.fontSize ?? 14) * oldPriceScale,
            color: muted,
            decoration: TextDecoration.lineThrough,
            decorationColor: muted,
          ),
        ),
        Text(formatMoney(promotionalPrice!), style: baseStyle.copyWith(color: context.appColors.primaryText)),
      ],
    );
  }
}
