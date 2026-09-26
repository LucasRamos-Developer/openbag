import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/ui.dart';
import '../../models/courier/courier_earnings.dart';
import '../../utils/formatters.dart';
import '../restaurant/restaurant_logo.dart';

/// Restaurantes em que o entregador já trabalhou (painel e perfil público)
class WorkHistoryList extends StatelessWidget {
  final List<WorkedRestaurant> restaurants;

  const WorkHistoryList({super.key, required this.restaurants});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final r in restaurants)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: RestaurantLogo(logoUrl: r.logoUrl, name: r.name, size: 44),
            title: Row(
              children: [
                Flexible(child: Text(r.name, overflow: TextOverflow.ellipsis)),
                if (r.fixed) ...[
                  const SizedBox(width: 8),
                  const AppStatusChip(label: 'Fixo', color: AppColors.primaryDark),
                ],
              ],
            ),
            subtitle: Text(
              '${r.deliveries} ${r.deliveries == 1 ? 'entrega' : 'entregas'}'
              '${r.firstDeliveryAt != null ? ' · desde ${formatDate(r.firstDeliveryAt)}' : ''}',
              style: textTheme.bodySmall,
            ),
            onTap: r.slug != null ? () => context.push('/r/${r.slug}') : null,
          ),
      ],
    );
  }
}
