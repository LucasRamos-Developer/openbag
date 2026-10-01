import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';

/// Código de entrega do cliente: ele mostra ao entregador, que digita para concluir. Aparece só quando a loja exige.
class DeliveryPinCard extends StatelessWidget {
  final String pin;

  const DeliveryPinCard({super.key, required this.pin});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.pin_outlined, color: c.primaryText, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Código de entrega', style: TextStyle(color: c.text, fontWeight: FontWeight.w700)),
                Text('Mostre ao entregador quando ele chegar. Não passe por telefone.',
                    style: TextStyle(color: c.textMuted, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            pin.split('').join(' '),
            semanticsLabel: 'Código $pin',
            style: TextStyle(
              color: c.text,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
