import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/delivery/partnership.dart';

/// Situação da parceria para quem está vendo: pedido pendente vira "aguardando você" ou "aguardando o outro lado"
class PartnershipStatusChip extends StatelessWidget {
  final PartnershipInfo partnership;
  final PartnershipSide viewer;

  const PartnershipStatusChip({super.key, required this.partnership, required this.viewer});

  @override
  Widget build(BuildContext context) {
    return switch (partnership.status) {
      PartnershipStatus.ACTIVE => const AppStatusChip(label: 'Parceira', color: AppColors.successDark),
      PartnershipStatus.PENDING => AppStatusChip(
          label: partnership.awaits(viewer) ? 'Aguardando sua resposta' : 'Aguardando ${viewer.other.label}',
          color: AppColors.warningDarker,
        ),
      PartnershipStatus.DECLINED => const AppStatusChip(label: 'Recusada', color: AppColors.grey600),
      PartnershipStatus.ENDED => const AppStatusChip(label: 'Encerrada', color: AppColors.grey600),
    };
  }
}
