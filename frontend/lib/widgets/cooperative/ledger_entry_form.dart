import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/association/member.dart';
import '../../models/cooperative/ledger.dart';
import '../../services/association_service.dart';
import '../../services/cooperative_service.dart';
import '../../utils/feedback.dart';
import '../../utils/formatters.dart';
import '../common/money_field.dart';

/// Abre o formulário de lançamento manual (tela cheia no celular). Devolve true se salvou.
/// [kinds] limita os tipos (a Caixinha só mostra contribuição e auxílio).
Future<bool> showLedgerEntryForm(BuildContext context, {List<ManualEntryKind> kinds = ManualEntryKind.values}) async =>
    await showAppAdaptive<bool>(context, builder: (_) => _LedgerEntryForm(kinds: kinds)) ?? false;

class _LedgerEntryForm extends StatefulWidget {
  final List<ManualEntryKind> kinds;

  const _LedgerEntryForm({required this.kinds});

  @override
  State<_LedgerEntryForm> createState() => _LedgerEntryFormState();
}

class _LedgerEntryFormState extends State<_LedgerEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  late ManualEntryKind _kind = widget.kinds.first;
  DateTime _date = DateTime.now();
  int? _membershipId;
  List<Member>? _members;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final page = await context.read<AssociationService>().fetchMembers(status: MembershipStatus.ACTIVE, size: 200);
      if (mounted) setState(() => _members = page.items);
    } catch (_) {
      if (mounted) setState(() => _members = const []);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_kind == ManualEntryKind.AID && _membershipId == null) {
      AppToast.show(context, message: 'Escolha o cooperado que recebe o auxílio', type: ToastType.warning);
      return;
    }
    setState(() => _saving = true);
    final orgId = context.read<AssociationService>().association!.id;
    final ok = await runWithFeedback(
      context,
      () => context.read<CooperativeService>().createLedgerEntry(
            orgId,
            kind: _kind,
            amount: parseMoney(_amount.text) ?? 0,
            description: _description.text.trim(),
            date: _date,
            membershipId: _membershipId,
          ),
      success: 'Lançamento registrado',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final members = _members;
    final needsMember = _kind == ManualEntryKind.AID;
    return AppAdaptiveSheet(
      title: 'Novo lançamento',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final kind in widget.kinds) ...[
              AppChoiceTile(
                title: kind.label,
                subtitle: kind.description,
                selected: _kind == kind,
                onTap: () => setState(() => _kind = kind),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            MoneyField(controller: _amount, label: 'Valor', required: true),
            const SizedBox(height: 16),
            AppTextField(
              controller: _description,
              labelText: needsMember ? 'Motivo do auxílio' : 'Descrição',
              hintText: switch (_kind) {
                ManualEntryKind.EXPENSE => 'Ex: aluguel da sede',
                ManualEntryKind.INCOME => 'Ex: patrocínio',
                ManualEntryKind.CONTRIBUTION => 'Ex: rifa beneficente',
                ManualEntryKind.AID => 'Ex: conserto da moto depois de um acidente',
              },
              variant: TextFieldVariant.filled,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v ?? '').trim().isEmpty ? 'Descreva o lançamento' : null,
            ),
            const SizedBox(height: 8),
            AppDateField(
              label: 'Data',
              value: _date,
              lastDate: DateTime.now(),
              onChanged: (d) => setState(() => _date = d ?? DateTime.now()),
            ),
            const SizedBox(height: 16),
            if (members == null)
              const LinearProgressIndicator()
            else
              AppSelect<int>(
                labelText: needsMember ? 'Cooperado que recebe' : 'Cooperado (opcional)',
                variant: TextFieldVariant.filled,
                value: _membershipId,
                items: [
                  for (final m in members)
                    SelectItem(
                      value: m.membershipId,
                      label: m.memberNumber != null ? '${m.fullName} · nº ${m.memberNumber}' : m.fullName,
                    ),
                ],
                onChanged: (v) => setState(() => _membershipId = v),
              ),
            if (needsMember) ...[
              const SizedBox(height: 8),
              Text(
                'Os cooperados veem só o valor do auxílio, sem o nome de quem recebeu.',
                style: TextStyle(color: context.appColors.textMuted, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        AppButton(text: 'Cancelar', variant: ButtonVariant.outlined, onPressed: () => Navigator.of(context).pop(false)),
        AppButton(text: 'Registrar', icon: Icons.check, isLoading: _saving, onPressed: _saving ? null : _save),
      ],
    );
  }
}
