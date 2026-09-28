import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/cooperative/ledger.dart';
import '../../../../services/association_service.dart';
import '../../../../services/cooperative_service.dart';
import '../../../../utils/feedback.dart';
import '../../../../utils/formatters.dart';
import '../../../../widgets/cooperative/fund_card.dart';
import '../../../../widgets/cooperative/ledger_entry_form.dart';

/// Livro-caixa do mês: as entradas das faturas pagas e os lançamentos manuais (despesas, outras entradas,
/// contribuições e auxílios). No celular, "Lançar" fica no botão flutuante.
class LedgerView extends StatefulWidget {
  const LedgerView({super.key});

  @override
  State<LedgerView> createState() => _LedgerViewState();
}

class _LedgerViewState extends State<LedgerView> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  LedgerAccount? _account;
  int _version = 0;

  int get _orgId => context.read<AssociationService>().association!.id;
  CooperativeService get _service => context.read<CooperativeService>();

  Future<List<LedgerEntry>> _load() async {
    final from = DateTime(_month.year, _month.month);
    final to = DateTime(_month.year, _month.month + 1, 0);
    final entries = <LedgerEntry>[];
    var page = 0;
    while (true) {
      final result = await _service.fetchLedger(_orgId, account: _account, from: from, to: to, page: page);
      entries.addAll(result.items);
      if (!result.hasMore || page > 20) break;
      page++;
    }
    return entries;
  }

  Future<void> _create() async {
    if (await showLedgerEntryForm(context)) setState(() => _version++);
  }

  Future<void> _actions(BuildContext tileContext, LedgerEntry entry) async {
    if (!entry.manual) {
      AppToast.show(context, message: 'Este lançamento veio de uma fatura: desfaça a baixa na aba Faturas');
      return;
    }
    final action = await showAppActionSheet<String>(
      tileContext,
      title: entry.description,
      actions: const [AppSheetAction(value: 'delete', label: 'Apagar lançamento', icon: Icons.delete_outline, destructive: true)],
    );
    if (action != 'delete' || !mounted) return;
    final confirmed = await AppDialog.confirm(context,
        title: 'Apagar lançamento?', message: '${entry.description} · ${formatMoney(entry.amount)}', confirmLabel: 'Apagar');
    if (!confirmed || !mounted) return;
    final ok = await runWithFeedback(context, () => _service.deleteLedgerEntry(_orgId, entry.id), success: 'Lançamento apagado');
    if (ok) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    final compact = AppLayout.isCompact(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: compact
          ? FloatingActionButton.extended(onPressed: _create, icon: const Icon(Icons.add), label: const Text('Lançar'))
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final padding = AppLayout.contentPadding(constraints.maxWidth, top: 8, bottom: 0);
            return Padding(
              padding: padding,
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppMonthSelector(
                    month: _month,
                    label: formatMonth,
                    lastMonth: DateTime.now(),
                    onChanged: (m) => setState(() => _month = m),
                  ),
                  AppDropdownChip<LedgerAccount?>(
                    label: 'Conta',
                    value: _account,
                    items: [
                      const SelectItem(value: null, label: 'Todas'),
                      for (final a in LedgerAccount.values) SelectItem(value: a, label: a.label),
                    ],
                    onSelected: (a) => setState(() => _account = a),
                  ),
                  if (!compact) AppButton(text: 'Lançar', icon: Icons.add, onPressed: _create),
                ],
              ),
            );
          }),
          Expanded(
            child: AppLoadView<List<LedgerEntry>>(
              key: ValueKey('${apiMonth(_month)}-${_account?.name}-$_version'),
              load: _load,
              builder: (context, entries, reload) {
                final totalIn = entries.where((e) => e.isIn).fold<double>(0, (s, e) => s + e.amount);
                final totalOut = entries.where((e) => !e.isIn).fold<double>(0, (s, e) => s + e.amount);
                return AppPageListView(
                  top: 12,
                  bottom: compact ? 96 : 32,
                  children: [
                    AppStatStrip(stats: [
                      AppStat(label: 'Entradas', value: formatMoney(totalIn)),
                      AppStat(label: 'Saídas', value: formatMoney(totalOut)),
                      AppStat(label: 'Resultado', value: formatMoney(totalIn - totalOut)),
                    ]),
                    const SizedBox(height: 16),
                    if (entries.isEmpty)
                      const AppEmptyState(icon: Icons.swap_vert, message: 'Nenhum lançamento neste mês.'),
                    for (final entry in entries) ...[
                      Builder(
                        builder: (tileContext) => MoneyMovementTile(
                          isIn: entry.isIn,
                          amount: entry.amount,
                          title: entry.description,
                          subtitle: [
                            entry.category.label,
                            if (entry.account == LedgerAccount.SOLIDARITY_FUND) 'Caixinha',
                          ].join(' · '),
                          date: entry.date,
                          onTap: () => _actions(tileContext, entry),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
