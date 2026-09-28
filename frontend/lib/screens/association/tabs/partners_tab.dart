import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/association/association_partnership.dart';
import '../../../models/delivery/delivery_rate.dart';
import '../../../models/restaurant.dart';
import '../../../services/api_client.dart';
import '../../../services/association_service.dart';
import '../../../utils/feedback.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/delivery/delivery_rate_summary.dart';
import '../../../widgets/partnership/partnership_card.dart';
import '../../../widgets/partnership/rate_proposal_dialog.dart';
import '../../../widgets/restaurant/restaurant_logo.dart';

/// Lojas parceiras da associação: pedidos das lojas, parcerias ativas com a tabela que vale em cada uma,
/// convites enviados e histórico. A tabela especial (acordo) só muda com o aceite dos dois lados.
class PartnersTab extends StatefulWidget {
  const PartnersTab({super.key});

  @override
  State<PartnersTab> createState() => PartnersTabState();
}

class PartnersTabState extends State<PartnersTab> {
  static const _viewer = PartnershipSide.ASSOCIATION;

  List<AssociationPartnership>? _partnerships;
  String? _error;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    try {
      final list = await context.read<AssociationService>().fetchPartnerships();
      if (mounted) {
        setState(() {
          _partnerships = list;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _replace(AssociationPartnership updated) {
    setState(() {
      final list = _partnerships ?? [];
      final index = list.indexWhere((p) => p.id == updated.id);
      _partnerships = index < 0 ? [updated, ...list] : ([...list]..[index] = updated);
    });
  }

  Future<void> _action(AssociationPartnership p, String action) async {
    if (action == PartnershipAction.end) {
      final confirmed = await AppDialog.confirm(
        context,
        title: p.isPending ? 'Cancelar convite?' : 'Encerrar parceria?',
        message: p.isPending
            ? 'O convite para ${p.restaurantName} será cancelado.'
            : 'A parceria com ${p.restaurantName} termina e a tabela especial deixa de valer. '
                'Se a loja recebe pedidos só de parceiras, ela passa a receber de qualquer entregador.',
        confirmLabel: p.isPending ? 'Cancelar convite' : 'Encerrar',
      );
      if (!confirmed || !mounted) return;
    }
    final service = context.read<AssociationService>();
    await runWithFeedback(context, () async => _replace(await service.partnershipAction(p.id, action)),
        success: _successMessage(action));
  }

  static String? _successMessage(String action) => switch (action) {
        PartnershipAction.accept => 'Parceria aceita',
        PartnershipAction.decline => 'Pedido recusado',
        PartnershipAction.end => 'Parceria encerrada',
        PartnershipAction.rateAccept => 'Tabela especial combinada',
        PartnershipAction.rateDecline => 'Proposta recusada',
        _ => null,
      };

  Future<void> _proposeRate(AssociationPartnership p) async {
    final service = context.read<AssociationService>();
    final choice = await showRateProposalDialog(
      context,
      counterpart: 'a loja',
      current: p.proposalStart(_viewer),
      defaultRate: service.association!.deliveryRate,
      hasAgreedRate: p.canProposeDefault,
      customerFee: p.customerFeeToCompare,
      title: p.awaits(_viewer) ? 'Contraproposta' : 'Propor tabela especial',
    );
    if (choice == null || !mounted) return;
    await runWithFeedback(context, () async => _replace(await service.proposeRate(p.id, choice.rate)),
        success: 'Proposta enviada à loja');
  }

  Future<void> _invite() async {
    final service = context.read<AssociationService>();
    final excluded = {
      for (final p in _partnerships ?? <AssociationPartnership>[])
        if (p.isActive || p.isPending) p.restaurantId,
    };
    final restaurant = await showDialog<Restaurant>(
      context: context,
      builder: (_) => _RestaurantSearchDialog(service: service, excluded: excluded),
    );
    if (restaurant == null || !mounted) return;

    // Convite com a tabela padrão ou já com uma proposta de tabela especial para esta loja
    final special = await showAppActionSheet<bool>(
      context,
      title: 'Qual tabela propor a ${restaurant.name}?',
      actions: [
        AppSheetAction(
          value: false,
          label: 'Tabela padrão da associação',
          description: deliveryRateLabel(service.association!.deliveryRate),
          icon: Icons.table_rows_outlined,
        ),
        const AppSheetAction(
          value: true,
          label: 'Propor uma tabela especial',
          description: 'Valor base e por km só para esta loja',
          icon: Icons.request_quote_outlined,
        ),
      ],
    );
    if (special == null || !mounted) return;

    DeliveryRate? rate;
    if (special) {
      final choice = await showRateProposalDialog(
        context,
        counterpart: 'a loja',
        current: service.association!.deliveryRate,
        defaultRate: service.association!.deliveryRate,
        hasAgreedRate: false,
        customerFee: restaurant.deliveryFeeByDistance ? null : restaurant.deliveryFee,
      );
      if (choice == null || !mounted) return;
      rate = choice.rate;
    }
    await runWithFeedback(context, () async => _replace(await service.inviteRestaurant(restaurant.id, rate: rate)),
        success: 'Convite enviado a ${restaurant.name}');
  }

  @override
  Widget build(BuildContext context) {
    final partnerships = _partnerships;
    if (partnerships == null) {
      return _error != null
          ? AppEmptyState(
              icon: Icons.cloud_off_outlined, message: _error!, actionLabel: 'Tentar novamente', onAction: refresh)
          : const Center(child: CircularProgressIndicator());
    }

    // Pedidos e contrapropostas que esperam a associação; os demais pendentes esperam a loja
    final requests = partnerships.where((p) => p.isPending && p.awaitsAssociation).toList();
    final active = partnerships.where((p) => p.isActive).toList()
      ..sort((a, b) => (b.awaitsAssociation ? 1 : 0) - (a.awaitsAssociation ? 1 : 0));
    final sent = partnerships.where((p) => p.isPending && !p.awaitsAssociation).toList();
    final history = partnerships.where((p) => !p.isActive && !p.isPending).take(10).toList();

    final compact = AppLayout.isCompact(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: compact
          ? FloatingActionButton.extended(
              onPressed: _invite,
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Convidar loja'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: refresh,
        child: AppPageListView(
          bottom: compact ? 96 : 32,
          children: [
            AppSectionHeader(
              title: 'Lojas parceiras',
              subtitle: 'Lojas que trabalham com os seus cooperados. Com cada uma, vocês podem combinar uma tabela '
                  'especial; ela vale só depois do aceite dos dois lados, e o entregador sempre recebe 100%.',
              action: compact
                  ? null
                  : AppButton(text: 'Convidar loja', icon: Icons.add_business_outlined, onPressed: _invite),
            ),
            if (partnerships.isEmpty)
              const AppEmptyState(
                icon: Icons.storefront_outlined,
                message: 'Nenhuma loja parceira ainda. Convide uma loja ou aguarde o pedido de uma delas.',
              ),
            ..._group('Pedidos de lojas', requests),
            ..._group('Parceiras', active),
            ..._group('Convites enviados', sent),
            ..._group('Histórico', history),
          ],
        ),
      ),
    );
  }

  List<Widget> _group(String title, List<AssociationPartnership> items) {
    if (items.isEmpty) return const [];
    final association = context.read<AssociationService>().association!;
    return [
      const SizedBox(height: 8),
      Text('$title (${items.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      for (final p in items) ...[
        PartnershipCard(
          partnership: p,
          viewer: _viewer,
          leading: RestaurantLogo(logoUrl: p.logoUrl, name: p.restaurantName, size: 44),
          title: p.restaurantName,
          subtitle: [
            if (p.location != null) p.location!,
            p.passesDeliveryFee ? 'Cobra do cliente pela distância' : 'Taxa ao cliente ${formatMoney(p.deliveryFee)}',
            if (p.coversDeliveryDifference) 'assume a diferença',
          ].join(' · '),
          defaultRate: association.deliveryRate,
          customerFee: p.customerFeeToCompare,
          onAction: (action) => _action(p, action),
          onProposeRate: () => _proposeRate(p),
        ),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 16),
    ];
  }
}

/// Busca de lojas pelo nome para convidar
class _RestaurantSearchDialog extends StatefulWidget {
  final AssociationService service;
  final Set<int> excluded;

  const _RestaurantSearchDialog({required this.service, required this.excluded});

  @override
  State<_RestaurantSearchDialog> createState() => _RestaurantSearchDialogState();
}

class _RestaurantSearchDialogState extends State<_RestaurantSearchDialog> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<Restaurant>? _results;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(text.trim()));
  }

  Future<void> _search(String text) async {
    if (text.length < 2) {
      setState(() => _results = null);
      return;
    }
    setState(() => _loading = true);
    try {
      final results = await widget.service.searchRestaurants(text);
      if (mounted && _query.text.trim() == text) {
        setState(() {
          _results = results.where((r) => !widget.excluded.contains(r.id)).toList();
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final results = _results;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Convidar loja'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('A parceria começa quando a loja aceitar o convite.', style: textTheme.bodyMedium),
            const SizedBox(height: 16),
            AppSearchBar(controller: _query, hintText: 'Nome da loja', onChanged: _onChanged),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Text(_error!, style: textTheme.bodyMedium?.copyWith(color: AppColors.errorDark))
            else if (results != null && results.isEmpty)
              Text('Nenhuma loja encontrada.', style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary))
            else if (results != null)
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final r = results[index];
                    return AppCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () => Navigator.of(context).pop(r),
                      child: Row(
                        children: [
                          RestaurantLogo(logoUrl: r.logoUrl, name: r.name, size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(
                                  [
                                    if (r.address != null) r.address!.areaLine,
                                    'Taxa ${formatMoney(r.deliveryFee)}',
                                  ].join(' · '),
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [AppButton(text: 'Fechar', variant: ButtonVariant.text, onPressed: () => Navigator.of(context).pop())],
    );
  }
}
