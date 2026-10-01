import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/ui/ui.dart';

/// "Entreguei" com PIN: o entregador digita o código de 4 dígitos que o cliente mostra. Devolve o código ou null.
Future<String?> showDeliveryPinDialog(BuildContext context, {required String charge}) =>
    showDialog<String>(context: context, builder: (_) => _DeliveryPinDialog(charge: charge));

class _DeliveryPinDialog extends StatefulWidget {
  /// "R$ 38,00 (Dinheiro)": o que cobrar antes de confirmar
  final String charge;

  const _DeliveryPinDialog({required this.charge});

  @override
  State<_DeliveryPinDialog> createState() => _DeliveryPinDialogState();
}

class _DeliveryPinDialogState extends State<_DeliveryPinDialog> {
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_pin.text.length == 4) Navigator.of(context).pop(_pin.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Código de entrega'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Peça ao cliente o código de 4 dígitos que aparece no pedido dele e confirme que recebeu ${widget.charge}.'),
          const SizedBox(height: 16),
          TextField(
            controller: _pin,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 12),
            decoration: const InputDecoration(labelText: 'Código', counterText: ''),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _confirm(),
          ),
        ],
      ),
      actions: [
        AppButton(text: 'Cancelar', variant: ButtonVariant.text, onPressed: () => Navigator.of(context).pop()),
        AppButton(text: 'Entreguei', icon: Icons.check_circle_outline, onPressed: _pin.text.length == 4 ? _confirm : null),
      ],
    );
  }
}
