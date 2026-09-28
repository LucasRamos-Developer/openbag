import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/cooperative/ledger.dart';
import '../../../../services/association_service.dart';
import '../../../../services/cooperative_service.dart';
import '../../../../widgets/cooperative/fund_card.dart';
import '../../../../widgets/cooperative/ledger_entry_form.dart';

/// Caixinha solidária: saldo em destaque, registrar contribuição ou auxílio e as movimentações do último ano
class FundView extends StatefulWidget {
  const FundView({super.key});

  @override
  State<FundView> createState() => _FundViewState();
}

class _FundViewState extends State<FundView> {
  int _version = 0;

  Future<({FinanceSummary summary, List<LedgerEntry> entries})> _load() async {
    final service = context.read<CooperativeService>();
    final orgId = context.read<AssociationService>().association!.id;
    final now = DateTime.now();
    final results = await Future.wait([
      service.fetchSummary(orgId),
      service.fetchLedger(orgId,
          account: LedgerAccount.SOLIDARITY_FUND, from: DateTime(now.year - 1, now.month, now.day + 1), to: now),
    ]);
    return (summary: results[0] as FinanceSummary, entries: (results[1] as LedgerPage).items);
  }

  Future<void> _register(ManualEntryKind kind) async {
    if (await showLedgerEntryForm(context, kinds: [kind])) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    return AppLoadView<({FinanceSummary summary, List<LedgerEntry> entries})>(
      key: ValueKey(_version),
      load: _load,
      builder: (context, data, reload) {
        final totalIn = data.entries.where((e) => e.isIn).fold<double>(0, (s, e) => s + e.amount);
        final totalOut = data.entries.where((e) => !e.isIn).fold<double>(0, (s, e) => s + e.amount);
        return AppPageListView(
          top: 8,
          children: [
            FundHeroCard(
              balance: data.summary.fundBalance,
              totalIn: totalIn,
              totalOut: totalOut,
              caption: 'Contribuições dos cooperados para quem passar por um problema',
            ),
            const SizedBox(height: 16),
            AppResponsiveRow(
              breakpoint: 420,
              spacing: 12,
              children: [
                AppButton(
                  text: 'Registrar contribuição',
                  icon: Icons.add,
                  variant: ButtonVariant.outlined,
                  fullWidth: true,
                  onPressed: () => _register(ManualEntryKind.CONTRIBUTION),
                ),
                AppButton(
                  text: 'Registrar auxílio',
                  icon: Icons.volunteer_activism_outlined,
                  fullWidth: true,
                  onPressed: () => _register(ManualEntryKind.AID),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'As contribuições mensais dos cooperados entram sozinhas quando a fatura é paga.',
              style: TextStyle(color: context.appColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Text('Movimentações', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (data.entries.isEmpty)
              const AppEmptyState(icon: Icons.volunteer_activism_outlined, message: 'Nenhuma movimentação na caixinha.'),
            for (final entry in data.entries) ...[
              MoneyMovementTile(
                isIn: entry.isIn,
                amount: entry.amount,
                title: entry.description,
                subtitle: entry.category == LedgerCategory.AID && entry.memberName != null ? entry.memberName : null,
                date: entry.date,
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}
