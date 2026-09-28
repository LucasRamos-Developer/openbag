import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/cooperative/billing.dart';
import '../../../../services/member_area_service.dart';
import '../../../../utils/feedback.dart';
import '../../../../utils/formatters.dart';
import '../../../../widgets/cooperative/invoice_widgets.dart';

typedef _InvoicesData = ({MyInvoices invoices, List<MemberAddon> addons});

/// Faturas do cooperado (a do mês em andamento e o histórico) e os adicionais que ele tem
class MemberInvoicesView extends StatefulWidget {
  const MemberInvoicesView({super.key});

  @override
  State<MemberInvoicesView> createState() => _MemberInvoicesViewState();
}

class _MemberInvoicesViewState extends State<MemberInvoicesView> {
  int _version = 0;

  MemberAreaService get _service => context.read<MemberAreaService>();

  Future<_InvoicesData> _load() async {
    final results = await Future.wait([_service.fetchInvoices(), _service.fetchAddons()]);
    return (invoices: results[0] as MyInvoices, addons: results[1] as List<MemberAddon>);
  }

  void _open(Invoice invoice) => showAppAdaptive<void>(
        context,
        builder: (context) => AppAdaptiveSheet(
          title: 'Fatura de ${formatMonth(invoice.month)}',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.centerLeft, child: InvoiceStatusChip(invoice: invoice)),
              const SizedBox(height: 16),
              InvoiceBreakdown(invoice: invoice),
              if (invoice.status == InvoiceStatus.OPEN && !invoice.preview) ...[
                const SizedBox(height: 16),
                Text('Pague à associação por Pix ou em dinheiro. O gestor registra o pagamento e a fatura fica paga aqui.',
                    style: TextStyle(color: context.appColors.textMuted)),
              ],
            ],
          ),
        ),
      );

  Future<void> _cancelAddon(MemberAddon addon) async {
    final confirmed = await AppDialog.confirm(context,
        title: 'Cancelar ${addon.name}?',
        message: 'O adicional sai da próxima fatura. Para voltar, fale com a associação.',
        confirmLabel: 'Cancelar adicional');
    if (!confirmed || !mounted) return;
    final ok = await runWithFeedback(context, () => _service.answerAddon(addon.id, 'cancel'), success: 'Adicional cancelado');
    if (ok) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    return AppLoadView<_InvoicesData>(
      key: ValueKey(_version),
      load: _load,
      builder: (context, data, reload) {
        final textTheme = Theme.of(context).textTheme;
        final current = data.invoices.current;
        final addons = data.addons.where((a) => a.isOpen).toList();
        return AppPageListView(
          top: 8,
          maxWidth: 820,
          children: [
            Text('Como é calculada: ${data.invoices.policy.summary}', style: TextStyle(color: context.appColors.textMuted)),
            const SizedBox(height: 16),
            if (current != null) ...[
              AppListTileCard(
                onTap: () => _open(current),
                title: _capitalize(formatMonth(current.month)),
                subtitle: 'Ganhos até agora ${formatMoney(current.earnings)}',
                value: formatMoney(current.total),
                trailing: InvoiceStatusChip(invoice: current),
              ),
              const SizedBox(height: 8),
            ],
            for (final invoice in data.invoices.history) ...[
              AppListTileCard(
                onTap: () => _open(invoice),
                title: _capitalize(formatMonth(invoice.month)),
                subtitle: invoice.status == InvoiceStatus.PAID
                    ? 'Paga em ${formatDate(invoice.paidOn)}'
                    : 'Vence em ${formatDate(invoice.dueDate)}',
                value: formatMoney(invoice.total),
                trailing: InvoiceStatusChip(invoice: invoice),
              ),
              const SizedBox(height: 8),
            ],
            if (current == null && data.invoices.history.isEmpty)
              const AppEmptyState(icon: Icons.receipt_long_outlined, message: 'Nenhuma fatura ainda.'),
            const SizedBox(height: 24),
            Text('Meus adicionais', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (addons.isEmpty)
              Text('Você não tem adicionais.', style: TextStyle(color: context.appColors.textMuted)),
            for (final addon in addons) ...[
              AppListTileCard(
                leading: const CircleAvatar(child: Icon(Icons.shield_outlined)),
                title: addon.name,
                subtitle: '${addon.priceLabel} · ${addon.status.label}',
                trailing: addon.status == MemberAddonStatus.ACTIVE
                    ? TextButton(onPressed: () => _cancelAddon(addon), child: const Text('Cancelar'))
                    : null,
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  static String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
