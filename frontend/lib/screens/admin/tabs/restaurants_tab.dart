import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/ui.dart';
import '../../../models/admin/admin_rows.dart';
import '../../../services/admin_service.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/admin/admin_row_card.dart';
import '../../../widgets/restaurant/restaurant_logo.dart';

/// Todos os restaurantes; o toque abre a vitrine da loja
class RestaurantsTab extends StatelessWidget {
  final AdminService service;

  const RestaurantsTab({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AppPagedList<AdminRestaurantRow>(
      title: 'Restaurantes',
      leadingIcon: Icons.storefront_outlined,
      searchHint: 'Nome, endereço da vitrine ou e-mail do dono',
      emptyMessage: 'Nenhum restaurante encontrado.',
      fetch: (query, page) => service.restaurants(query: query, page: page),
      itemBuilder: (context, r) => AdminRowCard(
        leading: RestaurantLogo(logoUrl: null, name: r.name, size: 44),
        title: r.name,
        lines: [
          [if (r.ownerName != null) r.ownerName!, if (r.ownerEmail != null) r.ownerEmail!].join(' · '),
          ['/r/${r.slug}', if (r.city != null) r.city!, if (r.createdAt != null) 'desde ${formatDate(r.createdAt)}']
              .join(' · '),
        ],
        trailing: [
          if (!r.active) const AppStatusChip(label: 'Inativo', color: AppColors.errorDark)
          else AppStatusChip(label: r.openNow ? 'Aberto' : 'Fechado', color: r.openNow ? c.success : c.textMuted),
        ],
        onTap: () => context.push('/r/${r.slug}'),
      ),
    );
  }
}
