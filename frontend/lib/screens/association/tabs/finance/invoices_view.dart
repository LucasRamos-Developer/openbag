import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/cooperative/billing.dart';
import '../../../../services/association_service.dart';
import '../../../../services/cooperative_service.dart';
import '../../../../utils/feedback.dart';
import '../../../../utils/formatters.dart';
import '../../../../widgets/cooperative/invoice_widgets.dart';

/// Faturas dos cooperados por mês: o mês em andamento é prévia; nos meses fechados o gestor gera as que faltam,
/// dá baixa (Pix, dinheiro...), dispensa ou desfaz
class InvoicesView extends StatefulWidget {
  const InvoicesView({super.key});

  @override
  State<InvoicesView> createState() => _InvoicesViewState();
}

enum _Filter { all, open, paid }

class _InvoicesViewState extends State<InvoicesView> {
  // Abre no mês passado: é nele que estão as faturas para cobrar
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month - 1);
  _Filter _filter = _Filter.all;
  int _version = 0;

  int get _orgId => context.read<AssociationService>().association!.id;
  CooperativeService get _service => context.read<CooperativeService>();

  void _reload() => setState(() => _version++);

  Future<void> _generate() async {
    final ok = await runWithFeedback(context, () => _service.generateInvoices(_orgId, _month),
        success: 'Faturas de ${formatMonth(_month)} geradas');
    if (ok) _reload();
  }

  Future<void> _open(Invoice invoice) async {
    // Os serviços são do app inteiro: a tela aberta por cima continua enxergando
    final changed = await showAppAdaptive<bool>(context, builder: (_) => _InvoiceDetails(invoice: invoice));
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
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
                  lastMonth: now,
                  onChanged: (m) => setState(() => _month = m),
                ),
                AppDropdownChip<_Filter>(
                  label: 'Situação',
                  emptyValue: _Filter.all,
                  value: _filter,
                  items: const [
                    SelectItem(value: _Filter.all, label: 'Todas'),
                    SelectItem(value: _Filter.open, label: 'Em aberto'),
                    SelectItem(value: _Filter.paid, label: 'Pagas'),
                  ],
                  onSelected: (f) => setState(() => _filter = f),
                ),
              ],
            ),
          );
        }),
        Expanded(
          child: AppLoadView<InvoiceMonth>(
            key: ValueKey('${apiMonth(_month)}-$_version'),
            load: () => _service.fetchInvoices(_orgId, _month),
            builder: (context, month, reload) => _buildMonth(month),
          ),
        ),
      ],
    );
  }

  Widget _buildMonth(InvoiceMonth month) {
    final invoices = month.invoices.where((i) => switch (_filter) {
          _Filter.all => true,
          _Filter.open => i.status == InvoiceStatus.OPEN,
          _Filter.paid => i.status == InvoiceStatus.PAID,
        });
    final t = month.totals;

    return AppPageListView(
      top: 12,
      children: [
        if (month.preview)
          const _Notice(
            icon: Icons.hourglass_empty,
            text: 'Mês em andamento: os valores ainda vão mudar. As faturas são geradas no dia 1 do próximo mês.',
          ),
        if (!month.preview && month.missing > 0)
          _Notice(
            icon: Icons.post_add,
            text: '${month.missing} ${month.missing == 1 ? 'cooperado ainda não tem' : 'cooperados ainda não têm'} '
                'fatura neste mês.',
            action: AppButton(text: 'Gerar faturas', icon: Icons.bolt, onPressed: _generate),
          ),
        AppStatStrip(stats: [
          AppStat(label: month.preview ? 'Previsto' : 'Total', value: formatMoney(t.total), caption: '${t.count} faturas'),
          AppStat(label: 'Pago', value: formatMoney(t.paid)),
          AppStat(
            label: 'Em aberto',
            value: formatMoney(t.open),
            caption: t.overdue > 0 ? '${formatMoney(t.overdue)} em atraso' : null,
          ),
        ]),
        const SizedBox(height: 16),
        if (invoices.isEmpty)
          AppEmptyState(
            icon: Icons.receipt_long_outlined,
            message: month.invoices.isEmpty ? 'Nenhuma fatura em ${formatMonth(month.month)}.' : 'Nenhuma fatura nesta situação.',
          ),
        for (final invoice in invoices) ...[
          AppListTileCard(
            onTap: () => _open(invoice),
            title: invoice.memberLabel,
            subtitle: invoice.preview
                ? 'Ganhos até agora ${formatMoney(invoice.earnings)}'
                : invoice.status == InvoiceStatus.PAID
                    ? 'Paga em ${formatDate(invoice.paidOn)}'
                    : 'Vence em ${formatDate(invoice.dueDate)}',
            value: formatMoney(invoice.total),
            trailing: InvoiceStatusChip(invoice: invoice),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const _Notice({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        backgroundColor: colors.surfaceAlt,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: colors.textMuted),
                const SizedBox(width: 12),
                Expanded(child: Text(text)),
              ],
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: action!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Detalhe da fatura com as ações: dar baixa, dispensar ou desfazer
class _InvoiceDetails extends StatefulWidget {
  final Invoice invoice;

  const _InvoiceDetails({required this.invoice});

  @override
  State<_InvoiceDetails> createState() => _InvoiceDetailsState();
}

class _InvoiceDetailsState extends State<_InvoiceDetails> {
  late Invoice _invoice = widget.invoice;
  bool _busy = false;
  bool _changed = false;

  int get _orgId => context.read<AssociationService>().association!.id;
  CooperativeService get _service => context.read<CooperativeService>();

  Future<void> _run(Future<Invoice> Function() action, String success) async {
    setState(() => _busy = true);
    await runWithFeedback(context, () async {
      final updated = await action();
      if (mounted) {
        setState(() {
          _invoice = updated;
          _changed = true;
        });
      }
    }, success: success);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _pay() async {
    final payment = await showAppAdaptive<_Payment>(context, builder: (_) => const _PaymentForm());
    if (payment == null || !mounted) return;
    await _run(
      () => _service.payInvoice(_orgId, _invoice.id!, method: payment.method, paidOn: payment.date, notes: payment.notes),
      'Pagamento registrado',
    );
  }

  Future<void> _waive() async {
    final reason = await AppDialog.reason(
      context,
      title: 'Dispensar a fatura?',
      confirmLabel: 'Dispensar',
      message: '${_invoice.memberName} não vai pagar a fatura de ${formatMonth(_invoice.month)}.',
    );
    if (reason == null || !mounted) return;
    await _run(() => _service.waiveInvoice(_orgId, _invoice.id!, reason), 'Fatura dispensada');
  }

  Future<void> _reopen() async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Desfazer?',
      message: _invoice.status == InvoiceStatus.PAID
          ? 'A fatura volta a ficar em aberto e os lançamentos do pagamento saem do caixa.'
          : 'A fatura volta a ficar em aberto.',
      confirmLabel: 'Desfazer',
    );
    if (!confirmed || !mounted) return;
    await _run(() => _service.reopenInvoice(_orgId, _invoice.id!), 'Fatura em aberto de novo');
  }

  @override
  Widget build(BuildContext context) {
    final invoice = _invoice;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: AppAdaptiveSheet(
        title: invoice.memberLabel,
        subtitle: 'Fatura de ${formatMonth(invoice.month)}',
        onClose: () => Navigator.of(context).pop(_changed),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(alignment: Alignment.centerLeft, child: InvoiceStatusChip(invoice: invoice)),
            const SizedBox(height: 16),
            InvoiceBreakdown(invoice: invoice),
          ],
        ),
        actions: invoice.preview
            ? const []
            : invoice.status == InvoiceStatus.OPEN
                ? [
                    AppButton(
                      text: 'Dispensar',
                      variant: ButtonVariant.outlined,
                      onPressed: _busy ? null : _waive,
                    ),
                    AppButton(text: 'Dar baixa', icon: Icons.check, isLoading: _busy, onPressed: _busy ? null : _pay),
                  ]
                : [
                    AppButton(
                      text: invoice.status == InvoiceStatus.PAID ? 'Desfazer baixa' : 'Desfazer dispensa',
                      icon: Icons.undo,
                      variant: ButtonVariant.outlined,
                      isLoading: _busy,
                      onPressed: _busy ? null : _reopen,
                    ),
                  ],
      ),
    );
  }
}

class _Payment {
  final MemberPaymentMethod method;
  final DateTime date;
  final String? notes;

  const _Payment(this.method, this.date, this.notes);
}

/// Baixa manual: como e quando o cooperado pagou
class _PaymentForm extends StatefulWidget {
  const _PaymentForm();

  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  MemberPaymentMethod _method = MemberPaymentMethod.PIX;
  DateTime _date = DateTime.now();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveSheet(
      title: 'Dar baixa',
      maxWidth: 480,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Como foi pago?', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (final method in MemberPaymentMethod.values) ...[
            AppChoiceTile(
              title: method.label,
              selected: _method == method,
              onTap: () => setState(() => _method = method),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          AppDateField(
            label: 'Data do pagamento',
            value: _date,
            lastDate: DateTime.now(),
            onChanged: (d) => setState(() => _date = d ?? DateTime.now()),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _notes,
            labelText: 'Observação (opcional)',
            variant: TextFieldVariant.filled,
            maxLength: 500,
          ),
        ],
      ),
      actions: [
        AppButton(text: 'Cancelar', variant: ButtonVariant.outlined, onPressed: () => Navigator.of(context).pop()),
        AppButton(
          text: 'Registrar',
          icon: Icons.check,
          onPressed: () => Navigator.of(context).pop(_Payment(_method, _date, _notes.text.trim())),
        ),
      ],
    );
  }
}
