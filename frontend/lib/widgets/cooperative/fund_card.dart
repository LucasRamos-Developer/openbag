import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/cooperative/ledger.dart';
import '../../utils/formatters.dart';

/// Saldo da caixinha em destaque, com o que entrou e saiu. O número principal vem primeiro e grande.
class FundHeroCard extends StatelessWidget {
  final double balance;
  final double totalIn;
  final double totalOut;
  final String? caption;

  const FundHeroCard({super.key, required this.balance, required this.totalIn, required this.totalOut, this.caption});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final figures = TextStyle(color: colors.text, fontFeatures: const [FontFeature.tabularFigures()]);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volunteer_activism_outlined, color: colors.primaryText),
              const SizedBox(width: 8),
              Text('Saldo da caixinha', style: TextStyle(color: colors.textMuted, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(formatMoney(balance), style: figures.copyWith(fontSize: 34, fontWeight: FontWeight.w800)),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(caption!, style: TextStyle(color: colors.textMuted, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 6,
            children: [
              _Flow(icon: Icons.south_west, label: 'Entrou', value: formatMoney(totalIn)),
              _Flow(icon: Icons.north_east, label: 'Saiu em auxílios', value: formatMoney(totalOut)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Flow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Flow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colors.textMuted),
        const SizedBox(width: 4),
        Text('$label ', style: TextStyle(color: colors.textMuted, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}

/// Movimentação da caixinha ou do livro-caixa: entrada (+) ou saída (−), com data
class MoneyMovementTile extends StatelessWidget {
  final bool isIn;
  final double amount;
  final String title;
  final String? subtitle;
  final DateTime date;
  final VoidCallback? onTap;

  const MoneyMovementTile({
    super.key,
    required this.isIn,
    required this.amount,
    required this.title,
    this.subtitle,
    required this.date,
    this.onTap,
  });

  factory MoneyMovementTile.fund(FundMovement movement) => MoneyMovementTile(
        isIn: movement.isIn,
        amount: movement.amount,
        title: movement.description,
        date: movement.date,
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppListTileCard(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: colors.surfaceAlt,
        child: Icon(isIn ? Icons.south_west : Icons.north_east, size: 18, color: colors.textMuted),
      ),
      title: title,
      subtitle: [formatDate(date), if (subtitle != null) subtitle!].join(' · '),
      // Sinal e rótulo carregam o sentido, não a cor
      value: '${isIn ? '+' : '−'} ${formatMoney(amount)}',
    );
  }
}
