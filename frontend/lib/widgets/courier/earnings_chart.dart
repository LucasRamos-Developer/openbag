import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/courier/courier_earnings.dart';
import '../../utils/formatters.dart';

/// Ganhos por dia em colunas: uma série (sem legenda; o título nomeia), barras finas com topo arredondado,
/// eixo discreto, rótulo só no maior valor e detalhe de cada dia no hover/toque
class EarningsChart extends StatelessWidget {
  static const _weekdays = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
  static String _two(int v) => v.toString().padLeft(2, '0');

  final List<EarningsDay> days;
  final double height;

  const EarningsChart({super.key, required this.days, this.height = 180});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 11);
    final max = days.fold<double>(0, (m, d) => d.amount > m ? d.amount : m);
    final maxIndex = days.indexWhere((d) => d.amount == max && max > 0);
    // Muitos dias: rótulo do eixo x a cada N para não colidir
    final labelEvery = days.length <= 10 ? 1 : (days.length / 7).ceil();
    String dayLabel(DateTime d) => days.length <= 7 ? _weekdays[d.weekday - 1] : '${_two(d.day)}/${_two(d.month)}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = constraints.maxWidth / (days.isEmpty ? 1 : days.length);
        final barWidth = (slot - 2).clamp(2.0, 24.0);

        return Column(
          children: [
            SizedBox(
              height: height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < days.length; i++)
                    SizedBox(
                      width: slot,
                      child: Tooltip(
                        message: '${formatDate(days[i].date)}\n${formatMoney(days[i].amount)} · '
                            '${days[i].deliveries} ${days[i].deliveries == 1 ? 'entrega' : 'entregas'}',
                        child: Semantics(
                          label: '${formatDate(days[i].date)}: ${formatMoney(days[i].amount)}',
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (i == maxIndex)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: FittedBox(child: Text(formatMoney(max), style: textTheme.labelSmall)),
                                ),
                              Container(
                                width: barWidth,
                                // Dia sem ganho: marca mínima para mostrar que o dia existe
                                height: max == 0 ? 2 : ((days[i].amount / max) * (height - 24)).clamp(2.0, height),
                                decoration: BoxDecoration(
                                  color: days[i].amount > 0 ? AppColors.primary : AppColors.grey300,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.borderLine),
            const SizedBox(height: 4),
            Row(
              children: [
                for (var i = 0; i < days.length; i++)
                  SizedBox(
                    width: slot,
                    child: i % labelEvery == 0
                        ? Text(dayLabel(days[i].date), textAlign: TextAlign.center, style: muted, maxLines: 1)
                        : null,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
