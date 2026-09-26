import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/association/member.dart';

/// Selo do status do vínculo do associado
class MembershipStatusChip extends StatelessWidget {
  final MembershipStatus status;

  const MembershipStatusChip({super.key, required this.status});

  static Color colorOf(MembershipStatus status) {
    switch (status) {
      case MembershipStatus.ACTIVE:
        return AppColors.successDark;
      case MembershipStatus.PENDING:
        return AppColors.warningDarker;
      case MembershipStatus.SUSPENDED:
        return AppColors.errorDark;
      default:
        return AppColors.grey600;
    }
  }

  @override
  Widget build(BuildContext context) => AppStatusChip(label: status.label, color: colorOf(status));
}
