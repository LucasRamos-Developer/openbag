import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/cash/cash_report.dart';
import '../../../services/api_client.dart';
import '../../../services/restaurant_cash_service.dart';
import '../../../services/restaurant_panel_service.dart';
import '../../../utils/feedback.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/courier/courier_avatar.dart';
import '../../../widgets/cash/subsidy_report_card.dart';

/// Períodos do caixa
enum CashPeriod {
  today('Hoje'),
  yesterday('Ontem'),
  week('7 dias'),
  month('Este mês'),
  lastMonth('Mês passado');

  final String label;

  const CashPeriod(this.label);

  /// Datas locais, [início, fim] inclusivo
  (DateTime, DateTime) range(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      CashPeriod.today => (today, today),
      CashPeriod.yesterday => (today.subtract(const Duration(days: 1)), today.subtract(const Duration(days: 1))),
      CashPeriod.week => (today.subtract(const Duration(days: 6)), today),
      CashPeriod.month => (DateTime(now.year, now.month, 1), today),
      CashPeriod.lastMonth => (DateTime(now.year, now.month - 1, 1), DateTime(now.year, now.month, 0)),
    };
  }
}

/// Caixa: vendas pelo OpenBag no período e acerto com cada entregador.
/// Pagamento na entrega: o dinheiro fica com o entregador até o acerto; cartão e Pix caem na maquininha/Pix da loja.
class CashTab extends StatefulWidget {
  const CashTab({super.key});

  @override
  State<CashTab> createState() => CashTabState();
}

class CashTabState extends State<CashTab> {
  CashPeriod _period = CashPeriod.today;
  CashReport? _report;
  String? _error;
  bool _loading = false;
  CourierCashLine? _settling;

  int? get _restaurantId => context.read<RestaurantPanelService>().selectedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  /// Recarrega ao voltar para a seção (o painel mantém as abas vivas)
  Future<void> refresh() => _load();

  Future<void> _load() async {
    final id = _restaurantId;
    if (id == null) return;
    final (from, to) = _period.range(DateTime.now());
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await context.read<RestaurantCashService>().report(id, from: from, to: to);
      if (mounted) setState(() => _report = report);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _settle(CourierCashLine line) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Acertar com ${line.name}?',
      message: '${line.pendingOrders} ${line.pendingOrders == 1 ? 'entrega' : 'entregas'} sem acerto.\n'
          'Recebeu em dinheiro: ${formatMoney(line.pendingCash)}\n'
          'Ganhou nas entregas: ${formatMoney(line.pendingEarnings)}\n\n'
          '${settlementBalanceLabel(line.pendingBalance)}.',
      confirmLabel: 'Acertado',
    );
    if (!confirmed || !mounted) return;
    setState(() => _settling = line);
    final ok = await runWithFeedback(
      context,
      () => context.read<RestaurantCashService>().settle(_restaurantId!, line),
      success: 'Acerto com ${line.name} registrado',
    );
    if (!mounted) return;
    setState(() => _settling = null);
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return RefreshIndicator(
      onRefresh: _load,
      child: AppPageListView(
        children: [
          const AppSectionHeader(title: 'Caixa', subtitle: 'Vendas pelo OpenBag e acerto com os entregadores'),
          AppFilterChips<CashPeriod>(
            items: [for (final p in CashPeriod.values) SelectItem(value: p, label: p.label)],
            value: _period,
            padding: const EdgeInsets.only(bottom: 8),
            onSelected: (p) {
              setState(() => _period = p);
              _load();
            },
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2) else const SizedBox(height: 2),
          const SizedBox(height: 12),
          if (report == null && _error != null)
            AppEmptyState(icon: Icons.cloud_off_outlined, message: _error!, actionLabel: 'Tentar novamente', onAction: _load)
          else if (report != null) ...[
            _Summary(summary: report.summary),
            const SizedBox(height: 16),
            if (report.subsidy.total > 0) ...[
              SubsidyReportCard(subsidy: report.subsidy),
              const SizedBox(height: 16),
            ],
            _PaymentsCard(payments: report.payments),
            const SizedBox(height: 16),
            _CouriersCard(lines: report.couriers, settling: _settling, onSettle: _settle),
            if (report.settlements.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SettlementsCard(settlements: report.settlements),
            ],
          ],
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final CashSummary summary;

  const _Summary({required this.summary});

  @override
  Widget build(BuildContext context) {
    return AppResponsiveGrid(
      maxColumns: 5,
      minItemWidth: 190,
      runSpacing: 16,
      children: [
        AppStatTile(
          label: 'Vendido',
          value: formatMoney(summary.totalReceived),
          icon: Icons.payments_outlined,
          caption: 'Produtos ${formatMoney(summary.productSales)} + entrega ${formatMoney(summary.deliveryFees)}',
          highlighted: true,
        ),
        AppStatTile(
          label: 'Pedidos entregues',
          value: '${summary.deliveredOrders}',
          icon: Icons.receipt_long_outlined,
          caption: summary.cancelledOrders == 0
              ? 'Nenhum cancelado'
              : '${summary.cancelledOrders} ${summary.cancelledOrders == 1 ? 'cancelado' : 'cancelados'}',
        ),
        AppStatTile(
          label: 'Pago aos entregadores',
          value: formatMoney(summary.paidToCouriers),
          icon: Icons.two_wheeler_outlined,
          caption: summary.restaurantSubsidy > 0
              ? 'Inclui ${formatMoney(summary.restaurantSubsidy)} de diferença assumida'
              : 'Valor das entregas feitas',
        ),
        AppStatTile(
          label: 'Saldo da loja',
          value: formatMoney(summary.storeBalance),
          icon: Icons.account_balance_wallet_outlined,
          caption: 'Vendido − pago aos entregadores',
        ),
        AppStatTile(
          label: 'Ticket médio',
          value: formatMoney(summary.averageTicket),
          icon: Icons.local_offer_outlined,
          caption: summary.withoutCourier > 0 ? '${summary.withoutCourier} entregues sem entregador marcado' : null,
        ),
      ],
    );
  }
}

/// Uma barra horizontal por forma de pagamento (magnitude de uma série só: uma cor, valor ao lado)
class _PaymentsCard extends StatelessWidget {
  final List<PaymentLine> payments;

  const _PaymentsCard({required this.payments});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final max = payments.fold(0.0, (m, p) => p.amount > m ? p.amount : m);
    final total = payments.fold(0.0, (s, p) => s + p.amount);

    return AppPanelCard(
      title: 'Formas de pagamento',
      subtitle: 'Dinheiro fica com o entregador até o acerto; cartão e Pix caem na maquininha ou no Pix da loja',
      child: payments.isEmpty
          ? Text('Nenhuma venda no período.', style: TextStyle(color: c.textMuted))
          : Column(
              children: [
                for (final p in payments)
                  Tooltip(
                    message: '${p.method.label}: ${p.orders} ${p.orders == 1 ? 'pedido' : 'pedidos'} · '
                        '${formatMoney(p.amount)} (${total == 0 ? 0 : (p.amount / total * 100).round()}%)',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 150,
                            child: Row(
                              children: [
                                Icon(p.method.icon, size: 18, color: c.textMuted),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(p.method.label.replaceAll(RegExp(r' \(.*\)'), ''),
                                      overflow: TextOverflow.ellipsis, style: TextStyle(color: c.text)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) => Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  height: 14,
                                  width: max == 0 ? 0 : (constraints.maxWidth * p.amount / max).clamp(4.0, constraints.maxWidth),
                                  decoration: BoxDecoration(
                                    color: c.primary,
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 150,
                            child: Text(
                              '${formatMoney(p.amount)} · ${p.orders}',
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                color: c.text,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _CouriersCard extends StatelessWidget {
  final List<CourierCashLine> lines;
  final CourierCashLine? settling;
  final void Function(CourierCashLine line) onSettle;

  const _CouriersCard({required this.lines, required this.settling, required this.onSettle});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AppPanelCard(
      title: 'Acerto com entregadores',
      subtitle: 'O saldo soma todas as entregas ainda não acertadas, de qualquer dia',
      child: lines.isEmpty
          ? Text('Nenhuma entrega com entregador no período.', style: TextStyle(color: c.textMuted))
          : Column(
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) Divider(height: 24, color: c.border),
                  _CourierRow(line: lines[i], busy: identical(settling, lines[i]), onSettle: () => onSettle(lines[i])),
                ],
              ],
            ),
    );
  }
}

class _CourierRow extends StatelessWidget {
  final CourierCashLine line;
  final bool busy;
  final VoidCallback onSettle;

  const _CourierRow({required this.line, required this.busy, required this.onSettle});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final info = Row(
      children: [
        line.staff
            ? CircleAvatar(
                radius: 20,
                backgroundColor: c.primary.withValues(alpha: 0.12),
                child: Icon(Icons.badge_outlined, color: c.primaryText, size: 20),
              )
            : CourierAvatar(photoUrl: line.photoUrl, name: line.name, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${line.name} · ${line.staff ? 'Equipe da loja' : 'App OpenBag'}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                '${line.deliveries} ${line.deliveries == 1 ? 'entrega' : 'entregas'} no período · '
                'ganhou ${formatMoney(line.earnings)} · recebeu ${formatMoney(line.cashCollected)} em dinheiro',
                style: TextStyle(color: c.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );

    final balance = line.hasPending
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(settlementBalanceLabel(line.pendingBalance),
                  textAlign: TextAlign.end, style: TextStyle(color: c.text, fontWeight: FontWeight.w800)),
              Text('${line.pendingOrders} sem acerto', style: TextStyle(color: c.textMuted, fontSize: 12)),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 18, color: c.success),
              const SizedBox(width: 6),
              Text('Tudo acertado', style: TextStyle(color: c.textMuted)),
            ],
          );

    final action = AppButton(
      text: 'Acertar',
      icon: Icons.handshake_outlined,
      variant: ButtonVariant.outlined,
      isLoading: busy,
      onPressed: line.hasPending && !busy ? onSettle : null,
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 640) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            info,
            const SizedBox(height: 10),
            Row(children: [Expanded(child: Align(alignment: Alignment.centerLeft, child: balance)), if (line.hasPending) action]),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: info),
          const SizedBox(width: 16),
          balance,
          if (line.hasPending) ...[const SizedBox(width: 16), action],
        ],
      );
    });
  }
}

class _SettlementsCard extends StatelessWidget {
  final List<Settlement> settlements;

  const _SettlementsCard({required this.settlements});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AppPanelCard(
      title: 'Acertos feitos no período',
      child: Column(
        children: [
          for (final s in settlements)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.handshake_outlined, color: c.primaryText),
              title: Text('${s.name} · ${s.ordersCount} ${s.ordersCount == 1 ? 'entrega' : 'entregas'}'),
              subtitle: Text(
                '${formatDateTime(s.settledAt)}${s.settledBy != null ? ' · por ${s.settledBy}' : ''} · '
                'dinheiro ${formatMoney(s.cashCollected)}, ganhos ${formatMoney(s.courierEarnings)}',
                style: TextStyle(color: c.textMuted, fontSize: 13),
              ),
              trailing: Text(settlementBalanceLabel(s.balance), style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
