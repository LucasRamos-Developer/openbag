import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/association/association_report.dart';
import '../../utils/formatters.dart';
import '../restaurant/restaurant_logo.dart';

String _km(double km) => km.toStringAsFixed(1).replaceAll('.', ',');

String _deliveries(int n) => '$n ${n == 1 ? 'entrega' : 'entregas'}';

/// Números do período: entregas, total pago aos cooperados, km, cooperados, lojas e diferença assumida
class AssociationReportSummaryGrid extends StatelessWidget {
  final AssociationReportSummary summary;

  const AssociationReportSummaryGrid({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return AppResponsiveGrid(
      maxColumns: 3,
      minItemWidth: 170,
      children: [
        AppStatTile(
          label: 'Pago aos cooperados',
          value: formatMoney(summary.earnings),
          icon: Icons.payments_outlined,
          highlighted: true,
        ),
        AppStatTile(label: 'Entregas', value: formatCount(summary.deliveries), icon: Icons.local_shipping_outlined),
        AppStatTile(label: 'Km rodados', value: _km(summary.distanceKm), icon: Icons.route_outlined),
        AppStatTile(label: 'Cooperados que entregaram', value: '${summary.members}', icon: Icons.groups_outlined),
        AppStatTile(label: 'Lojas atendidas', value: '${summary.restaurants}', icon: Icons.storefront_outlined),
        AppStatTile(
          label: 'Diferença assumida pelas lojas',
          value: formatMoney(summary.restaurantSubsidy),
          icon: Icons.volunteer_activism_outlined,
          caption: 'Já incluída no total pago',
        ),
      ],
    );
  }
}

/// Entregas e ganhos por loja, marcando as lojas com tabela especial
class AssociationRestaurantList extends StatelessWidget {
  final List<AssociationRestaurantLine> lines;

  const AssociationRestaurantList({super.key, required this.lines});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    if (lines.isEmpty) {
      return Text('Nenhuma entrega no período.', style: TextStyle(color: c.textMuted));
    }
    return Column(
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) Divider(height: 16, color: c.border),
          Row(
            children: [
              RestaurantLogo(logoUrl: lines[i].logoUrl, name: lines[i].name, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(lines[i].name, style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
                        if (lines[i].agreedRate)
                          const AppStatusChip(label: 'Tabela especial', color: AppColors.primaryDark),
                      ],
                    ),
                    Text(
                      [
                        _deliveries(lines[i].deliveries),
                        if (lines[i].restaurantSubsidy > 0)
                          'loja assumiu ${formatMoney(lines[i].restaurantSubsidy)}',
                      ].join(' · '),
                      style: TextStyle(color: c.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(formatMoney(lines[i].earnings), style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
            ],
          ),
        ],
      ],
    );
  }
}

String _times(int n) => '$n ${n == 1 ? 'vez' : 'vezes'}';

/// Ocorrências do período: quantas de cada tipo e, por loja, quais aconteceram.
/// No celular cada loja ocupa a largura toda, com os tipos embaixo do nome.
class AssociationIncidentsView extends StatelessWidget {
  final AssociationIncidents incidents;

  const AssociationIncidentsView({super.key, required this.incidents});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    if (incidents.total == 0) {
      return Text('Nenhuma ocorrência relatada no período.', style: TextStyle(color: c.textMuted));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in incidents.byType)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warningLighter.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.type.icon, size: 16, color: AppColors.warningDarker),
                    const SizedBox(width: 6),
                    Text('${t.type.label} · ${t.count}', style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < incidents.byRestaurant.length; i++) ...[
          if (i > 0) Divider(height: 16, color: c.border),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RestaurantLogo(logoUrl: incidents.byRestaurant[i].logoUrl, name: incidents.byRestaurant[i].name, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(incidents.byRestaurant[i].name, style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
                    Text(
                      incidents.byRestaurant[i].byType.map((t) => '${t.type.label}: ${_times(t.count)}').join(' · '),
                      style: TextStyle(color: c.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${incidents.byRestaurant[i].total}', style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
            ],
          ),
        ],
      ],
    );
  }
}

/// Entregas e ganhos por cooperado (só o gestor vê)
class AssociationMemberList extends StatelessWidget {
  final List<AssociationMemberLine> lines;

  const AssociationMemberList({super.key, required this.lines});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    if (lines.isEmpty) {
      return Text('Nenhuma entrega no período.', style: TextStyle(color: c.textMuted));
    }
    return Column(
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) Divider(height: 16, color: c.border),
          Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  lines[i].memberNumber != null ? 'Nº ${lines[i].memberNumber}' : '–',
                  style: TextStyle(color: c.textMuted, fontSize: 13),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lines[i].name, style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
                    Text('${_deliveries(lines[i].deliveries)} · ${_km(lines[i].distanceKm)} km',
                        style: TextStyle(color: c.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              Text(formatMoney(lines[i].earnings), style: TextStyle(fontWeight: FontWeight.w700, color: c.text)),
            ],
          ),
        ],
      ],
    );
  }
}
