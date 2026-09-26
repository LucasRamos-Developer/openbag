import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/store/store.dart';
import '../../../utils/feedback.dart';
import '../../../services/restaurant_panel_service.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/restaurant/opening_hours_editor.dart';
import '../../../widgets/restaurant/store_status_chip.dart';

/// Aba Loja: abrir/fechar e pausar, configurações de pedido e horários de funcionamento
class StoreTab extends StatelessWidget {
  const StoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RestaurantPanelService>().store!;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppSectionHeader(title: 'Loja', subtitle: 'Situação, pedidos e horários de funcionamento'),
                _StatusCard(store: store),
                const SizedBox(height: 16),
                _SettingsCard(key: ValueKey('settings-${store.id}'), store: store),
                const SizedBox(height: 16),
                _HoursCard(key: ValueKey('hours-${store.id}'), store: store),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _Panel({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      borderColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(title: title, subtitle: subtitle),
          child,
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final Store store;

  const _StatusCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final service = context.read<RestaurantPanelService>();
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return _Panel(
      title: 'Situação agora',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StoreStatusChip(store: store),
              const Spacer(),
              const Text('Loja aberta'),
              Switch(
                value: store.open,
                onChanged: (v) => runWithFeedback(context, () => service.setOpen(v),
                    success: v ? 'Loja aberta' : 'Loja fechada até você abrir de novo'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            !store.open
                ? 'A loja está fechada manualmente e não recebe pedidos.'
                : store.openNow
                    ? 'Recebendo pedidos.'
                    : store.paused
                        ? 'Pausada: os clientes veem a loja, mas não conseguem pedir.'
                        : 'Fora do horário de funcionamento.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 16),
          if (store.paused)
            AppButton(
              text: 'Retomar agora',
              icon: Icons.play_arrow_rounded,
              onPressed: () => runWithFeedback(context, service.resume, success: 'Pedidos retomados'),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Pausar por:', style: TextStyle(color: muted)),
                for (final minutes in const [15, 30, 60])
                  AppButton(
                    text: '$minutes min',
                    variant: ButtonVariant.outlined,
                    size: ButtonSize.small,
                    onPressed: store.open
                        ? () => runWithFeedback(context, () => service.pause(minutes), success: 'Loja pausada por $minutes minutos')
                        : null,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatefulWidget {
  final Store store;

  const _SettingsCard({super.key, required this.store});

  @override
  State<_SettingsCard> createState() => _SettingsCardState();
}

class _SettingsCardState extends State<_SettingsCard> {
  final _formKey = GlobalKey<FormState>();
  late AcceptanceMode _mode;
  late int _timeout;
  late String? _priceRange;
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
    _priceRange = s.priceRange;
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
        'priceRange': _priceRange,
        'autoPrintTicket': _autoPrint,
      }),
      success: 'Configurações salvas',
    );
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Pedidos',
      subtitle: 'Como os pedidos chegam, prazos e valores',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSelect<AcceptanceMode>(
              labelText: 'Recebimento de pedidos',
              variant: TextFieldVariant.filled,
              value: _mode,
              items: [for (final m in AcceptanceMode.values) SelectItem(value: m, label: m.label, description: m.description)],
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
            const SizedBox(height: 28),
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
                AppSelect<String?>(
                  labelText: 'Faixa de preço',
                  variant: TextFieldVariant.filled,
                  value: _priceRange,
                  items: const [
                    SelectItem(value: null, label: 'Não informar'),
                    SelectItem(value: '\$', label: '\$ · econômico'),
                    SelectItem(value: '\$\$', label: '\$\$ · moderado'),
                    SelectItem(value: '\$\$\$', label: '\$\$\$ · caro'),
                    SelectItem(value: '\$\$\$\$', label: '\$\$\$\$ · sofisticado'),
                  ],
                  onChanged: (v) => setState(() => _priceRange = v),
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
            const SizedBox(height: 8),
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
    );
  }
}

class _HoursCard extends StatefulWidget {
  final Store store;

  const _HoursCard({super.key, required this.store});

  @override
  State<_HoursCard> createState() => _HoursCardState();
}

class _HoursCardState extends State<_HoursCard> {
  late List<OpeningHour> _hours = List.of(widget.store.openingHours);
  bool _dirty = false;
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await runWithFeedback(context, () => context.read<RestaurantPanelService>().updateOpeningHours(_hours),
        success: 'Horários salvos');
    if (mounted) {
      setState(() {
        _isSaving = false;
        _dirty = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Horário de funcionamento',
      subtitle: _hours.isEmpty
          ? 'Sem horários: a loja segue apenas o botão "Loja aberta"'
          : 'Toque em um turno para editar. Turnos que passam da meia-noite continuam no dia seguinte.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OpeningHoursEditor(
            hours: _hours,
            onChanged: (hours) => setState(() {
              _hours = hours;
              _dirty = true;
            }),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              text: 'Salvar horários',
              icon: Icons.check,
              isLoading: _isSaving,
              onPressed: _dirty && !_isSaving ? _save : null,
            ),
          ),
        ],
      ),
    );
  }
}
