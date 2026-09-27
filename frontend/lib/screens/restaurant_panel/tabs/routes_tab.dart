import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/order/order.dart';
import '../../../models/routes/routes_board.dart';
import '../../../services/api_client.dart';
import '../../../services/restaurant_orders_service.dart';
import '../../../services/restaurant_panel_service.dart';
import '../../../services/restaurant_routes_service.dart';
import '../../../utils/feedback.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/delivery/courier_picker_sheet.dart';
import '../../../widgets/delivery/routes_map.dart';

/// Rotas: o sistema junta entregas do mesmo bairro ou direção e chama o entregador perto de ficarem prontas.
/// A loja acompanha e corrige: chamar agora, separar, juntar e escolher o entregador.
class RoutesTab extends StatefulWidget {
  const RoutesTab({super.key});

  @override
  State<RoutesTab> createState() => RoutesTabState();
}

class RoutesTabState extends State<RoutesTab> {
  RoutesBoard? _board;
  String? _error;
  bool _loading = false;
  final Set<int> _selected = {};
  Timer? _poll;
  Timer? _debounce;
  RestaurantOrdersService? _orders;

  int? get _restaurantId => context.read<RestaurantPanelService>().selectedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
    // O planejador muda as rotas com o tempo (hora de chamar o entregador): atualiza sozinho
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && TickerMode.valuesOf(context).enabled) refresh(quiet: true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cada mudança de pedido (tempo real) pode mudar as rotas
    final orders = context.read<RestaurantOrdersService>();
    if (!identical(orders, _orders)) {
      _orders?.removeListener(_onOrdersChanged);
      _orders = orders..addListener(_onOrdersChanged);
    }
  }

  void _onOrdersChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (mounted && TickerMode.valuesOf(context).enabled) refresh(quiet: true);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _debounce?.cancel();
    _orders?.removeListener(_onOrdersChanged);
    super.dispose();
  }

  Future<void> refresh({bool quiet = false}) async {
    final id = _restaurantId;
    if (id == null) return;
    if (!quiet) setState(() => _loading = true);
    try {
      final board = await context.read<RestaurantRoutesService>().board(id);
      if (!mounted) return;
      setState(() {
        _board = board;
        _error = null;
        // Mantém só a seleção de pedidos que ainda estão montando
        final selectable = board.planning.expand((c) => c.stops).map((s) => s.orderId).toSet();
        _selected.retainAll(selectable);
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted && !quiet) setState(() => _loading = false);
    }
  }

  Future<void> _act(Future<void> Function() action, String success) async {
    final ok = await runWithFeedback(context, action, success: success);
    if (ok && mounted) refresh(quiet: true);
  }

  RestaurantRoutesService get _service => context.read<RestaurantRoutesService>();

  Future<void> _merge() => _act(() async {
        await _service.merge(_restaurantId!, _selected.toList());
        _selected.clear();
      }, 'Rota montada: procurando entregador');

  Future<void> _pickCourier(RouteCard card) async {
    final assigned = await showCourierPickerSheet(
      context,
      target: CourierTarget(
        restaurantId: _restaurantId!,
        orderId: card.lead.orderId,
        displayCode: card.lead.displayCode,
        routeId: card.routeId,
        routeSize: card.stops.length,
      ),
    );
    if (assigned == true && mounted) refresh(quiet: true);
  }

  Future<void> _openSettings(DeliveryRouteSettings settings) async {
    final updated = await showDialog<DeliveryRouteSettings>(context: context, builder: (_) => _SettingsDialog(settings: settings));
    if (updated == null || !mounted) return;
    await _act(() => _service.updateSettings(_restaurantId!, updated), 'Configurações das rotas salvas');
  }

  @override
  Widget build(BuildContext context) {
    final board = _board;
    final c = context.appColors;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: refresh,
          child: AppPageListView(
            bottom: _selected.length >= 2 ? 96 : 32,
            children: [
              AppSectionHeader(
                title: 'Rotas',
                subtitle: 'Entregas do mesmo bairro ou direção saem juntas; o entregador é chamado perto de ficarem prontas',
                action: board == null
                    ? null
                    : AppButton(
                        text: 'Ajustes',
                        icon: Icons.tune,
                        variant: ButtonVariant.outlined,
                        onPressed: () => _openSettings(board.settings),
                      ),
              ),
              if (_loading && board == null) const LinearProgressIndicator(minHeight: 2),
              if (board == null && _error != null)
                AppEmptyState(icon: Icons.cloud_off_outlined, message: _error!, actionLabel: 'Tentar novamente', onAction: refresh)
              else if (board != null) ...[
                if (!board.settings.enabled)
                  _Banner(
                    icon: Icons.info_outline,
                    text: 'Agrupar entregas está desligado: cada pedido chama o entregador assim que é aceito. '
                        'Você ainda pode juntar pedidos na mão.',
                  ),
                if (board.storeLatitude != null && board.all.isNotEmpty) ...[
                  SizedBox(
                    height: 320,
                    child: RoutesMap(
                      key: ValueKey(board.all.expand((c) => c.stops).map((s) => s.orderId).join(',')),
                      storeLatitude: board.storeLatitude!,
                      storeLongitude: board.storeLongitude!,
                      cards: board.all,
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (board.storeLatitude == null)
                  const _Banner(
                    icon: Icons.location_off_outlined,
                    text: 'Cadastre a localização da loja (Loja › Endereço) para montar rotas e ver o mapa.',
                  ),
                if (board.all.isEmpty)
                  const AppEmptyState(icon: Icons.alt_route, message: 'Nenhuma entrega esperando ou em andamento agora.')
                else
                  LayoutBuilder(builder: (context, constraints) {
                    final planning = _Column(
                      title: 'Montando',
                      count: board.planning.length,
                      empty: 'Nada esperando entregador.',
                      children: [
                        for (final card in board.planning)
                          _RouteCardView(
                            card: card,
                            selected: _selected,
                            onToggle: (id) => setState(() => _selected.contains(id) ? _selected.remove(id) : _selected.add(id)),
                            onDispatchNow: () => _act(() => _service.dispatchNow(_restaurantId!, card), 'Chamando entregador'),
                            onSeparate: (stop) => _act(() => _service.separate(_restaurantId!, card.routeId!, stop.orderId),
                                '${stop.displayCode ?? 'Pedido'} sai sozinho'),
                            onPickCourier: () => _pickCourier(card),
                          ),
                      ],
                    );
                    final active = _Column(
                      title: 'Com entregador',
                      count: board.active.length,
                      empty: 'Ninguém em rota agora.',
                      children: [
                        for (final card in board.active) _RouteCardView(card: card, onPickCourier: () => _pickCourier(card)),
                      ],
                    );
                    if (constraints.maxWidth < 900) {
                      return Column(children: [planning, const SizedBox(height: 16), active]);
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Expanded(child: planning), const SizedBox(width: 16), Expanded(child: active)],
                    );
                  }),
              ],
            ],
          ),
        ),
        if (_selected.length >= 2)
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: Material(
                elevation: 6,
                color: c.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${_selected.length} pedidos selecionados', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      AppButton(text: 'Limpar', variant: ButtonVariant.text, onPressed: () => setState(_selected.clear)),
                      AppButton(text: 'Juntar em uma rota', icon: Icons.merge_type, onPressed: _merge),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Column extends StatelessWidget {
  final String title;
  final int count;
  final String empty;
  final List<Widget> children;

  const _Column({required this.title, required this.count, required this.empty, required this.children});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('$title ($count)', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
        if (children.isEmpty) Text(empty, style: TextStyle(color: c.textMuted)),
        for (final child in children) Padding(padding: const EdgeInsets.only(bottom: 12), child: child),
      ],
    );
  }
}

class _RouteCardView extends StatelessWidget {
  final RouteCard card;
  final Set<int>? selected;
  final ValueChanged<int>? onToggle;
  final VoidCallback? onDispatchNow;
  final ValueChanged<RouteStop>? onSeparate;
  final VoidCallback onPickCourier;

  const _RouteCardView({
    required this.card,
    this.selected,
    this.onToggle,
    this.onDispatchNow,
    this.onSeparate,
    required this.onPickCourier,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final color = RouteColors.of(card.routeId);
    final planning = !card.hasCourier;
    final title = card.isRoute ? 'Rota · ${card.stops.length} entregas' : 'Pedido ${card.lead.displayCode ?? ''}';
    final distance = [
      if (card.totalDistanceKm != null && card.totalDistanceKm! > 0) '${_km(card.totalDistanceKm!)} km',
      if (card.savedDistanceKm != null && card.savedDistanceKm! > 0) 'economiza ${_km(card.savedDistanceKm!)} km',
      if (card.manual) 'montada pela loja',
    ].join(' · ');

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: c.border,
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
              AppStatusChip(label: card.status.label, color: c.primaryText),
            ],
          ),
          if (distance.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(distance, style: TextStyle(color: c.textMuted, fontSize: 13)),
          ],
          if (card.hasCourier) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(card.courierKind == CourierKind.STAFF ? Icons.badge_outlined : Icons.two_wheeler, size: 18, color: c.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${card.courierName}${card.courierKind != null ? ' · ${card.courierKind!.label}' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
          if (card.waitReason != null) ...[
            const SizedBox(height: 10),
            _Banner(icon: Icons.hourglass_top_rounded, text: card.waitReason!),
          ] else if (planning && card.status == RouteStatus.PLANNED && card.dispatchAt != null) ...[
            const SizedBox(height: 8),
            Text(
              card.dispatchAt!.isAfter(DateTime.now())
                  ? 'Chama o entregador às ${formatTime(card.dispatchAt)}'
                  : 'Chamando o entregador em instantes…',
              style: TextStyle(color: c.textMuted, fontSize: 13),
            ),
          ] else if (planning && card.searchingCourierSince != null) ...[
            const SizedBox(height: 8),
            Text('Sem entregador disponível desde ${formatTime(card.searchingCourierSince)}',
                style: TextStyle(color: c.danger, fontSize: 13)),
          ],
          const SizedBox(height: 8),
          for (var i = 0; i < card.stops.length; i++)
            _StopRow(
              number: card.isRoute ? '${i + 1}' : '•',
              color: color,
              stop: card.stops[i],
              selected: selected?.contains(card.stops[i].orderId),
              onToggle: onToggle == null ? null : () => onToggle!(card.stops[i].orderId),
              onSeparate: planning && card.isRoute && onSeparate != null ? () => onSeparate!(card.stops[i]) : null,
            ),
          if (card.lead.pickedUpAt == null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (planning && card.status == RouteStatus.PLANNED && onDispatchNow != null)
                  AppButton(text: 'Chamar agora', icon: Icons.campaign_outlined, size: ButtonSize.small, onPressed: onDispatchNow),
                AppButton(
                  text: card.hasCourier ? 'Trocar entregador' : 'Escolher entregador',
                  icon: card.hasCourier ? Icons.swap_horiz : Icons.person_search_outlined,
                  variant: ButtonVariant.outlined,
                  size: ButtonSize.small,
                  onPressed: onPickCourier,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _km(double km) => km.toStringAsFixed(1).replaceAll('.', ',');
}

class _StopRow extends StatelessWidget {
  final String number;
  final Color color;
  final RouteStop stop;
  final bool? selected;
  final VoidCallback? onToggle;
  final VoidCallback? onSeparate;

  const _StopRow({required this.number, required this.color, required this.stop, this.selected, this.onToggle, this.onSeparate});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final (label, labelColor) = _state(c);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (selected != null)
            Checkbox(value: selected, onChanged: onToggle == null ? null : (_) => onToggle!(), visualDensity: VisualDensity.compact),
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(number, style: TextStyle(color: RouteColors.onColor(color), fontWeight: FontWeight.w800, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${stop.displayCode ?? ''}${stop.neighborhood != null ? ' · ${stop.neighborhood}' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(label, style: TextStyle(color: labelColor, fontSize: 12)),
              ],
            ),
          ),
          if (onSeparate != null)
            IconButton(tooltip: 'Separar: sai sozinho', icon: const Icon(Icons.call_split, size: 20), onPressed: onSeparate),
        ],
      ),
    );
  }

  (String, Color) _state(AppThemeColors c) {
    if (stop.status == OrderStatus.OUT_FOR_DELIVERY) return ('Saiu para entrega', c.textMuted);
    if (stop.ready) return ('Pronto', c.success);
    final eta = stop.expectedReadyAt;
    if (eta != null) {
      final minutes = eta.difference(DateTime.now()).inMinutes;
      return (minutes > 0 ? 'Pronto em ~$minutes min' : 'Deve ficar pronto a qualquer momento', c.textMuted);
    }
    return (stop.status.label, c.textMuted);
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Banner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c.primaryText),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: c.text, fontSize: 13))),
        ],
      ),
    );
  }
}

class _SettingsDialog extends StatefulWidget {
  final DeliveryRouteSettings settings;

  const _SettingsDialog({required this.settings});

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late DeliveryRouteSettings _value = widget.settings;

  Widget _select(String label, int value, List<int> options, String Function(int) text, ValueChanged<int> onChanged) {
    return AppSelect<int>(
      labelText: label,
      variant: TextFieldVariant.filled,
      enabled: _value.enabled,
      value: value,
      items: [for (final o in {...options, value}.toList()..sort()) SelectItem(value: o, label: text(o))],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajustes das rotas'),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Agrupar entregas automaticamente'),
              subtitle: const Text('Junta pedidos do mesmo bairro ou direção e chama o entregador perto de ficarem prontos'),
              value: _value.enabled,
              onChanged: (v) => setState(() => _value = _value.copyWith(enabled: v)),
            ),
            const SizedBox(height: 16),
            _select('Máximo de pedidos por rota', _value.maxOrders, [2, 3, 4], (v) => '$v pedidos',
                (v) => setState(() => _value = _value.copyWith(maxOrders: v))),
            const SizedBox(height: 20),
            _select('Pedido pronto espera outro por até', _value.maxHoldMinutes, [0, 3, 5, 8, 10, 15], (v) => '$v minutos',
                (v) => setState(() => _value = _value.copyWith(maxHoldMinutes: v))),
            const SizedBox(height: 20),
            _select('Chamar o entregador antes de ficar pronto', _value.leadMinutes, [0, 5, 8, 10, 15, 20],
                (v) => v == 0 ? 'Só quando estiver pronto' : '$v minutos antes',
                (v) => setState(() => _value = _value.copyWith(leadMinutes: v))),
          ],
        ),
      ),
      actions: [
        AppButton(text: 'Cancelar', variant: ButtonVariant.text, onPressed: () => Navigator.of(context).pop()),
        AppButton(text: 'Salvar', icon: Icons.check, onPressed: () => Navigator.of(context).pop(_value)),
      ],
    );
  }
}
