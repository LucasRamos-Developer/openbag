import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/association/association.dart';

/// Selo do status da associação na plataforma
class AssociationStatusChip extends StatelessWidget {
  final AssociationStatus status;

  const AssociationStatusChip({super.key, required this.status});

  static Color colorOf(AssociationStatus status) {
    switch (status) {
      case AssociationStatus.ACTIVE:
        return AppColors.successDark;
      case AssociationStatus.PENDING_APPROVAL:
        return AppColors.warningDarker;
      case AssociationStatus.REJECTED:
      case AssociationStatus.SUSPENDED:
        return AppColors.errorDark;
    }
  }

  @override
  Widget build(BuildContext context) => AppStatusChip(label: status.label, color: colorOf(status));
}
