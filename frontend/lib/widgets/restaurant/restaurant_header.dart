import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../core/ui/ui.dart';
import '../../models/restaurant.dart';
import '../../utils/formatters.dart';
import 'restaurant_logo.dart';

/// Topo da página do restaurante: banner com slogan + card de informações sobreposto
class RestaurantHeader extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onBack;
  final VoidCallback? onAbout;

  /// Altura da barra de navegação transparente que fica sobre o banner
  final double topInset;

  const RestaurantHeader({super.key, required this.restaurant, this.onBack, this.onAbout, this.topInset = 0});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 600;
      final bannerHeight = compact ? 190.0 : 210.0;
      final overlap = compact ? 24.0 : 28.0;
      final gutter = compact ? 12.0 : 24.0;

      return Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppHeroBanner(
              title: restaurant.name,
              subtitle: restaurant.slogan,
              image: restaurant.bannerUrl != null ? NetworkImage(AppConstants.fileUrl(restaurant.bannerUrl!)) : null,
              onBack: onBack,
              height: bannerHeight,
              bottomInset: overlap,
              topInset: topInset,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, topInset + bannerHeight, gutter, 0),
            child: RestaurantInfoCard(restaurant: restaurant, onAbout: onAbout, compact: compact),
          ),
        ],
      );
    });
  }
}

/// Card com logo, nome, categoria, status, prazo, taxa, mínimo e avaliação
class RestaurantInfoCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onAbout;
  final bool compact;

  const RestaurantInfoCard({super.key, required this.restaurant, this.onAbout, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final category = [
      if (restaurant.categories.isNotEmpty) restaurant.categories.join(', '),
      if (restaurant.priceRange != null) restaurant.priceRange!,
    ].join(' · ');

    final status = restaurant.openNow ? 'Aberto agora' : (restaurant.paused ? 'Pausado' : 'Fechado');
    final statusColor = restaurant.openNow ? c.success : c.danger;

    final meta = AppMetaRow(separators: !compact, children: [
      _StatusPill(label: status, color: statusColor),
      AppMetaItem(icon: Icons.schedule, label: restaurant.deliveryTimeRange),
      AppMetaItem(
        icon: Icons.pedal_bike_outlined,
        label: restaurant.deliveryFee > 0 ? 'Entrega ${formatMoney(restaurant.deliveryFee)}' : 'Entrega grátis',
      ),
      if (restaurant.minimumOrder > 0)
        AppMetaItem(icon: Icons.shopping_bag_outlined, label: 'Mínimo ${formatMoney(restaurant.minimumOrder)}'),
    ]);

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RestaurantLogo(logoUrl: restaurant.logoUrl, name: restaurant.name, size: compact ? 64 : 96),
              SizedBox(width: compact ? 14 : 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: (compact ? textTheme.titleLarge : textTheme.headlineMedium)
                          ?.copyWith(fontWeight: FontWeight.w800, color: c.text),
                    ),
                    if (category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      AppMetaItem(icon: Icons.storefront_outlined, label: category),
                    ],
                    if (compact) ...[const SizedBox(height: 6), _Rating(restaurant: restaurant, inline: true)],
                    if (!compact) ...[const SizedBox(height: 14), meta],
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Rating(restaurant: restaurant),
                    if (onAbout != null) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(onPressed: onAbout, icon: const Icon(Icons.info_outline, size: 18), label: const Text('Sobre')),
                    ],
                  ],
                ),
              ],
            ],
          ),
          if (compact) ...[
            const SizedBox(height: 14),
            meta,
            if (onAbout != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onAbout,
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Sobre o restaurante'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final background = Color.alphaBlend(color.withValues(alpha: 0.12), context.appColors.surface);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

class _Rating extends StatelessWidget {
  final Restaurant restaurant;
  final bool inline;

  const _Rating({required this.restaurant, this.inline = false});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    if (restaurant.totalReviews == 0) {
      return AppBadge(label: 'Novo no OpenBag', icon: Icons.auto_awesome_outlined, tone: BadgeTone.accent);
    }
    final score = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: c.rating, size: inline ? 20 : 26),
        const SizedBox(width: 4),
        Text(
          restaurant.formattedRating,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: inline ? 15 : 20, color: c.text),
        ),
      ],
    );
    final count = Text(
      '(${formatCount(restaurant.totalReviews)} ${restaurant.totalReviews == 1 ? 'avaliação' : 'avaliações'})',
      style: TextStyle(color: c.textMuted, fontSize: 13),
    );
    return inline
        ? Row(mainAxisSize: MainAxisSize.min, children: [score, const SizedBox(width: 6), count])
        : Column(crossAxisAlignment: CrossAxisAlignment.end, children: [score, const SizedBox(height: 2), count]);
  }
}
