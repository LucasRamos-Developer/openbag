import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/courier/courier_work.dart';
import '../../utils/formatters.dart';

String _km(double? km) => km == null ? '–' : '${km.toStringAsFixed(1).replaceAll('.', ',')} km';

/// Oferta de entrega em destaque: valor, distâncias e contagem regressiva para aceitar
class OfferCard extends StatelessWidget {
  final CourierOffer offer;
  final Duration timeout;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const OfferCard({
    super.key,
    required this.offer,
    required this.onAccept,
    required this.onDecline,
    this.timeout = const Duration(seconds: 30),
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final expired = DateTime.now().isAfter(offer.expiresAt);

    return AppCard(
      padding: const EdgeInsets.all(20),
      borderColor: AppColors.primary,
      borderWidth: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(offer.isRoute ? 'Nova rota · ${offer.stops.length} entregas' : 'Nova entrega',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Text(formatMoney(offer.courierFee),
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
            ],
          ),
          const SizedBox(height: 12),
          AppCountdown(until: offer.expiresAt, total: timeout),
          const SizedBox(height: 16),
          _Stop(
            icon: Icons.storefront,
            title: offer.restaurant?.name ?? 'Restaurante',
            subtitle: [
              if (offer.restaurant?.address != null) offer.restaurant!.address!,
              if (offer.pickupDistanceKm != null) 'a ${_km(offer.pickupDistanceKm)} de você',
            ].join(' · '),
          ),
          const SizedBox(height: 12),
          if (offer.isRoute) ...[
            for (var i = 0; i < offer.stops.length; i++) ...[
              _Stop(
                icon: Icons.looks_one_outlined,
                number: i + 1,
                title: '${offer.stops[i].displayCode ?? 'Entrega'}${offer.stops[i].neighborhood != null ? ' · ${offer.stops[i].neighborhood}' : ''}',
                subtitle: [
                  offer.stops[i].deliveryAddress ?? '',
                  if (offer.stops[i].paymentMethod != null)
                    '${offer.stops[i].paymentMethod!.label}${offer.stops[i].totalAmount != null ? ' ${formatMoney(offer.stops[i].totalAmount!)}' : ''}',
                ].where((t) => t.isNotEmpty).join(' · '),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              '${offer.routeDistanceKm != null ? 'Rota de ${_km(offer.routeDistanceKm)} saindo do restaurante · ' : ''}'
              'valor cheio de cada entrega',
              style: textTheme.bodySmall,
            ),
          ] else
            _Stop(
              icon: Icons.location_on,
              title: 'Entrega · ${_km(offer.deliveryDistanceKm)} do restaurante',
              subtitle: offer.deliveryAddress ?? '',
            ),
          if (offer.paymentMethod != null && !offer.isRoute) ...[
            const SizedBox(height: 12),
            Text('Cliente paga na entrega: ${offer.paymentMethod!.label}'
                '${offer.totalAmount != null ? ' · ${formatMoney(offer.totalAmount!)}' : ''}',
                style: textTheme.bodySmall),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Recusar',
                  variant: ButtonVariant.outlined,
                  onPressed: busy || expired ? null : onDecline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppButton(
                  text: offer.isRoute ? 'Aceitar rota' : 'Aceitar entrega',
                  icon: Icons.check,
                  size: ButtonSize.large,
                  isLoading: busy,
                  onPressed: busy || expired ? null : onAccept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  /// Posição na rota: substitui o ícone por um número
  final int? number;

  const _Stop({required this.icon, required this.title, required this.subtitle, this.number});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        number != null
            ? CircleAvatar(
                radius: 12,
                backgroundColor: context.appColors.primary,
                child: Text('$number', style: TextStyle(color: context.appColors.onAction, fontSize: 12, fontWeight: FontWeight.w800)),
              )
            : Icon(icon, color: AppColors.textBody),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              if (subtitle.isNotEmpty) Text(subtitle, style: textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
