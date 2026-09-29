import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/validators.dart';
import '../../../utils/formatters.dart';
import '../../../core/ui/ui.dart';
import '../../../widgets/onboarding/compact_image_picker.dart';

/// Step 2: Dados da associação/cooperativa
class AssociationInfoStep extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final ValueChanged<Map<String, dynamic>> onDataChanged;
  final ValueChanged<bool Function()>? onValidationCallback;

  const AssociationInfoStep({
    super.key,
    required this.initialData,
    required this.onDataChanged,
    this.onValidationCallback,
  });

  @override
  State<AssociationInfoStep> createState() => _AssociationInfoStepState();
}

class _AssociationInfoStepState extends State<AssociationInfoStep> {
  final _formKey = GlobalKey<FormState>();

  late String _type;
  late TextEditingController _tradingNameController;
  late TextEditingController _companyNameController;
  late TextEditingController _cnpjController;
  late TextEditingController _phoneController;
  late TextEditingController _contactEmailController;
  late TextEditingController _descriptionController;
  XFile? _logoFile;

  @override
  void initState() {
    super.initState();

    _type = widget.initialData['associationType'] ?? 'ASSOCIATION';
    _tradingNameController = TextEditingController(text: widget.initialData['associationTradingName']);
    _companyNameController = TextEditingController(text: widget.initialData['associationCompanyName']);
    _cnpjController = TextEditingController(text: widget.initialData['associationCNPJ']);
    _phoneController = TextEditingController(text: widget.initialData['associationPhoneNumber']);
    _contactEmailController = TextEditingController(text: widget.initialData['associationContactEmail']);
    _descriptionController = TextEditingController(text: widget.initialData['associationDescription']);
    _logoFile = widget.initialData['logoFile'];

    widget.onValidationCallback?.call(validate);
  }

  @override
  void dispose() {
    _tradingNameController.dispose();
    _companyNameController.dispose();
    _cnpjController.dispose();
    _phoneController.dispose();
    _contactEmailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  void _notifyChanges() {
    widget.onDataChanged({
      'associationType': _type,
      'associationTradingName': _tradingNameController.text.trim(),
      'associationCompanyName': _companyNameController.text.trim(),
      'associationCNPJ': _cnpjController.text.trim(),
      'associationPhoneNumber': _phoneController.text.trim(),
      'associationContactEmail': _contactEmailController.text.trim(),
      'associationDescription': _descriptionController.text.trim(),
      'logoFile': _logoFile,
    });
  }

  String? _validateOptionalEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return validateEmail(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Dados da Associação',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Informações da associação ou cooperativa de entregadores',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),

            AppSelect<String>(
              labelText: 'Tipo de organização',
              variant: TextFieldVariant.filled,
              value: _type,
              items: const [
                SelectItem(
                  value: 'ASSOCIATION',
                  label: 'Associação',
                  description: 'Associação de entregadores',
                ),
                SelectItem(
                  value: 'COOPERATIVE',
                  label: 'Cooperativa',
                  description: 'Cooperativa de entregadores',
                ),
              ],
              onChanged: (value) {
                setState(() => _type = value ?? 'ASSOCIATION');
                _notifyChanges();
              },
            ),
            const SizedBox(height: 20),

            AppTextField(
              controller: _tradingNameController,
              labelText: 'Nome fantasia',
              hintText: 'Ex: Coopentregas',
              variant: TextFieldVariant.filled,
              textCapitalization: TextCapitalization.words,
              validator: (value) => validateRequired(value, 'Nome fantasia'),
              onChanged: (_) => _notifyChanges(),
            ),
            const SizedBox(height: 20),

            AppTextField(
              controller: _companyNameController,
              labelText: 'Razão social',
              hintText: 'Ex: Cooperativa de Entregadores de São Paulo',
              variant: TextFieldVariant.filled,
              textCapitalization: TextCapitalization.words,
              validator: (value) => validateRequired(value, 'Razão social'),
              onChanged: (_) => _notifyChanges(),
            ),
            const SizedBox(height: 20),

            AppResponsiveRow(
              children: [
                AppTextField(
                  controller: _cnpjController,
                  labelText: 'CNPJ',
                  hintText: 'XX.XXX.XXX/XXXX-00',
                  variant: TextFieldVariant.filled,
                  keyboardType: TextInputType.text,
                  inputFormatters: [CNPJFormatter()],
                  validator: validateCNPJ,
                  onChanged: (_) => _notifyChanges(),
                ),
                AppTextField(
                  controller: _phoneController,
                  labelText: 'Telefone',
                  hintText: '(XX) XXXXX-XXXX',
                  variant: TextFieldVariant.filled,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneFormatter()],
                  validator: (value) => validateRequired(value, 'Telefone'),
                  onChanged: (_) => _notifyChanges(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            AppTextField(
              controller: _contactEmailController,
              labelText: 'Email de contato (opcional)',
              hintText: 'contato@associacao.org',
              variant: TextFieldVariant.filled,
              keyboardType: TextInputType.emailAddress,
              validator: _validateOptionalEmail,
              onChanged: (_) => _notifyChanges(),
            ),
            const SizedBox(height: 20),

            AppTextField(
              controller: _descriptionController,
              labelText: 'Descrição (opcional)',
              hintText: 'Conte sobre a associação, região de atuação e benefícios aos associados',
              variant: TextFieldVariant.filled,
              maxLines: 3,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => _notifyChanges(),
            ),
            const SizedBox(height: 20),

            CompactImagePicker(
              label: 'Logo (opcional)',
              imageFile: _logoFile,
              onImageSelected: (file) {
                setState(() => _logoFile = file);
                _notifyChanges();
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
