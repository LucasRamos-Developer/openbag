import 'package:flutter/material.dart';
import '../../../core/ui/ui.dart';
import '../../../models/admin/admin_rows.dart';
import '../../../models/order/order.dart';
import '../../../services/admin_service.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/admin/admin_row_card.dart';
import '../../../widgets/order/order_status_chip.dart';

/// Pedidos de todas as lojas, mais recentes primeiro, com filtro de situação
class OrdersTab extends StatefulWidget {
  final AdminService service;

  const OrdersTab({super.key, required this.service});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  OrderStatus? _status;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AppPagedList<AdminOrderRow>(
      title: 'Pedidos',
      leadingIcon: Icons.receipt_long_outlined,
      emptyMessage: 'Nenhum pedido encontrado.',
      filterKey: _status,
      filters: AppFilterChips<OrderStatus?>(
        padding: EdgeInsets.zero,
        items: [
          const SelectItem(value: null, label: 'Todos'),
          for (final status in OrderStatus.values) SelectItem(value: status, label: status.label),
        ],
        value: _status,
        onSelected: (status) => setState(() => _status = status),
      ),
      fetch: (_, page) => widget.service.orders(status: _status, page: page),
      itemBuilder: (context, order) => AdminRowCard(
        leading: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(Icons.receipt_long_outlined, color: c.primaryText),
        ),
        title: '${order.displayCode} · ${order.restaurantName}',
        lines: [
          [
            order.customerName ?? 'Cliente',
            if (order.courierName != null) 'entregador ${order.courierName}',
          ].join(' · '),
          [formatMoney(order.totalAmount), if (order.createdAt != null) formatDateTime(order.createdAt)].join(' · '),
        ],
        trailing: [OrderStatusChip(status: order.status)],
      ),
    );
  }
}
