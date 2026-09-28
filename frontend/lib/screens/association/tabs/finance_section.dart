import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/ui.dart';
import '../../../widgets/navigation/panel_sub_tabs.dart';
import '../association_section.dart';
import 'finance/billing_view.dart';
import 'finance/fund_view.dart';
import 'finance/invoices_view.dart';
import 'finance/ledger_view.dart';
import 'finance/summary_view.dart';

/// Financeiro da associação: resumo, faturas dos cooperados, livro-caixa, caixinha solidária e a cobrança
/// (política e adicionais), cada um numa sub-aba com endereço próprio
class FinanceSectionView extends StatelessWidget {
  final FinanceTab tab;

  const FinanceSectionView({super.key, this.tab = FinanceTab.summary});

  @override
  Widget build(BuildContext context) {
    return PanelSubTabs<FinanceTab>(
      title: 'Financeiro',
      subtitle: 'Mensalidades, adicionais, caixa da associação e caixinha solidária',
      tabs: [for (final t in FinanceTab.values) SelectItem(value: t, label: t.label, icon: t.icon)],
      value: tab,
      onSelected: (t) => context.go(t.path),
      child: switch (tab) {
        FinanceTab.summary => const FinanceSummaryView(),
        FinanceTab.invoices => const InvoicesView(),
        FinanceTab.ledger => const LedgerView(),
        FinanceTab.fund => const FundView(),
        FinanceTab.billing => const BillingView(),
      },
    );
  }
}
