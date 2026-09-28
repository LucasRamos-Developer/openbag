import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/delivery/delivery_rate.dart';
import '../../models/delivery/partnership.dart';
import '../../utils/formatters.dart';
import '../delivery/delivery_rate_summary.dart';
import 'partnership_status_chip.dart';

/// Uma parceria nos dois painéis: a loja vê a associação e a associação vê a loja.
/// Mostra a situação, a tabela que vale na loja (padrão ou especial), a proposta de tabela em aberto
/// e as ações de quem está vendo. As ações usam os nomes de [PartnershipAction].
class PartnershipCard extends StatelessWidget {
  final PartnershipInfo partnership;
  final PartnershipSide viewer;
  final Widget leading;
  final String title;
  final String? subtitle;

  /// Tabela padrão da associação (para comparar com a especial)
  final DeliveryRate defaultRate;

  /// Taxa cobrada do cliente pela loja: destaca na simulação o que passa dela
  final double? customerFee;
  final ValueChanged<String> onAction;
  final VoidCallback? onProposeRate;

  /// Avisos extras abaixo da tabela
  final Widget? footer;

  const PartnershipCard({
    super.key,
    required this.partnership,
    required this.viewer,
    required this.leading,
    required this.title,
    this.subtitle,
    required this.defaultRate,
    this.customerFee,
    required this.onAction,
    this.onProposeRate,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final p = partnership;
    final proposal = p.rateProposal;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        PartnershipStatusChip(partnership: p, viewer: viewer),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: textTheme.bodySmall),
                    ],
                    const SizedBox(height: 2),
                    Text(_dates(), style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          if (p.isActive) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Tabela nesta loja', style: textTheme.labelLarge),
                const SizedBox(width: 8),
                if (p.hasAgreedRate)
                  const AppStatusChip(label: 'Especial', color: AppColors.primaryDark)
                else
                  Text('(padrão da associação)', style: textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 6),
            DeliveryRateSummary(rate: p.effectiveRate, customerFee: customerFee),
            if (p.hasAgreedRate) ...[
              const SizedBox(height: 4),
              Text('Padrão da associação: ${deliveryRateLabel(defaultRate)}', style: textTheme.bodySmall),
            ],
          ],
          if (p.isPending && proposal == null) ...[
            const SizedBox(height: 12),
            Text('Tabela do pedido: padrão da associação', style: textTheme.labelLarge),
            const SizedBox(height: 6),
            DeliveryRateSummary(rate: p.effectiveRate, customerFee: customerFee),
          ],
          if (proposal != null && (p.isActive || p.isPending)) ...[
            const SizedBox(height: 12),
            _ProposalBox(proposal: proposal, viewer: viewer),
          ],
          if (footer != null) ...[const SizedBox(height: 12), footer!],
          if (_actions().isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: _actions(),
            ),
          ],
        ],
      ),
    );
  }

  String _dates() {
    final p = partnership;
    return switch (p.status) {
      PartnershipStatus.PENDING => 'Pedido por ${p.requestedBy?.label ?? '-'} em ${formatDate(p.since)}',
      PartnershipStatus.ACTIVE => 'Desde ${formatDate(p.since)}',
      PartnershipStatus.DECLINED => 'Pedido por ${p.requestedBy?.label ?? '-'} em ${formatDate(p.since)}, recusado',
      PartnershipStatus.ENDED =>
        'Encerrada em ${formatDate(p.endedAt)}${p.endedBy != null ? ' por ${p.endedBy!.label}' : ''}',
    };
  }

  List<Widget> _actions() {
    final p = partnership;
    final proposal = p.rateProposal;
    final myTurn = p.awaits(viewer);
    final counter = onProposeRate == null
        ? null
        : AppButton(
            text: 'Contraproposta',
            icon: Icons.swap_horiz,
            variant: ButtonVariant.outlined,
            onPressed: onProposeRate,
          );

    if (p.isPending) {
      return myTurn
          ? [
              AppButton(
                text: 'Recusar',
                variant: ButtonVariant.text,
                onPressed: () => onAction(PartnershipAction.decline),
              ),
              if (counter != null) counter,
              AppButton(text: 'Aceitar', icon: Icons.check, onPressed: () => onAction(PartnershipAction.accept)),
            ]
          : [
              AppButton(
                text: p.requestedBy == viewer ? 'Cancelar pedido' : 'Desistir',
                variant: ButtonVariant.text,
                onPressed: () => onAction(PartnershipAction.end),
              ),
            ];
    }
    if (!p.isActive) return const [];

    return [
      if (proposal != null && !myTurn)
        AppButton(
          text: 'Desistir da proposta',
          variant: ButtonVariant.text,
          onPressed: () => onAction(PartnershipAction.rateCancel),
        ),
      if (proposal != null && myTurn) ...[
        AppButton(
          text: 'Recusar tabela',
          variant: ButtonVariant.text,
          onPressed: () => onAction(PartnershipAction.rateDecline),
        ),
        if (counter != null) counter,
        AppButton(
          text: 'Aceitar tabela',
          icon: Icons.check,
          onPressed: () => onAction(PartnershipAction.rateAccept),
        ),
      ],
      AppButton(
        text: 'Encerrar parceria',
        icon: Icons.link_off,
        variant: ButtonVariant.text,
        onPressed: () => onAction(PartnershipAction.end),
      ),
      if (onProposeRate != null && !myTurn)
        AppButton(
          text: proposal == null ? 'Propor tabela' : 'Mudar proposta',
          icon: Icons.request_quote_outlined,
          variant: ButtonVariant.outlined,
          onPressed: onProposeRate,
        ),
    ];
  }
}

/// Proposta de tabela em aberto
class _ProposalBox extends StatelessWidget {
  final RateProposal proposal;
  final PartnershipSide viewer;

  const _ProposalBox({required this.proposal, required this.viewer});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mine = proposal.proposedBy == viewer;
    final who = mine ? 'Você propôs' : '${_capitalize(proposal.proposedBy.label)} propôs';
    final what = proposal.toDefault ? 'voltar à tabela padrão da associação' : 'uma tabela especial';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningLighter.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$who $what${mine ? '. Aguardando ${viewer.other.label}.' : '.'}',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (proposal.rate != null) ...[
            const SizedBox(height: 6),
            DeliveryRateSummary(rate: proposal.rate!),
          ],
        ],
      ),
    );
  }

  static String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
