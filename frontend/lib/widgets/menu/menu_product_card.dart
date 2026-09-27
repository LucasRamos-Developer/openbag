import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import 'menu_image.dart';
import 'price_text.dart';

/// Card de produto do cardápio público (padrão layout/restaurante-padrão.png):
/// foto, nome, descrição, selos, preço (com o antigo riscado) e botão de adicionar.
/// No celular, o preço e o botão descem para uma linha própria.
class MenuProductCard extends StatelessWidget {
  final String name;
  final String? description;
  final String? imageUrl;
  final double price;
  final double? promotionalPrice;
  final List<String> badges;
  final bool isCombo;
  final bool available;
  final VoidCallback onTap;

  /// Adicionar direto; null esconde o botão (ex: loja fechada ou item esgotado)
  final VoidCallback? onAdd;

  const MenuProductCard({
    super.key,
    required this.name,
    this.description,
    this.imageUrl,
    required this.price,
    this.promotionalPrice,
    this.badges = const [],
    this.isCombo = false,
    this.available = true,
    required this.onTap,
    this.onAdd,
  });

  bool get _onPromotion => promotionalPrice != null && promotionalPrice! < price;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 600;
      return Opacity(
        opacity: available ? 1 : 0.6,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: c.border),
                boxShadow: c.cardShadow,
              ),
              padding: const EdgeInsets.all(12),
              child: compact ? _compact(context) : _wide(context),
            ),
          ),
        ),
      );
    });
  }

  Widget _wide(BuildContext context) => Row(
        children: [
          MenuImage(imageUrl: imageUrl, size: 132, height: 98),
          const SizedBox(width: 20),
          Expanded(child: _details(context, descriptionLines: 2)),
          const SizedBox(width: 16),
          _price(context, size: 22),
          if (onAdd != null) ...[const SizedBox(width: 28), _AddButton(name: name, onPressed: onAdd!, size: 56)],
          const SizedBox(width: 8),
        ],
      );

  Widget _compact(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MenuImage(imageUrl: imageUrl, size: 96),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _details(context, descriptionLines: 2),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _price(context, size: 18)),
                    if (onAdd != null) _AddButton(name: name, onPressed: onAdd!, size: 44),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  Widget _details(BuildContext context, {required int descriptionLines}) {
    final c = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final chips = [
      if (!available) const AppBadge(label: 'Esgotado', tone: BadgeTone.neutral),
      if (_onPromotion)
        AppBadge(
          label: '-${((1 - promotionalPrice! / price) * 100).round()}%',
          icon: Icons.local_fire_department_outlined,
          tone: BadgeTone.danger,
        ),
      if (isCombo) const AppBadge(label: 'Combo', icon: Icons.sell_outlined),
      for (final badge in badges) AppBadge(label: badge),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 17, color: c.text)),
        if (description != null && description!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            maxLines: descriptionLines,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(color: c.textMuted),
          ),
        ],
        if (chips.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: chips),
        ],
      ],
    );
  }

  Widget _price(BuildContext context, {required double size}) => PriceText(
        price: price,
        promotionalPrice: promotionalPrice,
        style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: context.appColors.primaryText),
      );
}

class _AddButton extends StatelessWidget {
  final String name;
  final VoidCallback onPressed;
  final double size;

  const _AddButton({required this.name, required this.onPressed, required this.size});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Tooltip(
      message: 'Adicionar $name',
      child: Material(
        color: c.action,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onPressed,
          child: SizedBox(
            width: size * 1.2,
            height: size,
            child: Icon(Icons.add_shopping_cart, color: c.onAction, size: size * 0.46),
          ),
        ),
      ),
    );
  }
}
