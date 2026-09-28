import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/ui/ui.dart';
import '../../models/delivery/delivery_rate.dart';
import '../../utils/formatters.dart';
import 'delivery_rate_summary.dart';

/// Campos de uma tabela de entrega (valor base, km cobertos e adicional por km) com a simulação por distância.
/// Vai dentro de um [Form]: os campos validam sozinhos. Usado na tabela da associação e na tabela especial.
class DeliveryRateFields extends StatefulWidget {
  final DeliveryRate? initial;

  /// Tabela preenchida a cada digitação (nula enquanto faltar valor base ou distância)
  final ValueChanged<DeliveryRate?> onChanged;
  final List<double> sampleDistances;

  /// Destaca na simulação as distâncias em que o valor passa desta taxa
  final double? customerFee;

  /// Largura abaixo da qual os campos ficam um embaixo do outro
  final double breakpoint;

  const DeliveryRateFields({
    super.key,
    this.initial,
    required this.onChanged,
    this.sampleDistances = const [1, 3, 5, 8, 12],
    this.customerFee,
    this.breakpoint = 560,
  });

  @override
  State<DeliveryRateFields> createState() => _DeliveryRateFieldsState();
}

class _DeliveryRateFieldsState extends State<DeliveryRateFields> {
  late final TextEditingController _baseFee;
  late final TextEditingController _baseDistance;
  late final TextEditingController _extraPerKm;

  @override
  void initState() {
    super.initState();
    final rate = widget.initial;
    final configured = rate != null && rate.configured;
    _baseFee = TextEditingController(text: configured ? moneyInput(rate.baseFee!) : '');
    _baseDistance = TextEditingController(text: configured ? _kmInput(rate.baseDistanceKm!) : '');
    _extraPerKm = TextEditingController(text: configured ? moneyInput(rate.extraPerKm) : '');
    for (final c in [_baseFee, _baseDistance, _extraPerKm]) {
      c.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _baseFee.dispose();
    _baseDistance.dispose();
    _extraPerKm.dispose();
    super.dispose();
  }

  static String _kmInput(double km) => km.toString().replaceAll('.', ',').replaceAll(RegExp(r',0$'), '');

  static double? _parseKm(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  DeliveryRate? get _draft {
    final base = parseMoney(_baseFee.text);
    final km = _parseKm(_baseDistance.text);
    if (base == null || km == null) return null;
    return DeliveryRate(baseFee: base, baseDistanceKm: km, extraPerKm: parseMoney(_extraPerKm.text) ?? 0, configured: true);
  }

  void _changed() {
    setState(() {});
    widget.onChanged(_draft);
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppResponsiveRow(
          breakpoint: widget.breakpoint,
          children: [
            AppTextField(
              controller: _baseFee,
              labelText: 'Valor base',
              prefixText: 'R\$ ',
              variant: TextFieldVariant.filled,
              keyboardType: TextInputType.number,
              inputFormatters: [MoneyFormatter()],
              validator: (v) => parseMoney(v ?? '') == null ? 'Informe o valor base' : null,
            ),
            AppTextField(
              controller: _baseDistance,
              labelText: 'Cobre até',
              suffixText: 'km',
              variant: TextFieldVariant.filled,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
              validator: (v) {
                final km = _parseKm(v ?? '');
                if (km == null) return 'Informe a distância';
                if (km < 0 || km > 100) return 'Entre 0 e 100 km';
                return null;
              },
            ),
            AppTextField(
              controller: _extraPerKm,
              labelText: 'Adicional por km',
              helperText: 'Deixe 0,00 para não ter adicional',
              prefixText: 'R\$ ',
              variant: TextFieldVariant.filled,
              keyboardType: TextInputType.number,
              inputFormatters: [MoneyFormatter()],
            ),
          ],
        ),
        if (draft != null) ...[
          const SizedBox(height: 24),
          Text('Simulação', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DeliveryRateSummary(rate: draft, sampleDistances: widget.sampleDistances, customerFee: widget.customerFee),
        ],
      ],
    );
  }
}
