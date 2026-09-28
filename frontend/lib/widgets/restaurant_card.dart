import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../core/ui/ui.dart';
import '../models/restaurant.dart';
import '../utils/formatters.dart';
import 'restaurant/open_in_maps_button.dart';
import 'restaurant/restaurant_hours_label.dart';
import 'restaurant/restaurant_logo.dart';
import 'restaurant/restaurant_theme_scope.dart';

/// Card em caixa da vitrine: imagem de destaque, logo sobreposto, nome e nota, situação com horário
/// ("Aberto · fecha às 23:00"), endereço com botão para abrir no app de mapas e a linha de
/// entrega (prazo, taxa e pedido mínimo). Loja fechada tem a imagem esmaecida com o selo.
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;

  const RestaurantCard({super.key, required this.restaurant, this.onTap});

  static const double _logoSize = 52;

  /// Cores da loja só no logo e no fundo sem foto; o resto do card segue o tema da vitrine
  Widget _brandTheme(Widget child) =>
      RestaurantThemeScope(themePreset: restaurant.themePreset, brandColor: restaurant.brandColor, child: child);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    // Sem foto: o mesmo fundo do banner da página da loja, na cor que ela escolheu
    final placeholder = _brandTheme(const AppBrandBackdrop(gap: 18));
    final closedLabel = restaurant.paused ? 'Pausado' : 'Fechado';
    final address = restaurant.address;

    return AppCard(
      padding: EdgeInsets.zero,
      backgroundColor: c.surface,
      borderColor: c.border,
      borderWidth: 1,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Opacity(
                  opacity: restaurant.openNow ? 1 : 0.55,
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
                // Moldura branca com o mesmo formato do logo (quadrado arredondado)
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(_logoSize * 0.25 + 3),
                    boxShadow: c.cardShadow,
                  ),
                  child: _brandTheme(RestaurantLogo(logoUrl: restaurant.logoUrl, name: restaurant.name, size: _logoSize)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, _logoSize / 2 + 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.star_rounded, color: c.rating, size: 17),
                    const SizedBox(width: 3),
                    Text(
                      restaurant.totalReviews > 0 ? restaurant.formattedRating : 'Novo',
                      style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                RestaurantHoursLabel(restaurant: restaurant),
                const SizedBox(height: 10),
                // Endereço sempre em duas linhas: os cards da mesma linha da grade ficam do mesmo tamanho
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: c.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address == null || address.streetLine.isEmpty ? 'Endereço não informado' : address.streetLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            address == null || address.areaLine.isEmpty ? ' ' : address.areaLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: c.textMuted, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    if (address != null) ...[
                      const SizedBox(width: 8),
                      OpenInMapsButton(address: address, label: restaurant.name),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, thickness: 1, color: c.border),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(flex: 3, child: _Info(label: 'Entrega', value: restaurant.deliveryTimeRange)),
                    // Com "Taxa a partir de" (o rótulo mais longo) a coluna da taxa ganha mais espaço
                    Expanded(
                      flex: restaurant.deliveryFeeByDistance ? 4 : 3,
                      child: restaurant.deliveryFeeByDistance
                          ? _Info(label: 'Taxa a partir de', value: formatMoney(restaurant.deliveryFee))
                          : restaurant.deliveryFee > 0
                              ? _Info(label: 'Taxa', value: formatMoney(restaurant.deliveryFee))
                              : _Info(label: 'Taxa', value: 'Grátis', color: c.success),
                    ),
                    Expanded(
                      flex: 3,
                      child: _Info(
                        label: 'Mínimo',
                        value: restaurant.minimumOrder > 0 ? formatMoney(restaurant.minimumOrder) : 'Sem mínimo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rótulo pequeno e valor da linha de entrega do card
class _Info extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _Info({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: c.textMuted, fontSize: 11.5)),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color ?? c.text, fontSize: 13, fontWeight: FontWeight.w700),
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
                SizedBox(height: 12),
                AppSkeleton(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
