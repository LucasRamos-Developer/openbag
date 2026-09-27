import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/store/store.dart';
import '../../services/restaurant_panel_service.dart';
import '../../utils/feedback.dart';
import 'store_status_chip.dart';

/// Situação da loja no menu do painel; um toque abre as ações: abrir/fechar, pausar e retomar
class StoreStatusMenuTile extends StatelessWidget {
  final Store store;

  const StoreStatusMenuTile({super.key, required this.store});

  static const _pauseOptions = [15, 30, 60];

  static String detailOf(Store store) {
    if (!store.open) return 'Não recebe pedidos';
    if (store.openNow) return 'Recebendo pedidos';
    if (store.paused) return 'Clientes veem, mas não pedem';
    return 'Fora do horário de funcionamento';
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<RestaurantPanelService>();

    return AppPanelStatus(
      color: StoreStatusChip.colorOf(store),
      label: StoreStatusChip.labelOf(store),
      detail: detailOf(store),
      menuChildren: [
        MenuItemButton(
          leadingIcon: Icon(store.open ? Icons.lock_outline_rounded : Icons.lock_open_rounded),
          onPressed: () => runWithFeedback(context, () => service.setOpen(!store.open),
              success: store.open ? 'Loja fechada até você abrir de novo' : 'Loja aberta'),
          child: Text(store.open ? 'Fechar loja' : 'Abrir loja'),
        ),
        if (store.paused)
          MenuItemButton(
            leadingIcon: const Icon(Icons.play_arrow_rounded),
            onPressed: () => runWithFeedback(context, service.resume, success: 'Pedidos retomados'),
            child: const Text('Retomar agora'),
          )
        else if (store.open)
          for (final minutes in _pauseOptions)
            MenuItemButton(
              leadingIcon: const Icon(Icons.pause_circle_outline_rounded),
              onPressed: () => runWithFeedback(context, () => service.pause(minutes),
                  success: 'Loja pausada por $minutes minutos'),
              child: Text('Pausar por $minutes min'),
            ),
      ],
    );
  }
}
