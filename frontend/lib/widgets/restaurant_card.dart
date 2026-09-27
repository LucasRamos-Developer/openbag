import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../core/ui/ui.dart';
import '../models/restaurant.dart';
import '../utils/formatters.dart';
import 'restaurant/restaurant_logo.dart';

/// Card em caixa da vitrine: imagem de destaque, logo sobreposto, nome, categorias,
/// nota, prazo e taxa de entrega. Loja fechada fica esmaecida com o selo "Fechado".
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;

  const RestaurantCard({super.key, required this.restaurant, this.onTap});

  static const double _logoSize = 52;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [c.primary.withValues(alpha: 0.18), c.surfaceAlt])),
      child: Center(child: Icon(Icons.storefront_outlined, size: 40, color: c.primaryText.withValues(alpha: 0.5))),
    );
    final closedLabel = restaurant.paused ? 'Pausado' : 'Fechado';

    return AppCard(
      padding: EdgeInsets.zero,
      backgroundColor: c.surface,
      borderColor: c.border,
      borderWidth: 1,
      onTap: onTap,
      child: Opacity(
        opacity: restaurant.openNow ? 1 : 0.62,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: restaurant.bannerUrl != null
                        ? Image.network(
                            AppConstants.fileUrl(restaurant.bannerUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => placeholder,
                          )
                        : placeholder,
                  ),
                ),
                if (!restaurant.openNow)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(closedLabel,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                Positioned(
                  left: 14,
                  bottom: -_logoSize / 2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: c.surface,
                      shape: BoxShape.circle,
                      boxShadow: c.cardShadow,
                    ),
                    child: RestaurantLogo(logoUrl: restaurant.logoUrl, name: restaurant.name, size: _logoSize),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, _logoSize / 2 + 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    restaurant.categories.isEmpty ? ' ' : restaurant.categories.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.star_rounded, color: c.rating, size: 17),
                      const SizedBox(width: 3),
                      Text(
                        restaurant.totalReviews > 0 ? restaurant.formattedRating : 'Novo',
                        style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 12),
                      Flexible(child: _Meta(icon: Icons.schedule_rounded, label: restaurant.deliveryTimeRange)),
                      const SizedBox(width: 12),
                      Flexible(
                        child: restaurant.deliveryFee > 0
                            ? _Meta(icon: Icons.pedal_bike_outlined, label: formatMoney(restaurant.deliveryFee))
                            : _Meta(icon: Icons.pedal_bike_outlined, label: 'Grátis', color: c.success),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ícone + texto curto da linha de informações do card
class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _Meta({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? context.appColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: foreground),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 12.5,
              fontWeight: color == null ? FontWeight.w500 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Esqueleto do [RestaurantCard] enquanto a vitrine carrega
class RestaurantCardSkeleton extends StatelessWidget {
  const RestaurantCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      borderColor: context.appColors.border,
      borderWidth: 1,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(aspectRatio: 16 / 9, child: AppSkeleton(radius: 16)),
          Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12),
                AppSkeleton(width: 140, height: 16),
                SizedBox(height: 8),
                AppSkeleton(width: 90, height: 12),
                SizedBox(height: 12),
                AppSkeleton(width: 180, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
