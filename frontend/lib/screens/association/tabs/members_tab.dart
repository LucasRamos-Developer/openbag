import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/association/member.dart';
import '../../../services/api_client.dart';
import '../../../services/association_service.dart';
import '../../../utils/formatters.dart';
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

  MembershipStatus? _filter;
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
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AssociationService>(),
        child: _MemberDetailsSheet(member: member),
      ),
    );
    if (changed == true && mounted) _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: AppSectionHeader(
            title: 'Associados',
            subtitle: _isLoading && _members.isEmpty ? null : '$_total encontrado(s)',
            action: AppButton(
              text: 'Cadastrar',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: _openCreateForm,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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
        ),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildList() {
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
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderColor: colorScheme.outline.withValues(alpha: 0.15),
      borderWidth: 1,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
            child: Text(
              member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
              style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.memberNumber != null ? '${member.fullName} · nº ${member.memberNumber}' : member.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  member.vehicleSummary,
                  style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          MembershipStatusChip(status: member.status),
        ],
      ),
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

  @override
  void initState() {
    super.initState();
    _member = widget.member;
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
          MemberAction.remove => 'O vínculo é encerrado. Para voltar, o entregador precisará de uma nova solicitação ou convite.',
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
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(_member.fullName, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  MembershipStatusChip(status: _member.status),
                ],
              ),
              const SizedBox(height: 16),
              _info('Matrícula', _member.memberNumber != null ? 'nº ${_member.memberNumber}' : '-'),
              _info('Email', _member.email),
              _info('Telefone', _member.phoneNumber),
              _info('CPF', _member.formattedDocument),
              _info('CNH', _member.driverLicense ?? '-'),
              _info('Veículo', _member.vehicleSummary),
              _info('Entregas', '${_member.totalDeliveries}'),
              _info('Origem', _member.origin.label),
              _info('Solicitado em', formatDateTime(_member.requestedAt)),
              if (_member.decidedAt != null) _info('Última decisão', formatDateTime(_member.decidedAt)),
              if (_member.endedAt != null) _info('Encerrado em', formatDateTime(_member.endedAt)),
              if (_member.reason != null) _info('Motivo', _member.reason!),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  children: [
                    for (final action in actions)
                      AppButton(
                        text: action.label,
                        isLoading: _running == action,
                        onPressed: _running != null ? null : () => _run(action),
                        variant: action == MemberAction.approve || action == MemberAction.reactivate
                            ? ButtonVariant.contained
                            : ButtonVariant.outlined,
                        backgroundColor: action == MemberAction.remove || action == MemberAction.reject
                            ? AppColors.errorDark
                            : null,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
            width: 130,
            child: Text(label, style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6))),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
