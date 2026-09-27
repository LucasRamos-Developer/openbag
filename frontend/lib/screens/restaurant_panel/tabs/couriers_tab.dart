import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/association/association_summary.dart';
import '../../../models/delivery/courier_link.dart';
import '../../../models/delivery/restaurant_delivery_settings.dart';
import '../../../services/api_client.dart';
import '../../../services/restaurant_delivery_service.dart';
import '../../../services/restaurant_panel_service.dart';
import '../../../utils/feedback.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/association/association_logo.dart';
import '../../../widgets/courier/courier_avatar.dart';
import '../../../widgets/delivery/courier_link_status_chip.dart';
import '../../../widgets/delivery/delivery_rate_summary.dart';
import 'couriers/staff_section.dart';

/// Entregadores do restaurante: quem recebe os pedidos, associações parceiras, fixos e equipe própria
class CouriersTab extends StatefulWidget {
  const CouriersTab({super.key});

  @override
  State<CouriersTab> createState() => _CouriersTabState();
}

class _CouriersTabState extends State<CouriersTab> {
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final id = context.read<RestaurantPanelService>().selectedId;
    final service = context.read<RestaurantDeliveryService>()..clear();
    if (id != null) WidgetsBinding.instance.addPostFrameCallback((_) => service.load(id));
  }

  Future<void> _update({CourierPolicy? policy, bool? fallback, bool? covers, int? noShowMinutes}) async {
    final service = context.read<RestaurantDeliveryService>();
    final current = service.settings!;
    setState(() => _saving = true);
    await runWithFeedback(
      context,
      () => service.updateSettings(
        policy: policy ?? current.courierPolicy,
        fallbackToOpen: fallback ?? current.fallbackToOpen,
        coversDeliveryDifference: covers ?? current.coversDeliveryDifference,
        courierNoShowMinutes: noShowMinutes,
      ),
      success: 'Regras de entrega atualizadas',
    );
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _toggleCovers(bool value) async {
    if (value) {
      final confirmed = await AppDialog.confirm(
        context,
        title: 'Assumir a diferença?',
        message: 'Quando o valor da tabela da associação do entregador for maior que a sua taxa de entrega, '
            'o restaurante paga a diferença ao entregador. Ela aparece em cada pedido como subsídio de entrega.',
        confirmLabel: 'Assumir a diferença',
      );
      if (!confirmed) return;
    }
    await _update(covers: value);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RestaurantDeliveryService>();
    final settings = service.settings;

    if (settings == null) {
      return service.error != null
          ? AppEmptyState(
              icon: Icons.cloud_off_outlined,
              message: service.error!,
              actionLabel: 'Tentar novamente',
              onAction: () => service.load(context.read<RestaurantPanelService>().selectedId!),
            )
          : const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => service.load(context.read<RestaurantPanelService>().selectedId!),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _policySection(settings),
                  const SizedBox(height: 32),
                  _PartnersSection(settings: settings),
                  const SizedBox(height: 32),
                  const _FixedCouriersSection(),
                  const SizedBox(height: 32),
                  const StaffSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _policySection(RestaurantDeliverySettings settings) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: 'Quem recebe seus pedidos',
          subtitle: 'Os fixos em check-in na loja sempre recebem primeiro. '
              'Sua taxa de entrega: ${formatMoney(settings.deliveryFee)}.',
        ),
        for (final policy in CourierPolicy.values) ...[
          AppChoiceTile(
            title: policy.label,
            subtitle: policy.description,
            selected: settings.courierPolicy == policy,
            enabled: !_saving,
            onTap: () => _update(policy: policy),
          ),
          const SizedBox(height: 8),
        ],
        if (settings.courierPolicy == CourierPolicy.FIXED_ONLY)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.fallbackToOpen,
            onChanged: _saving ? null : (value) => _update(fallback: value),
            title: const Text('Se nenhum fixo estiver disponível, liberar para qualquer entregador'),
          ),
        const Divider(height: 32),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: settings.coversDeliveryDifference,
          onChanged: _saving ? null : _toggleCovers,
          title: const Text('Assumo a diferença da tabela das associações'),
          subtitle: Text(
            settings.coversDeliveryDifference
                ? 'Quando a tabela da associação passar da sua taxa, o restaurante paga a diferença ao entregador.'
                : 'Pedidos em que a tabela da associação passa da sua taxa não são oferecidos a esses entregadores.',
            style: textTheme.bodySmall,
          ),
        ),
        const Divider(height: 32),
        Text(
          'Entregador livre que não aparece na loja pode ser trocado depois do tempo abaixo. '
          'Fixos e equipe da loja podem ser trocados a qualquer momento antes da retirada.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        AppSelect<int>(
          labelText: 'Trocar entregador livre depois de',
          variant: TextFieldVariant.filled,
          enabled: !_saving,
          value: settings.courierNoShowMinutes,
          items: [
            for (final m in {5, 8, 10, 15, 20, 30, settings.courierNoShowMinutes}.toList()..sort())
              SelectItem(value: m, label: '$m minutos'),
          ],
          onChanged: (v) {
            if (v != null && v != settings.courierNoShowMinutes) _update(noShowMinutes: v);
          },
        ),
      ],
    );
  }
}

// ============= Parceiras =============

class _PartnersSection extends StatelessWidget {
  final RestaurantDeliverySettings settings;

  const _PartnersSection({required this.settings});

  Future<void> _add(BuildContext context) async {
    final service = context.read<RestaurantDeliveryService>();
    final chosen = await showDialog<AssociationSummary>(
      context: context,
      builder: (_) => _PartnerPickerDialog(
        service: service,
        excluded: settings.partners.map((p) => p.organizationId).toSet(),
        deliveryFee: settings.deliveryFee,
      ),
    );
    if (chosen == null || !context.mounted) return;
    await runWithFeedback(context, () => service.addPartner(chosen.id), success: '${chosen.tradingName} agora é parceira');
  }

  Future<void> _remove(BuildContext context, Partner partner) async {
    final service = context.read<RestaurantDeliveryService>();
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Encerrar parceria?',
      message: 'Com a política "só parceiras", os entregadores de ${partner.name} deixam de receber seus pedidos.',
      confirmLabel: 'Encerrar',
    );
    if (!confirmed || !context.mounted) return;
    await runWithFeedback(context, () => service.removePartner(partner.organizationId), success: 'Parceria encerrada');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: 'Associações parceiras',
          subtitle: 'Usadas com a política "só associações parceiras".',
          action: AppButton(text: 'Adicionar', icon: Icons.add, variant: ButtonVariant.outlined, onPressed: () => _add(context)),
        ),
        if (settings.partners.isEmpty)
          Text('Nenhuma parceira ainda.', style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary))
        else
          for (final partner in settings.partners) ...[
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AssociationLogo(logoUrl: partner.logoUrl, name: partner.name, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(partner.name, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DeliveryRateSummary(rate: partner.deliveryRate, customerFee: settings.deliveryFee),
                      ],
                    ),
                  ),
                  IconButton(tooltip: 'Encerrar parceria', icon: const Icon(Icons.link_off), onPressed: () => _remove(context, partner)),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _PartnerPickerDialog extends StatefulWidget {
  final RestaurantDeliveryService service;
  final Set<int> excluded;
  final double deliveryFee;

  const _PartnerPickerDialog({required this.service, required this.excluded, required this.deliveryFee});

  @override
  State<_PartnerPickerDialog> createState() => _PartnerPickerDialogState();
}

class _PartnerPickerDialogState extends State<_PartnerPickerDialog> {
  late final Future<List<AssociationSummary>> _future = widget.service.fetchActiveAssociations();

  @override
  Widget build(BuildContext context) {
    final covers = widget.service.settings?.coversDeliveryDifference ?? false;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Adicionar associação parceira'),
      content: SizedBox(
        width: 560,
        child: FutureBuilder<List<AssociationSummary>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Text(error is ApiException ? error.message : 'Não foi possível carregar as associações');
            }
            if (!snapshot.hasData) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
            final list = snapshot.data!.where((a) => !widget.excluded.contains(a.id)).toList();
            if (list.isEmpty) return const Text('Não há outras associações disponíveis.');
            return ListView.separated(
              shrinkWrap: true,
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final a = list[index];
                final exceeds = a.deliveryRate.configured && (a.deliveryRate.baseFee ?? 0) > widget.deliveryFee;
                final blocked = !a.deliveryRate.configured || (exceeds && !covers);
                return AppCard(
                  padding: const EdgeInsets.all(12),
                  onTap: blocked ? null : () => Navigator.of(context).pop(a),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AssociationLogo(logoUrl: a.logoUrl, name: a.tradingName, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.tradingName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (a.location != null) Text(a.location!, style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 6),
                            DeliveryRateSummary(rate: a.deliveryRate, customerFee: widget.deliveryFee),
                            if (exceeds && !covers)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'O valor base passa da sua taxa. Marque "Assumo a diferença" para poder ter esta parceria.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warningDarker),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [AppButton(text: 'Fechar', variant: ButtonVariant.text, onPressed: () => Navigator.of(context).pop())],
    );
  }
}

// ============= Fixos =============

class _FixedCouriersSection extends StatelessWidget {
  const _FixedCouriersSection();

  Future<void> _invite(BuildContext context) async {
    final service = context.read<RestaurantDeliveryService>();
    final controller = TextEditingController();
    final link = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Convidar entregador fixo'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Cole o link do perfil público do entregador (o do QR code da placa de verificação). '
                  'Ele recebe o convite no painel e aceita.'),
              const SizedBox(height: 16),
              AppTextField(controller: controller, labelText: 'Link do perfil', hintText: '…/e/joao-silva-ab12', autofocus: true),
            ],
          ),
        ),
        actions: [
          AppButton(text: 'Cancelar', variant: ButtonVariant.text, onPressed: () => Navigator.of(context).pop()),
          AppButton(text: 'Convidar', icon: Icons.send, onPressed: () => Navigator.of(context).pop(controller.text.trim())),
        ],
      ),
    );
    controller.dispose();
    if (link == null || link.isEmpty || !context.mounted) return;
    await runWithFeedback(context, () => service.inviteCourier(link), success: 'Convite enviado');
  }

  Future<void> _action(BuildContext context, CourierLink link, String action) async {
    final service = context.read<RestaurantDeliveryService>();
    if (action == 'end') {
      final confirmed = await AppDialog.confirm(
        context,
        title: link.isPending ? 'Cancelar convite?' : 'Encerrar vínculo?',
        message: link.isPending
            ? 'O convite para ${link.courier.fullName} será cancelado.'
            : '${link.courier.fullName} deixa de ser fixo da loja${link.checkedIn ? ' e o check-in é encerrado' : ''}.',
        confirmLabel: link.isPending ? 'Cancelar convite' : 'Encerrar',
      );
      if (!confirmed || !context.mounted) return;
    }
    await runWithFeedback(context, () => service.linkAction(link, action));
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RestaurantDeliveryService>();
    final links = service.links;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: 'Entregadores fixos',
          subtitle: 'Fixos fazem check-in na loja e, durante o turno, só entregam para você.',
          action: AppButton(text: 'Convidar', icon: Icons.person_add_alt, variant: ButtonVariant.outlined, onPressed: () => _invite(context)),
        ),
        if (links.isEmpty)
          const AppEmptyState(
            icon: Icons.two_wheeler,
            message: 'Nenhum entregador fixo. O entregador pode pedir pelo painel dele, colando o link da sua loja, '
                'ou você convida pelo link do perfil dele.',
          )
        else
          for (final link in links) ...[
            _FixedCourierTile(link: link, onAction: (action) => _action(context, link, action)),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _FixedCourierTile extends StatelessWidget {
  final CourierLink link;
  final ValueChanged<String> onAction;

  const _FixedCourierTile({required this.link, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final courier = link.courier;
    final textTheme = Theme.of(context).textTheme;
    final awaitingMe = link.isPending && link.requestedBy == LinkRequester.COURIER;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CourierAvatar(photoUrl: courier.photoUrl, name: courier.fullName, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(courier.fullName, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    CourierLinkStatusChip(link: link, viewer: LinkRequester.RESTAURANT),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (courier.associationName != null) courier.associationName!,
                    if (courier.vehicle != null) '${courier.vehicle!.type.label} ${courier.vehicle!.plate ?? ''}'.trim(),
                    if (courier.phoneNumber != null) courier.phoneNumber!,
                  ].join(' · '),
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (awaitingMe) ...[
            AppButton(text: 'Recusar', variant: ButtonVariant.text, onPressed: () => onAction('reject')),
            const SizedBox(width: 4),
            AppButton(text: 'Aprovar', icon: Icons.check, onPressed: () => onAction('approve')),
          ] else
            IconButton(
              tooltip: link.isPending ? 'Cancelar convite' : 'Encerrar vínculo',
              icon: const Icon(Icons.link_off),
              onPressed: () => onAction('end'),
            ),
        ],
      ),
    );
  }
}
