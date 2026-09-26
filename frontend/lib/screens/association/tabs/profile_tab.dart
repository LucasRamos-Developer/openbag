import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/association/association.dart';
import '../../../services/api_client.dart';
import '../../../services/association_service.dart';
import '../../../utils/formatters.dart';
import '../../../utils/validators.dart';
import '../../../widgets/association/association_logo.dart';

/// Edição dos dados da associação (o CNPJ não pode ser alterado).
/// Uma associação recusada que é salva volta para análise.
class ProfileTab extends StatefulWidget {
  final VoidCallback? onSaved;

  const ProfileTab({super.key, this.onSaved});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _formKey = GlobalKey<FormState>();
  late AssociationType _type;
  late final Map<String, TextEditingController> _c;
  bool _isSaving = false;
  bool _isUploadingLogo = false;

  @override
  void initState() {
    super.initState();
    final a = context.read<AssociationService>().association!;
    final address = a.address;
    _type = a.type;
    _c = {
      'tradingName': TextEditingController(text: a.tradingName),
      'companyName': TextEditingController(text: a.companyName),
      'phoneNumber': TextEditingController(text: a.phoneNumber),
      'contactEmail': TextEditingController(text: a.contactEmail),
      'description': TextEditingController(text: a.description),
      'zipCode': TextEditingController(text: address?.zipCode),
      'street': TextEditingController(text: address?.street),
      'number': TextEditingController(text: address?.number),
      'complement': TextEditingController(text: address?.complement),
      'neighborhood': TextEditingController(text: address?.neighborhood),
      'city': TextEditingController(text: address?.city),
      'state': TextEditingController(text: address?.state),
    };
  }

  @override
  void dispose() {
    for (final controller in _c.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _value(String key) {
    final text = _c[key]!.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final service = context.read<AssociationService>();
    final current = service.association!;
    final wasRejected = current.status == AssociationStatus.REJECTED;

    setState(() => _isSaving = true);
    try {
      await service.updateAssociation({
        'association': {
          'type': _type.name,
          'companyName': _value('companyName'),
          'tradingName': _value('tradingName'),
          'cnpj': current.cnpj,
          'description': _value('description'),
          'phoneNumber': _value('phoneNumber'),
          'contactEmail': _value('contactEmail'),
        },
        'address': {
          'zipCode': _value('zipCode'),
          'street': _value('street'),
          'number': _value('number'),
          'complement': _value('complement'),
          'neighborhood': _value('neighborhood'),
          'city': _value('city'),
          'state': _value('state')?.toUpperCase(),
          'latitude': current.address?.latitude,
          'longitude': current.address?.longitude,
        },
      });
      if (!mounted) return;
      AppToast.show(
        context,
        message: wasRejected ? 'Dados atualizados e reenviados para análise' : 'Dados atualizados',
        type: ToastType.success,
      );
      widget.onSaved?.call();
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changeLogo() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (file == null || !mounted) return;

    setState(() => _isUploadingLogo = true);
    try {
      await context.read<AssociationService>().updateLogo(file);
      if (mounted) AppToast.show(context, message: 'Logo atualizada', type: ToastType.success);
    } on ApiException catch (e) {
      if (mounted) AppToast.show(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  AppTextField _field(String key, String label, {String? Function(String?)? validator, List<TextInputFormatter>? formatters,
      TextInputType? keyboard, int maxLines = 1, TextCapitalization caps = TextCapitalization.none}) {
    return AppTextField(
      controller: _c[key],
      labelText: label,
      variant: TextFieldVariant.filled,
      validator: validator,
      inputFormatters: formatters,
      keyboardType: keyboard,
      maxLines: maxLines,
      textCapitalization: caps,
    );
  }

  @override
  Widget build(BuildContext context) {
    final association = context.watch<AssociationService>().association!;
    final isRejected = association.status == AssociationStatus.REJECTED;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSectionHeader(
                    title: isRejected ? 'Corrigir cadastro' : 'Dados da associação',
                    subtitle: isRejected
                        ? 'Ao salvar, o cadastro volta para análise da equipe OpenBag.'
                        : 'CNPJ ${association.formattedCnpj} · cadastrada em ${formatDate(association.createdAt)}',
                  ),
                  Row(
                    children: [
                      AssociationLogo(logoUrl: association.logoUrl, name: association.tradingName, size: 72),
                      const SizedBox(width: 16),
                      AppButton(
                        text: 'Trocar logo',
                        icon: Icons.image_outlined,
                        variant: ButtonVariant.outlined,
                        isLoading: _isUploadingLogo,
                        onPressed: _isUploadingLogo ? null : _changeLogo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AppSelect<AssociationType>(
                    labelText: 'Tipo de organização',
                    variant: TextFieldVariant.filled,
                    value: _type,
                    items: [for (final t in AssociationType.values) SelectItem(value: t, label: t.label)],
                    onChanged: (value) => setState(() => _type = value ?? _type),
                  ),
                  const SizedBox(height: 16),
                  _field('tradingName', 'Nome fantasia',
                      validator: (v) => validateRequired(v, 'Nome fantasia'), caps: TextCapitalization.words),
                  const SizedBox(height: 16),
                  _field('companyName', 'Razão social',
                      validator: (v) => validateRequired(v, 'Razão social'), caps: TextCapitalization.words),
                  const SizedBox(height: 16),
                  _field('phoneNumber', 'Telefone',
                      validator: (v) => validateRequired(v, 'Telefone'),
                      formatters: [phoneFormatterShort],
                      keyboard: TextInputType.phone),
                  const SizedBox(height: 16),
                  _field('contactEmail', 'Email de contato (opcional)',
                      validator: (v) => v == null || v.trim().isEmpty ? null : validateEmail(v.trim()),
                      keyboard: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _field('description', 'Descrição (opcional)', maxLines: 3, caps: TextCapitalization.sentences),
                  const SizedBox(height: 32),
                  const AppSectionHeader(title: 'Endereço'),
                  _field('zipCode', 'CEP',
                      validator: (v) => validateRequired(v, 'CEP'), formatters: [cepFormatter], keyboard: TextInputType.number),
                  const SizedBox(height: 16),
                  _field('street', 'Rua', validator: (v) => validateRequired(v, 'Rua')),
                  const SizedBox(height: 16),
                  AppResponsiveRow(
                    flex: const [1, 2],
                    children: [
                      _field('number', 'Número', validator: (v) => validateRequired(v, 'Número')),
                      _field('complement', 'Complemento (opcional)'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _field('neighborhood', 'Bairro', validator: (v) => validateRequired(v, 'Bairro')),
                  const SizedBox(height: 16),
                  AppResponsiveRow(
                    flex: const [3, 1],
                    children: [
                      _field('city', 'Cidade', validator: (v) => validateRequired(v, 'Cidade')),
                      _field('state', 'UF', validator: (v) => validateRequired(v, 'UF')),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      text: isRejected ? 'Salvar e reenviar' : 'Salvar alterações',
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
