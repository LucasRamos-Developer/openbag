import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/store/store.dart';
import '../../../../services/restaurant_panel_service.dart';
import '../../../../utils/feedback.dart';
import '../../../../utils/formatters.dart';

/// Loja › Pedidos e entrega: aceite, prazos, taxa, pedido mínimo e impressão da comanda
class DeliveryTab extends StatefulWidget {
  final Store store;

  const DeliveryTab({super.key, required this.store});

  @override
  State<DeliveryTab> createState() => _DeliveryTabState();
}

class _DeliveryTabState extends State<DeliveryTab> {
  final _formKey = GlobalKey<FormState>();
  late AcceptanceMode _mode;
  late int _timeout;
  late bool _autoPrint;
  late final TextEditingController _prep;
  late final TextEditingController _fee;
  late final TextEditingController _minimum;
  late final TextEditingController _timeMin;
  late final TextEditingController _timeMax;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.store;
    _mode = s.acceptanceMode;
    _timeout = s.acceptanceTimeoutMinutes;
    _autoPrint = s.autoPrintTicket;
    _prep = TextEditingController(text: '${s.defaultPreparationMinutes}');
    _fee = TextEditingController(text: moneyInput(s.deliveryFee));
    _minimum = TextEditingController(text: moneyInput(s.minimumOrder));
    _timeMin = TextEditingController(text: '${s.deliveryTimeMin}');
    _timeMax = TextEditingController(text: '${s.deliveryTimeMax}');
  }

  @override
  void dispose() {
    for (final c in [_prep, _fee, _minimum, _timeMin, _timeMax]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _positive(String? v, String field) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Informe $field' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final min = int.parse(_timeMin.text);
    final max = int.parse(_timeMax.text);
    if (min > max) {
      AppToast.show(context, message: 'O tempo mínimo de entrega não pode ser maior que o máximo', type: ToastType.warning);
      return;
    }

    setState(() => _isSaving = true);
    await runWithFeedback(
      context,
      () => context.read<RestaurantPanelService>().updateSettings({
        'acceptanceMode': _mode.name,
        'acceptanceTimeoutMinutes': _timeout,
        'defaultPreparationMinutes': int.parse(_prep.text),
        'deliveryFee': parseMoney(_fee.text) ?? 0,
        'minimumOrder': parseMoney(_minimum.text) ?? 0,
        'deliveryTimeMin': min,
        'deliveryTimeMax': max,
        'autoPrintTicket': _autoPrint,
      }),
      success: 'Configurações salvas',
    );
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppPageListView(
      top: 16,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPanelCard(
                title: 'Recebimento de pedidos',
                subtitle: 'Como os pedidos chegam e quanto tempo você tem para aceitar',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSelect<AcceptanceMode>(
                      labelText: 'Recebimento de pedidos',
                      variant: TextFieldVariant.filled,
                      value: _mode,
                      items: [
                        for (final m in AcceptanceMode.values)
                          SelectItem(value: m, label: m.label, description: m.description),
                      ],
                      onChanged: (v) => setState(() => _mode = v ?? _mode),
                    ),
                    const SizedBox(height: 20),
                    AppResponsiveRow(
                      children: [
                        AppSelect<int>(
                          labelText: 'Prazo para aceitar',
                          variant: TextFieldVariant.filled,
                          enabled: _mode == AcceptanceMode.MANUAL,
                          value: _timeout,
                          items: [
                            for (final m in {3, 5, 8, 10, 15, 20, _timeout}.toList()..sort())
                              SelectItem(value: m, label: '$m minutos'),
                          ],
                          onChanged: (v) => setState(() => _timeout = v ?? _timeout),
                        ),
                        AppTextField(
                          controller: _prep,
                          labelText: 'Tempo médio de preparo',
                          suffixText: 'min',
                          variant: TextFieldVariant.filled,
                          keyboardType: TextInputType.number,
                          inputFormatters: [IntegerFormatter()],
                          validator: (v) => _positive(v, 'o tempo de preparo'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Imprimir comanda ao aceitar'),
                      subtitle: const Text('Abre a impressão da comanda automaticamente quando um pedido é aceito'),
                      value: _autoPrint,
                      onChanged: (v) => setState(() => _autoPrint = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppPanelCard(
                title: 'Entrega',
                subtitle: 'Valores e prazos que o cliente vê antes de pedir',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppResponsiveRow(
                      children: [
                        AppTextField(
                          controller: _fee,
                          labelText: 'Taxa de entrega',
                          prefixText: 'R\$ ',
                          variant: TextFieldVariant.filled,
                          keyboardType: TextInputType.number,
                          inputFormatters: [MoneyFormatter()],
                        ),
                        AppTextField(
                          controller: _minimum,
                          labelText: 'Pedido mínimo',
                          prefixText: 'R\$ ',
                          variant: TextFieldVariant.filled,
                          keyboardType: TextInputType.number,
                          inputFormatters: [MoneyFormatter()],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    AppResponsiveRow(
                      children: [
                        AppTextField(
                          controller: _timeMin,
                          labelText: 'Entrega: de',
                          suffixText: 'min',
                          variant: TextFieldVariant.filled,
                          keyboardType: TextInputType.number,
                          inputFormatters: [IntegerFormatter()],
                          validator: (v) => _positive(v, 'o tempo mínimo'),
                        ),
                        AppTextField(
                          controller: _timeMax,
                          labelText: 'até',
                          suffixText: 'min',
                          variant: TextFieldVariant.filled,
                          keyboardType: TextInputType.number,
                          inputFormatters: [IntegerFormatter()],
                          validator: (v) => _positive(v, 'o tempo máximo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  text: 'Salvar configurações',
                  icon: Icons.check,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
