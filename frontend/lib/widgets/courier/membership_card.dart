import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/association/member.dart';
import '../../models/courier/courier_profile.dart';
import '../../services/courier_service.dart';
import '../../utils/feedback.dart';
import '../association/association_logo.dart';
import '../association/membership_status_chip.dart';
import 'association_picker.dart';

/// Associação do entregador: status do vínculo, sair/cancelar, ou entrar em uma
class CourierMembershipCard extends StatefulWidget {
  final CourierProfile profile;

  const CourierMembershipCard({super.key, required this.profile});

  @override
  State<CourierMembershipCard> createState() => _CourierMembershipCardState();
}

class _CourierMembershipCardState extends State<CourierMembershipCard> {
  AssociationChoice? _choice;
  bool _isSending = false;

  Future<void> _join() async {
    final choice = _choice;
    if (choice == null) return;
    setState(() => _isSending = true);
    await runWithFeedback(
      context,
      () => context.read<CourierService>().requestToJoin(choice),
      success: choice.isInvite ? 'Você entrou na associação' : 'Pedido enviado ao gestor da associação',
    );
    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _leave(bool pending) async {
    final service = context.read<CourierService>();
    final reason = await AppDialog.reason(
      context,
      title: pending ? 'Cancelar pedido de entrada?' : 'Sair da associação?',
      confirmLabel: pending ? 'Cancelar pedido' : 'Sair',
      message: pending
          ? null
          : 'Sem associação você não pode ficar online nem receber entregas até entrar em outra.',
    );
    if (reason == null || !mounted) return;
    await runWithFeedback(context, () => service.leaveAssociation(reason: reason));
  }

  @override
  Widget build(BuildContext context) {
    final association = widget.profile.association;
    final textTheme = Theme.of(context).textTheme;

    if (association == null) {
      return AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSectionHeader(
              title: 'Minha associação',
              subtitle: 'Você não faz parte de nenhuma associação. Entre em uma para poder receber entregas.',
            ),
            AssociationPicker(value: _choice, onChanged: (choice) => setState(() => _choice = choice)),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                text: _choice?.isInvite == true ? 'Entrar' : 'Pedir para entrar',
                icon: Icons.send,
                isLoading: _isSending,
                onPressed: _choice == null || _isSending ? null : _join,
              ),
            ),
          ],
        ),
      );
    }

    final pending = association.status == MembershipStatus.PENDING;
    final details = pending
        ? 'Seu pedido de entrada está aguardando a aprovação do gestor.'
        : [
            if (association.memberNumber != null) 'Associado nº ${association.memberNumber}',
            if (association.status == MembershipStatus.SUSPENDED) 'Vínculo suspenso: fale com o gestor da associação.',
          ].join(' · ');
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AssociationLogo(logoUrl: association.logoUrl, name: association.name, size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(association.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    MembershipStatusChip(status: association.status),
                  ],
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(details, style: textTheme.bodyMedium),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              text: pending ? 'Cancelar pedido' : 'Sair da associação',
              variant: ButtonVariant.text,
              onPressed: () => _leave(pending),
            ),
          ),
        ],
      ),
    );
  }
}
