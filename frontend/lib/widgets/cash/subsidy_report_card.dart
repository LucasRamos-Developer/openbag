import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/cash/cash_report.dart';
import '../../utils/formatters.dart';

/// Diferença que a loja assumiu nas entregas do período: total, por associação e pedido a pedido
/// (taxa cobrada do cliente → valor da tabela → diferença). O entregador sempre recebe o valor cheio da tabela.
class SubsidyReportCard extends StatelessWidget {
  final SubsidyReport subsidy;

  const SubsidyReportCard({super.key, required this.subsidy});

  static String _km(double km) => km.toStringAsFixed(1).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final average = subsidy.orders == 0 ? 0.0 : subsidy.total / subsidy.orders;

    return AppPanelCard(
      title: 'Diferença assumida nas entregas',
      subtitle: 'Quando a taxa cobrada do cliente é menor que a tabela da associação, a loja paga a diferença',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppResponsiveGrid(
            maxColumns: 3,
            minItemWidth: 170,
            children: [
              AppStatTile(label: 'Total assumido', value: formatMoney(subsidy.total), icon: Icons.volunteer_activism_outlined),
              AppStatTile(label: 'Pedidos com diferença', value: '${subsidy.orders}', icon: Icons.receipt_long_outlined),
              AppStatTile(label: 'Média por pedido', value: formatMoney(average), icon: Icons.functions),
            ],
          ),
          if (subsidy.byAssociation.length > 1 ||
              (subsidy.byAssociation.length == 1 && subsidy.byAssociation.first.name.isNotEmpty)) ...[
            const SizedBox(height: 16),
            Text('Por associação', style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
            const SizedBox(height: 4),
            for (final a in subsidy.byAssociation)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(a.name, style: TextStyle(color: c.text))),
                    Text('${a.orders} ${a.orders == 1 ? 'pedido' : 'pedidos'} · ',
                        style: TextStyle(color: c.textMuted, fontSize: 13)),
                    Text(formatMoney(a.total), style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 16),
          Text('Pedido a pedido', style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
          for (var i = 0; i < subsidy.lines.length; i++) ...[
            if (i > 0) Divider(height: 16, color: c.border),
            _LineRow(line: subsidy.lines[i]),
          ],
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  final SubsidyLine line;

  const _LineRow({required this.line});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final numbers = TextStyle(color: c.text, fontFeatures: const [FontFeature.tabularFigures()]);
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          [line.displayCode ?? 'Pedido', if (line.deliveredAt != null) formatDateTime(line.deliveredAt)].join(' · '),
          style: TextStyle(fontWeight: FontWeight.w600, color: c.text),
        ),
        Text(
          [
            if (line.courierName != null) line.courierName!,
            if (line.distanceKm != null) '${SubsidyReportCard._km(line.distanceKm!)} km',
          ].join(' · '),
          style: TextStyle(color: c.textMuted, fontSize: 13),
        ),
      ],
    );
    final values = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text('cobrou ${formatMoney(line.customerFee)}', style: numbers),
        Icon(Icons.arrow_forward, size: 14, color: c.textMuted),
        Text('tabela ${formatMoney(line.courierFee)}', style: numbers),
        Icon(Icons.arrow_forward, size: 14, color: c.textMuted),
        Text(formatMoney(line.subsidy), style: numbers.copyWith(fontWeight: FontWeight.w800)),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 640
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [info, const SizedBox(height: 4), values])
            : Row(children: [Expanded(child: info), values]),
      ),
    );
  }
}
