import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../core/ui/ui.dart';
import '../models/restaurant.dart';
import '../utils/formatters.dart';
import 'restaurant/restaurant_logo.dart';

/// Card de restaurante nas listas da vitrine
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;

  const RestaurantCard({super.key, required this.restaurant, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurface.withValues(alpha: 0.6);
    final banner = Container(color: colorScheme.primary.withValues(alpha: 0.12));

    return Opacity(
      opacity: restaurant.openNow ? 1 : 0.6,
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.zero,
        borderColor: colorScheme.outline.withValues(alpha: 0.15),
        borderWidth: 1,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 3,
                child: restaurant.bannerUrl != null
                    ? Image.network(AppConstants.fileUrl(restaurant.bannerUrl!), fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => banner)
                    : banner,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  RestaurantLogo(logoUrl: restaurant.logoUrl, name: restaurant.name, size: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(restaurant.name,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        if (restaurant.categories.isNotEmpty)
                          Text(restaurant.categories.join(' · '), style: TextStyle(color: muted, fontSize: 13)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                              const SizedBox(width: 2),
                              Text(restaurant.totalReviews > 0 ? restaurant.formattedRating : 'Novo',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ]),
                            Text(restaurant.deliveryTimeRange, style: TextStyle(color: muted, fontSize: 13)),
                            Text(
                              restaurant.deliveryFee > 0 ? 'Entrega ${formatMoney(restaurant.deliveryFee)}' : 'Entrega grátis',
                              style: TextStyle(
                                color: restaurant.deliveryFee > 0 ? muted : AppColors.successDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!restaurant.openNow) const AppStatusChip(label: 'Fechado', color: AppColors.grey700),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
