import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/cooperative/billing.dart';
import '../../utils/formatters.dart';

/// Situação da fatura com ícone + texto (nunca só a cor): paga, em aberto, atrasada, dispensada ou prévia
class InvoiceStatusChip extends StatelessWidget {
  final Invoice invoice;

  const InvoiceStatusChip({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = invoice.preview
        ? ('Parcial', AppColors.grey600, Icons.hourglass_empty)
        : switch (invoice.status) {
            InvoiceStatus.PAID => ('Paga', AppColors.successDark, Icons.check_circle_outline),
            InvoiceStatus.WAIVED => ('Dispensada', AppColors.grey600, Icons.remove_circle_outline),
            InvoiceStatus.OPEN when invoice.overdue => ('Atrasada', AppColors.errorDark, Icons.error_outline),
            InvoiceStatus.OPEN => ('Em aberto', AppColors.warningDarker, Icons.schedule),
          };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        AppStatusChip(label: label, color: color),
      ],
    );
  }
}

/// Itens da fatura (mensalidade, adicionais, caixinha) e o total
class InvoiceBreakdown extends StatelessWidget {
  final Invoice invoice;

  const InvoiceBreakdown({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final figures = TextStyle(color: colors.text, fontFeatures: const [FontFeature.tabularFigures()]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ganhos no mês: ${formatMoney(invoice.earnings)} · ${invoice.deliveries} '
          '${invoice.deliveries == 1 ? 'entrega' : 'entregas'}',
          style: TextStyle(color: colors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 8),
        for (final line in invoice.lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(switch (line.type) {
                  InvoiceLineType.FEE => Icons.receipt_outlined,
                  InvoiceLineType.ADDON => Icons.shield_outlined,
                  InvoiceLineType.SOLIDARITY => Icons.volunteer_activism_outlined,
                }, size: 18, color: colors.textMuted),
                const SizedBox(width: 8),
                Expanded(child: Text(line.description, style: TextStyle(color: colors.text))),
                Text(formatMoney(line.amount), style: figures),
              ],
            ),
          ),
        Divider(height: 20, color: colors.border),
        Row(
          children: [
            Expanded(child: Text('Total', style: TextStyle(color: colors.text, fontWeight: FontWeight.w700))),
            Text(formatMoney(invoice.total),
                style: figures.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        if (invoice.dueDate != null && !invoice.preview) ...[
          const SizedBox(height: 6),
          Text(
            invoice.status == InvoiceStatus.PAID
                ? 'Paga em ${formatDate(invoice.paidOn)}${invoice.paymentMethod != null ? ' · ${invoice.paymentMethod!.label}' : ''}'
                : 'Vence em ${formatDate(invoice.dueDate)}',
            style: TextStyle(color: colors.textMuted, fontSize: 13),
          ),
        ],
        if (invoice.notes != null) ...[
          const SizedBox(height: 4),
          Text(invoice.notes!, style: TextStyle(color: colors.textMuted, fontSize: 13)),
        ],
      ],
    );
  }
}
