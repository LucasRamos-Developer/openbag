import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/association/association_report.dart';
import '../../../models/courier/courier_earnings.dart';
import '../../../services/api_client.dart';
import '../../../services/courier_service.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/association/association_report_widgets.dart';
import '../../../widgets/courier/earnings_chart.dart';
import '../../../widgets/courier/earnings_summary.dart';
import '../../../widgets/courier/work_stats_card.dart';

enum _Period {
  today('Hoje', 1),
  week('7 dias', 7),
  twoWeeks('15 dias', 15),
  month('30 dias', 30);

  final String label;
  final int days;
  const _Period(this.label, this.days);
}

/// Quanto o entregador ganhou: hoje, semana, mês, gráfico por dia, km, tempo e médias, e as entregas do período
class EarningsTab extends StatefulWidget {
  const EarningsTab({super.key});

  @override
  State<EarningsTab> createState() => EarningsTabState();
}

class EarningsTabState extends State<EarningsTab> {
  _Period _period = _Period.week;
  CourierEarnings? _earnings;
  // Resumo da associação no mesmo período (nulo se ele não for cooperado ativo)
  AssociationReport? _association;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
  }

  Future<void> refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final today = DateTime.now();
    final from = DateTime(today.year, today.month, today.day).subtract(Duration(days: _period.days - 1));
    final service = context.read<CourierService>();
    try {
      final data = await service.fetchEarnings(from: from, to: today);
      final association = await _fetchAssociation(service, from, today);
      if (mounted) {
        setState(() {
          _earnings = data;
          _association = association;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static Future<AssociationReport?> _fetchAssociation(CourierService service, DateTime from, DateTime to) async {
    try {
      return await service.fetchAssociationReport(from: from, to: to);
    } on ApiException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final earnings = _earnings;
    final textTheme = Theme.of(context).textTheme;

    if (earnings == null) {
      return _error != null
          ? AppEmptyState(icon: Icons.cloud_off_outlined, message: _error!, actionLabel: 'Tentar novamente', onAction: refresh)
          : const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppSectionHeader(
                    title: 'Meus ganhos',
                    subtitle: 'Valor da tabela que vale em cada loja (a da sua associação ou a especial combinada '
                        'com a loja) por entrega concluída. Você fica com 100%.',
                  ),
                  EarningsSummary(earnings: earnings),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Período', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      if (_loading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppFilterChips<_Period>(
                    items: [for (final p in _Period.values) SelectItem(value: p, label: p.label)],
                    value: _period,
                    onSelected: (p) {
                      setState(() => _period = p);
                      refresh();
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${formatMoney(earnings.period.amount)} em ${earnings.period.deliveries} '
                    '${earnings.period.deliveries == 1 ? 'entrega' : 'entregas'} '
                    '${_period == _Period.today ? 'hoje' : 'nos últimos ${_period.days} dias'}',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_period != _Period.today)
                    AppCard(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                      child: EarningsChart(days: earnings.daily),
                    ),
                  if (earnings.stats != null) ...[
                    const SizedBox(height: 16),
                    WorkStatsCard(stats: earnings.stats!),
                  ],
                  if (_association != null) ...[
                    const SizedBox(height: 24),
                    _AssociationShare(report: _association!, days: _period.days),
                  ],
                  const SizedBox(height: 24),
                  Text('Entregas do período', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (earnings.deliveries.isEmpty)
                    Text('Nenhuma entrega no período.', style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary))
                  else
                    for (final d in earnings.deliveries)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(d.restaurantName),
                        subtitle: Text([
                          formatDateTime(d.deliveredAt),
                          if (d.displayCode != null) 'Pedido ${d.displayCode}',
                          if (d.distanceKm != null) '${d.distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km',
                        ].join(' · ')),
                        trailing: Text(formatMoney(d.courierFee), style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
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

/// Minha associação no período: o total dos cooperados, a minha parte e as lojas atendidas.
/// Os ganhos de cada colega não aparecem.
class _AssociationShare extends StatelessWidget {
  final AssociationReport report;
  final int days;

  const _AssociationShare({required this.report, required this.days});

  @override
  Widget build(BuildContext context) {
    final mine = report.mine;
    return AppPanelCard(
      title: 'Minha associação',
      subtitle: days == 1 ? '${report.associationName} hoje' : '${report.associationName} nos últimos $days dias',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppResponsiveGrid(
            maxColumns: 3,
            minItemWidth: 170,
            children: [
              AppStatTile(
                label: 'Pago aos cooperados',
                value: formatMoney(report.summary.earnings),
                icon: Icons.groups_outlined,
              ),
              AppStatTile(
                label: 'Entregas da associação',
                value: formatCount(report.summary.deliveries),
                icon: Icons.local_shipping_outlined,
              ),
              if (mine != null)
                AppStatTile(
                  label: 'Minha parte',
                  value: formatMoney(mine.earnings),
                  caption: '${mine.deliveries} ${mine.deliveries == 1 ? 'entrega' : 'entregas'}',
                  icon: Icons.person_outline,
                  highlighted: true,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Por loja', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          AssociationRestaurantList(lines: report.byRestaurant),
        ],
      ),
    );
  }
}
