import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/cooperative/ledger.dart';
import '../../../../services/association_service.dart';
import '../../../../services/cooperative_service.dart';
import '../../../../utils/formatters.dart';
import '../../../../widgets/cooperative/cash_flow_chart.dart';
import '../../../../widgets/cooperative/fund_card.dart';
import '../../association_section.dart';

/// Painel financeiro: saldo da caixinha em destaque, arrecadado, gasto, a receber e o gráfico dos últimos meses
class FinanceSummaryView extends StatelessWidget {
  const FinanceSummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    final association = context.watch<AssociationService>().association!;
    final service = context.read<CooperativeService>();

    return AppLoadView<FinanceSummary>(
      load: () => service.fetchSummary(association.id),
      builder: (context, summary, reload) => AppPageListView(
        top: 8,
        children: [
          if (!association.feePolicyConfigured) ...[
            _SetupBanner(onTap: () => context.go(FinanceTab.billing.path)),
            const SizedBox(height: 16),
          ],
          FundHeroCard(
            balance: summary.fundBalance,
            totalIn: summary.fundIn,
            totalOut: summary.fundOut,
            caption: 'Entradas e saídas desde ${formatDate(summary.from)}',
          ),
          const SizedBox(height: 16),
          // No celular: 2 colunas; em telas largas, 4 lado a lado
          AppResponsiveGrid(
            minItemWidth: 160,
            children: [
              AppStatTile(
                label: 'Arrecadado',
                value: formatMoney(summary.collected),
                icon: Icons.south_west,
                caption: 'Mensalidades e contribuições',
              ),
              AppStatTile(
                label: 'Gasto',
                value: formatMoney(summary.spent),
                icon: Icons.north_east,
                caption: 'Despesas e auxílios',
              ),
              AppStatTile(
                label: 'A receber',
                value: formatMoney(summary.receivable),
                icon: Icons.schedule,
                caption: summary.overdue > 0 ? '${formatMoney(summary.overdue)} em atraso' : 'Nada em atraso',
              ),
              AppStatTile(
                label: 'Caixa geral',
                value: formatMoney(summary.generalBalance),
                icon: Icons.account_balance_outlined,
                caption: 'Saldo total',
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppPanelCard(
            title: 'Entradas e saídas por mês',
            subtitle: '${formatMonth(summary.from)} a ${formatMonth(summary.to)}',
            child: CashFlowChart(months: summary.months),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              AppButton(
                text: 'Ver faturas',
                icon: Icons.receipt_long_outlined,
                variant: ButtonVariant.outlined,
                onPressed: () => context.go(FinanceTab.invoices.path),
              ),
              AppButton(
                text: 'Lançamentos',
                icon: Icons.swap_vert,
                variant: ButtonVariant.outlined,
                onPressed: () => context.go(FinanceTab.ledger.path),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetupBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _SetupBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      backgroundColor: AppColors.warningLighter.withValues(alpha: 0.5),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warningDarker),
          SizedBox(width: 12),
          Expanded(
            child: Text('Defina como cobrar a mensalidade dos cooperados para gerar as faturas.',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
