import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/order/order.dart';
import '../../utils/formatters.dart';
import '../../services/restaurant_orders_service.dart';
import '../delivery/order_courier_section.dart';
import 'order_items_list.dart';
import 'order_status_chip.dart';
import 'order_timers.dart';
import 'price_summary.dart';

/// Detalhe do pedido para o restaurante, com as ações da etapa atual e a comanda
Future<void> showRestaurantOrderSheet(
  BuildContext context, {
  required Order order,
  required Future<void> Function(OrderAction action) onAction,
  required VoidCallback onPrint,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => _RestaurantOrderSheet(order: order, onAction: onAction, onPrint: onPrint),
  );
}

class _RestaurantOrderSheet extends StatefulWidget {
  final Order order;
  final Future<void> Function(OrderAction action) onAction;
  final VoidCallback onPrint;

  const _RestaurantOrderSheet({required this.order, required this.onAction, required this.onPrint});

  @override
  State<_RestaurantOrderSheet> createState() => _RestaurantOrderSheetState();
}

class _RestaurantOrderSheetState extends State<_RestaurantOrderSheet> {
  OrderAction? _running;

  Future<void> _run(OrderAction action) async {
    setState(() => _running = action);
    try {
      await widget.onAction(action);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Versão em tempo real do pedido: a ficha acompanha a atribuição e as mudanças de etapa
    final order = context.watch<RestaurantOrdersService>().byId(widget.order.id) ?? widget.order;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final next = OrderAction.nextFor(order.status);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                Row(
                  children: [
                    Text(order.displayCode ?? '#${order.id}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 12),
                    OrderStatusChip(status: order.status),
                    const Spacer(),
                    IconButton(tooltip: 'Imprimir comanda', icon: const Icon(Icons.print_outlined), onPressed: widget.onPrint),
                  ],
                ),
                Text('Feito às ${formatTime(order.createdAt)} · ${order.orderNumber}', style: TextStyle(color: muted)),
                if (order.status == OrderStatus.PENDING && order.acceptDeadline != null) ...[
                  const SizedBox(height: 8),
                  DeadlineCountdown(deadline: order.acceptDeadline!),
                ],
                const AppSectionHeader(title: 'Itens', padding: EdgeInsets.only(top: 20, bottom: 8)),
                OrderItemsList(items: order.items),
                if (order.notes != null) ...[
                  const AppSectionHeader(title: 'Observações do cliente', padding: EdgeInsets.only(top: 16, bottom: 8)),
                  Text(order.notes!),
                ],
                const SizedBox(height: 12),
                PriceSummary(subtotal: order.subtotal, deliveryFee: order.deliveryFee, total: order.totalAmount),
                const AppSectionHeader(title: 'Pagamento na entrega', padding: EdgeInsets.only(top: 20, bottom: 8)),
                Text(order.changeFor != null
                    ? '${order.paymentMethod.label} · troco para ${formatMoney(order.changeFor!)} '
                        '(levar ${formatMoney(order.changeFor! - order.totalAmount)})'
                    : order.paymentMethod.label),
                const AppSectionHeader(title: 'Entrega', padding: EdgeInsets.only(top: 20, bottom: 8)),
                if (order.customerName != null) Text(order.customerName!, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (order.customerPhone != null) Text(order.customerPhone!),
                if (order.deliveryAddress != null) Text(order.deliveryAddress!),
                if (order.courierName != null || order.awaitingCourier) ...[
                  const AppSectionHeader(title: 'Entregador', padding: EdgeInsets.only(top: 20, bottom: 8)),
                  OrderCourierSection(order: order),
                ],
              ],
            ),
          ),
          if (next != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    if (OrderAction.canReject(order.status)) ...[
                      Expanded(
                        child: AppButton(
                          text: order.status == OrderStatus.PENDING ? 'Recusar' : 'Cancelar pedido',
                          variant: ButtonVariant.outlined,
                          backgroundColor: AppColors.errorDark,
                          size: ButtonSize.large,
                          isLoading: _running == OrderAction.reject,
                          onPressed: _running != null ? null : () => _run(OrderAction.reject),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: AppButton(
                        text: next.label,
                        size: ButtonSize.large,
                        isLoading: _running == next,
                        onPressed: _running != null ? null : () => _run(next),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
