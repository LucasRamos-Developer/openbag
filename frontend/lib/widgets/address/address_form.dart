import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../services/onboarding_service.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';

/// Controla os campos do [AddressForm] e monta o endereço para a API
class AddressFormController {
  final zipCode = TextEditingController();
  final street = TextEditingController();
  final number = TextEditingController();
  final complement = TextEditingController();
  final neighborhood = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final reference = TextEditingController();

  List<TextEditingController> get _all => [zipCode, street, number, complement, neighborhood, city, state, reference];

  void fill(Map<String, dynamic> data) {
    zipCode.text = data['zipCode'] ?? '';
    street.text = data['street'] ?? '';
    number.text = data['number'] ?? '';
    complement.text = data['complement'] ?? '';
    neighborhood.text = data['neighborhood'] ?? '';
    city.text = data['city'] ?? '';
    state.text = data['state'] ?? '';
    reference.text = data['reference'] ?? '';
  }

  String? _value(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Map<String, dynamic> toJson() => {
        'zipCode': _value(zipCode),
        'street': _value(street),
        'number': _value(number),
        'complement': _value(complement),
        'neighborhood': _value(neighborhood),
        'city': _value(city),
        'state': _value(state)?.toUpperCase(),
        'reference': _value(reference),
      };

  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
  }
}

/// Campos de endereço com preenchimento automático pelo CEP (ViaCEP).
/// Deve ficar dentro de um [Form] para a validação.
class AddressForm extends StatefulWidget {
  final AddressFormController controller;

  const AddressForm({super.key, required this.controller});

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _onboardingService = OnboardingService();
  bool _searching = false;

  AddressFormController get _c => widget.controller;

  Future<void> _searchZip() async {
    final zip = _c.zipCode.text.replaceAll(RegExp(r'\D'), '');
    if (zip.length != 8) return;
    setState(() => _searching = true);
    final address = await _onboardingService.fetchAddressByCEP(zip);
    if (!mounted) return;
    setState(() => _searching = false);
    if (address == null) {
      AppToast.show(context, message: 'CEP não encontrado', type: ToastType.warning);
      return;
    }
    _c.street.text = address['street'] ?? '';
    _c.neighborhood.text = address['neighborhood'] ?? '';
    _c.city.text = address['city'] ?? '';
    _c.state.text = address['state'] ?? '';
  }

  AppTextField _field(TextEditingController controller, String label,
      {String? Function(String?)? validator, TextInputType? keyboard, TextCapitalization caps = TextCapitalization.words}) {
    return AppTextField(
      controller: controller,
      labelText: label,
      variant: TextFieldVariant.filled,
      keyboardType: keyboard,
      textCapitalization: caps,
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _c.zipCode,
          labelText: 'CEP',
          hintText: '00000-000',
          variant: TextFieldVariant.filled,
          keyboardType: TextInputType.number,
          inputFormatters: [cepFormatter],
          onChanged: (v) {
            if (v.replaceAll(RegExp(r'\D'), '').length == 8) _searchZip();
          },
          suffixIcon: _searching
              ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton(tooltip: 'Buscar CEP', icon: const Icon(Icons.search), onPressed: _searchZip),
        ),
        const SizedBox(height: 28),
        AppResponsiveRow(
          flex: const [3, 1],
          breakpoint: 360,
          children: [
            _field(_c.street, 'Rua', validator: (v) => validateRequired(v, 'Rua')),
            _field(_c.number, 'Número', validator: (v) => validateRequired(v, 'Número'), keyboard: TextInputType.text),
          ],
        ),
        const SizedBox(height: 28),
        AppResponsiveRow(
          children: [
            _field(_c.complement, 'Complemento (opcional)', caps: TextCapitalization.sentences),
            _field(_c.neighborhood, 'Bairro', validator: (v) => validateRequired(v, 'Bairro')),
          ],
        ),
        const SizedBox(height: 28),
        AppResponsiveRow(
          flex: const [3, 1],
          breakpoint: 360,
          children: [
            _field(_c.city, 'Cidade', validator: (v) => validateRequired(v, 'Cidade')),
            _field(_c.state, 'UF', validator: (v) => validateRequired(v, 'UF'), caps: TextCapitalization.characters),
          ],
        ),
        const SizedBox(height: 28),
        _field(_c.reference, 'Ponto de referência (opcional)', caps: TextCapitalization.sentences),
      ],
    );
  }
}
