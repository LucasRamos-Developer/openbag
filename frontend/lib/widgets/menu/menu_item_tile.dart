import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import 'menu_image.dart';
import 'price_text.dart';

/// Linha de item do cardápio: foto, nome, descrição, preço e selos.
/// Usada no painel do dono (com um controle no [trailing]) e na página do restaurante.
class MenuItemTile extends StatelessWidget {
  final String name;
  final String? description;
  final double price;
  final double? promotionalPrice;
  final String? imageUrl;
  final bool available;
  final bool active;

  /// Texto extra abaixo da descrição (ex: itens do combo, "2 grupos de complementos")
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const MenuItemTile({
    super.key,
    required this.name,
    this.description,
    required this.price,
    this.promotionalPrice,
    this.imageUrl,
    this.available = true,
    this.active = true,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final muted = colorScheme.onSurface.withValues(alpha: 0.6);
    final dimmed = !available || !active;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Opacity(
          opacity: dimmed ? 0.55 : 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(name, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        if (!active) const AppStatusChip(label: 'Oculto', color: AppColors.grey600),
                        if (active && !available) const AppStatusChip(label: 'Esgotado', color: AppColors.errorDark),
                      ],
                    ),
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(description!,
                          maxLines: 2, overflow: TextOverflow.ellipsis, style: textTheme.bodySmall?.copyWith(color: muted)),
                    ],
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: textTheme.bodySmall?.copyWith(color: muted)),
                    ],
                    const SizedBox(height: 6),
                    PriceText(price: price, promotionalPrice: promotionalPrice),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              MenuImage(imageUrl: imageUrl),
              if (trailing != null) ...[const SizedBox(width: 4), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
