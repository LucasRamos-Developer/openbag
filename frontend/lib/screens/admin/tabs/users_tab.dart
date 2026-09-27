import 'package:flutter/material.dart';
import '../../../core/ui/ui.dart';
import '../../../models/admin/admin_rows.dart';
import '../../../services/admin_service.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/admin/admin_row_card.dart';

/// Todas as contas, com os papéis de cada uma
class UsersTab extends StatelessWidget {
  final AdminService service;

  const UsersTab({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AppPagedList<AdminUserRow>(
      title: 'Usuários',
      leadingIcon: Icons.people_outline,
      searchHint: 'Nome ou e-mail',
      emptyMessage: 'Nenhum usuário encontrado.',
      fetch: (query, page) => service.users(query: query, page: page),
      itemBuilder: (context, user) => AdminRowCard(
        leading: AppImageAvatar(url: null, name: user.fullName, size: 44),
        title: user.fullName,
        lines: [
          [user.email, if (user.phoneNumber != null) user.phoneNumber!].join(' · '),
          [
            user.roles.isEmpty ? 'Sem papéis' : user.roles.map(AdminUserRow.roleLabel).join(', '),
            if (user.createdAt != null) 'desde ${formatDate(user.createdAt)}',
          ].join(' · '),
        ],
        trailing: [
          if (user.roles.contains('ADMIN')) AppStatusChip(label: 'Admin', color: c.primaryText),
          if (!user.active) const AppStatusChip(label: 'Inativo', color: AppColors.errorDark),
        ],
      ),
    );
  }
}
