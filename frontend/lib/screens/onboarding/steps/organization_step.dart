import 'package:flutter/material.dart';
import '../../../utils/validators.dart';
import '../../../utils/formatters.dart';
import '../../../core/ui/ui.dart';

/// Step 2: Dados do Restaurante
class OrganizationStep extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final ValueChanged<Map<String, dynamic>> onDataChanged;
  final ValueChanged<bool Function()>? onValidationCallback;

  const OrganizationStep({
    super.key,
    required this.initialData,
    required this.onDataChanged,
    this.onValidationCallback,
  });

  @override
  State<OrganizationStep> createState() => _OrganizationStepState();
}

class _OrganizationStepState extends State<OrganizationStep> {
  final _formKey = GlobalKey<FormState>();

  // Controllers - Restaurante
  late TextEditingController _nameController;
  late TextEditingController _slugController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _cnpjController;
  late TextEditingController _deliveryFeeController;
  late TextEditingController _minimumOrderController;
  late TextEditingController _deliveryTimeController;

  @override
  void initState() {
    super.initState();

    // Inicializar controllers - Restaurante
    _nameController = TextEditingController(text: widget.initialData['restaurantName']);
    _slugController = TextEditingController(text: widget.initialData['restaurantSlug']);
    _descriptionController = TextEditingController(text: widget.initialData['restaurantDescription']);
    _phoneController = TextEditingController(text: widget.initialData['restaurantPhoneNumber']);
    _cnpjController = TextEditingController(text: widget.initialData['restaurantCNPJ']);
    _deliveryFeeController = TextEditingController(
      text: widget.initialData['deliveryFee']?.toString() ?? '',
    );
    _minimumOrderController = TextEditingController(
      text: widget.initialData['minimumOrder']?.toString() ?? '',
    );
    _deliveryTimeController = TextEditingController(
      text: widget.initialData['deliveryTimeMin']?.toString() ?? '',
    );

    // Auto-gerar slug ao digitar o nome
    _nameController.addListener(_generateSlug);

    // Registrar callback de validação
    widget.onValidationCallback?.call(validate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _cnpjController.dispose();
    _deliveryFeeController.dispose();
    _minimumOrderController.dispose();
    _deliveryTimeController.dispose();
    super.dispose();
  }

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  void _generateSlug() {
    if (_nameController.text.isNotEmpty) {
      _slugController.text = slugify(_nameController.text);
      _notifyChanges();
    }
  }

  void _notifyChanges() {
    widget.onDataChanged({
      'restaurantName': _nameController.text.trim(),
      'restaurantSlug': _slugController.text.trim(),
      'restaurantDescription': _descriptionController.text.trim(),
      'restaurantPhoneNumber': _phoneController.text.trim(),
      'restaurantCNPJ': _cnpjController.text.trim(),
      'deliveryFee': double.tryParse(_deliveryFeeController.text.replaceAll(',', '.')),
      'minimumOrder': double.tryParse(_minimumOrderController.text.replaceAll(',', '.')),
      'deliveryTimeMin': int.tryParse(_deliveryTimeController.text),
      'deliveryTimeMax': int.tryParse(_deliveryTimeController.text),
    });
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
              'Dados do Estabelecimento',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Informações básicas sobre seu restaurante',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),

            // Nome do restaurante
            AppTextField(
              controller: _nameController,
              labelText: 'Nome do restaurante',
              hintText: 'Ex: Pizzaria do João',
              variant: TextFieldVariant.filled,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              validator: (value) => validateRequired(value, 'Nome do restaurante'),
              onChanged: (_) => _notifyChanges(),
            ),
            const SizedBox(height: 20),

            // Slug
            AppTextField(
              controller: _slugController,
              labelText: 'URL amigável',
              hintText: 'pizzaria-do-joao',
              prefixText: 'www.openbag.app/r/',
              variant: TextFieldVariant.filled,
              readOnly: true,
              validator: (value) => validateRequired(value, 'Slug'),
            ),
            const SizedBox(height: 20),

            // Telefone e CNPJ na mesma linha
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _phoneController,
                    labelText: 'Telefone',
                    hintText: '(XX) XXXXX-XXXX',
                    variant: TextFieldVariant.filled,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [phoneFormatterShort],
                    validator: (value) => validateRequired(value, 'Telefone'),
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    controller: _cnpjController,
                    labelText: 'CNPJ',
                    hintText: 'XX.XXX.XXX/XXXX-00',
                    variant: TextFieldVariant.filled,
                    keyboardType: TextInputType.text,
                    inputFormatters: [CNPJFormatter()],
                    validator: validateCNPJ,
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Descrição
            AppTextField(
              controller: _descriptionController,
              labelText: 'Descrição',
              hintText: 'Conte sobre seu restaurante',
              variant: TextFieldVariant.filled,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) => validateRequired(value, 'Descrição'),
              onChanged: (_) => _notifyChanges(),
            ),
            const SizedBox(height: 20),

            // Taxa de entrega, Pedido mínimo e Tempo de entrega na mesma linha
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _deliveryFeeController,
                    labelText: 'Taxa de entrega',
                    hintText: '0,00',
                    prefixText: 'R\$ ',
                    variant: TextFieldVariant.filled,
                    keyboardType: TextInputType.number,
                    inputFormatters: [MoneyFormatter()],
                    validator: (value) => validateNonNegativeNumber(value, 'Taxa de entrega'),
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    controller: _minimumOrderController,
                    labelText: 'Pedido mínimo',
                    hintText: '0,00',
                    prefixText: 'R\$ ',
                    variant: TextFieldVariant.filled,
                    keyboardType: TextInputType.number,
                    inputFormatters: [MoneyFormatter()],
                    validator: (value) => validateNonNegativeNumber(value, 'Pedido mínimo'),
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    controller: _deliveryTimeController,
                    labelText: 'Tempo de entrega',
                    hintText: '30',
                    suffixText: 'min',
                    variant: TextFieldVariant.filled,
                    keyboardType: TextInputType.number,
                    inputFormatters: [IntegerFormatter()],
                    validator: (value) => validatePositiveInteger(value, 'Tempo de entrega'),
                    onChanged: (_) => _notifyChanges(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
