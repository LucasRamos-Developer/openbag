import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/order/order.dart';
import '../../services/api_client.dart';
import '../../services/order_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/order/order_status_chip.dart';
import '../../widgets/restaurant/restaurant_logo.dart';
import '../../widgets/navigation/storefront_scaffold.dart';

/// Meus pedidos (mais recentes primeiro)
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order>? _orders;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final orders = await context.read<OrderService>().fetchMyOrders();
      if (mounted) setState(() => _orders = orders);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StorefrontScaffold(
      title: 'Meus pedidos',
      current: StorefrontLink.orders,
      // Largura útil da lista (720 menos o padding de 16 de cada lado), para alinhar o título
      maxWidth: 720 - 32,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null && _orders == null) {
      return AppEmptyState(icon: Icons.cloud_off_outlined, message: _error!, actionLabel: 'Tentar novamente', onAction: _load);
    }
    if (_orders == null) return const Center(child: CircularProgressIndicator());
    if (_orders!.isEmpty) {
      return AppEmptyState(
        icon: Icons.receipt_long_outlined,
        message: 'Você ainda não fez nenhum pedido.',
        actionLabel: 'Ver restaurantes',
        onAction: () => context.go('/home'),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _orders!.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _OrderCard(order: _orders![i]),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
      borderWidth: 1,
      onTap: () => context.push('/pedidos/${order.id}'),
      child: Row(
        children: [
          RestaurantLogo(logoUrl: order.restaurant.logoUrl, name: order.restaurant.name, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.restaurant.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${formatDateTime(order.createdAt)} · ${order.itemCount} ${order.itemCount == 1 ? 'item' : 'itens'}'
                  ' · ${formatMoney(order.totalAmount)}',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
                const SizedBox(height: 6),
                OrderStatusChip(status: order.status),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
