import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/association/association.dart';
import '../../models/association/member.dart';
import '../../models/panel_profile.dart';
import '../../services/association_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/association/association_logo.dart';
import '../../widgets/navigation/panel_profiles.dart';
import '../../widgets/navigation/panel_routes.dart';
import 'association_section.dart';
import 'tabs/delivery_rate_tab.dart';
import 'tabs/invites_tab.dart';
import 'tabs/members_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/profile_tab.dart';

/// Painel do gestor da associação/cooperativa
///
/// Associação ativa: abas Visão geral, Associados, Convites e Dados.
/// Associação pendente/recusada/suspensa: tela de status (a recusada pode corrigir os dados e reenviar).
class AssociationPanelScreen extends StatefulWidget {
  final AssociationSection section;

  const AssociationPanelScreen({super.key, this.section = AssociationSection.overview});

  @override
  State<AssociationPanelScreen> createState() => _AssociationPanelScreenState();
}

class _AssociationPanelScreenState extends State<AssociationPanelScreen> {
  // Filtro aplicado ao abrir a aba de associados a partir da visão geral
  MembershipStatus? _membersFilter;
  bool _editingRejected = false;

  List<AppPanelDestination> _destinations(AssociationService service) => [
        for (final section in AssociationSection.values)
          section.destination(
            badge: switch (section) {
              AssociationSection.members => service.stats?.pendingRequests ?? 0,
              AssociationSection.deliveries => service.association?.deliveryRate.configured == false ? 1 : 0,
              _ => 0,
            },
          ),
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
    setState(() => _membersFilter = filter);
    context.go(AssociationSection.members.path);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AssociationService>();
    final association = service.association;

    if (association == null) {
      return AppPanelScaffold(
        header: _buildHeader(null),
        title: 'Minha associação',
        onDestinationSelected: (_) {},
        onLogout: _logout,
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
      return AppPanelScaffold(
        header: _buildHeader(association),
        title: association.status.label,
        onDestinationSelected: (_) {},
        onLogout: _logout,
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
      index: widget.section.index,
      children: [
        OverviewTab(onOpenMembers: _openMembers, onOpenInvites: () => context.go(AssociationSection.invites.path)),
        MembersTab(key: ValueKey(_membersFilter), initialFilter: _membersFilter),
        const InvitesTab(),
        const DeliveryRateTab(),
        const ProfileTab(),
      ],
    );

    return AppPanelScaffold(
      header: _buildHeader(association),
      onLogout: _logout,
      destinations: _destinations(service),
      selectedIndex: widget.section.index,
      onDestinationSelected: (index) => context.go(AssociationSection.values[index].path),
      body: body,
    );
  }

  Widget _buildHeader(Association? association) {
    final name = association?.tradingName ?? 'Minha associação';

    return AppPanelProfileHeader(
      avatar: AssociationLogo(logoUrl: association?.logoUrl, name: name, size: 40),
      title: name,
      subtitle: association?.type.label ?? PanelProfile.association.label,
      sections: [panelProfilesSection(context, current: PanelProfile.association)],
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
