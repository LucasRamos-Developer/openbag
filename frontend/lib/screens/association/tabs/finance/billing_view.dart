import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/cooperative/billing.dart';
import '../../../../services/association_service.dart';
import '../../../../services/cooperative_service.dart';
import '../../../../utils/feedback.dart';
import '../../../../utils/formatters.dart';
import '../../../../widgets/common/money_field.dart';

/// Cobrança: como a mensalidade é calculada (fixa ou percentual dos ganhos com teto) e os adicionais que a
/// associação propõe aos cooperados (ex: seguro de vida, +10% na mensalidade)
class BillingView extends StatefulWidget {
  const BillingView({super.key});

  @override
  State<BillingView> createState() => _BillingViewState();
}

class _BillingViewState extends State<BillingView> {
  int _version = 0;

  int get _orgId => context.read<AssociationService>().association!.id;
  CooperativeService get _service => context.read<CooperativeService>();

  Future<({FeePolicy policy, List<AddonPlan> plans})> _load() async {
    final results = await Future.wait([_service.fetchFeePolicy(_orgId), _service.fetchAddonPlans(_orgId)]);
    return (policy: results[0] as FeePolicy, plans: results[1] as List<AddonPlan>);
  }

  void _reload() => setState(() => _version++);

  Future<void> _editPlan([AddonPlan? plan]) async {
    final saved = await showAppAdaptive<bool>(context, builder: (_) => _AddonPlanForm(plan: plan));
    if (saved == true) _reload();
  }

  Future<void> _planActions(BuildContext tileContext, AddonPlan plan) async {
    final action = await showAppActionSheet<String>(
      tileContext,
      title: plan.name,
      actions: [
        if (plan.active)
          const AppSheetAction(
            value: 'propose',
            label: 'Propor a todos os cooperados ativos',
            description: 'Cada um aceita ou recusa no painel dele',
            icon: Icons.campaign_outlined,
          ),
        const AppSheetAction(value: 'edit', label: 'Editar', icon: Icons.edit_outlined),
        AppSheetAction(
          value: 'toggle',
          label: plan.active ? 'Parar de oferecer' : 'Voltar a oferecer',
          description: plan.active ? 'Quem já tem continua com o adicional' : null,
          icon: plan.active ? Icons.pause_circle_outline : Icons.play_circle_outline,
        ),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'propose':
        await runWithFeedback(context, () async {
          final count = await _service.proposeAddon(_orgId, plan.id);
          if (mounted) {
            AppToast.show(context,
                message: count == 0 ? 'Todos os cooperados ativos já receberam a proposta' : 'Proposta enviada a $count cooperado(s)',
                type: ToastType.success);
          }
        });
        _reload();
      case 'edit':
        await _editPlan(plan);
      case 'toggle':
        final ok = await runWithFeedback(
          context,
          () => _service.saveAddonPlan(_orgId, {
            'name': plan.name,
            'description': plan.description,
            'pricing': plan.pricing.name,
            'value': plan.value,
            'active': !plan.active,
          }, planId: plan.id),
        );
        if (ok) _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLoadView<({FeePolicy policy, List<AddonPlan> plans})>(
      key: ValueKey(_version),
      load: _load,
      builder: (context, data, reload) => AppPageListView(
        top: 8,
        maxWidth: 820,
        children: [
          _FeePolicyCard(policy: data.policy, onSaved: _reload),
          const SizedBox(height: 16),
          AppPanelCard(
            title: 'Adicionais',
            subtitle: 'Cobrados junto com a mensalidade de quem aceitar. Ex: seguro de vida, +10% na mensalidade.',
            action: AppLayout.isCompact(context)
                ? IconButton(tooltip: 'Novo adicional', icon: const Icon(Icons.add), onPressed: () => _editPlan())
                : AppButton(text: 'Novo adicional', icon: Icons.add, variant: ButtonVariant.outlined, onPressed: () => _editPlan()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (data.plans.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Nenhum adicional ainda.'),
                  ),
                for (final plan in data.plans) ...[
                  Builder(
                    builder: (tileContext) => AppListTileCard(
                      onTap: () => _planActions(tileContext, plan),
                      leading: const CircleAvatar(child: Icon(Icons.shield_outlined)),
                      title: plan.name,
                      subtitle: '${plan.priceLabel} · ${plan.activeMembers} ativo(s)'
                          '${plan.proposedMembers > 0 ? ' · ${plan.proposedMembers} aguardando resposta' : ''}',
                      trailing: plan.active ? null : const AppStatusChip(label: 'Pausado', color: AppColors.grey600),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Política da mensalidade: fixa ou percentual até o teto, com simulação de quanto o cooperado paga
class _FeePolicyCard extends StatefulWidget {
  final FeePolicy policy;
  final VoidCallback onSaved;

  const _FeePolicyCard({required this.policy, required this.onSaved});

  @override
  State<_FeePolicyCard> createState() => _FeePolicyCardState();
}

class _FeePolicyCardState extends State<_FeePolicyCard> {
  final _formKey = GlobalKey<FormState>();
  late FeeMode _mode = widget.policy.mode ?? FeeMode.PERCENTAGE;
  late final _fixed = TextEditingController(text: _input(widget.policy.fixedAmount));
  late final _percentage = TextEditingController(
      text: widget.policy.percentage != null ? formatPercent(widget.policy.percentage!).replaceAll('%', '') : '');
  late final _cap = TextEditingController(text: _input(widget.policy.monthlyCap));
  late int _dueDay = widget.policy.dueDay;
  bool _saving = false;

  static String _input(double? value) => value != null ? moneyInput(value) : '';

  double? get _pct => double.tryParse(_percentage.text.replaceAll(',', '.'));

  @override
  void initState() {
    super.initState();
    for (final c in [_fixed, _percentage, _cap]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _fixed.dispose();
    _percentage.dispose();
    _cap.dispose();
    super.dispose();
  }

  /// Quanto o cooperado paga para alguns ganhos no mês (antes dos adicionais)
  double _feeFor(double earnings) {
    if (_mode == FeeMode.FIXED) return parseMoney(_fixed.text) ?? 0;
    final fee = earnings * (_pct ?? 0) / 100;
    final cap = parseMoney(_cap.text);
    return cap != null && cap > 0 && fee > cap ? cap : fee;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final association = context.read<AssociationService>();
    final cap = parseMoney(_cap.text);
    final ok = await runWithFeedback(
      context,
      () async {
        await context.read<CooperativeService>().updateFeePolicy(
              association.association!.id,
              FeePolicy(
                mode: _mode,
                fixedAmount: _mode == FeeMode.FIXED ? parseMoney(_fixed.text) : null,
                percentage: _mode == FeeMode.PERCENTAGE ? _pct : null,
                monthlyCap: _mode == FeeMode.PERCENTAGE && cap != null && cap > 0 ? cap : null,
                dueDay: _dueDay,
              ),
            );
        // Atualiza o aviso do menu ("cobrança não definida")
        await association.loadMyAssociation();
      },
      success: 'Cobrança atualizada',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppPanelCard(
      title: 'Mensalidade',
      subtitle: widget.policy.configured ? 'Hoje: ${widget.policy.summary}' : 'Ainda não definida',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final mode in FeeMode.values) ...[
              AppChoiceTile(
                title: mode.label,
                subtitle: mode.description,
                selected: _mode == mode,
                onTap: () => setState(() => _mode = mode),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            if (_mode == FeeMode.FIXED)
              MoneyField(controller: _fixed, label: 'Valor da mensalidade', required: true)
            else
              AppResponsiveRow(
                children: [
                  AppTextField(
                    controller: _percentage,
                    labelText: 'Percentual dos ganhos',
                    suffixText: '%',
                    variant: TextFieldVariant.filled,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (_) => (_pct ?? 0) <= 0 || (_pct ?? 0) > 100 ? 'Entre 0 e 100' : null,
                  ),
                  MoneyField(controller: _cap, label: 'Teto (opcional)'),
                ],
              ),
            if (_mode == FeeMode.PERCENTAGE) ...[
              const SizedBox(height: 6),
              Text('Passando do teto, o cooperado não paga mais mensalidade no mês, só os adicionais.',
                  style: TextStyle(color: colors.textMuted, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            AppSelect<int>(
              labelText: 'Vencimento da fatura',
              variant: TextFieldVariant.filled,
              value: _dueDay,
              items: [for (final d in [5, 10, 15, 20, 25]) SelectItem(value: d, label: 'Dia $d do mês seguinte')],
              onChanged: (v) => setState(() => _dueDay = v ?? _dueDay),
            ),
            if (_mode == FeeMode.PERCENTAGE && (_pct ?? 0) > 0) ...[
              const SizedBox(height: 16),
              Text('Quanto o cooperado paga', style: TextStyle(color: colors.textMuted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              AppKeyValueList(rows: [
                for (final earned in [800.0, 1500.0, 2500.0, 4000.0])
                  ('Ganhou ${formatMoney(earned)} no mês', formatMoney(_feeFor(earned))),
              ]),
            ],
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                text: 'Salvar cobrança',
                icon: Icons.check,
                fullWidth: AppLayout.isCompact(context),
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cadastro ou edição de um adicional
class _AddonPlanForm extends StatefulWidget {
  final AddonPlan? plan;

  const _AddonPlanForm({this.plan});

  @override
  State<_AddonPlanForm> createState() => _AddonPlanFormState();
}

class _AddonPlanFormState extends State<_AddonPlanForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.plan?.name ?? 'Seguro de vida');
  late final _description = TextEditingController(text: widget.plan?.description ?? '');
  late AddonPricing _pricing = widget.plan?.pricing ?? AddonPricing.PERCENT_OF_FEE;
  late final _value = TextEditingController(
      text: widget.plan == null
          ? '10'
          : widget.plan!.pricing == AddonPricing.PERCENT_OF_FEE
              ? formatPercent(widget.plan!.value).replaceAll('%', '')
              : moneyInput(widget.plan!.value));
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _value.dispose();
    super.dispose();
  }

  double? get _parsedValue => _pricing == AddonPricing.PERCENT_OF_FEE
      ? double.tryParse(_value.text.replaceAll(',', '.'))
      : parseMoney(_value.text);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await runWithFeedback(
      context,
      () => context.read<CooperativeService>().saveAddonPlan(
            context.read<AssociationService>().association!.id,
            {
              'name': _name.text.trim(),
              'description': _description.text.trim(),
              'pricing': _pricing.name,
              'value': _parsedValue,
              'active': widget.plan?.active ?? true,
            },
            planId: widget.plan?.id,
          ),
      success: 'Adicional salvo',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveSheet(
      title: widget.plan == null ? 'Novo adicional' : 'Editar adicional',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _name,
              labelText: 'Nome',
              variant: TextFieldVariant.filled,
              maxLength: 80,
              validator: (v) => (v ?? '').trim().isEmpty ? 'Dê um nome' : null,
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _description,
              labelText: 'O que cobre (opcional)',
              variant: TextFieldVariant.filled,
              maxLines: 3,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            for (final pricing in AddonPricing.values) ...[
              AppChoiceTile(
                title: pricing.label,
                subtitle: pricing == AddonPricing.PERCENT_OF_FEE
                    ? 'Acompanha a mensalidade (10% = seguro de vida)'
                    : 'O mesmo valor todo mês',
                selected: _pricing == pricing,
                onTap: () => setState(() {
                  _pricing = pricing;
                  _value.clear();
                }),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            if (_pricing == AddonPricing.PERCENT_OF_FEE)
              AppTextField(
                controller: _value,
                labelText: 'Percentual da mensalidade',
                suffixText: '%',
                variant: TextFieldVariant.filled,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (_) => (_parsedValue ?? 0) <= 0 ? 'Informe o percentual' : null,
              )
            else
              MoneyField(controller: _value, label: 'Valor por mês', required: true),
          ],
        ),
      ),
      actions: [
        AppButton(text: 'Cancelar', variant: ButtonVariant.outlined, onPressed: () => Navigator.of(context).pop(false)),
        AppButton(text: 'Salvar', icon: Icons.check, isLoading: _saving, onPressed: _saving ? null : _save),
      ],
    );
  }
}
