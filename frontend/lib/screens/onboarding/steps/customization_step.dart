import 'dart:io';
import 'package:flutter/material.dart';
import '../../../widgets/onboarding/image_picker_card.dart';
import '../../../widgets/onboarding/color_picker_field.dart';
import '../../../widgets/onboarding/category_selector.dart';
import '../../../models/onboarding/layout_config.dart';

/// Step 3: Personalização (Imagens + Cores + Categorias + Resumo)
class CustomizationStep extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final ValueChanged<Map<String, dynamic>> onDataChanged;
  final VoidCallback onSubmit;
  final bool isSubmitting;
  final ValueChanged<bool Function()>? onValidationCallback;

  const CustomizationStep({
    super.key,
    required this.initialData,
    required this.onDataChanged,
    required this.onSubmit,
    this.isSubmitting = false,
    this.onValidationCallback,
  });

  @override
  State<CustomizationStep> createState() => _CustomizationStepState();
}

class _CustomizationStepState extends State<CustomizationStep> {
  File? _logoFile;
  File? _bannerFile;
  String _primaryColor = LayoutConfig.defaultConfig.primaryColor;
  String _secondaryColor = LayoutConfig.defaultConfig.secondaryColor;
  List<int> _selectedCategoryIds = [];

  @override
  void initState() {
    super.initState();
    
    // Restaurar dados salvos
    _logoFile = widget.initialData['logoFile'];
    _bannerFile = widget.initialData['bannerFile'];
    
    // Carregar cores do layoutConfig se existir
    if (widget.initialData['layoutConfig'] != null) {
      final config = LayoutConfig.fromJson(widget.initialData['layoutConfig']);
      _primaryColor = config.primaryColor;
      _secondaryColor = config.secondaryColor;
    }
    
    if (widget.initialData['categoryIds'] != null) {
      _selectedCategoryIds = List<int>.from(widget.initialData['categoryIds']);
    }

    // Registrar callback de validação
    widget.onValidationCallback?.call(validate);
  }

  bool validate() {
    if (_selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos uma categoria'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  void _notifyChanges() {
    widget.onDataChanged({
      'logoFile': _logoFile,
      'bannerFile': _bannerFile,
      'layoutConfig': {
        'primaryColor': _primaryColor,
        'secondaryColor': _secondaryColor,
      },
      'categoryIds': _selectedCategoryIds,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'Personalização',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customize a aparência do seu restaurante',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // SEÇÃO 1: IMAGENS
          _buildSectionHeader('Imagens', Icons.collections),
          const SizedBox(height: 16),

          ImagePickerCard(
            label: 'Logo do Restaurante (opcional)',
            imageFile: _logoFile,
            onImageSelected: (file) {
              setState(() {
                _logoFile = file;
                _notifyChanges();
              });
            },
          ),
          const SizedBox(height: 16),

          ImagePickerCard(
            label: 'Banner de Capa (opcional)',
            imageFile: _bannerFile,
            onImageSelected: (file) {
              setState(() {
                _bannerFile = file;
                _notifyChanges();
              });
            },
          ),

          const SizedBox(height: 32),

          // SEÇÃO 2: CORES
          _buildSectionHeader('Cores da Marca', Icons.palette),
          const SizedBox(height: 16),

          ColorPickerField(
            label: 'Cor Primária',
            value: _primaryColor,
            onColorChanged: (color) {
              setState(() {
                _primaryColor = color;
                _notifyChanges();
              });
            },
          ),
          const SizedBox(height: 16),

          ColorPickerField(
            label: 'Cor Secundária',
            value: _secondaryColor,
            onColorChanged: (color) {
              setState(() {
                _secondaryColor = color;
                _notifyChanges();
              });
            },
          ),
          const SizedBox(height: 16),

          // Preview das cores
          _buildColorPreview(),

          const SizedBox(height: 32),

          // SEÇÃO 3: CATEGORIAS
          _buildSectionHeader('Categorias', Icons.category),
          const SizedBox(height: 16),

          CategorySelector(
            selectedCategoryIds: _selectedCategoryIds,
            onSelectionChanged: (ids) {
              setState(() {
                _selectedCategoryIds = ids;
                _notifyChanges();
              });
            },
          ),

          const SizedBox(height: 32),

          // SEÇÃO 4: RESUMO
          _buildSectionHeader('Resumo do Cadastro', Icons.summarize),
          const SizedBox(height: 16),

          _buildSummary(),

          const SizedBox(height: 32),

          // Botão de submissão
          ElevatedButton(
            onPressed: widget.isSubmitting ? null : widget.onSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: widget.isSubmitting
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Cadastrando...'),
                    ],
                  )
                : const Text('Finalizar Cadastro'),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildColorPreview() {
    final primaryColor = Color(
      int.parse(_primaryColor.substring(1), radix: 16) + 0xFF000000,
    );
    final secondaryColor = Color(
      int.parse(_secondaryColor.substring(1), radix: 16) + 0xFF000000,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview das Cores',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Primária',
                        style: TextStyle(
                          color: _getContrastColor(primaryColor),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Secundária',
                        style: TextStyle(
                          color: _getContrastColor(secondaryColor),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildSummary() {
    return ExpansionTile(
      title: const Text('Ver todos os dados'),
      subtitle: const Text('Clique para expandir o resumo completo'),
      leading: const Icon(Icons.info_outline),
      initiallyExpanded: false,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dados do proprietário (se não logado)
              if (widget.initialData['ownerFullName'] != null) ...[
                _buildSummarySection(
                  'Proprietário',
                  [
                    'Nome: ${widget.initialData['ownerFullName']}',
                    'Email: ${widget.initialData['ownerEmail']}',
                    'Telefone: ${widget.initialData['ownerPhoneNumber']}',
                  ],
                ),
                const Divider(height: 32),
              ],

              // Dados do restaurante
              _buildSummarySection(
                'Restaurante',
                [
                  'Nome: ${widget.initialData['restaurantName']}',
                  'Slug: ${widget.initialData['restaurantSlug']}',
                  'CNPJ: ${widget.initialData['restaurantCNPJ']}',
                  'Telefone: ${widget.initialData['restaurantPhoneNumber']}',
                  'Taxa de entrega: R\$ ${widget.initialData['deliveryFee']?.toStringAsFixed(2) ?? '0,00'}',
                  'Pedido mínimo: R\$ ${widget.initialData['minimumOrder']?.toStringAsFixed(2) ?? '0,00'}',
                  'Tempo de entrega: ${widget.initialData['deliveryTimeMin']} min',
                ],
              ),
              const Divider(height: 32),

              // Endereço
              _buildSummarySection(
                'Endereço',
                [
                  '${widget.initialData['addressStreet']}, ${widget.initialData['addressNumber']}',
                  if (widget.initialData['addressComplement']?.isNotEmpty == true)
                    widget.initialData['addressComplement'],
                  '${widget.initialData['addressNeighborhood']} - ${widget.initialData['addressCity']}/${widget.initialData['addressState']}',
                  'CEP: ${widget.initialData['addressZipCode']}',
                ],
              ),
              const Divider(height: 32),

              // Horários
              _buildSummarySection(
                'Horários de Funcionamento',
                (widget.initialData['openingHours'] as List? ?? []).map((h) {
                  final weekdays = ['', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
                  final label = h['label']?.isNotEmpty == true ? '${h['label']} - ' : '';
                  return '$label${weekdays[h['weekday']]}: ${h['openTime'].substring(0, 5)} - ${h['closeTime'].substring(0, 5)}';
                }).toList(),
              ),
              const Divider(height: 32),

              // Personalização
              _buildSummarySection(
                'Personalização',
                [
                  'Logo: ${_logoFile != null ? 'Selecionado' : 'Não selecionado'}',
                  'Banner: ${_bannerFile != null ? 'Selecionado' : 'Não selecionado'}',
                  'Cor primária: $_primaryColor',
                  'Cor secundária: $_secondaryColor',
                  'Categorias: ${_selectedCategoryIds.length} selecionada(s)',
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...items.where((item) => item.isNotEmpty).map((item) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16)),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
