import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/courier/courier_work.dart';
import '../../../models/delivery/courier_link.dart';
import '../../../services/api_client.dart';
import '../../../services/courier_service.dart';
import '../../../services/courier_work_service.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/courier/active_delivery_card.dart';
import '../../../widgets/courier/offer_card.dart';
import '../../../widgets/order/live_indicator.dart';
import '../../../widgets/restaurant/restaurant_logo.dart';

/// Tela de trabalho do entregador: ficar online, check-in, ofertas e a entrega em andamento
class WorkTab extends StatefulWidget {
  /// Abre a aba de veículos (trocar o veículo em uso)
  final VoidCallback onOpenVehicles;

  const WorkTab({super.key, required this.onOpenVehicles});

  @override
  State<WorkTab> createState() => _WorkTabState();
}

class _WorkTabState extends State<WorkTab> {
  late final CourierWorkService _work = context.read<CourierWorkService>();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _work.addListener(_showNotice);
    WidgetsBinding.instance.addPostFrameCallback((_) => _work.attach());
  }

  @override
  void dispose() {
    _work.removeListener(_showNotice);
    _work.detach();
    super.dispose();
  }

  void _showNotice() {
    final notice = _work.takeNotice();
    if (notice != null && mounted) AppToast.show(context, message: notice, type: ToastType.info);
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (success != null && mounted) AppToast.show(context, message: success, type: ToastType.success);
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, message: e.message, type: ToastType.error, duration: const Duration(seconds: 6));
      // O estado pode ter mudado (oferta expirou, pedido cancelado)
      await _work.refresh();
    } on LocationUnavailable catch (e) {
      if (mounted) AppToast.show(context, message: e.message, type: ToastType.warning, duration: const Duration(seconds: 6));
    } catch (_) {
      if (mounted) AppToast.show(context, message: 'Não foi possível obter sua localização', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deliver(CourierOrder order) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Confirmar entrega?',
      message: 'Confirme que entregou o pedido e recebeu ${formatMoney(order.totalAmount)} (${order.paymentMethod.label}).',
      confirmLabel: 'Entreguei',
    );
    if (confirmed) await _run(() => _work.deliver(order), success: 'Entrega concluída!');
  }

  @override
  Widget build(BuildContext context) {
    final work = context.watch<CourierWorkService>();
    final state = work.state;

    if (state == null) {
      return work.error != null
          ? AppEmptyState(icon: Icons.cloud_off_outlined, message: work.error!, actionLabel: 'Tentar novamente', onAction: work.refresh)
          : const Center(child: CircularProgressIndicator());
    }

    final offer = state.pendingOffer;
    final showOffer = offer != null && DateTime.now().isBefore(offer.expiresAt) && state.activeOrder == null;

    return RefreshIndicator(
      onRefresh: work.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusCard(state: state, connected: work.connected, onOpenVehicles: widget.onOpenVehicles),
                  const SizedBox(height: 16),
                  if (state.blockers.isNotEmpty) ...[
                    _Blockers(blockers: state.blockers),
                    const SizedBox(height: 16),
                  ],
                  if (state.activeOrder != null) ...[
                    ActiveDeliveryCard(
                      order: state.activeOrder!,
                      busy: _busy,
                      onPickUp: () => _run(() => _work.pickUp(state.activeOrder!), success: 'Boa entrega!'),
                      onDeliver: () => _deliver(state.activeOrder!),
                    ),
                    const SizedBox(height: 16),
                  ] else if (showOffer) ...[
                    OfferCard(
                      offer: offer,
                      busy: _busy,
                      onAccept: () => _run(() => _work.acceptOffer(offer), success: 'Entrega aceita'),
                      onDecline: () => _run(() => _work.declineOffer(offer)),
                    ),
                    const SizedBox(height: 16),
                  ] else if (state.workStatus == CourierWorkStatus.ONLINE)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: AppEmptyState(
                        icon: Icons.radar,
                        message: 'Aguardando entregas… Mantenha esta tela aberta: quando chegar uma oferta, o app toca.',
                      ),
                    ),
                  _Actions(state: state, busy: _busy, run: _run),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final CourierWorkState state;
  final bool connected;
  final VoidCallback onOpenVehicles;

  const _StatusCard({required this.state, required this.connected, required this.onOpenVehicles});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final vehicle = context.watch<CourierService>().profile?.activeVehicle;
    final color = switch (state.workStatus) {
      CourierWorkStatus.ONLINE => AppColors.successDark,
      CourierWorkStatus.BUSY => AppColors.infoDark,
      CourierWorkStatus.OFFLINE => AppColors.grey600,
    };
    final shift = state.shift;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 14, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(state.workStatus.label,
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
              ),
              if (state.isWorking) LiveIndicator(connected: connected),
            ],
          ),
          if (shift != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                shift.isFixed
                    ? 'Check-in em ${shift.restaurant?.name ?? 'restaurante'} desde ${formatTime(shift.startedAt)} · só pedidos desta loja'
                    : 'Modo livre desde ${formatTime(shift.startedAt)}',
                style: textTheme.bodyMedium,
              ),
            ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(child: _Metric(label: 'Ganhos hoje', value: formatMoney(state.earnedToday))),
              Expanded(child: _Metric(label: 'Entregas hoje', value: '${state.deliveriesToday}')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(vehicle?.type.icon ?? Icons.two_wheeler, color: AppColors.textBody),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vehicle == null ? 'Nenhum veículo em uso' : [vehicle.title, if (vehicle.plate != null) vehicle.plate!].join(' · '),
                  style: textTheme.bodyMedium,
                ),
              ),
              if (state.workStatus != CourierWorkStatus.BUSY)
                AppButton(text: 'Trocar', variant: ButtonVariant.text, onPressed: onOpenVehicles),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
        Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _Blockers extends StatelessWidget {
  final List<String> blockers;

  const _Blockers({required this.blockers});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: AppColors.warningLighter.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Antes de trabalhar', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          for (final b in blockers) Text('• $b'),
        ],
      ),
    );
  }
}

/// Ficar online/offline, check-in/check-out nos restaurantes em que é fixo
class _Actions extends StatelessWidget {
  final CourierWorkState state;
  final bool busy;
  final Future<void> Function(Future<void> Function() action, {String? success}) run;

  const _Actions({required this.state, required this.busy, required this.run});

  @override
  Widget build(BuildContext context) {
    final work = context.read<CourierWorkService>();
    final fixedRestaurants = context.watch<CourierService>().activeLinks;
    final blocked = state.blockers.isNotEmpty;
    final shift = state.shift;
    final textTheme = Theme.of(context).textTheme;

    if (state.workStatus == CourierWorkStatus.BUSY) return const SizedBox.shrink();

    if (shift != null) {
      return AppButton(
        text: shift.isFixed ? 'Fazer check-out' : 'Ficar offline',
        icon: shift.isFixed ? Icons.logout : Icons.power_settings_new,
        variant: ButtonVariant.outlined,
        fullWidth: true,
        isLoading: busy,
        onPressed: busy ? null : () => run(shift.isFixed ? work.checkOut : work.goOffline),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          text: 'Ficar online',
          icon: Icons.power_settings_new,
          size: ButtonSize.large,
          fullWidth: true,
          isLoading: busy,
          onPressed: busy || blocked ? null : () => run(work.goOnline, success: 'Você está online'),
        ),
        const SizedBox(height: 6),
        Text('No modo livre você recebe entregas dos restaurantes por perto, com prioridade para quem ganhou menos hoje.',
            textAlign: TextAlign.center, style: textTheme.bodySmall),
        if (fixedRestaurants.isNotEmpty) ...[
          const SizedBox(height: 24),
          const AppSectionHeader(
            title: 'Check-in como fixo',
            subtitle: 'Chegue ao restaurante e faça o check-in. Durante o turno você só recebe pedidos dele.',
          ),
          for (final link in fixedRestaurants) ...[
            _CheckInTile(
              link: link,
              enabled: !busy && !blocked,
              onCheckIn: () => run(() => work.checkIn(link.restaurant.id), success: 'Check-in feito em ${link.restaurant.name}'),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _CheckInTile extends StatelessWidget {
  final CourierLink link;
  final bool enabled;
  final VoidCallback onCheckIn;

  const _CheckInTile({required this.link, required this.enabled, required this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    final restaurant = link.restaurant;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          RestaurantLogo(logoUrl: restaurant.logoUrl, name: restaurant.name, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (restaurant.address != null) Text(restaurant.address!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          AppButton(text: 'Check-in', icon: Icons.login, onPressed: enabled ? onCheckIn : null),
        ],
      ),
    );
  }
}
