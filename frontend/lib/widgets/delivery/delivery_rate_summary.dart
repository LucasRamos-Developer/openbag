import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/delivery/delivery_rate.dart';
import '../../utils/formatters.dart';

/// Descrição curta da tabela: "R$ 7,00 até 3 km + R$ 1,50/km"
String deliveryRateLabel(DeliveryRate rate) {
  if (!rate.configured) return 'Tabela de entrega não definida';
  final km = _km(rate.baseDistanceKm ?? 0);
  final base = '${formatMoney(rate.baseFee ?? 0)} até $km km';
  return rate.hasExtra ? '$base + ${formatMoney(rate.extraPerKm)}/km' : '$base (sem adicional)';
}

String _km(double km) => km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toStringAsFixed(1).replaceAll('.', ',');

/// Tabela da associação com uma simulação de valores por distância
class DeliveryRateSummary extends StatelessWidget {
  final DeliveryRate rate;
  final List<double> sampleDistances;

  /// Destaca as distâncias em que o valor passa desta taxa (taxa cobrada pelo restaurante)
  final double? customerFee;

  const DeliveryRateSummary({
    super.key,
    required this.rate,
    this.sampleDistances = const [2, 4, 6, 8],
    this.customerFee,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (!rate.configured) {
      return Text(deliveryRateLabel(rate), style: textTheme.bodyMedium?.copyWith(color: AppColors.warningDarker));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(deliveryRateLabel(rate), style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final km in sampleDistances)
              _SampleChip(
                label: '${_km(km)} km',
                value: rate.feeFor(km),
                exceeds: customerFee != null && rate.feeFor(km) > customerFee!,
              ),
          ],
        ),
      ],
    );
  }
}

class _SampleChip extends StatelessWidget {
  final String label;
  final double value;
  final bool exceeds;

  const _SampleChip({required this.label, required this.value, required this.exceeds});

  @override
  Widget build(BuildContext context) {
    final color = exceeds ? AppColors.warningDarker : AppColors.textBody;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (exceeds ? AppColors.warningLighter : AppColors.grey200).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: ${formatMoney(value)}', style: TextStyle(color: color, fontSize: 13)),
    );
  }
}
