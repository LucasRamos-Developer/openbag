import 'package:flutter/material.dart';
import '../../../core/ui/ui.dart';
import '../../../models/admin/admin_rows.dart';
import '../../../utils/formatters.dart';
import '../admin_section.dart';

/// Visão geral da plataforma: um bloco por área, que leva à lista correspondente
class OverviewTab extends StatelessWidget {
  final AdminOverview? overview;
  final String? error;
  final Future<void> Function() onRefresh;
  final ValueChanged<AdminSection> onOpen;

  const OverviewTab({super.key, required this.overview, this.error, required this.onRefresh, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final data = overview;
    if (data == null) {
      return error != null
          ? AppEmptyState(icon: Icons.cloud_off_outlined, message: error!, actionLabel: 'Tentar novamente', onAction: onRefresh)
          : const Center(child: CircularProgressIndicator());
    }

    final tiles = [
      (AdminSection.restaurants, 'Restaurantes', formatCount(data.restaurants), '${formatCount(data.restaurantsOpenNow)} abertos agora'),
      (
        AdminSection.associations,
        'Associações',
        formatCount(data.associations),
        data.associationsPending > 0 ? '${formatCount(data.associationsPending)} aguardando aprovação' : 'Nenhuma pendente',
      ),
      (AdminSection.couriers, 'Entregadores', formatCount(data.couriers), '${formatCount(data.couriersOnline)} online agora'),
      (AdminSection.users, 'Usuários', formatCount(data.users), 'Contas cadastradas'),
      (AdminSection.orders, 'Pedidos hoje', formatCount(data.ordersToday), 'Desde a meia-noite'),
    ];

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: AppPageListView(
        children: [
          const AppSectionHeader(
            title: 'Visão geral',
            subtitle: 'Tudo o que acontece na plataforma, em um só lugar',
            leadingIcon: Icons.dashboard_outlined,
          ),
          AppResponsiveGrid(
            maxColumns: 3,
            minItemWidth: 240,
            children: [
              for (final (section, label, value, caption) in tiles)
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () => onOpen(section),
                  child: AppStatTile(
                    icon: section.icon,
                    label: label,
                    value: value,
                    caption: caption,
                    highlighted: section == AdminSection.associations && data.associationsPending > 0,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
