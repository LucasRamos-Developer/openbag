import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/delivery/delivery_rate.dart';
import '../delivery/delivery_rate_fields.dart';
import '../delivery/delivery_rate_summary.dart';

/// Resposta do diálogo: a tabela proposta ou, com [toDefault], voltar à tabela padrão da associação
class RateProposalChoice {
  final DeliveryRate? rate;
  final bool toDefault;

  const RateProposalChoice.rate(DeliveryRate this.rate) : toDefault = false;

  const RateProposalChoice.toDefault()
      : rate = null,
        toDefault = true;
}

/// Pede a tabela especial para propor ao outro lado da parceria (ou a contraproposta a uma proposta dele).
/// Vale só depois do aceite dele. No celular abre em tela cheia.
Future<RateProposalChoice?> showRateProposalDialog(
  BuildContext context, {
  required String counterpart,
  required DeliveryRate current,
  required DeliveryRate defaultRate,
  required bool hasAgreedRate,
  double? customerFee,
  String title = 'Propor tabela especial',
}) {
  return showAppAdaptive<RateProposalChoice>(
    context,
    builder: (_) => _RateProposalDialog(
      title: title,
      counterpart: counterpart,
      current: current,
      defaultRate: defaultRate,
      hasAgreedRate: hasAgreedRate,
      customerFee: customerFee,
    ),
  );
}

class _RateProposalDialog extends StatefulWidget {
  final String title;
  final String counterpart;
  final DeliveryRate current;
  final DeliveryRate defaultRate;
  final bool hasAgreedRate;
  final double? customerFee;

  const _RateProposalDialog({
    required this.title,
    required this.counterpart,
    required this.current,
    required this.defaultRate,
    required this.hasAgreedRate,
    required this.customerFee,
  });

  @override
  State<_RateProposalDialog> createState() => _RateProposalDialogState();
}

class _RateProposalDialogState extends State<_RateProposalDialog> {
  final _formKey = GlobalKey<FormState>();
  DeliveryRate? _draft;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppAdaptiveSheet(
      title: widget.title,
      maxWidth: 680,
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'A tabela vale só nesta parceria e só depois que ${widget.counterpart} aceitar. '
              'O entregador sempre recebe 100% do valor.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text('Tabela padrão da associação: ${deliveryRateLabel(widget.defaultRate)}',
                style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            DeliveryRateFields(
              initial: widget.current,
              customerFee: widget.customerFee,
              sampleDistances: const [2, 4, 6, 8],
              onChanged: (rate) => _draft = rate,
            ),
            if (widget.hasAgreedRate) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  text: 'Voltar à tabela padrão',
                  icon: Icons.undo,
                  variant: ButtonVariant.text,
                  onPressed: () => Navigator.of(context).pop(const RateProposalChoice.toDefault()),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        AppButton(text: 'Cancelar', variant: ButtonVariant.outlined, onPressed: () => Navigator.of(context).pop()),
        AppButton(
          text: 'Enviar proposta',
          icon: Icons.send,
          onPressed: () {
            if (_formKey.currentState!.validate() && _draft != null) {
              Navigator.of(context).pop(RateProposalChoice.rate(_draft!));
            }
          },
        ),
      ],
    );
  }
}
