import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/cooperative/community.dart';
import '../../../services/association_service.dart';
import '../../../services/cooperative_service.dart';
import '../../../utils/feedback.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/cooperative/benefit_card.dart';

/// Convênios da associação com parceiros (oficinas, idiomas, descontos), que os cooperados veem no painel deles
class BenefitsTab extends StatefulWidget {
  const BenefitsTab({super.key});

  @override
  State<BenefitsTab> createState() => _BenefitsTabState();
}

class _BenefitsTabState extends State<BenefitsTab> {
  int _version = 0;

  Future<void> _edit([Benefit? benefit]) async {
    final saved = await showAppAdaptive<bool>(context, builder: (_) => _BenefitForm(benefit: benefit));
    if (saved == true) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    final compact = AppLayout.isCompact(context);
    final orgId = context.watch<AssociationService>().association!.id;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: compact
          ? FloatingActionButton.extended(onPressed: _edit, icon: const Icon(Icons.add), label: const Text('Novo convênio'))
          : null,
      body: AppLoadView<List<Benefit>>(
        key: ValueKey(_version),
        load: () => context.read<CooperativeService>().fetchBenefits(orgId),
        builder: (context, benefits, reload) => AppPageListView(
          top: compact ? 16 : 24,
          bottom: compact ? 96 : 32,
          children: [
            // No celular a barra do topo já diz "Convênios" e o cadastro fica no botão flutuante
            if (!compact)
              AppSectionHeader(
                title: 'Convênios',
                subtitle: 'Descontos e vantagens com parceiros, disponíveis para todos os cooperados',
                action: AppButton(text: 'Novo convênio', icon: Icons.add, onPressed: _edit),
              ),
            if (benefits.isEmpty)
              AppEmptyState(
                icon: Icons.handshake_outlined,
                message: 'Nenhum convênio ainda. Cadastre oficinas, escolas e parceiros com desconto para os cooperados.',
                actionLabel: 'Cadastrar',
                onAction: _edit,
              ),
            AppResponsiveGrid(
              minItemWidth: 320,
              maxColumns: 3,
              children: [
                for (final benefit in benefits) BenefitCard(benefit: benefit, showStatus: true, onTap: () => _edit(benefit)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitForm extends StatefulWidget {
  final Benefit? benefit;

  const _BenefitForm({this.benefit});

  @override
  State<_BenefitForm> createState() => _BenefitFormState();
}

class _BenefitFormState extends State<_BenefitForm> {
  final _formKey = GlobalKey<FormState>();
  late final _partner = TextEditingController(text: widget.benefit?.partnerName);
  late final _headline = TextEditingController(text: widget.benefit?.headline);
  late final _description = TextEditingController(text: widget.benefit?.description);
  late final _address = TextEditingController(text: widget.benefit?.address);
  late final _phone = TextEditingController(text: widget.benefit?.phone);
  late final _link = TextEditingController(text: widget.benefit?.link);
  late BenefitCategory _category = widget.benefit?.category ?? BenefitCategory.WORKSHOP;
  late DateTime? _validUntil = widget.benefit?.validUntil;
  late bool _active = widget.benefit?.active ?? true;
  XFile? _logo;
  bool _saving = false;

  int get _orgId => context.read<AssociationService>().association!.id;

  @override
  void dispose() {
    for (final c in [_partner, _headline, _description, _address, _phone, _link]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 85);
    if (file != null) setState(() => _logo = file);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final service = context.read<CooperativeService>();
    final ok = await runWithFeedback(context, () async {
      final saved = await service.saveBenefit(_orgId, {
        'partnerName': _partner.text.trim(),
        'category': _category.name,
        'headline': _headline.text.trim(),
        'description': _description.text.trim(),
        'address': _address.text.trim(),
        'phone': _phone.text.replaceAll(RegExp(r'\D'), ''),
        'link': _link.text.trim(),
        'validUntil': _validUntil != null ? apiDate(_validUntil!) : null,
        'active': _active,
      }, benefitId: widget.benefit?.id);
      if (_logo != null) await service.updateBenefitLogo(_orgId, saved.id, _logo!);
    }, success: 'Convênio salvo');
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final confirmed = await AppDialog.confirm(context,
        title: 'Apagar convênio?', message: widget.benefit!.partnerName, confirmLabel: 'Apagar');
    if (!confirmed || !mounted) return;
    final ok = await runWithFeedback(
        context, () => context.read<CooperativeService>().deleteBenefit(_orgId, widget.benefit!.id),
        success: 'Convênio apagado');
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveSheet(
      title: widget.benefit == null ? 'Novo convênio' : 'Editar convênio',
      maxWidth: 640,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _partner,
              labelText: 'Parceiro',
              hintText: 'Ex: Oficina Duas Rodas',
              variant: TextFieldVariant.filled,
              maxLength: 120,
              validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o parceiro' : null,
            ),
            const SizedBox(height: 8),
            AppSelect<BenefitCategory>(
              labelText: 'Categoria',
              variant: TextFieldVariant.filled,
              value: _category,
              items: [for (final c in BenefitCategory.values) SelectItem(value: c, label: c.label, icon: c.icon)],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _headline,
              labelText: 'Benefício em poucas palavras',
              hintText: 'Ex: 15% em peças e mão de obra',
              variant: TextFieldVariant.filled,
              maxLength: 120,
              validator: (v) => (v ?? '').trim().isEmpty ? 'Descreva o benefício' : null,
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _description,
              labelText: 'Como usar (opcional)',
              hintText: 'Ex: apresente a carteirinha da cooperativa',
              variant: TextFieldVariant.filled,
              maxLines: 3,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            AppTextField(controller: _address, labelText: 'Endereço (opcional)', variant: TextFieldVariant.filled, maxLength: 250),
            const SizedBox(height: 8),
            AppResponsiveRow(
              children: [
                AppTextField(
                  controller: _phone,
                  labelText: 'Telefone (opcional)',
                  variant: TextFieldVariant.filled,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneFormatter()],
                ),
                AppTextField(
                  controller: _link,
                  labelText: 'Site (opcional)',
                  hintText: 'https://',
                  variant: TextFieldVariant.filled,
                  keyboardType: TextInputType.url,
                  validator: (v) => (v ?? '').trim().isEmpty || RegExp(r'^https?://').hasMatch(v!.trim())
                      ? null
                      : 'Comece com https://',
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppDateField(
              label: 'Válido até (opcional)',
              value: _validUntil,
              hint: 'Sem validade',
              clearable: true,
              firstDate: DateTime.now(),
              onChanged: (d) => setState(() => _validUntil = d),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: const Text('Visível para os cooperados'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.image_outlined),
              title: Text(_logo != null ? _logo!.name : 'Logo do parceiro (opcional)'),
              trailing: TextButton(onPressed: _pickLogo, child: Text(_logo != null ? 'Trocar' : 'Escolher')),
            ),
            if (widget.benefit != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _delete,
                  icon: Icon(Icons.delete_outline, color: context.appColors.danger),
                  label: Text('Apagar convênio', style: TextStyle(color: context.appColors.danger)),
                ),
              ),
            ],
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
