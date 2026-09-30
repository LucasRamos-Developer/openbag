import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/order/order.dart';
import '../../../services/restaurant_orders_service.dart';
import '../../../services/restaurant_panel_service.dart';
import '../../../utils/feedback.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/order/live_indicator.dart';
import '../../../widgets/order/order_card.dart';
import '../../../widgets/order/order_status_chip.dart';
import '../../../widgets/order/order_ticket.dart';
import '../../../widgets/order/restaurant_order_sheet.dart';
import '../store_order_screen.dart';

/// Gestor de pedidos: colunas Novos · Em preparo · Prontos · Em entrega, em tempo real
class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

enum _Column {
  novos('Novos'),
  preparo('Em preparo'),
  prontos('Prontos'),
  entrega('Em entrega');

  final String label;
  const _Column(this.label);
}

class _OrdersTabState extends State<OrdersTab> {
  late final RestaurantOrdersService _orders = context.read<RestaurantOrdersService>();
  _Column _mobileColumn = _Column.novos;
  bool _showHistory = false;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    final panel = context.read<RestaurantPanelService>();
    _orders.attach(panel.selectedId!);
    // Comanda automática ao aceitar (configuração da loja)
    _orders.onAccepted = (order) {
      if (panel.store?.autoPrintTicket == true) _print(order);
    };
    _orders.onIncident = (order, incident) {
      if (!mounted) return;
      AppToast.show(context,
          message: 'Pedido ${order.displayCode ?? '#${order.id}'}: ${incident.title}',
          type: ToastType.warning,
          duration: const Duration(seconds: 8));
    };
  }

  @override
  void dispose() {
    _orders.onAccepted = null;
    _orders.onIncident = null;
    _orders.detach();
    super.dispose();
  }

  String get _restaurantName => context.read<RestaurantPanelService>().store?.name ?? 'OpenBag';

  /// O pedido do balcão entra já aceito: no celular, mostra a coluna "Em preparo" em vez de "Novos" vazia
  Future<void> _newStoreOrder() async {
    final created = await context.push<bool>(storeOrderPath);
    if (created == true && mounted) {
      setState(() {
        _showHistory = false;
        _mobileColumn = _Column.preparo;
      });
    }
  }

  void _print(Order order) => printOrderTicket(order, restaurantName: _restaurantName);

  List<Order> _ordersOf(_Column column) => switch (column) {
        _Column.novos => _orders.pending,
        _Column.preparo => _orders.inKitchen,
        _Column.prontos => _orders.ready,
        _Column.entrega => _orders.outForDelivery,
      };

  Future<void> _act(Order order, OrderAction action) async {
    String? reason;
    if (action == OrderAction.reject) {
      reason = await AppDialog.reason(
        context,
        title: order.status == OrderStatus.PENDING ? 'Recusar ${order.displayCode}?' : 'Cancelar ${order.displayCode}?',
        message: 'O cliente verá o motivo.',
        confirmLabel: order.status == OrderStatus.PENDING ? 'Recusar' : 'Cancelar pedido',
        required: true,
      );
      if (reason == null || !mounted) return;
    }
    setState(() => _busy.add(order.id));
    await runWithFeedback(context, () => _orders.perform(order, action, reason: reason));
    if (mounted) setState(() => _busy.remove(order.id));
  }

  void _open(Order order) => showRestaurantOrderSheet(
        context,
        order: order,
        onAction: (action) => _act(order, action),
        onPrint: () => _print(order),
      );

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<RestaurantOrdersService>();
    final wide = MediaQuery.of(context).size.width >= 1100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Pedidos', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
              LiveIndicator(connected: orders.connected),
              AppButton(
                text: 'Novo pedido',
                icon: Icons.add,
                onPressed: _newStoreOrder,
              ),
              if (!orders.alertSound.unlocked)
                AppButton(
                  text: 'Ativar alertas sonoros',
                  icon: Icons.volume_up_outlined,
                  variant: ButtonVariant.soft,
                  onPressed: orders.enableSound,
                ),
              AppButton(
                text: _showHistory ? 'Ver quadro' : 'Histórico do dia',
                icon: _showHistory ? Icons.view_column_outlined : Icons.history,
                variant: ButtonVariant.text,
                onPressed: () => setState(() => _showHistory = !_showHistory),
              ),
              AppButton(
                text: 'Abrir tela da cozinha',
                icon: Icons.soup_kitchen_outlined,
                variant: ButtonVariant.outlined,
                onPressed: () => context.push('/restaurante/cozinha'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _showHistory
              ? _History(onOpen: _open)
              : orders.isLoading && orders.pending.isEmpty && orders.inKitchen.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : wide
                      ? _buildColumns()
                      : _buildMobile(),
        ),
      ],
    );
  }

  Widget _buildColumns() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final column in _Column.values)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                      child: Text('${column.label} (${_ordersOf(column).length})',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    Expanded(child: _buildList(column)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFilterChips<_Column>(
          items: [for (final c in _Column.values) SelectItem(value: c, label: '${c.label} (${_ordersOf(c).length})')],
          value: _mobileColumn,
          onSelected: (c) => setState(() => _mobileColumn = c),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildList(_mobileColumn),
          ),
        ),
      ],
    );
  }

  Widget _buildList(_Column column) {
    final list = _ordersOf(column);
    if (list.isEmpty) {
      final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text(column == _Column.novos ? 'Nenhum pedido novo' : 'Vazio',
            textAlign: TextAlign.center, style: TextStyle(color: muted)),
      );
    }
    return RefreshIndicator(
      onRefresh: _orders.refresh,
      child: ListView(
        children: [
          for (final order in list)
            OrderCard(
              key: ValueKey(order.id),
              order: order,
              busy: _busy.contains(order.id),
              onTap: () => _open(order),
              onAction: (action) => _act(order, action),
            ),
        ],
      ),
    );
  }
}

/// Pedidos do dia (inclui entregues e cancelados)
class _History extends StatefulWidget {
  final void Function(Order order) onOpen;

  const _History({required this.onOpen});

  @override
  State<_History> createState() => _HistoryState();
}

class _HistoryState extends State<_History> {
  List<Order>? _orders;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await runWithFeedback(context, () async {
      final orders = await context.read<RestaurantOrdersService>().fetchHistory();
      if (mounted) setState(() => _orders = orders);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_orders == null) return const Center(child: CircularProgressIndicator());
    if (_orders!.isEmpty) return const AppEmptyState(icon: Icons.receipt_long_outlined, message: 'Nenhum pedido hoje.');

    final delivered = _orders!.where((o) => o.status == OrderStatus.DELIVERED);
    final revenue = delivered.fold(0.0, (sum, o) => sum + o.totalAmount);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          Text('${_orders!.length} pedidos hoje · ${delivered.length} entregues · ${formatMoney(revenue)} em pedidos entregues',
              style: TextStyle(color: muted)),
          const SizedBox(height: 12),
          for (final order in _orders!)
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => widget.onOpen(order),
              leading: Text(order.displayCode ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
              title: Text(order.items.map((i) => '${i.quantity}x ${i.name}').join(', '), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text([
                formatTime(order.createdAt),
                if (order.customerName != null) order.customerName!,
                formatMoney(order.totalAmount),
                if (order.fromStore) order.channel.label,
                if (order.isPickup) order.fulfillment.label,
              ].join(' · ')),
              trailing: OrderStatusChip(status: order.status),
            ),
        ],
      ),
    );
  }
}
