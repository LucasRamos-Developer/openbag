import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/association/association_report.dart';
import '../../../models/report_period.dart';
import '../../../services/api_client.dart';
import '../../../services/association_service.dart';
import '../../../widgets/association/association_report_widgets.dart';
import '../../../widgets/courier/earnings_chart.dart';

/// Relatórios da associação: entregas e ganhos dos cooperados no período, por dia, por cooperado e por loja
class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => ReportsTabState();
}

class ReportsTabState extends State<ReportsTab> {
  ReportPeriod _period = ReportPeriod.month;
  AssociationReport? _report;
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
    final (from, to) = _period.range(DateTime.now());
    try {
      final report = await context.read<AssociationService>().fetchReport(from: from, to: to);
      if (mounted) setState(() => _report = report);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return RefreshIndicator(
      onRefresh: refresh,
      child: AppPageListView(
        children: [
          const AppSectionHeader(
            title: 'Relatórios',
            subtitle: 'Entregas dos cooperados pela associação. Cada entrega conta para a associação em que o '
                'cooperado estava no dia, mesmo que ele tenha saído depois.',
          ),
          AppFilterChips<ReportPeriod>(
            items: [for (final p in ReportPeriod.values) SelectItem(value: p, label: p.label)],
            value: _period,
            padding: const EdgeInsets.only(bottom: 8),
            onSelected: (p) {
              setState(() => _period = p);
              refresh();
            },
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2) else const SizedBox(height: 2),
          const SizedBox(height: 12),
          if (report == null && _error != null)
            AppEmptyState(icon: Icons.cloud_off_outlined, message: _error!, actionLabel: 'Tentar novamente', onAction: refresh)
          else if (report != null) ...[
            AssociationReportSummaryGrid(summary: report.summary),
            const SizedBox(height: 16),
            AppPanelCard(
              title: 'Pago por dia',
              child: EarningsChart(days: report.daily),
            ),
            const SizedBox(height: 16),
            AppPanelCard(
              title: 'Por cooperado',
              subtitle: 'Quem ganhou mais primeiro',
              child: AssociationMemberList(lines: report.byMember ?? const []),
            ),
            const SizedBox(height: 16),
            AppPanelCard(
              title: 'Por loja',
              subtitle: 'Lojas com mais entregas primeiro',
              child: AssociationRestaurantList(lines: report.byRestaurant),
            ),
            const SizedBox(height: 16),
            AppPanelCard(
              title: 'Ocorrências',
              subtitle: 'Relatadas pelos cooperados, por tipo e por loja. Servem para conversar com as lojas; '
                  'não contam contra ninguém.',
              child: AssociationIncidentsView(incidents: report.incidents),
            ),
          ],
        ],
      ),
    );
  }
}
