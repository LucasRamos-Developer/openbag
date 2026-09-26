import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/association/association.dart';
import '../../models/association/member.dart';
import '../../services/association_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/association/association_logo.dart';
import 'tabs/invites_tab.dart';
import 'tabs/members_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/profile_tab.dart';

/// Painel do gestor da associação/cooperativa
///
/// Associação ativa: abas Visão geral, Associados, Convites e Dados.
/// Associação pendente/recusada/suspensa: tela de status (a recusada pode corrigir os dados e reenviar).
class AssociationPanelScreen extends StatefulWidget {
  const AssociationPanelScreen({super.key});

  @override
  State<AssociationPanelScreen> createState() => _AssociationPanelScreenState();
}

class _AssociationPanelScreenState extends State<AssociationPanelScreen> {
  int _tabIndex = 0;
  // Filtro aplicado ao abrir a aba de associados a partir da visão geral
  MembershipStatus? _membersFilter;
  bool _editingRejected = false;

  List<AppPanelDestination> _destinations(AssociationService service) => [
        const AppPanelDestination(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Visão geral'),
        AppPanelDestination(
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups,
          label: 'Associados',
          badge: service.stats?.pendingRequests ?? 0,
        ),
        const AppPanelDestination(
          icon: Icons.confirmation_number_outlined,
          selectedIcon: Icons.confirmation_number,
          label: 'Convites',
        ),
        const AppPanelDestination(icon: Icons.apartment_outlined, selectedIcon: Icons.apartment, label: 'Dados'),
      ];

  @override
  void initState() {
    super.initState();
    // Descarta dados de uma sessão anterior (outro gestor) antes de carregar
    final service = context.read<AssociationService>()..clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => service.loadMyAssociation());
  }

  Future<void> _logout() async {
    final associationService = context.read<AssociationService>();
    await context.read<AuthService>().logout();
    associationService.clear();
    if (mounted) context.go('/login');
  }

  void _openMembers(MembershipStatus? filter) {
    setState(() {
      _membersFilter = filter;
      _tabIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AssociationService>();
    final association = service.association;

    if (association == null) {
      return Scaffold(
        appBar: _buildAppBar(null),
        body: service.isLoading || service.error == null
            ? const Center(child: CircularProgressIndicator())
            : AppEmptyState(
                icon: Icons.cloud_off_outlined,
                message: service.error!,
                actionLabel: 'Tentar novamente',
                onAction: service.loadMyAssociation,
              ),
      );
    }

    if (!association.isActive) {
      return Scaffold(
        appBar: _buildAppBar(association),
        body: _editingRejected
            ? ProfileTab(onSaved: () => setState(() => _editingRejected = false))
            : _StatusView(
                association: association,
                onRefresh: service.loadMyAssociation,
                onEdit: () => setState(() => _editingRejected = true),
              ),
      );
    }

    final body = IndexedStack(
      index: _tabIndex,
      children: [
        OverviewTab(onOpenMembers: _openMembers, onOpenInvites: () => setState(() => _tabIndex = 2)),
        MembersTab(key: ValueKey(_membersFilter), initialFilter: _membersFilter),
        const InvitesTab(),
        const ProfileTab(),
      ],
    );

    return AppPanelScaffold(
      appBar: _buildAppBar(association),
      destinations: _destinations(service),
      selectedIndex: _tabIndex,
      onDestinationSelected: (index) => setState(() => _tabIndex = index),
      body: body,
    );
  }

  PreferredSizeWidget _buildAppBar(Association? association) {
    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          if (association != null) ...[
            AssociationLogo(logoUrl: association.logoUrl, name: association.tradingName, size: 36),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  association?.tradingName ?? 'Minha associação',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (association != null)
                  Text(
                    association.type.label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Sair',
          icon: const Icon(Icons.logout),
          onPressed: _logout,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Associação ainda não aprovada, recusada ou suspensa
class _StatusView extends StatelessWidget {
  final Association association;
  final Future<void> Function() onRefresh;
  final VoidCallback onEdit;

  const _StatusView({required this.association, required this.onRefresh, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (icon, color, title, message) = switch (association.status) {
      AssociationStatus.PENDING_APPROVAL => (
          Icons.hourglass_top_rounded,
          AppColors.warningDarker,
          'Cadastro em análise',
          'Recebemos o cadastro de ${association.tradingName}. Nossa equipe está validando os dados e, '
              'assim que a associação for aprovada, você poderá cadastrar associados e gerar convites.',
        ),
      AssociationStatus.REJECTED => (
          Icons.error_outline_rounded,
          AppColors.errorDark,
          'Cadastro recusado',
          'O cadastro não foi aprovado. Confira o motivo abaixo, corrija os dados e reenvie para uma nova análise.',
        ),
      _ => (
          Icons.pause_circle_outline_rounded,
          AppColors.errorDark,
          'Associação suspensa',
          'A associação está suspensa na plataforma. Entre em contato com o suporte do OpenBag.',
        ),
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AppCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: color),
                const SizedBox(height: 16),
                Text(title, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center, style: textTheme.bodyLarge),
                if (association.rejectionReason != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Motivo: ${association.rejectionReason}', style: textTheme.bodyMedium),
                  ),
                ],
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    AppButton(
                      text: 'Atualizar status',
                      icon: Icons.refresh,
                      variant: ButtonVariant.outlined,
                      onPressed: onRefresh,
                    ),
                    if (association.status == AssociationStatus.REJECTED)
                      AppButton(text: 'Corrigir dados', icon: Icons.edit_outlined, onPressed: onEdit),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
