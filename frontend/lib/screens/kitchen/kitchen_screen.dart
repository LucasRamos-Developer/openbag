import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/ui/ui.dart';
import '../../models/order/order.dart';
import '../../services/restaurant_orders_service.dart';
import '../../services/restaurant_panel_service.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';
import '../../widgets/order/live_indicator.dart';
import '../../widgets/order/order_items_list.dart';
import '../../widgets/order/order_timers.dart';

/// Tela da cozinha (KDS) para tablet ou TV: A fazer · Preparando · Pronto.
/// Letras grandes, cronômetro por pedido e um toque para avançar a etapa.
class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

enum _KitchenColumn {
  todo('A fazer', Icons.inbox_outlined),
  preparing('Preparando', Icons.local_fire_department_outlined),
  ready('Pronto', Icons.check_circle_outline);

  final String label;
  final IconData icon;
  const _KitchenColumn(this.label, this.icon);
}

class _KitchenScreenState extends State<KitchenScreen> {
  RestaurantOrdersService? _orders;
  _KitchenColumn _narrowColumn = _KitchenColumn.todo;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _keepScreenOn(true);
    _start();
  }

  Future<void> _start() async {
    final panel = context.read<RestaurantPanelService>();
    final orders = context.read<RestaurantOrdersService>();
    // Aberta direto pela URL (tablet dedicado): carrega o restaurante do dono primeiro
    if (panel.selectedId == null) await panel.load();
    if (!mounted || panel.selectedId == null) return;
    await orders.attach(panel.selectedId!);
    if (mounted) setState(() => _orders = orders);
  }

  /// Mantém a tela ligada. O navegador pode recusar (aba em segundo plano, sem interação):
  /// nesse caso a tela funciona normalmente, só pode apagar sozinha.
  Future<void> _keepScreenOn(bool on) async {
    try {
      await (on ? WakelockPlus.enable() : WakelockPlus.disable());
    } catch (_) {}
  }

  @override
  void dispose() {
    _keepScreenOn(false);
    _orders?.detach();
    super.dispose();
  }

  List<Order> _ordersOf(_KitchenColumn column, RestaurantOrdersService orders) => switch (column) {
        _KitchenColumn.todo => orders.confirmed,
        _KitchenColumn.preparing => orders.preparing,
        _KitchenColumn.ready => orders.ready,
      };

  Future<void> _advance(Order order) async {
    final action = order.status == OrderStatus.CONFIRMED ? OrderAction.start : OrderAction.ready;
    setState(() => _busy.add(order.id));
    await runWithFeedback(context, () => _orders!.perform(order, action));
    if (mounted) setState(() => _busy.remove(order.id));
  }

  @override
  Widget build(BuildContext context) {
    final panel = context.watch<RestaurantPanelService>();
    final orders = context.watch<RestaurantOrdersService>();
    final prepMinutes = panel.store?.defaultPreparationMinutes ?? 20;

    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF12161C),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B2129),
          leading: IconButton(
            tooltip: 'Voltar ao painel',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop() ? context.pop() : context.go('/restaurante'),
          ),
          title: Text('Cozinha · ${panel.store?.name ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
          actions: [
            LiveIndicator(connected: orders.connected),
            const SizedBox(width: 16),
            if (!orders.alertSound.unlocked)
              TextButton.icon(
                onPressed: orders.enableSound,
                icon: const Icon(Icons.volume_up_outlined),
                label: const Text('Ativar som'),
              ),
            const _Clock(),
            const SizedBox(width: 16),
          ],
        ),
        body: _orders == null
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth >= 900
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final column in _KitchenColumn.values)
                            Expanded(child: _buildColumn(column, orders, prepMinutes)),
                        ],
                      )
                    : Column(
                        children: [
                          AppFilterChips<_KitchenColumn>(
                            items: [
                              for (final c in _KitchenColumn.values)
                                SelectItem(value: c, label: '${c.label} (${_ordersOf(c, orders).length})'),
                            ],
                            value: _narrowColumn,
                            onSelected: (c) => setState(() => _narrowColumn = c),
                          ),
                          Expanded(child: _buildColumn(_narrowColumn, orders, prepMinutes, showHeader: false)),
                        ],
                      ),
              ),
      ),
    );
  }

  Widget _buildColumn(_KitchenColumn column, RestaurantOrdersService orders, int prepMinutes, {bool showHeader = true}) {
    final list = _ordersOf(column, orders);
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF1B2129), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 12),
              child: Row(
                children: [
                  Icon(column.icon, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text('${column.label}  ${list.length}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                ],
              ),
            ),
          Expanded(
            child: list.isEmpty
                ? Center(child: Text('Nenhum pedido', style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 18)))
                : ListView(
                    children: [
                      for (final order in list)
                        _KitchenCard(
                          key: ValueKey(order.id),
                          order: order,
                          prepMinutes: prepMinutes,
                          busy: _busy.contains(order.id),
                          onAdvance: column == _KitchenColumn.ready ? null : () => _advance(order),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _KitchenCard extends StatelessWidget {
  final Order order;
  final int prepMinutes;
  final bool busy;
  final VoidCallback? onAdvance;

  const _KitchenCard({super.key, required this.order, required this.prepMinutes, required this.busy, this.onAdvance});

  @override
  Widget build(BuildContext context) {
    final isReady = order.status == OrderStatus.READY_FOR_PICKUP;
    final since = (isReady ? order.readyAt : order.acceptedAt) ?? order.createdAt ?? DateTime.now();
    final prep = Duration(minutes: prepMinutes);

    return Card(
      color: const Color(0xFF232B35),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(order.displayCode ?? '#${order.id}',
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
                const Spacer(),
                ElapsedTimer(
                  since: since,
                  // No preparo: amarelo aos 75% do tempo médio e vermelho ao passar dele
                  warnAfter: isReady ? const Duration(minutes: 10) : prep * 0.75,
                  dangerAfter: isReady ? const Duration(minutes: 20) : prep,
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
              ],
            ),
            Text('Pedido às ${formatTime(order.createdAt)}${order.customerName != null ? ' · ${order.customerName}' : ''}',
                style: const TextStyle(color: Colors.white54)),
            if (order.isPickup)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('RETIRADA NA LOJA',
                    style: TextStyle(color: AppColors.warningLight, fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            const Divider(color: Colors.white24, height: 20),
            DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: OrderItemsList(items: order.items, large: true, showPrices: false),
            ),
            if (order.notes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.warningDarker.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(8)),
                child: Text('Obs. do pedido: ${order.notes}',
                    style: const TextStyle(color: AppColors.warningLight, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
            if (onAdvance != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: busy ? null : onAdvance,
                  icon: busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(order.status == OrderStatus.CONFIRMED ? Icons.play_arrow_rounded : Icons.check_rounded, size: 28),
                  label: Text(order.status == OrderStatus.CONFIRMED ? 'Iniciar preparo' : 'Pronto',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(order.isPickup ? 'Aguardando o cliente retirar' : 'Aguardando saída para entrega',
                    style: const TextStyle(color: Colors.white54)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Relógio HH:mm no topo da cozinha
class _Clock extends StatefulWidget {
  const _Clock();

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Text(formatTime(DateTime.now()), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      );
}
