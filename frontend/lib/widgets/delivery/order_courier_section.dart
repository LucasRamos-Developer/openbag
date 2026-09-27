import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/delivery/courier_options.dart';
import '../../models/order/order.dart';
import '../../services/restaurant_delivery_service.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';
import '../courier/order_courier_card.dart';
import 'courier_picker_sheet.dart';

/// Bloco "Entregador" do pedido no painel da loja: quem leva, escolher, trocar e tirar.
///
/// Regra de troca (vem do backend): fixo e equipe a qualquer momento antes da retirada; entregador livre
/// só se não aparecer na loja em X minutos — até lá mostra a contagem.
class OrderCourierSection extends StatefulWidget {
  final Order order;

  const OrderCourierSection({super.key, required this.order});

  @override
  State<OrderCourierSection> createState() => _OrderCourierSectionState();
}

class _OrderCourierSectionState extends State<OrderCourierSection> {
  CurrentCourier? _current;
  bool _loading = false;
  bool _removing = false;

  Order get _order => widget.order;
  bool get _hasCourier => _order.courier != null || _order.staffCourier != null;

  @override
  void initState() {
    super.initState();
    _loadRule();
  }

  @override
  void didUpdateWidget(OrderCourierSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.courierName != _order.courierName || oldWidget.order.status != _order.status) _loadRule();
  }

  Future<void> _loadRule() async {
    if (!_hasCourier || !_order.beforePickup) {
      setState(() => _current = null);
      return;
    }
    setState(() => _loading = true);
    try {
      final options = await context.read<RestaurantDeliveryService>().courierOptions(_order.restaurant.id!, _order.id);
      if (mounted) setState(() => _current = options.current);
    } catch (_) {
      // Sem a regra, os botões ficam escondidos; o backend valida de qualquer forma
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pick() async {
    final assigned = await showCourierPickerSheet(context, target: CourierTarget.order(_order));
    if (assigned == true && mounted) _loadRule();
  }

  Future<void> _remove() async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Tirar o pedido de ${_order.courierName}?',
      message: 'O pedido volta a procurar entregador e não será oferecido de novo a essa pessoa.',
      confirmLabel: 'Tirar',
    );
    if (!confirmed || !mounted) return;
    setState(() => _removing = true);
    await runWithFeedback(context, () => context.read<RestaurantDeliveryService>().unassignCourier(_order.restaurant.id!, _order.id),
        success: 'Procurando outro entregador');
    if (mounted) setState(() => _removing = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;

    if (!_hasCourier) {
      final since = _order.searchingCourierSince;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(since != null
                    ? 'Nenhum entregador disponível desde ${formatTime(since)}. Continuamos procurando.'
                    : 'Procurando entregador…'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              text: 'Escolher entregador',
              icon: Icons.person_search_outlined,
              variant: ButtonVariant.outlined,
              onPressed: _pick,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_order.courier != null)
          OrderCourierCard(courier: _order.courier!)
        else
          _StaffCard(staff: _order.staffCourier!),
        if (_order.courierKind != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: AppStatusChip(label: _order.courierKind!.label, color: c.primaryText),
          ),
        ],
        if (_order.beforePickup) ...[
          const SizedBox(height: 12),
          if (_loading && _current == null)
            const LinearProgressIndicator(minHeight: 2)
          else if (_current != null && _current!.canReassign)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppButton(text: 'Trocar entregador', icon: Icons.swap_horiz, variant: ButtonVariant.outlined, onPressed: _pick),
                AppButton(
                  text: 'Tirar',
                  variant: ButtonVariant.text,
                  isLoading: _removing,
                  onPressed: _removing ? null : _remove,
                ),
              ],
            )
          else if (_current != null)
            _LockedReassign(current: _current!, assignedAt: _order.assignedAt, onUnlocked: _loadRule),
        ],
      ],
    );
  }
}

/// Entregador livre: a troca só libera se ele não aparecer; mostra quanto falta ou que ele já chegou
class _LockedReassign extends StatelessWidget {
  final CurrentCourier current;
  final DateTime? assignedAt;
  final VoidCallback onUnlocked;

  const _LockedReassign({required this.current, required this.assignedAt, required this.onUnlocked});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final availableAt = current.availableAt;
    final counting = !current.atStore && availableAt != null && availableAt.isAfter(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(current.atStore ? Icons.storefront_outlined : Icons.lock_clock_outlined, size: 18, color: c.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  current.atStore
                      ? 'O entregador já está na loja'
                      : counting
                          ? 'Entregador livre: dá para trocar às ${formatTime(availableAt)} se ele não chegar'
                          : (current.reason ?? 'Troca indisponível agora'),
                  style: TextStyle(color: c.textMuted, fontSize: 13),
                ),
              ),
            ],
          ),
          if (counting) ...[
            const SizedBox(height: 8),
            AppCountdown(
              until: availableAt,
              total: assignedAt != null ? availableAt.difference(assignedAt!) : const Duration(minutes: 10),
              onFinished: onUnlocked,
            ),
          ],
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final OrderStaffCourier staff;

  const _StaffCard({required this.staff});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: c.primary.withValues(alpha: 0.12),
          child: Icon(Icons.badge_outlined, color: c.primaryText),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(staff.phone ?? 'Equipe da loja', style: TextStyle(color: c.textMuted, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
