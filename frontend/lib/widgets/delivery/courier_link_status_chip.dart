import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/delivery/courier_link.dart';

/// Situação do vínculo de entregador fixo (em check-in, fixo, aguardando)
class CourierLinkStatusChip extends StatelessWidget {
  final CourierLink link;

  /// Quem está vendo: muda o texto do pendente ("aguardando você" x "aguardando o outro lado")
  final LinkRequester viewer;

  const CourierLinkStatusChip({super.key, required this.link, required this.viewer});

  @override
  Widget build(BuildContext context) {
    if (link.isActive && link.checkedIn) {
      return const AppStatusChip(label: 'Em check-in', color: AppColors.successDark);
    }
    if (link.isActive) {
      return const AppStatusChip(label: 'Fixo', color: AppColors.primaryDark);
    }
    if (link.isPending) {
      final waitingMe = link.requestedBy != viewer;
      return AppStatusChip(
        label: waitingMe ? 'Aguardando sua resposta' : 'Aguardando resposta',
        color: AppColors.warningDarker,
      );
    }
    return AppStatusChip(label: link.status.label, color: AppColors.grey600);
  }
}
