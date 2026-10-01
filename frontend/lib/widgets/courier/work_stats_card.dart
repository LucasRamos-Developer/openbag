import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/courier/courier_earnings.dart';
import '../../utils/formatters.dart';

/// Km, tempo e médias do período na aba Ganhos. Só o próprio entregador vê; não é ranking nem pesa no despacho.
/// No celular, duas colunas.
class WorkStatsCard extends StatelessWidget {
  final CourierWorkStats stats;

  const WorkStatsCard({super.key, required this.stats});

  static String _money(double? value) => value == null ? '—' : formatMoney(value);

  @override
  Widget build(BuildContext context) {
    final muted = context.appColors.textMuted;
    final perDelivery = [
      if (stats.kmPerDelivery != null) formatKm(stats.kmPerDelivery!),
      if (stats.minutesPerDelivery != null) formatMinutes(stats.minutesPerDelivery!),
    ].join(' · ');

    return AppPanelCard(
      title: 'Km, tempo e médias',
      subtitle: 'Só você vê. Não é ranking e não conta no despacho.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppResponsiveGrid(
            maxColumns: 3,
            minItemWidth: 130,
            // Rótulos curtos: no celular são duas colunas de ~140px
            children: [
              AppStatTile(
                label: 'Com pedido',
                value: formatKm(stats.deliveryKm),
                icon: Icons.route_outlined,
                caption: 'da loja ao cliente',
              ),
              AppStatTile(
                label: 'Até a loja',
                value: formatKm(stats.pickupKm),
                icon: Icons.storefront_outlined,
                caption: 'de onde você aceitou',
              ),
              AppStatTile(
                label: 'Em turno',
                value: formatMinutes(stats.onlineMinutes),
                icon: Icons.schedule_outlined,
                caption: '${formatMinutes(stats.deliveringMinutes)} com pedido',
              ),
              AppStatTile(
                label: 'Por entrega',
                value: _money(stats.amountPerDelivery),
                icon: Icons.local_shipping_outlined,
                caption: perDelivery.isEmpty ? null : perDelivery,
              ),
              AppStatTile(
                label: 'R\$ por km',
                value: _money(stats.perKm),
                icon: Icons.speed_outlined,
                caption: '${formatKm(stats.totalKm)} rodados',
              ),
              AppStatTile(
                label: 'R\$ por hora',
                value: _money(stats.perHour),
                icon: Icons.timer_outlined,
                caption: 'em operação',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Os km são estimados pela distância entre os pontos (de onde você aceitou até a loja e da loja ao '
            'cliente), não medidos pelo GPS. O tempo em operação vem dos seus turnos.',
            style: TextStyle(color: muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
