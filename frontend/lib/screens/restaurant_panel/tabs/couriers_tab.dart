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
import '../../../widgets/partnership/partnership_card.dart';
import '../../../widgets/partnership/rate_proposal_dialog.dart';
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

  Future<void> _update({CourierPolicy? policy, bool? fallback, bool? covers, bool? passes, int? noShowMinutes}) async {
    final service = context.read<RestaurantDeliveryService>();
    final current = service.settings!;
    setState(() => _saving = true);
    await runWithFeedback(
      context,
      () => service.updateSettings(
        policy: policy ?? current.courierPolicy,
        fallbackToOpen: fallback ?? current.fallbackToOpen,
        coversDeliveryDifference: covers ?? current.coversDeliveryDifference,
        passesDeliveryFee: passes,
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

  Future<void> _setPassesFee(RestaurantDeliverySettings settings, bool passes) async {
    if (passes == settings.passesDeliveryFee) return;
    if (passes) {
      final from = settings.deliveryFeeFrom;
      final confirmed = await AppDialog.confirm(
        context,
        title: 'Repassar a taxa ao cliente?',
        message: 'O cliente passa a pagar a entrega pela distância, pela maior tabela das associações que atendem '
            'a loja${from != null ? ' (a partir de ${formatMoney(from)})' : ''}. O entregador recebe o valor inteiro '
            'e a sua taxa fixa deixa de ser cobrada.',
        confirmLabel: 'Repassar ao cliente',
      );
      if (!confirmed) return;
    }
    await _update(passes: passes);
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
          subtitle: 'Os fixos em check-in na loja sempre recebem primeiro.',
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
        const SizedBox(height: 24),
        const AppSectionHeader(
          title: 'Taxa de entrega para o cliente',
          subtitle: 'Todo o valor da entrega vai para o entregador.',
        ),
        AppChoiceTile(
          leading: const Icon(Icons.storefront_outlined),
          title: 'Taxa fixa da loja',
          subtitle: 'O cliente paga ${formatDeliveryFee(settings.deliveryFee)} em qualquer distância '
              '(valor em Loja › Entrega). Se a tabela do entregador passar dela, você pode assumir a diferença.',
          selected: !settings.passesDeliveryFee,
          enabled: !_saving,
          onTap: () => _setPassesFee(settings, false),
        ),
        const SizedBox(height: 8),
        AppChoiceTile(
          leading: const Icon(Icons.route_outlined),
          title: 'Repassar ao cliente',
          subtitle: 'O cliente paga pela distância, pela maior tabela das associações. Na vitrine aparece '
              '"a partir de${settings.deliveryFeeFrom != null ? ' ${formatMoney(settings.deliveryFeeFrom!)}' : ''}".',
          selected: settings.passesDeliveryFee,
          enabled: !_saving,
          onTap: () => _setPassesFee(settings, true),
        ),
        if (settings.passesDeliveryFee && settings.deliveryFeeSimulation.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Quanto o cliente paga', style: textTheme.labelLarge),
          const SizedBox(height: 8),
          AppKeyValueList(rows: [
            for (final sample in settings.deliveryFeeSimulation)
              ('Entrega a ${formatDistance(sample.distanceKm)}', formatMoney(sample.fee)),
          ]),
        ],
        if (!settings.passesDeliveryFee) ...[
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
        ],
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
  static const _viewer = PartnershipSide.RESTAURANT;

  final RestaurantDeliverySettings settings;

  const _PartnersSection({required this.settings});

  Future<void> _request(BuildContext context) async {
    final service = context.read<RestaurantDeliveryService>();
    final chosen = await showDialog<AssociationSummary>(
      context: context,
      builder: (_) => _PartnerPickerDialog(
        service: service,
        excluded: {
          for (final p in [...settings.partners, ...settings.partnershipRequests]) p.organizationId,
        },
        deliveryFee: settings.customerFeeToCompare,
      ),
    );
    if (chosen == null || !context.mounted) return;
    await runWithFeedback(context, () => service.addPartner(chosen.id));
    if (!context.mounted) return;
    // Se a associação já tinha convidado, a parceria começa na hora
    final active = service.settings?.partners.any((p) => p.organizationId == chosen.id) ?? false;
    AppToast.show(
      context,
      message: active ? '${chosen.tradingName} agora é parceira' : 'Pedido enviado a ${chosen.tradingName}',
      type: ToastType.success,
    );
  }

  Future<void> _action(BuildContext context, Partner partner, String action) async {
    final service = context.read<RestaurantDeliveryService>();
    if (action == PartnershipAction.end) {
      final confirmed = await AppDialog.confirm(
        context,
        title: partner.isPending ? 'Cancelar pedido?' : 'Encerrar parceria?',
        message: partner.isPending
            ? 'O pedido de parceria para ${partner.name} será cancelado.'
            : 'Com a política "só parceiras", os entregadores de ${partner.name} deixam de receber seus pedidos. '
                'A tabela especial combinada deixa de valer.',
        confirmLabel: partner.isPending ? 'Cancelar pedido' : 'Encerrar',
      );
      if (!confirmed || !context.mounted) return;
    }
    await runWithFeedback(context, () => service.partnershipAction(partner.id, action), success: switch (action) {
      PartnershipAction.accept => '${partner.name} agora é parceira',
      PartnershipAction.end => partner.isPending ? 'Pedido cancelado' : 'Parceria encerrada',
      PartnershipAction.rateAccept => 'Tabela especial combinada',
      _ => null,
    });
  }

  Future<void> _proposeRate(BuildContext context, Partner partner) async {
    final service = context.read<RestaurantDeliveryService>();
    final choice = await showRateProposalDialog(
      context,
      counterpart: 'a associação',
      current: partner.proposalStart(_viewer),
      defaultRate: partner.deliveryRate,
      hasAgreedRate: partner.canProposeDefault,
      customerFee: settings.customerFeeToCompare,
      title: partner.awaits(_viewer) ? 'Contraproposta' : 'Propor tabela especial',
    );
    if (choice == null || !context.mounted) return;
    await runWithFeedback(context, () => service.proposeRate(partner.id, choice.rate),
        success: 'Proposta enviada a ${partner.name}');
  }

  Widget _card(BuildContext context, Partner partner) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: PartnershipCard(
          partnership: partner,
          viewer: _viewer,
          leading: AssociationLogo(logoUrl: partner.logoUrl, name: partner.name, size: 44),
          title: partner.name,
          subtitle: partner.location,
          defaultRate: partner.deliveryRate,
          customerFee: settings.customerFeeToCompare,
          onAction: (action) => _action(context, partner, action),
          onProposeRate: () => _proposeRate(context, partner),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final requests = [...settings.partnershipRequests]
      ..sort((a, b) => (a.requestedBy == _viewer ? 1 : 0) - (b.requestedBy == _viewer ? 1 : 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: 'Associações parceiras',
          subtitle: 'Usadas com a política "só associações parceiras". A parceria começa quando a associação aceita, '
              'e vocês podem combinar uma tabela especial para a sua loja.',
          action: AppButton(
            text: 'Pedir parceria',
            icon: Icons.add,
            variant: ButtonVariant.outlined,
            onPressed: () => _request(context),
          ),
        ),
        if (settings.partnersEndedNoticeAt != null) ...[
          AppCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: AppColors.warningLighter.withValues(alpha: 0.4),
            child: Text(
              'Em ${formatDateTime(settings.partnersEndedNoticeAt)} a última associação parceira encerrou a parceria. '
              'Para a loja não ficar sem entregador, seus pedidos passaram a ir para qualquer entregador. '
              'Escolha acima quem recebe os pedidos para confirmar.',
              style: textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (settings.partners.isEmpty && requests.isEmpty)
          Text('Nenhuma parceira ainda.', style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        for (final partner in requests) _card(context, partner),
        for (final partner in settings.partners) _card(context, partner),
        if (settings.partnershipHistory.isNotEmpty)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Histórico (${settings.partnershipHistory.length})', style: textTheme.titleSmall),
            children: [for (final partner in settings.partnershipHistory) _card(context, partner)],
          ),
      ],
    );
  }
}

class _PartnerPickerDialog extends StatefulWidget {
  final RestaurantDeliveryService service;
  final Set<int> excluded;
  /// Taxa do cliente para comparar com a tabela (nula = a loja repassa a taxa e nada passa dela)
  final double? deliveryFee;

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
      title: const Text('Pedir parceria a uma associação'),
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
                final fee = widget.deliveryFee;
                final exceeds = fee != null && a.deliveryRate.configured && (a.deliveryRate.baseFee ?? 0) > fee;
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
