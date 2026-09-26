import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/association/member.dart';
import '../../../services/association_service.dart';

/// Visão geral: contadores da associação e atalhos para as solicitações pendentes
class OverviewTab extends StatelessWidget {
  final void Function(MembershipStatus? filter) onOpenMembers;
  final VoidCallback onOpenInvites;

  const OverviewTab({super.key, required this.onOpenMembers, required this.onOpenInvites});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AssociationService>();
    final stats = service.stats;

    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final vehicleTotal = stats.activeMembersByVehicleType.values.fold<int>(0, (a, b) => a + b);

    return RefreshIndicator(
      onRefresh: service.refreshStats,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const AppSectionHeader(title: 'Visão geral', subtitle: 'Acompanhe os associados da sua organização'),

          if (stats.pendingRequests > 0) ...[
            AppCard(
              backgroundColor: AppColors.warningLighter.withValues(alpha: 0.5),
              onTap: () => onOpenMembers(MembershipStatus.PENDING),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.person_add_alt_1_outlined, color: AppColors.warningDarker),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      stats.pendingRequests == 1
                          ? '1 entregador aguarda sua aprovação'
                          : '${stats.pendingRequests} entregadores aguardam sua aprovação',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Text('Revisar', style: TextStyle(color: AppColors.warningDarker, fontWeight: FontWeight.w600)),
                  const Icon(Icons.chevron_right, color: AppColors.warningDarker),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 520 ? 2 : 1);
              final tiles = [
                _StatTile(
                  label: 'Associados ativos',
                  value: stats.activeMembers,
                  icon: Icons.groups_outlined,
                  onTap: () => onOpenMembers(MembershipStatus.ACTIVE),
                ),
                _StatTile(
                  label: 'Disponíveis agora',
                  value: stats.availableNow,
                  icon: Icons.delivery_dining_outlined,
                ),
                _StatTile(
                  label: 'Solicitações pendentes',
                  value: stats.pendingRequests,
                  icon: Icons.hourglass_top_outlined,
                  onTap: () => onOpenMembers(MembershipStatus.PENDING),
                ),
                _StatTile(
                  label: 'Suspensos',
                  value: stats.suspendedMembers,
                  icon: Icons.pause_circle_outline,
                  onTap: () => onOpenMembers(MembershipStatus.SUSPENDED),
                ),
                _StatTile(
                  label: 'Entregas realizadas',
                  value: stats.totalDeliveries,
                  icon: Icons.inventory_2_outlined,
                ),
                _StatTile(
                  label: 'Convites válidos',
                  value: stats.activeInvites,
                  icon: Icons.confirmation_number_outlined,
                  onTap: onOpenInvites,
                ),
              ];
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final tile in tiles)
                    SizedBox(
                      width: (constraints.maxWidth - 16 * (columns - 1)) / columns,
                      child: tile,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Associados ativos por veículo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                if (vehicleTotal == 0)
                  Text('Nenhum associado ativo ainda.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)))
                else
                  for (final type in VehicleType.values)
                    _VehicleRow(
                      label: type.label,
                      count: stats.activeMembersByVehicleType[type.name] ?? 0,
                      total: vehicleTotal,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatTile({required this.label, required this.value, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      borderColor: colorScheme.outline.withValues(alpha: 0.15),
      borderWidth: 1,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text(label, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7))),
              ],
            ),
          ),
          if (onTap != null) Icon(Icons.chevron_right, color: colorScheme.onSurface.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}

class _VehicleRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;

  const _VehicleRow({required this.label, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : count / total,
                minHeight: 8,
                backgroundColor: colorScheme.outline.withValues(alpha: 0.12),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text('$count', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
