import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/order/order.dart';
import '../../services/api_client.dart';
import '../../services/order_service.dart';
import '../../services/realtime_service.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';
import '../../widgets/order/order_items_list.dart';
import '../../widgets/order/order_status_chip.dart';
import '../../widgets/order/order_status_timeline.dart';
import '../../widgets/order/price_summary.dart';
import '../../widgets/restaurant/restaurant_logo.dart';

/// Acompanhamento do pedido pelo cliente.
/// Atualiza em tempo real pelo WebSocket; a cada 30s recarrega como reserva.
class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  String? _error;
  Timer? _poll;
  VoidCallback? _stopListening;

  @override
  void initState() {
    super.initState();
    _load();
    _stopListening = context.read<RealtimeService>().listen(
      '/topic/orders/${widget.orderId}',
      (message) {
        if (mounted) setState(() => _order = Order.fromJson(message['order']));
      },
      onReconnect: _load,
    );
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_order != null && !_order!.status.isFinal) _load();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _stopListening?.call();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final order = await context.read<OrderService>().fetchOrder(widget.orderId);
      if (mounted) setState(() => _order = order);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _cancel() async {
    final ok = await AppDialog.confirm(
      context,
      title: 'Cancelar o pedido?',
      message: 'O restaurante ainda não aceitou, então o cancelamento é imediato.',
      confirmLabel: 'Cancelar pedido',
    );
    if (!ok || !mounted) return;
    await runWithFeedback(context, () async {
      final order = await context.read<OrderService>().cancelOrder(widget.orderId);
      if (mounted) setState(() => _order = order);
    }, success: 'Pedido cancelado');
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return Scaffold(
      appBar: AppBar(
        title: Text(order?.displayCode != null ? 'Pedido ${order!.displayCode}' : 'Pedido'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar',
          onPressed: () => context.canPop() ? context.pop() : context.go('/pedidos'),
        ),
      ),
      body: order == null
          ? (_error != null
              ? AppEmptyState(icon: Icons.receipt_long_outlined, message: _error!, actionLabel: 'Tentar novamente', onAction: _load)
              : const Center(child: CircularProgressIndicator()))
          : RefreshIndicator(onRefresh: _load, child: _buildContent(order)),
    );
  }

  Widget _buildContent(Order order) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                RestaurantLogo(logoUrl: order.restaurant.logoUrl, name: order.restaurant.name, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.restaurant.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      Text('Feito em ${formatDateTime(order.createdAt)}', style: TextStyle(color: muted, fontSize: 13)),
                    ],
                  ),
                ),
                OrderStatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.all(16),
              borderColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
              borderWidth: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!order.status.isFinal && order.estimatedDeliveryTime != null && order.createdAt != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'Previsão de entrega até ${formatTime(order.createdAt!.add(Duration(minutes: order.estimatedDeliveryTime!)))}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  OrderStatusTimeline(order: order),
                ],
              ),
            ),
            if (order.status == OrderStatus.PENDING) ...[
              const SizedBox(height: 12),
              AppButton(text: 'Cancelar pedido', variant: ButtonVariant.outlined, backgroundColor: AppColors.errorDark, onPressed: _cancel),
            ],
            const AppSectionHeader(title: 'Itens', padding: EdgeInsets.only(top: 24, bottom: 8)),
            OrderItemsList(items: order.items),
            const SizedBox(height: 12),
            PriceSummary(subtotal: order.subtotal, deliveryFee: order.deliveryFee, total: order.totalAmount),
            const AppSectionHeader(title: 'Pagamento na entrega', padding: EdgeInsets.only(top: 24, bottom: 8)),
            Row(
              children: [
                Icon(order.paymentMethod.icon, color: muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(order.changeFor != null
                      ? '${order.paymentMethod.label} · troco para ${formatMoney(order.changeFor!)}'
                      : order.paymentMethod.label),
                ),
              ],
            ),
            if (order.deliveryAddress != null) ...[
              const AppSectionHeader(title: 'Endereço de entrega', padding: EdgeInsets.only(top: 24, bottom: 8)),
              Text(order.deliveryAddress!),
            ],
            if (order.notes != null) ...[
              const AppSectionHeader(title: 'Observações', padding: EdgeInsets.only(top: 24, bottom: 8)),
              Text(order.notes!),
            ],
            if (order.restaurant.phoneNumber != null) ...[
              const SizedBox(height: 24),
              Text('Dúvidas? Fale com o restaurante: ${order.restaurant.phoneNumber}', style: TextStyle(color: muted)),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
