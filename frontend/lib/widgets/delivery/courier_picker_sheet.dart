import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/delivery/courier_options.dart';
import '../../models/order/order.dart';
import '../../services/restaurant_delivery_service.dart';
import '../../services/restaurant_routes_service.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';
import '../courier/courier_avatar.dart';

/// Para quem escolher o entregador: um pedido ou uma rota inteira (as opções vêm do pedido líder da rota)
class CourierTarget {
  final int restaurantId;
  final int orderId;
  final String? displayCode;
  final int? routeId;
  final int routeSize;

  const CourierTarget({required this.restaurantId, required this.orderId, this.displayCode, this.routeId, this.routeSize = 1});

  factory CourierTarget.order(Order order) =>
      CourierTarget(restaurantId: order.restaurant.id!, orderId: order.id, displayCode: order.displayCode);

  String get title => routeId != null ? 'a rota com $routeSize entregas' : (displayCode ?? 'o pedido');
}

/// Escolher quem leva o pedido (ou a rota): fixos em check-in, livres online por perto e equipe da loja.
/// A atribuição é direta (o entregador não precisa aceitar). Retorna true se alguém foi atribuído.
Future<bool?> showCourierPickerSheet(BuildContext context, {required CourierTarget target}) => showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => CourierPickerSheet(target: target),
    );

class CourierPickerSheet extends StatefulWidget {
  final CourierTarget target;

  const CourierPickerSheet({super.key, required this.target});

  @override
  State<CourierPickerSheet> createState() => _CourierPickerSheetState();
}

class _CourierPickerSheetState extends State<CourierPickerSheet> {
  late Future<CourierOptions> _future = _load();
  CourierOption? _assigning;

  CourierTarget get _target => widget.target;

  Future<CourierOptions> _load() =>
      context.read<RestaurantDeliveryService>().courierOptions(_target.restaurantId, _target.orderId);

  Future<void> _assign(CourierOption option) async {
    setState(() => _assigning = option);
    final ok = await runWithFeedback(
      context,
      () => _target.routeId != null
          ? context.read<RestaurantRoutesService>().assign(_target.restaurantId, _target.routeId!, option)
          : context.read<RestaurantDeliveryService>().assignCourier(_target.restaurantId, _target.orderId, option),
      success: _target.routeId != null ? 'Rota com ${option.name}' : '${_target.displayCode ?? 'Pedido'} com ${option.name}',
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _assigning = null;
        _future = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => FutureBuilder<CourierOptions>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppEmptyState(
              icon: Icons.cloud_off_outlined,
              message: 'Não foi possível carregar os entregadores.',
              actionLabel: 'Tentar novamente',
              onAction: () => setState(() => _future = _load()),
            );
          }
          final options = snapshot.data!.options;
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              AppSectionHeader(
                title: 'Quem vai levar ${_target.title}?',
                subtitle: _target.routeId != null
                    ? 'A rota vai direto para a pessoa escolhida, sem precisar aceitar. Valores por pedido.'
                    : 'O pedido vai direto para a pessoa escolhida, sem precisar aceitar',
              ),
              if (options.isEmpty)
                const AppEmptyState(
                  icon: Icons.person_search_outlined,
                  message: 'Ninguém disponível agora.\nCadastre a equipe da loja na seção Entregadores.',
                ),
              for (final kind in CourierKind.values)
                if (options.any((o) => o.kind == kind)) ...[
                  _GroupTitle(kind: kind),
                  for (final option in options.where((o) => o.kind == kind))
                    _OptionTile(
                      option: option,
                      busy: identical(_assigning, option),
                      onAssign: _assigning == null && option.available ? () => _assign(option) : null,
                    ),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  final CourierKind kind;

  const _GroupTitle({required this.kind});

  @override
  Widget build(BuildContext context) {
    final title = switch (kind) {
      CourierKind.FIXED => 'Fixos em check-in',
      CourierKind.FREE => 'Online por perto',
      CourierKind.STAFF => 'Equipe da loja',
    };
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: context.appColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final CourierOption option;
  final bool busy;
  final VoidCallback? onAssign;

  const _OptionTile({required this.option, required this.busy, this.onAssign});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final details = [
      if (option.distanceKm != null) '${option.distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km da loja',
      if (option.vehicleType != null) option.vehicleType!.label,
      if (option.fee != null) 'recebe ${formatMoney(option.fee!)}',
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: option.available,
      leading: option.kind == CourierKind.STAFF
          ? CircleAvatar(
              radius: 20,
              backgroundColor: c.primary.withValues(alpha: 0.12),
              child: Icon(Icons.badge_outlined, color: c.primaryText, size: 20),
            )
          : CourierAvatar(photoUrl: option.photoUrl, name: option.name, size: 40),
      title: Text(option.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        option.blockedReason ?? details,
        style: TextStyle(color: option.available ? c.textMuted : c.danger, fontSize: 13),
      ),
      trailing: AppButton(
        text: 'Atribuir',
        variant: ButtonVariant.outlined,
        size: ButtonSize.small,
        isLoading: busy,
        onPressed: onAssign,
      ),
    );
  }
}
