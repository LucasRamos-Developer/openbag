import 'dart:io';
import 'package:flutter/material.dart';
import '../../../widgets/onboarding/compact_image_picker.dart';
import '../../../widgets/onboarding/color_picker_field.dart';
import '../../../models/onboarding/layout_config.dart';
import '../../../models/restaurant.dart';
import '../../../services/category_service.dart';
import '../../../core/ui/ui.dart';

/// Step 4: Personalização (Logo + Cores + Categorias)
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
  String _primaryColor = LayoutConfig.defaultConfig.primaryColor;
  String _secondaryColor = LayoutConfig.defaultConfig.secondaryColor;
  List<int> _selectedCategoryIds = [];
  
  final CategoryService _categoryService = CategoryService();
  List<Category>? _categories;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    
    // Restaurar dados salvos
    _logoFile = widget.initialData['logoFile'];
    
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
    
    // Carregar categorias
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getAllCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
        AppToast.show(
          context,
          message: 'Erro ao carregar categorias: $e',
          type: ToastType.error,
        );
      }
    }
  }

  bool validate() {
    // Por enquanto, sem validações obrigatórias
    return true;
  }

  void _notifyChanges() {
    widget.onDataChanged({
      'logoFile': _logoFile,
      'layoutConfig': {
        'primaryColor': _primaryColor,
        'secondaryColor': _secondaryColor,
      },
      'categoryIds': _selectedCategoryIds,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Personalização',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Customize a aparência do seu restaurante',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),

            // Logo | Cores (Primária e Secundária em coluna)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Expanded(
                  flex: 2,
                  child: CompactImagePicker(
                    label: '',
                    imageFile: _logoFile,
                    onImageSelected: (file) {
                      setState(() {
                        _logoFile = file;
                        _notifyChanges();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                
                // Cores (coluna)
                Expanded(
                  child: Column(
                    children: [
                      // Cor Primária
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
                      const SizedBox(height: 20),
                      
                      // Cor Secundária
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Categorias (Select multiselect)
            if (_isLoadingCategories)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_categories != null && _categories!.isNotEmpty)
              AppSelect<int>(
                labelText: 'Categorias',
                hintText: 'Selecione as categorias do seu restaurante',
                variant: TextFieldVariant.filled,
                multiSelect: true,
                values: _selectedCategoryIds,
                items: _categories!
                    .map((c) => SelectItem(
                          value: c.id,
                          label: c.name,
                          description: c.description,
                        ))
                    .toList(),
                onMultiChanged: (ids) {
                  setState(() {
                    _selectedCategoryIds = ids;
                    _notifyChanges();
                  });
                },
                validator: (value) {
                  if (_selectedCategoryIds.isEmpty) {
                    return 'Selecione pelo menos uma categoria';
                  }
                  return null;
                },
              )
            else
              AppTextField(
                labelText: 'Categorias',
                hintText: 'Erro ao carregar categorias',
                variant: TextFieldVariant.filled,
                enabled: false,
              ),
          ],
        ),
      ),
    );
  }
}
