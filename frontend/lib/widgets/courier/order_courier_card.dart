import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/ui.dart';
import '../../models/order/order.dart';
import '../../utils/maps.dart';
import 'courier_avatar.dart';

/// Entregador do pedido (cliente e restaurante): foto, veículo, contato e perfil público verificado
class OrderCourierCard extends StatelessWidget {
  final OrderCourier courier;

  const OrderCourierCard({super.key, required this.courier});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CourierAvatar(photoUrl: courier.photoUrl, name: courier.fullName, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(courier.fullName, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                if (courier.vehicleLine.isNotEmpty)
                  Row(
                    children: [
                      Icon(courier.vehicleType?.icon ?? Icons.two_wheeler, size: 16, color: AppColors.textBody),
                      const SizedBox(width: 6),
                      Flexible(child: Text(courier.vehicleLine, style: textTheme.bodySmall)),
                    ],
                  ),
                if (courier.slug != null)
                  InkWell(
                    onTap: () => context.push('/e/${courier.slug}'),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('Ver perfil verificado', style: textTheme.bodySmall?.copyWith(color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (courier.phoneNumber != null)
            IconButton(tooltip: 'Ligar para o entregador', icon: const Icon(Icons.phone_outlined), onPressed: () => callPhone(courier.phoneNumber!)),
        ],
      ),
    );
  }
}
