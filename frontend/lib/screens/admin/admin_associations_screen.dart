import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/association/association.dart';
import '../../services/admin_association_service.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/association/association_logo.dart';
import '../../widgets/association/association_status_chip.dart';

/// Moderação de associações pelo ADMIN: aprovar, recusar (com motivo) e suspender
class AdminAssociationsScreen extends StatefulWidget {
  const AdminAssociationsScreen({super.key});

  @override
  State<AdminAssociationsScreen> createState() => _AdminAssociationsScreenState();
}

class _AdminAssociationsScreenState extends State<AdminAssociationsScreen> {
  late final AdminAssociationService _service;
  AssociationStatus? _filter = AssociationStatus.PENDING_APPROVAL;
  List<Association>? _associations;
  String? _error;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _service = AdminAssociationService(context.read<AuthService>().apiClient);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _associations = null;
      _error = null;
    });
    try {
      final list = await _service.fetchAssociations(status: _filter);
      if (mounted) setState(() => _associations = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _act(Association association, Future<Association> Function() action, String success) async {
    setState(() => _busyId = association.id);
    try {
      await action();
      if (!mounted) return;
      AppToast.show(context, message: success, type: ToastType.success);
      await _load();
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _approve(Association a) async {
    final ok = await AppDialog.confirm(
      context,
      title: 'Aprovar ${a.tradingName}?',
      message: 'A associação poderá cadastrar associados e gerar convites.',
      confirmLabel: 'Aprovar',
    );
    if (ok) await _act(a, () => _service.approve(a.id), '${a.tradingName} aprovada');
  }

  Future<void> _reject(Association a) async {
    final reason = await AppDialog.reason(
      context,
      title: 'Recusar ${a.tradingName}?',
      message: 'O motivo fica visível para o gestor, que pode corrigir os dados e reenviar.',
      confirmLabel: 'Recusar',
      required: true,
    );
    if (reason != null) await _act(a, () => _service.reject(a.id, reason), '${a.tradingName} recusada');
  }

  Future<void> _suspend(Association a) async {
    final reason = await AppDialog.reason(context, title: 'Suspender ${a.tradingName}?', confirmLabel: 'Suspender');
    if (reason != null) {
      await _act(a, () => _service.suspend(a.id, reason: reason.isEmpty ? null : reason), '${a.tradingName} suspensa');
    }
  }

  Future<void> _logout() async {
    await context.read<AuthService>().logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Associações'),
        actions: [
          IconButton(tooltip: 'Sair', icon: const Icon(Icons.logout), onPressed: _logout),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppFilterChips<AssociationStatus?>(
                items: [
                  const SelectItem(value: null, label: 'Todas'),
                  for (final status in AssociationStatus.values) SelectItem(value: status, label: status.label),
                ],
                value: _filter,
                onSelected: (status) {
                  setState(() => _filter = status);
                  _load();
                },
              ),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_error != null) {
      return AppEmptyState(
          icon: Icons.cloud_off_outlined, message: _error!, actionLabel: 'Tentar novamente', onAction: _load);
    }
    if (_associations == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_associations!.isEmpty) {
      return AppEmptyState(
        icon: Icons.inbox_outlined,
        message: _filter == AssociationStatus.PENDING_APPROVAL
            ? 'Nenhuma associação aguardando aprovação.'
            : 'Nenhuma associação encontrada.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        itemCount: _associations!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildCard(_associations![index]),
      ),
    );
  }

  Widget _buildCard(Association a) {
    final colorScheme = Theme.of(context).colorScheme;
    final muted = TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6));
    final busy = _busyId == a.id;

    return AppCard(
      padding: const EdgeInsets.all(20),
      borderColor: colorScheme.outline.withValues(alpha: 0.15),
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AssociationLogo(logoUrl: a.logoUrl, name: a.tradingName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.tradingName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    Text('${a.type.label} · ${a.companyName}', style: muted),
                  ],
                ),
              ),
              AssociationStatusChip(status: a.status),
            ],
          ),
          const SizedBox(height: 12),
          Text('CNPJ ${a.formattedCnpj} · cadastro em ${formatDate(a.createdAt)}', style: muted),
          if (a.address != null) Text(a.address!.summary, style: muted),
          if (a.manager != null) Text('Gestor: ${a.manager!.fullName} (${a.manager!.email})', style: muted),
          if (a.description != null && a.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(a.description!),
          ],
          if (a.rejectionReason != null) ...[
            const SizedBox(height: 8),
            Text('Motivo: ${a.rejectionReason}', style: const TextStyle(color: AppColors.errorDark)),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (a.status == AssociationStatus.PENDING_APPROVAL)
                  AppButton(
                    text: 'Recusar',
                    variant: ButtonVariant.outlined,
                    backgroundColor: AppColors.errorDark,
                    onPressed: busy ? null : () => _reject(a),
                  ),
                if (a.status == AssociationStatus.ACTIVE)
                  AppButton(
                    text: 'Suspender',
                    variant: ButtonVariant.outlined,
                    backgroundColor: AppColors.errorDark,
                    onPressed: busy ? null : () => _suspend(a),
                  ),
                if (a.status != AssociationStatus.ACTIVE)
                  AppButton(
                    text: a.status == AssociationStatus.PENDING_APPROVAL ? 'Aprovar' : 'Reativar',
                    isLoading: busy,
                    onPressed: busy ? null : () => _approve(a),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
