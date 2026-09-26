import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/order/order.dart';
import '../../utils/formatters.dart';
import 'order_timers.dart';

/// Cartão de pedido no gestor do restaurante.
/// Pedido novo (aguardando aceite) ganha destaque, prazo e botões de aceitar/recusar.
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final void Function(OrderAction action)? onAction;
  final bool busy;

  const OrderCard({super.key, required this.order, required this.onTap, this.onAction, this.busy = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurface.withValues(alpha: 0.6);
    final isNew = order.status == OrderStatus.PENDING;
    final next = OrderAction.nextFor(order.status);
    final items = order.items.map((i) => '${i.quantity}x ${i.name}').join(', ');

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      borderWidth: isNew ? 2 : 1,
      borderColor: isNew ? AppColors.warningDarker : colorScheme.outline.withValues(alpha: 0.15),
      backgroundColor: isNew ? AppColors.warningLighter.withValues(alpha: 0.25) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(order.displayCode ?? '#${order.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(order.customerName ?? '', overflow: TextOverflow.ellipsis, style: TextStyle(color: muted)),
              ),
              if (order.createdAt != null)
                ElapsedTimer(
                  since: order.createdAt!,
                  warnAfter: const Duration(minutes: 20),
                  dangerAfter: const Duration(minutes: 40),
                  style: TextStyle(color: muted, fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(items, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('${formatMoney(order.totalAmount)} · ${order.paymentMethod.label}',
              style: TextStyle(color: muted, fontSize: 13)),
          if (order.courier != null || order.awaitingCourier) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(order.courier != null ? Icons.two_wheeler : Icons.search, size: 14,
                    color: order.searchingCourierSince != null ? AppColors.warningDarker : muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.courier != null
                        ? order.courier!.fullName
                        : (order.searchingCourierSince != null ? 'Sem entregador disponível' : 'Procurando entregador'),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: order.searchingCourierSince != null && order.courier == null ? AppColors.warningDarker : muted,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          if (isNew && order.acceptDeadline != null) ...[
            const SizedBox(height: 6),
            DeadlineCountdown(deadline: order.acceptDeadline!),
          ],
          if (onAction != null && next != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (isNew) ...[
                  Expanded(
                    child: AppButton(
                      text: 'Recusar',
                      variant: ButtonVariant.outlined,
                      backgroundColor: AppColors.errorDark,
                      size: ButtonSize.small,
                      onPressed: busy ? null : () => onAction!(OrderAction.reject),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: AppButton(
                    text: next.label,
                    size: ButtonSize.small,
                    isLoading: busy,
                    onPressed: busy ? null : () => onAction!(next),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
