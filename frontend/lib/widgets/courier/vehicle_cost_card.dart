import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/courier/courier_earnings.dart';
import '../../utils/formatters.dart';

/// "Resultado estimado" na aba Ganhos: receita, custo de cada parte e o que sobra. Sem custos informados, convida a
/// preencher em vez de mostrar zero. Sempre avisa que é estimativa.
class VehicleCostCard extends StatelessWidget {
  final VehicleCostEstimate? cost;

  /// Abre os custos de um veículo (o ativo, quando ainda não há custo nenhum)
  final void Function(int? vehicleId) onEditCosts;

  const VehicleCostCard({super.key, required this.cost, required this.onEditCosts});

  static String _part(double? value) => value == null ? 'não informado' : '− ${formatMoney(value)}';

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final cost = this.cost;

    if (cost == null) {
      return AppPanelCard(
        title: 'Resultado estimado',
        subtitle: 'Quanto sobra depois do combustível, da manutenção e da depreciação',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Informe os custos do seu veículo para ver o resultado estimado do período. Leva um minuto.',
                style: TextStyle(color: c.textMuted)),
            const SizedBox(height: 12),
            AppButton(
              text: 'Informar custos do veículo',
              icon: Icons.tune,
              variant: ButtonVariant.outlined,
              fullWidth: true,
              onPressed: () => onEditCosts(null),
            ),
          ],
        ),
      );
    }

    final missing = cost.vehicles.where((v) => !v.complete && v.distanceKm > 0).toList();
    return AppPanelCard(
      title: 'Resultado estimado',
      subtitle: '${formatKm(cost.distanceKm)} rodados no período',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppKeyValueList(rows: [
            ('Ganhos', formatMoney(cost.revenue)),
            ('Combustível', _part(cost.fuel)),
            ('Manutenção', _part(cost.maintenance)),
            ('Depreciação', _part(cost.depreciation)),
            ('Custo total', '− ${formatMoney(cost.total)}'),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('Sobra estimada', style: TextStyle(color: c.text, fontWeight: FontWeight.w700))),
              Text(formatMoney(cost.result),
                  style: TextStyle(
                      color: cost.result < 0 ? c.danger : c.text, fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'É uma estimativa, não um valor contábil: km × (preço ÷ consumo + manutenção + depreciação), com os '
            'custos que você informou.',
            style: TextStyle(color: c.textMuted, fontSize: 13),
          ),
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Faltam custos de ${missing.map((v) => v.name).join(', ')}: a sobra real é menor.',
                style: const TextStyle(color: AppColors.warningDarker, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 8),
          for (final v in missing.isNotEmpty ? missing : cost.vehicles.take(1))
            AppButton(
              text: missing.isNotEmpty ? 'Completar custos de ${v.name}' : 'Ajustar custos',
              icon: Icons.tune,
              variant: ButtonVariant.text,
              fullWidth: true,
              onPressed: () => onEditCosts(v.vehicleId),
            ),
        ],
      ),
    );
  }
}
