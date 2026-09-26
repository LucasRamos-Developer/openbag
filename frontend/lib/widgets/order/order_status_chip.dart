import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/order/order.dart';

/// Selo do status do pedido
class OrderStatusChip extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusChip({super.key, required this.status});

  static Color colorOf(OrderStatus status) {
    switch (status) {
      case OrderStatus.PENDING:
        return AppColors.warningDarker;
      case OrderStatus.CANCELLED:
        return AppColors.errorDark;
      case OrderStatus.DELIVERED:
        return AppColors.grey700;
      default:
        return AppColors.successDark;
    }
  }

  @override
  Widget build(BuildContext context) => AppStatusChip(label: status.label, color: colorOf(status));
}
