import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/cooperative/ledger.dart';
import '../../utils/formatters.dart';

/// Entradas e saídas por mês em colunas agrupadas (duas séries, um eixo só).
///
/// Cores categóricas validadas para daltonismo e contraste nos dois modos (azul = entradas, laranja = saídas);
/// a legenda fica sempre visível e o texto usa as cores de texto, nunca a da série. Barras finas com topo
/// arredondado e 2 px entre elas, rótulo só no maior valor, detalhe no toque/hover e a opção de ver em tabela.
class CashFlowChart extends StatefulWidget {
  final List<FinanceMonth> months;
  final double height;

  const CashFlowChart({super.key, required this.months, this.height = 200});

  static const _inLight = Color(0xFF2A78D6);
  static const _inDark = Color(0xFF3987E5);
  static const _outLight = Color(0xFFEB6834);
  static const _outDark = Color(0xFFD95926);

  @override
  State<CashFlowChart> createState() => _CashFlowChartState();
}

class _CashFlowChartState extends State<CashFlowChart> {
  bool _table = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final inColor = colors.isDark ? CashFlowChart._inDark : CashFlowChart._inLight;
    final outColor = colors.isDark ? CashFlowChart._outDark : CashFlowChart._outLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _LegendItem(color: inColor, label: 'Entradas'),
            const SizedBox(width: 16),
            _LegendItem(color: outColor, label: 'Saídas'),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() => _table = !_table),
              icon: Icon(_table ? Icons.bar_chart : Icons.table_rows_outlined, size: 18),
              label: Text(_table ? 'Gráfico' : 'Tabela'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _table ? _buildTable(context) : _buildChart(context, inColor, outColor),
      ],
    );
  }

  Widget _buildChart(BuildContext context, Color inColor, Color outColor) {
    final colors = context.appColors;
    final months = widget.months;
    final height = widget.height;
    final max = months.fold<double>(0, (m, e) => [m, e.inAmount, e.outAmount].reduce((a, b) => a > b ? a : b));
    final labelStyle = TextStyle(color: colors.textMuted, fontSize: 11);

    // Posição do maior valor: só ele ganha rótulo
    var maxKey = '';
    for (var i = 0; i < months.length; i++) {
      if (max > 0 && months[i].inAmount == max) maxKey = 'in$i';
      if (max > 0 && months[i].outAmount == max && maxKey.isEmpty) maxKey = 'out$i';
    }

    Widget bar(double value, Color color, double width, String tooltip, bool labeled) {
      final barHeight = max == 0 ? 2.0 : ((value / max) * (height - 28)).clamp(2.0, height);
      return Tooltip(
        message: tooltip,
        triggerMode: TooltipTriggerMode.tap,
        child: Semantics(
          label: tooltip,
          // Área de toque maior que a barra
          child: SizedBox(
            width: width + 8,
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (labeled)
                  // O rótulo pode ser mais largo que a barra: transborda para os lados sem encolher
                  SizedBox(
                    height: 18,
                    child: OverflowBox(
                      maxWidth: 120,
                      child: Text(formatMoney(value),
                          maxLines: 1,
                          style: TextStyle(color: colors.text, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                Container(
                  width: width,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: value > 0 ? color : colors.border,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final slot = constraints.maxWidth / (months.isEmpty ? 1 : months.length);
      final barWidth = ((slot - 20) / 2).clamp(6.0, 28.0);
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.border))),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < months.length; i++)
                  SizedBox(
                    width: slot,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        bar(months[i].inAmount, inColor, barWidth,
                            '${formatMonth(months[i].month)}\nEntradas: ${formatMoney(months[i].inAmount)}',
                            maxKey == 'in$i'),
                        bar(months[i].outAmount, outColor, barWidth,
                            '${formatMonth(months[i].month)}\nSaídas: ${formatMoney(months[i].outAmount)}',
                            maxKey == 'out$i'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final m in months)
                SizedBox(
                  width: slot,
                  child: Text(formatMonthShort(m.month), textAlign: TextAlign.center, style: labelStyle),
                ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildTable(BuildContext context) {
    final colors = context.appColors;
    final header = TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.w600);
    const figures = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);
    Widget row(List<Widget> cells) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Expanded(flex: 3, child: cells[0]),
            Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: cells[1])),
            Expanded(flex: 3, child: Align(alignment: Alignment.centerRight, child: cells[2])),
          ]),
        );
    return Column(
      children: [
        row([Text('Mês', style: header), Text('Entradas', style: header), Text('Saídas', style: header)]),
        for (final m in widget.months.reversed) ...[
          Divider(height: 1, color: colors.border),
          row([
            Text(formatMonth(m.month)),
            Text(formatMoney(m.inAmount), style: figures),
            Text(formatMoney(m.outAmount), style: figures),
          ]),
        ],
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: context.appColors.text, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
