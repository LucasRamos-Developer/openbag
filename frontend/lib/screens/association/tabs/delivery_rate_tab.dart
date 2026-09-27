import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/delivery/delivery_rate.dart';
import '../../../services/association_service.dart';
import '../../../utils/feedback.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/delivery/delivery_rate_summary.dart';

/// Tabela de valores de entrega da associação: o entregador recebe 100% do valor calculado
class DeliveryRateTab extends StatefulWidget {
  const DeliveryRateTab({super.key});

  @override
  State<DeliveryRateTab> createState() => _DeliveryRateTabState();
}

class _DeliveryRateTabState extends State<DeliveryRateTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _baseFee;
  late final TextEditingController _baseDistance;
  late final TextEditingController _extraPerKm;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final rate = context.read<AssociationService>().association!.deliveryRate;
    _baseFee = TextEditingController(text: rate.baseFee != null ? moneyInput(rate.baseFee!) : '');
    _baseDistance = TextEditingController(text: rate.baseDistanceKm != null ? _kmInput(rate.baseDistanceKm!) : '');
    _extraPerKm = TextEditingController(text: rate.configured ? moneyInput(rate.extraPerKm) : '');
    for (final c in [_baseFee, _baseDistance, _extraPerKm]) {
      c.addListener(() => setState(() {}));
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await runWithFeedback(context, () => context.read<AssociationService>().updateDeliveryRate(_draft!),
        success: 'Tabela de entrega salva');
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<AssociationService>().association!.deliveryRate;
    final draft = _draft;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppSectionHeader(
                    title: 'Tabela de entrega',
                    subtitle: 'Quanto o entregador recebe por entrega. Ele fica com 100% do valor. '
                        'Restaurantes cuja taxa for menor que esta tabela precisam assumir a diferença.',
                  ),
                  if (!saved.configured)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: AppCard(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: AppColors.warningLighter.withValues(alpha: 0.4),
                        child: Text(
                          'Enquanto a tabela não for definida, os associados não conseguem ficar online.',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  AppResponsiveRow(
                    breakpoint: 560,
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
                  const SizedBox(height: 24),
                  if (draft != null) ...[
                    Text('Simulação', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DeliveryRateSummary(rate: draft, sampleDistances: const [1, 3, 5, 8, 12]),
                    const SizedBox(height: 24),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      text: 'Salvar tabela',
                      icon: Icons.check,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
