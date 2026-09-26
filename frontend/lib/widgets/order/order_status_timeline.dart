import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/order/order.dart';

/// Linha do tempo do pedido para o cliente: etapas concluídas, atual e próximas
class OrderStatusTimeline extends StatelessWidget {
  final Order order;

  const OrderStatusTimeline({super.key, required this.order});

  String _time(DateTime? at) {
    if (at == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(at.hour)}:${two(at.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurface.withValues(alpha: 0.45);

    if (order.status == OrderStatus.CANCELLED) {
      return Row(
        children: [
          const Icon(Icons.cancel, color: AppColors.errorDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              order.cancellationReason ?? 'Pedido cancelado',
              style: const TextStyle(color: AppColors.errorDark, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    final currentIndex = OrderStatus.progress.indexOf(order.status);
    return Column(
      children: [
        for (var i = 0; i < OrderStatus.progress.length; i++)
          _Step(
            status: OrderStatus.progress[i],
            done: i < currentIndex || (i == currentIndex && order.status == OrderStatus.DELIVERED),
            current: i == currentIndex && order.status != OrderStatus.DELIVERED,
            time: _time(order.reachedAt(OrderStatus.progress[i])),
            isLast: i == OrderStatus.progress.length - 1,
            activeColor: colorScheme.primary,
            mutedColor: muted,
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final OrderStatus status;
  final bool done;
  final bool current;
  final String time;
  final bool isLast;
  final Color activeColor;
  final Color mutedColor;

  const _Step({
    required this.status,
    required this.done,
    required this.current,
    required this.time,
    required this.isLast,
    required this.activeColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    final reached = done || current;
    final color = reached ? activeColor : mutedColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
                child: done
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : current
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                            ),
                          )
                        : null,
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: done ? color : mutedColor.withValues(alpha: 0.3))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.label,
                    style: TextStyle(fontWeight: current ? FontWeight.w700 : FontWeight.w500, color: reached ? null : mutedColor),
                  ),
                  if (current) Text(status.description, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          Text(time, style: TextStyle(color: mutedColor, fontSize: 12)),
        ],
      ),
    );
  }
}
