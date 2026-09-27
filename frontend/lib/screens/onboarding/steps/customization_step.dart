import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../widgets/onboarding/compact_image_picker.dart';
import '../../../widgets/restaurant/theme_preset_picker.dart';
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
  XFile? _logoFile;
  AppThemePreset _preset = AppThemePreset.fallback;
  String? _brandColor;
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
      _preset = AppThemePreset.fromKey(config.themePreset);
      _brandColor = config.brandColor;
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
      'layoutConfig': LayoutConfig(themePreset: _preset.key, brandColor: _brandColor).toJson(),
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

            // Logo
            CompactImagePicker(
              label: 'Logo (opcional)',
              imageFile: _logoFile,
              onImageSelected: (file) {
                setState(() {
                  _logoFile = file;
                  _notifyChanges();
                });
              },
            ),
            const SizedBox(height: 28),

            // Tema da página (dá para trocar depois em Loja > Aparência)
            Text('Tema da sua página', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Escolha as cores da sua loja. Você pode trocar quando quiser no painel.',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            ThemePresetPicker(
              value: _preset,
              onChanged: (preset) => setState(() {
                _preset = preset;
                _notifyChanges();
              }),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Usar a cor da minha marca'),
              value: _brandColor != null,
              onChanged: (v) => setState(() {
                _brandColor = v ? AppThemeColors.toHex(_preset.colors.primary) : null;
                _notifyChanges();
              }),
            ),
            if (_brandColor != null)
              AppColorField(
                label: 'Cor da marca',
                value: _brandColor!,
                onChanged: (hex) => setState(() {
                  _brandColor = hex;
                  _notifyChanges();
                }),
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
