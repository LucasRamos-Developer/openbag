import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/ui.dart';
import '../../../models/admin/admin_rows.dart';
import '../../../services/admin_service.dart';
import '../../../widgets/admin/admin_row_card.dart';

/// Todos os entregadores; o toque abre o perfil público
class CouriersTab extends StatelessWidget {
  final AdminService service;

  const CouriersTab({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AppPagedList<AdminCourierRow>(
      title: 'Entregadores',
      leadingIcon: Icons.two_wheeler_outlined,
      searchHint: 'Nome ou e-mail',
      emptyMessage: 'Nenhum entregador encontrado.',
      fetch: (query, page) => service.couriers(query: query, page: page),
      itemBuilder: (context, courier) => AdminRowCard(
        leading: AppImageAvatar(url: null, name: courier.fullName, size: 44),
        title: courier.fullName,
        lines: [
          [courier.email, courier.association ?? 'Sem associação'].join(' · '),
          [
            if (courier.vehicle != null) courier.vehicle!,
            '${courier.totalDeliveries} ${courier.totalDeliveries == 1 ? 'entrega' : 'entregas'}',
            if (courier.rating > 0) '★ ${courier.rating.toStringAsFixed(1)}',
          ].join(' · '),
        ],
        trailing: [
          if (!courier.active) const AppStatusChip(label: 'Inativo', color: AppColors.errorDark),
          AppStatusChip(label: courier.workStatusLabel, color: courier.online ? c.success : c.textMuted),
        ],
        onTap: courier.slug == null ? null : () => context.push('/e/${courier.slug}'),
      ),
    );
  }
}
