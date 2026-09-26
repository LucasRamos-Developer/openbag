import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/delivery/courier_link.dart';
import '../../../services/courier_service.dart';
import '../../../utils/feedback.dart';
import '../../../widgets/delivery/courier_link_status_chip.dart';
import '../../../widgets/restaurant/restaurant_logo.dart';
import 'work_history_section.dart';

/// Lojas do entregador: restaurantes em que é fixo (pedidos e convites) e onde já trabalhou
class CourierRestaurantsTab extends StatefulWidget {
  const CourierRestaurantsTab({super.key});

  @override
  State<CourierRestaurantsTab> createState() => CourierRestaurantsTabState();
}

class CourierRestaurantsTabState extends State<CourierRestaurantsTab> {
  final _historyKey = GlobalKey<WorkHistorySectionState>();

  /// Recarrega vínculos e histórico (ao abrir a aba)
  Future<void> refresh() async {
    await Future.wait([context.read<CourierService>().loadLinks(), _historyKey.currentState?.refresh() ?? Future.value()]);
  }

  final _link = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    final text = _link.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final ok = await runWithFeedback(context, () => context.read<CourierService>().requestLink(text),
        success: 'Pedido enviado ao restaurante');
    if (ok) _link.clear();
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _action(CourierLink link, String action) async {
    final service = context.read<CourierService>();
    if (action == 'end') {
      final confirmed = await AppDialog.confirm(
        context,
        title: link.isPending ? 'Cancelar pedido?' : 'Deixar de ser fixo?',
        message: link.isPending
            ? 'O pedido para ser fixo de ${link.restaurant.name} será cancelado.'
            : 'Você deixa de ser fixo de ${link.restaurant.name}${link.checkedIn ? ' e o check-in é encerrado' : ''}.',
        confirmLabel: link.isPending ? 'Cancelar pedido' : 'Deixar de ser fixo',
      );
      if (!confirmed || !mounted) return;
    }
    await runWithFeedback(context, () => service.linkAction(link, action));
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<CourierService>();
    final links = service.links;

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppSectionHeader(
                    title: 'Restaurantes em que sou fixo',
                    subtitle: 'O dono do restaurante precisa aprovar. Como fixo você faz check-in na loja e, '
                        'durante o turno, só entrega para ela.',
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _link,
                          labelText: 'Link da página do restaurante',
                          hintText: '…/r/nome-do-restaurante',
                          variant: TextFieldVariant.filled,
                          onSubmitted: (_) => _request(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: AppButton(text: 'Pedir', icon: Icons.send, isLoading: _sending, onPressed: _sending ? null : _request),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (links.isEmpty)
                    const AppEmptyState(icon: Icons.storefront_outlined, message: 'Você ainda não é fixo de nenhum restaurante.')
                  else
                    for (final link in links) ...[
                      _LinkTile(link: link, onAction: (action) => _action(link, action)),
                      const SizedBox(height: 8),
                    ],
                  const SizedBox(height: 32),
                  WorkHistorySection(key: _historyKey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final CourierLink link;
  final ValueChanged<String> onAction;

  const _LinkTile({required this.link, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final restaurant = link.restaurant;
    final invitedMe = link.isPending && link.requestedBy == LinkRequester.RESTAURANT;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: restaurant.slug != null ? () => context.push('/r/${restaurant.slug}') : null,
      child: Row(
        children: [
          RestaurantLogo(logoUrl: restaurant.logoUrl, name: restaurant.name, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(restaurant.name, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    CourierLinkStatusChip(link: link, viewer: LinkRequester.COURIER),
                  ],
                ),
                if (restaurant.address != null) Text(restaurant.address!, style: textTheme.bodySmall),
                if (invitedMe) Text('O restaurante convidou você para ser fixo.', style: textTheme.bodySmall),
              ],
            ),
          ),
          if (invitedMe) ...[
            AppButton(text: 'Recusar', variant: ButtonVariant.text, onPressed: () => onAction('decline')),
            const SizedBox(width: 4),
            AppButton(text: 'Aceitar', icon: Icons.check, onPressed: () => onAction('accept')),
          ] else
            IconButton(
              tooltip: link.isPending ? 'Cancelar pedido' : 'Deixar de ser fixo',
              icon: const Icon(Icons.link_off),
              onPressed: () => onAction('end'),
            ),
        ],
      ),
    );
  }
}
