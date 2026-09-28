import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/order/order.dart';

/// Selos do pedido registrado pela loja (balcão, telefone, WhatsApp) e da retirada na loja.
/// Pedido do app com entrega não mostra nada.
class OrderOriginBadges extends StatelessWidget {
  final Order order;

  const OrderOriginBadges({super.key, required this.order});

  static bool shows(Order order) => order.fromStore || order.isPickup;

  @override
  Widget build(BuildContext context) {
    if (!shows(order)) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (order.fromStore) AppBadge(label: order.channel.label, icon: order.channel.icon, tone: BadgeTone.neutral),
        if (order.isPickup) AppBadge(label: order.fulfillment.label, icon: order.fulfillment.icon, tone: BadgeTone.accent),
      ],
    );
  }
}
