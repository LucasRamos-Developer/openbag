import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/courier/courier_earnings.dart';
import '../../../services/api_client.dart';
import '../../../services/courier_service.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/courier/earnings_chart.dart';
import '../../../widgets/courier/earnings_summary.dart';

enum _Period {
  week('7 dias', 7),
  twoWeeks('15 dias', 15),
  month('30 dias', 30);

  final String label;
  final int days;
  const _Period(this.label, this.days);
}

/// Quanto o entregador ganhou: hoje, semana, mês, gráfico por dia e as entregas do período
class EarningsTab extends StatefulWidget {
  const EarningsTab({super.key});

  @override
  State<EarningsTab> createState() => EarningsTabState();
}

class EarningsTabState extends State<EarningsTab> {
  _Period _period = _Period.week;
  CourierEarnings? _earnings;
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
    try {
      final data = await context.read<CourierService>().fetchEarnings(
            from: DateTime(today.year, today.month, today.day).subtract(Duration(days: _period.days - 1)),
            to: today,
          );
      if (mounted) setState(() => _earnings = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
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
                    subtitle: 'Valor da tabela da sua associação por entrega concluída. Você fica com 100%.',
                  ),
                  EarningsSummary(earnings: earnings),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Ganhos por dia', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
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
                    '${earnings.period.deliveries == 1 ? 'entrega' : 'entregas'} nos últimos ${_period.days} dias',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    child: EarningsChart(days: earnings.daily),
                  ),
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
