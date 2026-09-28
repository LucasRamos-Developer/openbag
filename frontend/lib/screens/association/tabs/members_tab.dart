import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/association/member.dart';
import '../../../services/api_client.dart';
import '../../../services/association_service.dart';
import '../../../utils/file_download.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/courier/vehicle_tile.dart';
import '../../../widgets/association/membership_status_chip.dart';
import '../member_form_screen.dart';

/// Lista de associados com filtro por status, busca e ações do gestor
class MembersTab extends StatefulWidget {
  final MembershipStatus? initialFilter;

  const MembersTab({super.key, this.initialFilter});

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  static const _filters = <SelectItem<MembershipStatus?>>[
    SelectItem(value: null, label: 'Todos'),
    SelectItem(value: MembershipStatus.PENDING, label: 'Pendentes'),
    SelectItem(value: MembershipStatus.ACTIVE, label: 'Ativos'),
    SelectItem(value: MembershipStatus.SUSPENDED, label: 'Suspensos'),
    SelectItem(value: MembershipStatus.REJECTED, label: 'Recusados'),
    SelectItem(value: MembershipStatus.REMOVED, label: 'Desligados'),
    SelectItem(value: MembershipStatus.LEFT, label: 'Saíram'),
  ];

  final _searchController = TextEditingController();
  Timer? _debounce;

  static final _vehicleFilters = <SelectItem<VehicleType?>>[
    const SelectItem(value: null, label: 'Todos'),
    for (final type in VehicleType.values) SelectItem(value: type, label: type.label, icon: type.icon),
  ];

  MembershipStatus? _filter;
  VehicleType? _vehicleFilter;
  MemberBillingFilter? _billingFilter;
  bool _exporting = false;
  final List<Member> _members = [];
  int _page = 0;
  bool _hasMore = false;
  int _total = 0;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final page = await context.read<AssociationService>().fetchMembers(
            status: _filter,
            vehicleType: _vehicleFilter,
            billing: _billingFilter,
            query: _searchController.text.trim(),
            page: reset ? 0 : _page + 1,
          );
      if (!mounted) return;
      setState(() {
        if (reset) _members.clear();
        _members.addAll(page.items);
        _page = page.page;
        _hasMore = page.hasMore;
        _total = page.totalElements;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(reset: true));
  }

  void _selectFilter(MembershipStatus? filter) {
    setState(() => _filter = filter);
    _load(reset: true);
  }

  void _selectVehicle(VehicleType? type) {
    setState(() => _vehicleFilter = type);
    _load(reset: true);
  }

  Future<void> _export() async {
    if (!canDownloadFiles) {
      AppToast.show(context, message: 'A exportação está disponível na versão web', type: ToastType.info);
      return;
    }
    setState(() => _exporting = true);
    try {
      final bytes = await context.read<AssociationService>().exportMembers(
            status: _filter,
            vehicleType: _vehicleFilter,
            billing: _billingFilter,
            query: _searchController.text.trim(),
          );
      final today = DateTime.now();
      downloadBytes(bytes,
          fileName: 'associados-${today.year}-${_two(today.month)}-${_two(today.day)}.csv', mimeType: 'text/csv');
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  Future<void> _openCreateForm() async {
    final created = await Navigator.of(context).push<Member>(
      MaterialPageRoute(builder: (_) => const MemberFormScreen()),
    );
    if (created != null && mounted) {
      AppToast.show(context, message: '${created.fullName} cadastrado como associado', type: ToastType.success);
      _load(reset: true);
    }
  }

  Future<void> _openDetails(Member member) async {
    final changed = await showAppAdaptive<bool>(
      context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AssociationService>(),
        child: _MemberDetailsSheet(member: member),
      ),
    );
    if (changed == true && mounted) _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    // Os blocos já têm 24 de margem lateral: a largura máxima soma as duas margens
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth + 48),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final compact = AppLayout.isCompact(context);
    final gutter = compact ? 16.0 : 24.0;
    final exportButton = compact
        ? IconButton(
            tooltip: 'Exportar planilha',
            onPressed: _exporting ? null : _export,
            icon: _exporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.file_download_outlined),
          )
        : AppButton(
            text: 'Exportar',
            icon: Icons.file_download_outlined,
            variant: ButtonVariant.outlined,
            isLoading: _exporting,
            onPressed: _export,
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      // No celular o cadastro fica no botão flutuante, ao alcance do polegar
      floatingActionButton: compact
          ? FloatingActionButton.extended(
              onPressed: _openCreateForm,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Cadastrar'),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, compact ? 16 : 24, gutter, 0),
            child: AppSectionHeader(
              title: 'Associados',
              subtitle: _isLoading && _members.isEmpty ? null : '$_total encontrado(s)',
              action: compact
                  ? exportButton
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        exportButton,
                        const SizedBox(width: 12),
                        AppButton(
                          text: 'Cadastrar',
                          icon: Icons.person_add_alt_1_outlined,
                          onPressed: _openCreateForm,
                        ),
                      ],
                    ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: AppTextField(
              controller: _searchController,
              hintText: 'Buscar por nome, email ou CPF',
              prefixIcon: const Icon(Icons.search),
              variant: TextFieldVariant.filled,
              size: TextFieldSize.small,
              onChanged: _onSearchChanged,
            ),
          ),
          AppFilterChips<MembershipStatus?>(
            items: _filters,
            value: _filter,
            onSelected: _selectFilter,
            padding: EdgeInsets.symmetric(horizontal: gutter, vertical: 10),
            leading: [
              AppDropdownChip<MemberBillingFilter?>(
                label: 'Mensalidade',
                items: [
                  const SelectItem(value: null, label: 'Todas'),
                  for (final f in MemberBillingFilter.values) SelectItem(value: f, label: f.label),
                ],
                value: _billingFilter,
                onSelected: (f) {
                  setState(() => _billingFilter = f);
                  _load(reset: true);
                },
              ),
              AppDropdownChip<VehicleType?>(
                label: 'Veículo',
                items: _vehicleFilters,
                value: _vehicleFilter,
                onSelected: _selectVehicle,
              ),
            ],
          ),
          Expanded(child: _buildList(gutter, compact)),
        ],
      ),
    );
  }

  Widget _buildList(double gutter, bool compact) {
    if (_error != null && _members.isEmpty) {
      return AppEmptyState(
        icon: Icons.cloud_off_outlined,
        message: _error!,
        actionLabel: 'Tentar novamente',
        onAction: () => _load(reset: true),
      );
    }
    if (_members.isEmpty) {
      return _isLoading
          ? const Center(child: CircularProgressIndicator())
          : AppEmptyState(
              icon: Icons.groups_outlined,
              message: _filter == MembershipStatus.PENDING
                  ? 'Nenhuma solicitação aguardando aprovação.'
                  : 'Nenhum associado encontrado.',
            );
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        // No celular sobra espaço no fim para o botão flutuante não cobrir o último item
        padding: EdgeInsets.fromLTRB(gutter, 0, gutter, compact ? 96 : 24),
        itemCount: _members.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == _members.length) {
            return Center(
              child: AppButton(
                text: 'Carregar mais',
                variant: ButtonVariant.text,
                isLoading: _isLoading,
                onPressed: () => _load(),
              ),
            );
          }
          final member = _members[index];
          return _MemberTile(member: member, onTap: () => _openDetails(member));
        },
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Member member;
  final VoidCallback onTap;

  const _MemberTile({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppListTileCard(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
        child: Text(
          member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
        ),
      ),
      title: member.memberNumber != null ? '${member.fullName} · nº ${member.memberNumber}' : member.fullName,
      subtitle: member.openInvoices > 0
          ? '${formatMoney(member.openAmount)} em aberto · ${member.vehicleSummary}'
          : member.vehicleSummary,
      trailing: MembershipStatusChip(status: member.status),
    );
  }
}

/// Detalhes do associado com as ações permitidas para o status atual
class _MemberDetailsSheet extends StatefulWidget {
  final Member member;

  const _MemberDetailsSheet({required this.member});

  @override
  State<_MemberDetailsSheet> createState() => _MemberDetailsSheetState();
}

class _MemberDetailsSheetState extends State<_MemberDetailsSheet> {
  late Member _member;
  MemberAction? _running;
  bool _changed = false;

  bool _loadingDetails = true;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    _loadDetails();
  }

  /// A listagem não traz os veículos: busca a ficha completa
  Future<void> _loadDetails() async {
    try {
      final member = await context.read<AssociationService>().fetchMember(_member.membershipId);
      if (mounted) setState(() => _member = member);
    } on ApiException catch (_) {
      // Sem a ficha completa, mostra o que veio da listagem
    } finally {
      if (mounted) setState(() => _loadingDetails = false);
    }
  }

  Future<void> _run(MemberAction action) async {
    String? reason;
    if (action.asksReason) {
      reason = await AppDialog.reason(
        context,
        title: '${action.label} ${_member.fullName}?',
        confirmLabel: action.label,
        message: switch (action) {
          MemberAction.suspend => 'O entregador fica impedido de receber entregas até ser reativado.',
          MemberAction.remove =>
            'O vínculo é encerrado. Para voltar, o entregador precisará de uma nova solicitação ou convite.',
          _ => null,
        },
      );
      if (reason == null) return;
    } else {
      final confirmed = await AppDialog.confirm(
        context,
        title: '${action.label} ${_member.fullName}?',
        message: action == MemberAction.approve
            ? 'O entregador passa a ser associado ativo e poderá receber entregas.'
            : 'O entregador volta a ficar ativo e poderá receber entregas.',
        confirmLabel: action.label,
      );
      if (!confirmed) return;
    }

    if (!mounted) return;
    setState(() => _running = action);
    try {
      final updated = await context.read<AssociationService>().memberAction(
            _member.membershipId,
            action,
            reason: reason,
          );
      if (!mounted) return;
      setState(() {
        _member = updated;
        _changed = true;
      });
      AppToast.show(context, message: 'Status atualizado: ${updated.status.label}', type: ToastType.success);
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _running = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final actions = MemberAction.availableFor(_member.status);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: AppAdaptiveSheet(
        title: _member.fullName,
        subtitle: _member.memberNumber != null ? 'Associado nº ${_member.memberNumber}' : null,
        onClose: () => Navigator.of(context).pop(_changed),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(alignment: Alignment.centerLeft, child: MembershipStatusChip(status: _member.status)),
            const SizedBox(height: 12),
            _info('Email', _member.email),
            _info('Telefone', _member.phoneNumber),
            _info('CPF', _member.formattedDocument),
            _info('CNH', _member.driverLicense ?? '-'),
            _info('Entregas', '${_member.totalDeliveries}'),
            _info(
              'Mensalidade',
              _member.openInvoices == 0
                  ? 'Em dia'
                  : '${_member.openInvoices} ${_member.openInvoices == 1 ? 'fatura' : 'faturas'} em aberto · '
                      '${formatMoney(_member.openAmount)}',
            ),
            _info('Origem', _member.origin.label),
            _info('Solicitado em', formatDateTime(_member.requestedAt)),
            if (_member.decidedAt != null) _info('Última decisão', formatDateTime(_member.decidedAt)),
            if (_member.endedAt != null) _info('Encerrado em', formatDateTime(_member.endedAt)),
            if (_member.reason != null) _info('Motivo', _member.reason!),
            const SizedBox(height: 20),
            Text('Veículos', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (_loadingDetails)
              const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
            else if (_member.vehicles.isEmpty)
              Text(_member.vehicleSummary, style: textTheme.bodyMedium)
            else
              for (final vehicle in _member.vehicles)
                Padding(padding: const EdgeInsets.only(bottom: 8), child: VehicleTile(vehicle: vehicle)),
          ],
        ),
        actions: [
          for (final action in actions)
            AppButton(
              text: action.label,
              isLoading: _running == action,
              onPressed: _running != null ? null : () => _run(action),
              variant: action == MemberAction.approve || action == MemberAction.reactivate
                  ? ButtonVariant.contained
                  : ButtonVariant.outlined,
              backgroundColor:
                  action == MemberAction.remove || action == MemberAction.reject ? AppColors.errorDark : null,
            ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6))),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
