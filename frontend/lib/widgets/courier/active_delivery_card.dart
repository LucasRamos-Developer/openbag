import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/courier/courier_work.dart';
import '../../models/order/order.dart' show PaymentMethod;
import '../../utils/formatters.dart';
import '../../utils/maps.dart';

/// Entrega em andamento: retirar no restaurante e levar ao cliente, com rota, contatos e cobrança
class ActiveDeliveryCard extends StatelessWidget {
  final CourierOrder order;
  final bool busy;
  final VoidCallback onPickUp;
  final VoidCallback onDeliver;

  /// "Relatar problema": pedido não pronto, cliente não localizado...
  final VoidCallback? onReportIncident;

  const ActiveDeliveryCard({
    super.key,
    required this.order,
    required this.onPickUp,
    required this.onDeliver,
    this.onReportIncident,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pickedUp = order.pickedUp;
    final change = order.changeFor != null && order.paymentMethod == PaymentMethod.CASH
        ? order.changeFor! - order.totalAmount
        : null;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pedido ${order.displayCode ?? '#${order.orderId}'}',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              AppStatusChip(
                label: pickedUp ? 'A caminho do cliente' : (order.readyForPickup ? 'Pronto para retirar' : 'Em preparo'),
                color: pickedUp ? AppColors.infoDark : (order.readyForPickup ? AppColors.successDark : AppColors.warningDarker),
              ),
            ],
          ),
          if (order.courierFee != null)
            Text('Você recebe ${formatMoney(order.courierFee!)}', style: textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark)),
          const SizedBox(height: 16),
          _Leg(
            done: pickedUp,
            icon: Icons.storefront,
            title: 'Retirar em ${order.restaurant.name}',
            subtitle: order.restaurant.address,
            onDirections: () => openDirections(
                latitude: order.restaurant.latitude, longitude: order.restaurant.longitude, address: order.restaurant.address),
            phone: order.restaurantPhone,
          ),
          const Divider(height: 24),
          _Leg(
            done: false,
            icon: Icons.location_on,
            title: 'Entregar para ${order.customerName ?? 'o cliente'}',
            subtitle: order.deliveryAddress,
            onDirections: () => openDirections(
                latitude: order.deliveryLatitude, longitude: order.deliveryLongitude, address: order.deliveryAddress),
            phone: order.customerPhone,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.grey200, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cobrar na entrega: ${formatMoney(order.totalAmount)} · ${order.paymentMethod.label}',
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (change != null && change > 0)
                  Text('Levar troco de ${formatMoney(change)} (cliente paga com ${formatMoney(order.changeFor!)})',
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.warningDarker)),
                if (order.items.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(order.items.join(' · '), style: textTheme.bodySmall),
                ],
                if (order.notes != null) Text('Obs.: ${order.notes}', style: textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (pickedUp)
            AppButton(
              text: 'Entreguei',
              icon: Icons.check_circle_outline,
              size: ButtonSize.large,
              fullWidth: true,
              isLoading: busy,
              onPressed: busy ? null : onDeliver,
            )
          else if (order.readyForPickup)
            AppButton(
              text: 'Retirei o pedido',
              icon: Icons.shopping_bag_outlined,
              size: ButtonSize.large,
              fullWidth: true,
              isLoading: busy,
              onPressed: busy ? null : onPickUp,
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warningLighter.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.soup_kitchen_outlined, color: AppColors.warningDarker),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'O pedido está sendo preparado. Vá até o restaurante: o botão de retirada aparece quando ficar pronto.',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          if (order.reportedIncidents.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.campaign_outlined, size: 18, color: AppColors.warningDarker),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('A loja foi avisada: ${order.reportedIncidents.map((t) => t.label).join(', ')}',
                      style: textTheme.bodySmall?.copyWith(color: AppColors.warningDarker)),
                ),
              ],
            ),
          ],
          if (onReportIncident != null) ...[
            const SizedBox(height: 8),
            AppButton(
              text: 'Relatar problema',
              icon: Icons.report_problem_outlined,
              variant: ButtonVariant.text,
              fullWidth: true,
              onPressed: busy ? null : onReportIncident,
            ),
          ],
        ],
      ),
    );
  }
}

class _Leg extends StatelessWidget {
  final bool done;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onDirections;
  final String? phone;

  const _Leg({required this.done, required this.icon, required this.title, this.subtitle, required this.onDirections, this.phone});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = done ? AppColors.textSecondary : AppColors.textTitle;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(done ? Icons.check_circle : icon, color: done ? AppColors.successDark : AppColors.textBody),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: color)),
              if (subtitle != null) Text(subtitle!, style: textTheme.bodySmall),
            ],
          ),
        ),
        if (!done) ...[
          if (phone != null)
            IconButton(tooltip: 'Ligar', icon: const Icon(Icons.phone_outlined), onPressed: () => callPhone(phone!)),
          IconButton(tooltip: 'Rota', icon: const Icon(Icons.directions_outlined), onPressed: onDirections),
        ],
      ],
    );
  }
}
