import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/courier/vehicle.dart';
import '../../services/courier_service.dart';
import '../../utils/feedback.dart';

/// Custos do veículo para o resultado estimado da aba Ganhos. Todos opcionais; combustível só em moto e carro.
/// No celular abre em tela cheia. Devolve true quando salvou.
Future<bool?> showVehicleCostsSheet(BuildContext context, Vehicle vehicle) =>
    showAppAdaptive<bool>(context, builder: (_) => _VehicleCostsSheet(vehicle: vehicle));

class _VehicleCostsSheet extends StatefulWidget {
  final Vehicle vehicle;

  const _VehicleCostsSheet({required this.vehicle});

  @override
  State<_VehicleCostsSheet> createState() => _VehicleCostsSheetState();
}

class _VehicleCostsSheetState extends State<_VehicleCostsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _consumption = TextEditingController(text: _text(widget.vehicle.fuelConsumptionKmPerLiter));
  late final _price = TextEditingController(text: _text(widget.vehicle.fuelPricePerLiter));
  late final _maintenance = TextEditingController(text: _text(widget.vehicle.maintenancePerKm));
  late final _depreciation = TextEditingController(text: _text(widget.vehicle.depreciationPerKm));
  bool _saving = false;

  /// 35.0 → "35"; 0.18 → "0,18"
  static String _text(double? value) {
    if (value == null) return '';
    final text = value.toString().replaceAll(RegExp(r'\.?0+$'), '');
    return text.replaceAll('.', ',');
  }

  static double? _parse(String text) {
    final normalized = text.trim().replaceAll(',', '.');
    return normalized.isEmpty ? null : double.tryParse(normalized);
  }

  static String? _validate(String? text, {bool positive = false}) {
    if (text == null || text.trim().isEmpty) return null;
    final value = _parse(text);
    if (value == null) return 'Use só números, como 0,18';
    if (value < 0 || (positive && value == 0)) return positive ? 'Deve ser maior que zero' : 'Não pode ser negativo';
    return null;
  }

  @override
  void dispose() {
    for (final c in [_consumption, _price, _maintenance, _depreciation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await runWithFeedback(
      context,
      () => context.read<CourierService>().updateVehicleCosts(
            widget.vehicle.id,
            fuelConsumptionKmPerLiter: _parse(_consumption.text),
            fuelPricePerLiter: _parse(_price.text),
            maintenancePerKm: _parse(_maintenance.text),
            depreciationPerKm: _parse(_depreciation.text),
          ),
      success: 'Custos salvos',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  Widget _field(TextEditingController controller, String label, String hint, String helper, String suffix,
          {bool positive = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: controller,
              labelText: label,
              hintText: hint,
              suffixText: suffix,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              validator: (v) => _validate(v, positive: positive),
            ),
            // A dica fica fora do campo: o helperText do AppTextField não quebra linha e cobre o campo seguinte
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(helper, style: TextStyle(color: context.appColors.textMuted, fontSize: 12)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;
    return AppAdaptiveSheet(
      title: 'Custos do veículo',
      subtitle: vehicle.title,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Servem para estimar quanto sobra dos seus ganhos. Preencha o que souber; dá para mudar quando quiser. '
              'Só você vê.',
              style: TextStyle(color: context.appColors.textMuted),
            ),
            const SizedBox(height: 16),
            if (vehicle.usesFuel) ...[
              _field(_consumption, 'Consumo', 'Ex.: 35', 'Quantos km o veículo faz com um litro', 'km/l', positive: true),
              _field(_price, 'Preço do combustível', 'Ex.: 6,20', 'O que você paga no litro', 'R\$/l'),
            ],
            _field(_maintenance, 'Manutenção por km', 'Ex.: 0,18',
                'Some óleo, pneus, relação e revisões do ano e divida pelos km do ano', 'R\$/km'),
            _field(_depreciation, 'Depreciação por km', 'Ex.: 0,10',
                'Quanto o veículo perde de valor no ano, dividido pelos km do ano', 'R\$/km'),
          ],
        ),
      ),
      actions: [
        AppButton(
          text: 'Cancelar',
          variant: ButtonVariant.outlined,
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        ),
        AppButton(text: 'Salvar', isLoading: _saving, onPressed: _saving ? null : _save),
      ],
    );
  }
}
