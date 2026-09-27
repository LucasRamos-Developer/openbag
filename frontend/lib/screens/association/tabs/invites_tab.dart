import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/association/invite.dart';
import '../../../services/api_client.dart';
import '../../../services/association_service.dart';
import '../../../utils/formatters.dart';

/// Códigos de convite: o entregador que se cadastra com um código válido entra direto como associado ativo
class InvitesTab extends StatefulWidget {
  const InvitesTab({super.key});

  @override
  State<InvitesTab> createState() => _InvitesTabState();
}

class _InvitesTabState extends State<InvitesTab> {
  List<Invite>? _invites;
  String? _error;
  bool _isCreating = false;

  int _expiresInDays = 7;
  int? _maxUses = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final invites = await context.read<AssociationService>().fetchInvites();
      if (mounted) {
        setState(() {
          _invites = invites;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _create() async {
    setState(() => _isCreating = true);
    try {
      final invite = await context.read<AssociationService>().createInvite(
            expiresInDays: _expiresInDays,
            maxUses: _maxUses,
          );
      if (!mounted) return;
      setState(() => _invites = [invite, ...?_invites]);
      _copy(invite.code);
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _revoke(Invite invite) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Revogar convite ${invite.code}?',
      message: 'O código deixa de funcionar imediatamente. Quem já entrou com ele continua associado.',
      confirmLabel: 'Revogar',
    );
    if (!confirmed || !mounted) return;

    try {
      final updated = await context.read<AssociationService>().revokeInvite(invite.id);
      if (!mounted) return;
      setState(() => _invites = [for (final i in _invites!) i.id == updated.id ? updated : i]);
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, message: e.message, type: ToastType.error);
    }
  }

  Future<void> _copy(String code) async {
    try {
      await Clipboard.setData(ClipboardData(text: code));
      if (mounted) AppToast.show(context, message: 'Código $code copiado', type: ToastType.success);
    } catch (_) {
      // Navegador sem permissão de área de transferência: o código continua selecionável na lista
      if (mounted) AppToast.show(context, message: 'Código gerado: $code', type: ToastType.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: AppPageListView(
        children: [
          const AppSectionHeader(
            title: 'Convites',
            subtitle: 'Envie o código ao entregador. Ao se cadastrar com ele, o entregador entra direto como associado, sem precisar de aprovação.',
          ),
          _buildCreateCard(),
          const SizedBox(height: 24),
          ..._buildInviteList(),
        ],
      ),
    );
  }

  Widget _buildCreateCard() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      borderColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
      borderWidth: 1,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          SizedBox(
            width: 200,
            child: AppSelect<int>(
              labelText: 'Validade',
              variant: TextFieldVariant.filled,
              value: _expiresInDays,
              items: const [
                SelectItem(value: 1, label: '1 dia'),
                SelectItem(value: 7, label: '7 dias'),
                SelectItem(value: 30, label: '30 dias'),
                SelectItem(value: 90, label: '90 dias'),
              ],
              onChanged: (value) => setState(() => _expiresInDays = value ?? 7),
            ),
          ),
          SizedBox(
            width: 200,
            child: AppSelect<int>(
              labelText: 'Limite de usos',
              variant: TextFieldVariant.filled,
              value: _maxUses ?? 0,
              items: const [
                SelectItem(value: 1, label: '1 entregador'),
                SelectItem(value: 10, label: 'Até 10'),
                SelectItem(value: 50, label: 'Até 50'),
                SelectItem(value: 0, label: 'Sem limite'),
              ],
              onChanged: (value) => setState(() => _maxUses = (value == null || value == 0) ? null : value),
            ),
          ),
          AppButton(
            text: 'Gerar código',
            icon: Icons.add,
            size: ButtonSize.large,
            isLoading: _isCreating,
            onPressed: _isCreating ? null : _create,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInviteList() {
    if (_error != null && _invites == null) {
      return [AppEmptyState(icon: Icons.cloud_off_outlined, message: _error!, actionLabel: 'Tentar novamente', onAction: _load)];
    }
    if (_invites == null) {
      return [const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))];
    }
    if (_invites!.isEmpty) {
      return [const AppEmptyState(icon: Icons.confirmation_number_outlined, message: 'Nenhum convite gerado ainda.')];
    }

    final colorScheme = Theme.of(context).colorScheme;
    return [
      for (final invite in _invites!)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderColor: colorScheme.outline.withValues(alpha: 0.15),
            borderWidth: 1,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        invite.code,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: invite.usable ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${invite.statusLabel} · ${invite.usesLabel} · expira em ${formatDateTime(invite.expiresAt)}',
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
                if (invite.usable) ...[
                  IconButton(
                    tooltip: 'Copiar código',
                    icon: const Icon(Icons.copy_outlined),
                    onPressed: () => _copy(invite.code),
                  ),
                  IconButton(
                    tooltip: 'Revogar',
                    icon: const Icon(Icons.block_outlined),
                    color: AppColors.errorDark,
                    onPressed: () => _revoke(invite),
                  ),
                ],
              ],
            ),
          ),
        ),
    ];
  }
}
